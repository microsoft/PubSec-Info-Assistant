# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import json
import logging
import urllib.parse
from datetime import datetime, timedelta

import openai
from approaches.approach import Approach
from azure.search.documents import SearchClient
from azure.search.documents.models import QueryType
from azure.storage.blob import (
    AccountSasPermissions,
    BlobServiceClient,
    ResourceTypes,
    generate_account_sas,
)
from text import nonewlines


class ChatReadRetrieveReadApproach(Approach):
    """
    Simple retrieve-then-read implementation, using the Cognitive Search and OpenAI APIs directly. It first retrieves
    top documents from search, then constructs a prompt with them, and then uses OpenAI to generate an completion
    (answer) with that prompt.
    """

    prompt_prefix = """<|im_start|>
    You are an intelligent OpenAI bot that help citizens of Albania discover information about online government services on "e-Albania" portal. Some services on "e-Albania" portal are building permits, 
    e-signatures, certificates and other governmental services offered online.
    
    Your persona is approachable, friendly, welcoming, knowledgable, patient, empathetic, assertive and proffesional who helps answer questions of citizens of Albania about "e-Albania" portal only.
    If you think something is not legal, please respond with "Nuk kam informacion per kete pyetje".
    {response_length_prompt}
           
    The data is formated as follows. 
    Category is in the title field: "title". 
    Keywords are in the section field: "section".
    Section that contains the answer is in content field:"content".
     
    Instructions:
        
    1. If there is specific information available in the source document, provide an answer without providing any citation.
    2. Provide step-by-step instructions if available in source document in format that is easier for reading. Add new lines, dashes and numbered lists.
    3. If there is no relevant information about the question in the source document, respond with "Nuk kam informacion per kete pyetje" without providing any citation.
    4. Make sure to respond only to questions based on the source document below.
    5. Always respond in Albanian language only.
    6. Structure the output for easier readability adding dashess, new rows and numbered lists where needed.
    7. Answer only the new question. Do not generate new User questions after providing the answer. Do not provide answers outside sources below.
    8. If there is a link in the source provided, EXCLUDE it from output.
    9. If user is asking for illegal things such as fake documents, respond with "Nuk kam informacion per kete pyetje" without providing any citation.
    {userPersona}
        
    User persona: citizen of Albania looking for information about digital services provided on e-Albania portal.
    
    Emphasize the use of facts listed in the provided source documents in order they are presented. Avoid generating speculative or generalized information. 
    {systemPersona}
    Structure the output for easier readability adding dashess, new rows and numbered lists where needed.
    Make sure to avoid making assumptions or adding personal opinions and additional questions.
    Do not provide answers outside sources below.

    {follow_up_questions_prompt}
    {injected_prompt}
    Sources:
    {sources}
    
    Structure the output for easier readability adding dashess, new rows and numbered lists where needed.
    
    <|im_end|>
    {chat_history}
    """
    follow_up_questions_prompt_content = """
    Generate three very brief follow-up questions that the user would likely ask next about digital services available on e-albania portal data. Use triple angle brackets to reference the questions, e.g. <<<Are there exclusions for prescriptions?>>>. Try not to repeat questions that have already been asked.
    Only generate questions and do not generate any text before or after the questions, such as 'Next Questions'. Generate questions only in {query_term_language} language.
    """

    query_prompt_template = """
    Below is a question asked by the user that needs to be answered by searching in source documents.
Generate a search query based on the Question.
Do not include cited source filenames and document names e.g info.txt or doc.pdf in the search query terms.
Do not include any text inside [] or <<<>>> in the search query terms.
If the question is not in {query_term_language}, translate the question to {query_term_language} before generating the search query.
Treat each search term as an individual keyword. Do not combine terms in quotes or brackets.
IMPORTANT: Do NOT include these specific words in the result: "albania", "Albania", "e-albania", "ealbania", "e-Albania".

    ##  
    Question:  Kerkese per vertetim qe skam biznes e-Albania portal  
    Search query: vertetim skam biznes  
    ##  
    Question:  Cilat jane hapat per te marr nje vertetim liste notash ne e albania?  
    Search query: Vertetim liste notash hapat për të marrë në Shqipëri  
    ##  
    Question: Si mund te nxjerr nje vertetim Albania qe nuk kam precedente penale ne e-albania e ealbania?  
    Search query: precedente penale, vertetim, aplikim  
    ##  
DO NOT put the following words in the result: "albania", "Albania", "e-albania", "ealbania", "e-Albania". These words should be completely excluded from the search query.
Question:
{question}

    Search query:
    """

    def __init__(
        self,
        search_client: SearchClient,
        oai_service_name: str,
        oai_service_key: str,
        chatgpt_deployment: str,
        source_page_field: str,
        content_field: str,
        blob_client: BlobServiceClient,
        query_term_language: str,
    ):
        self.search_client = search_client
        self.chatgpt_deployment = chatgpt_deployment
        self.source_page_field = source_page_field
        self.content_field = content_field
        self.blob_client = blob_client
        self.query_term_language = query_term_language

        openai.api_base = "https://" + oai_service_name + ".openai.azure.com/"
        openai.api_type = "azure"
        openai.api_key = oai_service_key

    def run(self, history: list[dict], overrides: dict) -> any:
        """
        Run the approach on the query and documents.

        Args:
            history: The chat history. (e.g. [{"user": "hello", "bot": "hi"}])
            overrides: Overrides from the user interface for the approach. (e.g. temperature, top,
                semantic_captions etc.)

        Returns:
            The response from the approach as a dict.
        """
        # Overrides
        use_semantic_captions = True if overrides.get("semantic_captions") else False
        top = overrides.get("top") or 3
        response_length = int(overrides.get("response_length") or 1024)

        ## Category filter
        exclude_category = overrides.get("exclude_category") or None
        category_filter = (
            "category ne '{}'".format(exclude_category.replace("'", "''"))
            if exclude_category
            else None
        )

        ## Personas
        user_persona = overrides.get("user_persona", "")
        system_persona = overrides.get("system_persona", "")

        # STEP 1: Generate an optimized keyword search query based on the chat history and the last question.

        prompt = self.query_prompt_template.format(
            chat_history=self.get_chat_history_as_text(
                history, include_last_turn=False
            ),
            question=history[-1]["user"].lower(),
            query_term_language=self.query_term_language,
        )

        completion = openai.Completion.create(
            engine=self.chatgpt_deployment,
            prompt=prompt,
            temperature=0.0,
            max_tokens=32,
            n=1,
            stop=["\n"],
        )
        raw_query_proposal = completion.choices[0].text
        generated_query = raw_query_proposal.strip('"')

        # STEP 2: Retrieve relevant documents from the search index with the optimized query term
        if overrides.get("semantic_ranker"):
            raw_search_results = self.search_client.search(
                generated_query,
                filter=category_filter,
                query_type=QueryType.SEMANTIC,
                query_language="en-us",
                query_speller="lexicon",
                semantic_configuration_name="default",
                top=top,
                query_caption="extractive|highlight-false"
                if use_semantic_captions
                else None,
            )
        else:
            raw_search_results = self.search_client.search(
                generated_query, filter=category_filter, top=top
            )

        citation_lookup = {}  # dict of "FileX" moniker to the actual file name
        results = []  # list of results to be used in the prompt
        data_points = []  # list of data points to be used in the response

        for idx, doc in enumerate(
            raw_search_results
        ):  # for each document in the search results
            if use_semantic_captions:
                # if using semantic captions, use the captions instead of the content
                # include the "FileX" moniker in the prompt, and the actual file name in the response
                results.append(
                    f"File{idx} "
                    + "| "
                    + nonewlines(" . ".join([c.text for c in doc["@search.captions"]]))
                )
                data_points.append(
                    "/".join(doc[self.source_page_field].split("/")[4:])
                    + "| "
                    + nonewlines(" . ".join([c.text for c in doc["@search.captions"]]))
                )
            else:
                # if not using semantic captions, use the content instead of the captions
                # include the "FileX" moniker in the prompt, and the actual file name in the response
                results.append(
                    f"File{idx} " + "| " + nonewlines(doc[self.content_field])
                )
                data_points.append(
                    "/".join(
                        urllib.parse.unquote(doc[self.source_page_field]).split("/")[4:]
                    )
                    + "| "
                    + nonewlines(doc[self.content_field])
                )
            # add the "FileX" moniker and full file name to the citation lookup

            citation_lookup[f"File{idx}"] = {
                "citation": urllib.parse.unquote(doc[self.source_page_field]),
                "source_path": self.get_source_file_name(doc[self.content_field]),
                "page_number": self.get_first_page_num_for_chunk(
                    doc[self.content_field]
                ),
            }

        # create a single string of all the results to be used in the prompt
        results_text = "".join(results)
        if results_text == "":
            content = "\n NONE"
        else:
            content = "\n " + results_text

        # STEP 3: Generate the prompt to be sent to the GPT model
        follow_up_questions_prompt = (
            self.follow_up_questions_prompt_content
            if overrides.get("suggest_followup_questions")
            else ""
        )

        # Allow client to replace the entire prompt, or to inject into the existing prompt using >>>
        prompt_override = overrides.get("prompt_template")
        if prompt_override is None:
            prompt = self.prompt_prefix.format(
                injected_prompt="",
                sources=content,
                chat_history=self.get_chat_history_as_text(history),
                follow_up_questions_prompt=follow_up_questions_prompt,
                response_length_prompt=self.get_response_length_prompt_text(
                    response_length
                ),
                userPersona=user_persona,
                systemPersona=system_persona,
            )
        elif prompt_override.startswith(">>>"):
            prompt = self.prompt_prefix.format(
                injected_prompt=prompt_override[3:] + "\n ",
                sources=content,
                chat_history=self.get_chat_history_as_text(history),
                follow_up_questions_prompt=follow_up_questions_prompt,
                response_length_prompt=self.get_response_length_prompt_text(
                    response_length
                ),
                userPersona=user_persona,
                systemPersona=system_persona,
            )
        else:
            prompt = prompt_override.format(
                sources=content,
                chat_history=self.get_chat_history_as_text(history),
                follow_up_questions_prompt=follow_up_questions_prompt,
                response_length_prompt=self.get_response_length_prompt_text(
                    response_length
                ),
                userPersona=user_persona,
                systemPersona=system_persona,
            )

        # STEP 3: Generate a contextual and content-specific answer using the search results and chat history

        completion = openai.Completion.create(
            engine=self.chatgpt_deployment,
            prompt=prompt,
            temperature=float(overrides.get("response_temp")) or 0.7,
            max_tokens=response_length,
            n=1,
            stop=["<|im_end|>", "<|im_start|>"],
        )

        return {
            "data_points": data_points,
            "answer": f"{urllib.parse.unquote(completion.choices[0].text)}",
            "thoughts": f"Searched for:<br>{generated_query}<br><br>Prompt:<br>"
            + prompt.replace("\n", "<br>"),
            "citation_lookup": citation_lookup,
        }

    def get_chat_history_as_text(self, history, include_last_turn=True) -> str:
        """
        Get the chat history as a single string of text for presenting to the user.

        Args:
            history: The chat history. (e.g. [{"user": "hello", "bot": "hi"}])
            include_last_turn: Whether to include the last turn in the chat history.

        Returns:
            The chat history as a single string of text.
        """
        history_text = ""
        for h in reversed(history if include_last_turn else history[:-1]):
            history_text = (
                """User:"""
                + " "
                + h["user"]
                + "\n"
                + """"""
                + "\n"
                + """Assistant:"""
                + " "
                + (h.get("bot") + """""" if h.get("bot") else "")
                + "\n"
                + history_text
            )

        return history_text

    def get_response_length_prompt_text(self, response_length: int):
        """
        Get the prompt text for the response length

        Args:
            response_length: The response length mapped to a prompt text.

        Returns:
            The prompt text for the response length.
        """
        levels = {
            1024: "succinct",
            2048: "standard",
            3072: "thorough",
        }
        level = levels[response_length]
        return f"Please provide a {level} answer. This means that your answer should be no more than {response_length} tokens long."

    def get_source_file_name(self, content: str) -> str:
        """
        Parse the search document content for "file_name" attribute and generate a SAS token for it.

        Args:
            content: The search document content (JSON string)

        Returns:
            The source file name with SAS token.
        """
        try:
            source_path = urllib.parse.unquote(json.loads(content)["file_name"])
            sas_token = generate_account_sas(
                self.blob_client.account_name,
                self.blob_client.credential.account_key,
                resource_types=ResourceTypes(object=True, service=True, container=True),
                permission=AccountSasPermissions(
                    read=True,
                    write=True,
                    list=True,
                    delete=False,
                    add=True,
                    create=True,
                    update=True,
                    process=False,
                ),
                expiry=datetime.utcnow() + timedelta(hours=1),
            )
            return self.blob_client.url + source_path + "?" + sas_token
        except Exception as error:
            logging.exception("Unable to parse source file name: " + str(error) + "")
            return ""

    def get_first_page_num_for_chunk(self, content: str) -> str:
        """
        Parse the search document content for the first page from the "pages" attribute

        Args:
            content: The search document content (JSON string)

        Returns:
            The first page number.
        """
        try:
            page_num = str(json.loads(content)["pages"][0])
            if page_num is None:
                return "0"
            return page_num
        except Exception as error:
            logging.exception("Unable to parse first page num: " + str(error) + "")
            return "0"