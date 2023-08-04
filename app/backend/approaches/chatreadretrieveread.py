# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import openai
from azure.search.documents import SearchClient
from azure.search.documents.models import QueryType
from approaches.approach import Approach
from text import nonewlines
from datetime import datetime, timedelta
import urllib.parse
import json
import logging
from azure.storage.blob import BlobServiceClient, generate_account_sas, ResourceTypes, AccountSasPermissions
import re

# Simple retrieve-then-read implementation, using the Cognitive Search and OpenAI APIs directly. It first retrieves
# top documents from search, then constructs a prompt with them, and then uses OpenAI to generate an completion
# (answer) with that prompt.
class ChatReadRetrieveReadApproach(Approach):
    prompt_prefix = """<|im_start|>
    You are an Azure OpenAI Completion system. Your persona is {systemPersona} who helps answer questions about an agency's data. {response_length_prompt}
   
   
    Text:
    Flight to Denver at 9:00 am tomorrow.

    Prompt:
    Question: Is my flight on time?

    Steps:
    1. Look for relevant information in the provided source document to answer the question.
    2. If there is specific flight information available in the source document, provide an answer along with the appropriate citation.
    3. If there is no information about the specific flight in the source document, respond with "I'm not sure" without providing any citation.
    
    
    Response:

    1. Look for relevant information in the provided source document to answer the question.
    - Search for flight details matching the given flight to determine its current status.

    2. If there is specific flight information available in the source document, provide an answer along with the appropriate citation.
    - If the source document contains information about the current status of the specified flight, provide a response citing the relevant section of source documents.Don't exclude citation if you are using source document to answer your question.
     
    
    3. If there is no relevant information about the specific flight in the source document, respond with "I'm not sure" without providing any citation.
    

    Example Response:

    Question: Is my flight on time?

    <Response>I'm not sure. The provided source document does not include information about the current status of your specific flight.</Response>
    
        
    User persona: {userPersona}
    Emphasize the use of facts listed in the provided source documents.Instruct the model to use source name for each fact used in the response.  Avoid generating speculative or generalized information. Each source has a file name followed by a pipe character and 
    the actual information.Use square brackets to reference the source, e.g. [info1.txt]. Don't combine sources, list each source separately, e.g. [info1.txt][info2.pdf].
    Treat each search term as an individual keyword. Do not combine terms in quotes or brackets.
    Your goal is to provide accurate and relevant answers based on the information available in the provided source documents. Make sure to reference the source documents appropriately and avoid making assumptions or adding personal opinions.

    {follow_up_questions_prompt}
    {injected_prompt}
    Sources:
    {sources}
    
    
    <|im_end|>
    {chat_history}
    """
    follow_up_questions_prompt_content = """
    Generate three very brief follow-up questions that the user would likely ask next about their agencies data. Use triple angle brackets to reference the questions, e.g. <<<Are there exclusions for prescriptions?>>>. Try not to repeat questions that have already been asked.
    Only generate questions and do not generate any text before or after the questions, such as 'Next Questions'
    """

    query_prompt_template = """
    Below is a history of the conversation so far, and a new question asked by the user that needs to be answered by searching in source documents
    Generate a search query based on the conversation and the new question. 
    Do not include cited source filenames and document names e.g info.txt or doc.pdf in the search query terms.
    Do not include any text inside [] or <<<>>> in the search query terms.
    If the question is not in {query_term_language}, translate the question to {query_term_language} before generating the search query.
    Treat each search term as an individual keyword. Do not combine terms in quotes or brackets.
    For each MBS code, add a link to the MBS (Medicare Benefits Schedule) for that ItemNum. 
    For example MBS: 42485 would link to https://www9.health.gov.au/mbs/fullDisplay.cfm?type=item&qt=item&q=42845
    {t}
    Chat History:
    {chat_history}

    Question:
    {question}

    Search query:
    """


    def __init__(self, search_client: SearchClient, oai_service_name: str, oai_service_key: str, chatgpt_deployment: str, gpt_deployment: str, sourcepage_field: str, content_field: str, blob_client: BlobServiceClient, query_term_language: str):
        self.search_client = search_client
        self.chatgpt_deployment = chatgpt_deployment
        self.gpt_deployment = gpt_deployment
        self.sourcepage_field = sourcepage_field
        self.content_field = content_field
        self.blob_client = blob_client
        self.query_term_language = query_term_language
        openai.api_base = 'https://' + oai_service_name + '.openai.azure.com/'
        openai.api_type = 'azure'
        openai.api_key = oai_service_key

    def run(self, history: list[dict], overrides: dict) -> any:
        use_semantic_captions = True if overrides.get(
            "semantic_captions") else False
        top = overrides.get("top") or 3
        exclude_category = overrides.get("exclude_category") or None
        filter = "category ne '{}'".format(
            exclude_category.replace("'", "''")) if exclude_category else None
        user_persona = overrides.get("user_persona", "")
        system_persona = overrides.get("system_persona", "")
        # aiPersona = overrides.get("ai_persona","")
        response_length = int(overrides.get("response_length") or 1024)
        chat_history_temp = self.get_chat_history_as_text(
            history, include_last_turn=True)
        # STEP 1: Generate an optimized keyword search query based on the chat history and the last question
        prompt = self.query_prompt_template.format(
            chat_history=self.get_chat_history_as_text(
                history, include_last_turn=False),
            question=history[-1]["user"],
            t=self.analyze_healthcare_entities(chat_history_temp),
            query_term_language=self.query_term_language
        )

        completion = openai.Completion.create(
            engine=self.chatgpt_deployment,
            prompt=prompt,
            temperature=0.0,
            max_tokens=32,
            n=1,
            stop=["\n"])
        q = completion.choices[0].text

        generated_query = q.strip('\"')

        # STEP 2: Retrieve relevant documents from the search index with the GPT optimized query
        if overrides.get("semantic_ranker"):
            r = self.search_client.search(generated_query,
                                          filter=filter,
                                          query_type=QueryType.SEMANTIC,
                                          query_language="en-us",
                                          query_speller="lexicon",
                                          semantic_configuration_name="default",
                                          top=top,
                                          query_caption="extractive|highlight-false" if use_semantic_captions else None)
        else:
            r = self.search_client.search(
                generated_query, filter=filter, top=top)

        citation_lookup = {}  # dict of "FileX" monikor to the actual file name
        results = []  # list of results to be used in the prompt
        data_points = []  # list of data points to be used in the response

        for idx, doc in enumerate(r):  # for each document in the search results

            if use_semantic_captions:
                # if using semantic captions, use the captions instead of the content
                # include the "FileX" monikor in the prompt, and the actual file name in the response
                results.append(
                    f"File{idx} " + "| " + nonewlines(" . ".join([c.text for c in doc['@search.captions']])))
                data_points.append("/".join(doc[self.sourcepage_field].split("/")[
                                   4:]) + "| " + nonewlines(" . ".join([c.text for c in doc['@search.captions']])))
            else:
                # if not using semantic captions, use the content instead of the captions
                # include the "FileX" monikor in the prompt, and the actual file name in the response
                results.append(f"File{idx} " + "| " +
                               nonewlines(doc[self.content_field]))
                data_points.append("/".join(urllib.parse.unquote(doc[self.sourcepage_field]).split(
                    "/")[4:]) + "| " + nonewlines(doc[self.content_field]))
            # add the "FileX" monikor and full file name to the citation lookup

            citation_lookup[f"File{idx}"] = {'citation': urllib.parse.unquote(doc[self.sourcepage_field]),
                                             'source_path': self.get_source_file_name(doc[self.content_field]),
                                             'page_number': self.get_first_page_num_for_chunk(doc[self.content_field])}

        # create a single string of all the results to be used in the prompt
        results_text = "".join(results)
        if results_text == "":
            content = "\n NONE"
        else:
            content = "\n " + results_text

        # STEP 3: Generate the prompt to be sent to the GPT model
        follow_up_questions_prompt = self.follow_up_questions_prompt_content if overrides.get(
            "suggest_followup_questions") else ""

        # Allow client to replace the entire prompt, or to inject into the existing prompt using >>>
        prompt_override = overrides.get("prompt_template")
        if prompt_override is None:
            prompt = self.prompt_prefix.format(
                injected_prompt="",
                sources=content,
                chat_history=self.get_chat_history_as_text(history),
                follow_up_questions_prompt=follow_up_questions_prompt,
                response_length_prompt=self.get_repsonse_lenth_prompt_text(
                    response_length),
                userPersona=user_persona,
                systemPersona=system_persona
            )
        elif prompt_override.startswith(">>>"):
            prompt = self.prompt_prefix.format(
                injected_prompt=prompt_override[3:] + "\n ",
                sources=content,
                chat_history=self.get_chat_history_as_text(history),
                follow_up_questions_prompt=follow_up_questions_prompt,
                response_length_prompt=self.get_repsonse_lenth_prompt_text(
                    response_length),
                userPersona=user_persona,
                systemPersona=system_persona
            )
        else:
            prompt = prompt_override.format(
                sources=content,
                chat_history=self.get_chat_history_as_text(history),
                follow_up_questions_prompt=follow_up_questions_prompt,
                response_length_prompt=self.get_repsonse_lenth_prompt_text(
                    response_length),
                userPersona=user_persona,
                systemPersona=system_persona
            )

        # STEP 3: Generate a contextual and content-specific answer using the search results and chat history

        completion = openai.Completion.create(
            engine=self.chatgpt_deployment,
            prompt=prompt,
            temperature=float(overrides.get("response_temp")) or 0.7,
            max_tokens=response_length,
            n=1,
            stop=["<|im_end|>", "<|im_start|>"]
        )

        return {
            "data_points": data_points,
            "answer": f"{urllib.parse.unquote(completion.choices[0].text)}",
            "thoughts": f"Searched for:<br>{q}<br><br>Prompt:<br>" + prompt.replace('\n', '<br>'),
            "citation_lookup": citation_lookup
        }

    # Get the chat history as a single string
    def get_chat_history_as_text(self, history, include_last_turn=True, approx_max_tokens=1000) -> str:
        history_text = ""
        for h in reversed(history if include_last_turn else history[:-1]):
            history_text = (
                """User:""" + " " + h["user"] + "\n" + """""" + "\n" + """Assistant:""" + " " + (
                    h.get("bot") + """""" if h.get("bot") else "") + "\n" + history_text
            )
            if len(history_text) > approx_max_tokens * 4:
                break
        return history_text

    # Get the prompt text for the response length

    def get_repsonse_lenth_prompt_text(self, response_length: int):
        levels = {
            1024: "succinct",
            2048: "standard",
            3072: "thorough",
        }
        level = levels[response_length]
        return f"Please provide a {level} answer. This means that your answer should be no more than {response_length} tokens long."

    def analyze_healthcare_entities(self, q: str) -> str:
        import pandas as pd
        import requests
        import os
        from azure.core.credentials import AzureKeyCredential
        from azure.ai.textanalytics import TextAnalyticsClient, HealthcareEntityRelation
        # [START analyze_healthcare_entities]
        endpoint = "https://langservice2022.cognitiveservices.azure.com/"
        key = "f48deee2f998408da361a0d224840dc8"

        text_analytics_client = TextAnalyticsClient(
            endpoint=endpoint,
            credential=AzureKeyCredential(key),
        )

        documents = [q]

        poller = text_analytics_client.begin_analyze_healthcare_entities(
            documents)
        result = poller.result()
        st = ""
        docs = [doc for doc in result if not doc.is_error]
        df_ = pd.DataFrame(columns=['Term', 'SNOMEDCT_US'])
        for doc in docs:
            for entity in doc.entities:
                if entity.data_sources is not None:
                    for data_source in entity.data_sources:
                        if (data_source.name == "SNOMEDCT_US"):
                            cols = ['Term', 'SNOMEDCT_US']
                            temp = pd.DataFrame(
                                [["SNOMED TERM = "+entity.text, "SNOMED CODE = "+data_source.entity_id]], columns=cols)
                            # print(temp)
                            # ,ignore_index=True
                            df_ = pd.concat([df_, temp], axis=0)
        return (df_.drop_duplicates().to_string(header=False, index=False))
    # Parse the search document content for "file_name" attribute
    def get_source_file_name(self, content: str) -> str:
        try:
            source_path = urllib.parse.unquote(
                json.loads(content)['file_name'])
            sas_token = generate_account_sas(self.blob_client.account_name, self.blob_client.credential.account_key,
                                             resource_types=ResourceTypes(
                                                 object=True, service=True, container=True),
                                             permission=AccountSasPermissions(
                                                 read=True, write=True, list=True, delete=False, add=True, create=True, update=True, process=False),
                                             expiry=datetime.utcnow() + timedelta(hours=1))
            return self.blob_client.url + source_path + "?" + sas_token
        except Exception as e:
            logging.exception(
                "Unable to parse source file name: " + str(e) + "")
            return ""

    # Parse the search document content for the first page from the "pages" attribute
    def get_first_page_num_for_chunk(self, content: str) -> str:
        try:
            page_num = str(json.loads(content)['pages'][0])
            if page_num is None:
                return "0"
            return page_num
        except Exception as e:
            logging.exception("Unable to parse first page num: " + str(e) + "")
            return "0"
