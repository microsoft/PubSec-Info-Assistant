# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import json
import re
import logging
import urllib.parse
from datetime import datetime, timedelta
from typing import Any, Sequence

import openai
from approaches.approach import Approach
from azure.core.credentials import AzureKeyCredential 
from azure.search.documents import SearchClient  
from azure.search.documents.indexes import SearchIndexClient  
from azure.search.documents.models import RawVectorQuery
from azure.search.documents.models import QueryType

from text import nonewlines
from datetime import datetime, timedelta
from azure.storage.blob import (
    AccountSasPermissions,
    BlobServiceClient,
    ResourceTypes,
    generate_account_sas,
)
from text import nonewlines
import tiktoken
from core.messagebuilder import MessageBuilder
from core.modelhelper import get_token_limit
from core.modelhelper import num_tokens_from_messages
import requests
from urllib.parse import quote

# Simple retrieve-then-read implementation, using the Cognitive Search and
# OpenAI APIs directly. It first retrieves top documents from search,
# then constructs a prompt with them, and then uses OpenAI to generate
# an completion (answer) with that prompt.

class ChatReadRetrieveReadApproach(Approach):

     # Chat roles
    SYSTEM = "system"
    USER = "user"
    ASSISTANT = "assistant"
     
    system_message_chat_conversation = """You are an Azure OpenAI Completion system. Your persona is {systemPersona} who helps answer questions about an agency's data. {response_length_prompt}
    User persona is {userPersona} Answer ONLY with the facts listed in the list of sources above in {query_term_language}
    Your goal is to provide accurate and relevant answers based on the facts listed above in the provided source documents. Make sure to reference the above source documents appropriately and avoid making assumptions or adding personal opinions.
    
    Emphasize the use of facts listed in the above provided source documents.Instruct the model to use source name for each fact used in the response.  Avoid generating speculative or generalized information. Each source has a file name followed by a pipe character and 
    the actual information.Use square brackets to reference the source, e.g. [info1.txt]. Do not combine sources, list each source separately, e.g. [info1.txt][info2.pdf].
    
    Here is how you should answer every question:
    
    -Look for relevant information in the above source documents to answer the question in {query_term_language}.
    -If the source document does not include the exact answer, please respond with relevant information from the data in the response along with citation.You must include a citation to each document referenced.      
    -If you cannot find any relevant information in the above sources, respond with I am not sure.Do not provide personal opinions or assumptions.
    
    {follow_up_questions_prompt}
    {injected_prompt}
    
    """
    follow_up_questions_prompt_content = """
    Generate three very brief follow-up questions that the user would likely ask next about their agencies data. Use triple angle brackets to reference the questions, e.g. <<<Are there exclusions for prescriptions?>>>. Try not to repeat questions that have already been asked.
    Only generate questions and do not generate any text before or after the questions, such as 'Next Questions'
    """
    query_prompt_template = """Below is a history of the conversation so far, and a new question asked by the user that needs to be answered by searching in source documents.
    Generate a search query based on the conversation and the new question. Treat each search term as an individual keyword. Do not combine terms in quotes or brackets.
    Do not include cited source filenames and document names e.g info.txt or doc.pdf in the search query terms.
    Do not include any text inside [] or <<<>>> in the search query terms.
    Do not include any special characters like '+'.
    If the question is not in {query_term_language}, translate the question to {query_term_language} before generating the search query.
    If you cannot generate a search query, return just the number 0.
    """

    #Few Shot prompting for Keyword Search Query
    query_prompt_few_shots = [
    {'role' : USER, 'content' : 'What are the future plans for public transportation development?' },
    {'role' : ASSISTANT, 'content' : 'Future plans for public transportation' },
    {'role' : USER, 'content' : 'how much renewable energy was generated last year?' },
    {'role' : ASSISTANT, 'content' : 'Renewable energy generation last year' }
    ]

    #Few Shot prompting for Response. This will feed into Chain of thought system message.
    response_prompt_few_shots = [
    {"role": USER ,'content': 'I am looking for information in source documents'},
    {'role': ASSISTANT, 'content': 'user is looking for information in source documents. Do not provide answers that are not in the source documents'},
    {'role': USER, 'content': 'What steps are being taken to promote energy conservation?'},
    {'role': ASSISTANT, 'content': 'Several steps are being taken to promote energy conservation including reducing energy consumption, increasing energy efficiency, and increasing the use of renewable energy sources.Citations[info1.json]'}
    ]
    
    # # Define a class variable for the base URL
    # EMBEDDING_SERVICE_BASE_URL = 'https://infoasst-cr-{}.azurewebsites.net'
    
    def __init__(
        self,
        search_client: SearchClient,
        oai_service_name: str,
        oai_service_key: str,
        chatgpt_deployment: str,
        source_file_field: str,
        content_field: str,
        page_number_field: str,
        chunk_file_field: str,
        content_storage_container: str,
        blob_client: BlobServiceClient,
        query_term_language: str,
        model_name: str,
        model_version: str,
        is_gov_cloud_deployment: str,
        TARGET_EMBEDDING_MODEL: str,
        ENRICHMENT_APPSERVICE_NAME: str
    ):
        self.search_client = search_client
        self.chatgpt_deployment = chatgpt_deployment
        self.source_file_field = source_file_field
        self.content_field = content_field
        self.page_number_field = page_number_field
        self.chunk_file_field = chunk_file_field
        self.content_storage_container = content_storage_container
        self.blob_client = blob_client
        self.query_term_language = query_term_language
        self.chatgpt_token_limit = get_token_limit(model_name)
        #escape target embeddiong model name
        self.escaped_target_model = re.sub(r'[^a-zA-Z0-9_\-.]', '_', TARGET_EMBEDDING_MODEL)
        
        if is_gov_cloud_deployment:
            self.embedding_service_url = f'https://{ENRICHMENT_APPSERVICE_NAME}.azurewebsites.us'
        else:
            self.embedding_service_url = f'https://{ENRICHMENT_APPSERVICE_NAME}.azurewebsites.net'
        
        openai.api_base = 'https://' + oai_service_name + '.openai.azure.com/'
        openai.api_type = 'azure'
        openai.api_key = oai_service_key

        self.model_name = model_name
        self.model_version = model_version
        self.is_gov_cloud_deployment = is_gov_cloud_deployment
        

    # def run(self, history: list[dict], overrides: dict) -> any:
    def run(self, history: Sequence[dict[str, str]], overrides: dict[str, Any]) -> Any:
        use_semantic_captions = True if overrides.get("semantic_captions") else False
        top = overrides.get("top") or 3
        user_persona = overrides.get("user_persona", "")
        system_persona = overrides.get("system_persona", "")
        response_length = int(overrides.get("response_length") or 1024)
        folder_filter = overrides.get("selected_folders", "")
        tags_filter = overrides.get("selected_tags", "")

        user_q = 'Generate search query for: ' + history[-1]["user"]
        
        query_prompt=self.query_prompt_template.format(query_term_language=self.query_term_language)
        

        # STEP 1: Generate an optimized keyword search query based on the chat history and the last question
        messages = self.get_messages_from_history(
            query_prompt,
            self.model_name,
            history,
            user_q,
            self.query_prompt_few_shots,
            self.chatgpt_token_limit - len(user_q)
            )

        chat_completion = openai.ChatCompletion.create(
            deployment_id=self.chatgpt_deployment,
            model=self.model_name,
            messages=messages,
            temperature=0.0,
            max_tokens=32,
            n=1)

        generated_query = chat_completion.choices[0].message.content
        #if we fail to generate a query, return the last user question
        if generated_query.strip() == "0":
            generated_query = history[-1]["user"]

        # Generate embedding using REST API
        url = f'{self.embedding_service_url}/models/{self.escaped_target_model}/embed'
        data = [f'"{generated_query}"']
        headers = {
                'Accept': 'application/json',  
                'Content-Type': 'application/json',
            }

        response = requests.post(url, json=data,headers=headers,timeout=60)
        if response.status_code == 200:
            response_data = response.json()
            embedded_query_vector =response_data.get('data')          
        else:
            logging.error(f"Error generating embedding:: {response.status_code}")
            raise Exception('Error generating embedding:', response.status_code)

        #vector set up for pure vector search & Hybrid search & Hybrid semantic
        vector = RawVectorQuery(vector=embedded_query_vector, k=top, fields="contentVector")

        #Create a filter for the search query
        if (folder_filter != "") & (folder_filter != "All"):
            search_filter = f"search.in(folder, '{folder_filter}')"
        else:
            search_filter = None
        if tags_filter != "" :
            quoted_tags_filter = tags_filter.replace(",","','")
            if search_filter is not None:
                search_filter = search_filter + f" and tags/any(t: search.in(t, '{quoted_tags_filter}'))"
            else:
                search_filter = f"tags/any(t: search.in(t, '{quoted_tags_filter}'))"

        # Hybrid Search
        # r = self.search_client.search(generated_query, vector_queries =[vector], top=top)

        # Pure Vector Search
        # r=self.search_client.search(search_text=None,vector_queries =[vector], top=top)
        
        # vector search with filter
        # r=self.search_client.search(search_text=None, vectors=[vector], filter="processed_datetime le 2023-09-18T04:06:29.675Z" , top=top)
        # r=self.search_client.search(search_text=None, vectors=[vector], filter="search.ismatch('upload/ospolicydocs/China, climate change and the energy transition.pdf', 'file_name')", top=top)

        #  hybrid semantic search using semantic reranker
       
        if (not self.is_gov_cloud_deployment and overrides.get("semantic_ranker")):
            r = self.search_client.search(
                generated_query,
                query_type=QueryType.SEMANTIC,
                query_language="en-us",
                # query_language=self.query_term_language,
                query_speller="lexicon",
                semantic_configuration_name="default",
                top=top,
                query_caption="extractive|highlight-false"
                if use_semantic_captions else None,
                vector_queries =[vector],
                filter=search_filter
            )
        else:
            r = self.search_client.search(
                generated_query, top=top,vector_queries =[vector], filter=search_filter
            )

        citation_lookup = {}  # dict of "FileX" moniker to the actual file name
        results = []  # list of results to be used in the prompt
        data_points = []  # list of data points to be used in the response

        for idx, doc in enumerate(r):  # for each document in the search results
            # include the "FileX" moniker in the prompt, and the actual file name in the response
            results.append(
                f"File{idx} " + "| " + nonewlines(doc[self.content_field])
            )
            data_points.append(
               "/".join(urllib.parse.unquote(doc[self.source_file_field]).split("/")[4:]
                ) + "| " + nonewlines(doc[self.content_field])
                )
            # uncomment to debug size of each search result content_field
            # print(f"File{idx}: ", self.num_tokens_from_string(f"File{idx} " + /
            #  "| " + nonewlines(doc[self.content_field]), "cl100k_base"))

            # add the "FileX" moniker and full file name to the citation lookup
            citation_lookup[f"File{idx}"] = {
                "citation": urllib.parse.unquote("https://" + doc[self.source_file_field].split("/")[2] + f"/{self.content_storage_container}/" + doc[self.chunk_file_field]),
                "source_path": self.get_source_file_with_sas(doc[self.source_file_field]),
                "page_number": str(doc[self.page_number_field][0]) or "0",
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
            system_message = self.system_message_chat_conversation.format(
                query_term_language=self.query_term_language,
                injected_prompt="",
                follow_up_questions_prompt=follow_up_questions_prompt,
                response_length_prompt=self.get_response_length_prompt_text(
                    response_length
                ),
                userPersona=user_persona,
                systemPersona=system_persona,
            )
        elif prompt_override.startswith(">>>"):
            system_message = self.system_message_chat_conversation.format(
                query_term_language=self.query_term_language,
                injected_prompt=prompt_override[3:] + "\n ",
                follow_up_questions_prompt=follow_up_questions_prompt,
                response_length_prompt=self.get_response_length_prompt_text(
                    response_length
                ),
                userPersona=user_persona,
                systemPersona=system_persona,
            )
        else:
            system_message = self.system_message_chat_conversation.format(
                query_term_language=self.query_term_language,
                follow_up_questions_prompt=follow_up_questions_prompt,
                response_length_prompt=self.get_response_length_prompt_text(
                    response_length
                ),
                userPersona=user_persona,
                systemPersona=system_persona,
            )
        # STEP 3: Generate a contextual and content-specific answer using the search results and chat history.
        #Added conditional block to use different system messages for different models.

        if self.model_name.startswith("gpt-35-turbo"):
            messages = self.get_messages_from_history(
                system_message,
                self.model_name,
                history,
                history[-1]["user"] + "Sources:\n" + content + "\n\n",
                self.response_prompt_few_shots,
                max_tokens=self.chatgpt_token_limit - 500
            )

            #Uncomment to debug token usage.
            #print(messages)
            #message_string = ""
            #for message in messages:
            #    # enumerate the messages and add the role and content elements of the dictoinary to the message_string
            #    message_string += f"{message['role']}: {message['content']}\n"
            #print("Content Tokens: ", self.num_tokens_from_string("Sources:\n" + content + "\n\n", "cl100k_base"))
            #print("System Message Tokens: ", self.num_tokens_from_string(system_message, "cl100k_base"))
            #print("Few Shot Tokens: ", self.num_tokens_from_string(self.response_prompt_few_shots[0]['content'], "cl100k_base"))
            #print("Message Tokens: ", self.num_tokens_from_string(message_string, "cl100k_base"))

            chat_completion = openai.ChatCompletion.create(
            deployment_id=self.chatgpt_deployment,
            model=self.model_name,
            messages=messages,
            temperature=float(overrides.get("response_temp")) or 0.6,
            n=1
        )

        elif self.model_name.startswith("gpt-4"):
            messages = self.get_messages_from_history(
                "Sources:\n" + content + "\n\n" + system_message,
                # system_message + "\n\nSources:\n" + content,
                self.model_name,
                history,
                history[-1]["user"],
                self.response_prompt_few_shots,
                max_tokens=self.chatgpt_token_limit
            )

            #Uncomment to debug token usage.
            #print(messages)
            #message_string = ""
            #for message in messages:
            #    # enumerate the messages and add the role and content elements of the dictoinary to the message_string
            #    message_string += f"{message['role']}: {message['content']}\n"
            #print("Content Tokens: ", self.num_tokens_from_string("Sources:\n" + content + "\n\n", "cl100k_base"))
            #print("System Message Tokens: ", self.num_tokens_from_string(system_message, "cl100k_base"))
            #print("Few Shot Tokens: ", self.num_tokens_from_string(self.response_prompt_few_shots[0]['content'], "cl100k_base"))
            #print("Message Tokens: ", self.num_tokens_from_string(message_string, "cl100k_base"))

            chat_completion = openai.ChatCompletion.create(
            deployment_id=self.chatgpt_deployment,
            model=self.model_name,
            messages=messages,
            temperature=float(overrides.get("response_temp")) or 0.6,
            max_tokens=1024,
            n=1
        )

        # STEP 4: Format the response
        msg_to_display = '\n\n'.join([str(message) for message in messages])

        return {
            "data_points": data_points,
            "answer": f"{urllib.parse.unquote(chat_completion.choices[0].message.content)}",
            "thoughts": f"Searched for:<br>{generated_query}<br><br>Conversations:<br>" + msg_to_display.replace('\n', '<br>'),
            "citation_lookup": citation_lookup
        }

    #Aparmar. Custom method to construct Chat History as opposed to single string of chat History.
    def get_messages_from_history(
        self,
        system_prompt: str,
        model_id: str,
        history: Sequence[dict[str, str]],
        user_conv: str,
        few_shots = [],
        max_tokens: int = 4096) -> []:
        """
        Construct a list of messages from the chat history and the user's question.
        """
        message_builder = MessageBuilder(system_prompt, model_id)

        # Few Shot prompting. Add examples to show the chat what responses we want. It will try to mimic any responses and make sure they match the rules laid out in the system message.
        for shot in few_shots:
            message_builder.append_message(shot.get('role'), shot.get('content'))

        user_content = user_conv
        append_index = len(few_shots) + 1

        message_builder.append_message(self.USER, user_content, index=append_index)

        for h in reversed(history[:-1]):
            if h.get("bot"):
                message_builder.append_message(self.ASSISTANT, h.get('bot'), index=append_index)
            message_builder.append_message(self.USER, h.get('user'), index=append_index)
            if message_builder.token_length > max_tokens:
                break

        messages = message_builder.messages
        return messages

    #Get the prompt text for the response length
    def get_response_length_prompt_text(self, response_length: int):
        """ Function to return the response length prompt text"""
        levels = {
            1024: "succinct",
            2048: "standard",
            3072: "thorough",
        }
        level = levels[response_length]
        return f"Please provide a {level} answer. This means that your answer should be no more than {response_length} tokens long."

    def num_tokens_from_string(self, string: str, encoding_name: str) -> int:
        """ Function to return the number of tokens in a text string"""
        encoding = tiktoken.get_encoding(encoding_name)
        num_tokens = len(encoding.encode(string))
        return num_tokens

    def get_source_file_with_sas(self, source_file: str) -> str:
        """ Function to return the source file with a SAS token"""
        try:
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
            return source_file + "?" + sas_token
        except Exception as error:
            logging.error(f"Unable to parse source file name: {str(error)}")
            return ""