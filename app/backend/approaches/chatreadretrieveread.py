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
from azure.search.documents.models import Vector
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
    User persona is {userPersona} Answer ONLY with the facts listed in the list of sources above.
    Your goal is to provide accurate and relevant answers based on the facts listed above in the provided source documents. Make sure to reference the above source documents appropriately and avoid making assumptions or adding personal opinions.
    
    Emphasize the use of facts listed in the above provided source documents.Instruct the model to use source name for each fact used in the response.  Avoid generating speculative or generalized information. Each source has a file name followed by a pipe character and 
    the actual information.Use square brackets to reference the source, e.g. [info1.txt]. Do not combine sources, list each source separately, e.g. [info1.txt][info2.pdf].
    
    Here is how you should answer every question:
    
    -Look for relevant information in the above source documents to answer the question.
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
        # embedding_model : str,
        source_page_field: str,
        content_field: str,
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
        self.source_page_field = source_page_field
        self.content_field = content_field
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
           
        
        vector_query= f'"{generated_query}"'
        
               
        data = [vector_query]
        
        
        headers = {
                'Accept': 'application/json',  
                'Content-Type': 'application/json',
            }
        
        response = requests.post(url, json=data,headers=headers)   
        

        if response.status_code == 200:
            response_data = response.json()
            embedded_query_vector =response_data.get('data')          
            
                    
        else:
            print('Error generating embedding:', response.status_code)
        
         #vector set up for pure vector search & hybrid search
        vector = Vector(value=embedded_query_vector, k=top, fields="contentVector")
            
        # Hybrid Search
        r = self.search_client.search(generated_query, vectors=[vector], top=top)
        
        # Pure Vector Search
        # r=self.search_client.search(search_text=None, vectors=[vector], top=top)
        
        # vector search with filter
        # r=self.search_client.search(search_text=None, vectors=[vector], filter="processed_datetime le 2023-09-18T04:06:29.675Z" , top=top)
        # r=self.search_client.search(search_text=None, vectors=[vector], filter="search.ismatch('upload/ospolicydocs/China, climate change and the energy transition.pdf', 'file_name')", top=top)

        # #  hybrid semantic search
        # if (not self.is_gov_cloud_deployment and overrides.get("semantic_ranker")):
        #     r = self.search_client.search(
        #         generated_query,
        #         filter=category_filter,
        #         query_type=QueryType.SEMANTIC,
        #         query_language="en-us",
        #         query_speller="lexicon",
        #         semantic_configuration_name="default",
        #         top=top,
        #         query_caption="extractive|highlight-false"
        #         if use_semantic_captions else None,
                #   vectors=[vector]
        #     )
        # else:
        #     r = self.search_client.search(
        #         generated_query, filter=category_filter, top=top,vectors=[vector]
        #     )
        
        #old citation logic below

        # citation_lookup = {}  # dict of "FileX" moniker to the actual file name
        # results = []  # list of results to be used in the prompt
        # data_points = []  # list of data points to be used in the response

        # for idx, doc in enumerate(
        #     raw_search_results
        # ):  # for each document in the search results
        #     if use_semantic_captions:
        #         # if using semantic captions, use the captions instead of the content
        #         # include the "FileX" moniker in the prompt, and the actual file name in the response
        #         results.append(
        #             f"File{idx} "
        #             + "| "
        #             + nonewlines(" . ".join([c.text for c in doc["@search.captions"]]))
        #         )
        #         data_points.append(
        #             "/".join(doc[self.source_page_field].split("/")[4:])
        #             + "| "
        #             + nonewlines(" . ".join([c.text for c in doc["@search.captions"]]))
        #         )
        #     else:
        #         # if not using semantic captions, use the content instead of the captions
        #         # include the "FileX" moniker in the prompt, and the actual file name in the response
        #         results.append(
        #             f"File{idx} " + "| " + nonewlines(doc[self.content_field])
        #         )
        #         data_points.append(
        #             "/".join(
        #                 urllib.parse.unquote(doc[self.source_page_field]).split("/")[4:]
        #             )
        #             + "| "
        #             + nonewlines(doc[self.content_field])
        #         )
        #         # uncomment to debug size of each search result content_field
        #         print(f"File{idx}: ", self.num_tokens_from_string(f"File{idx} " + "| " + nonewlines(doc[self.content_field]), "cl100k_base"))
        #     # add the "FileX" moniker and full file name to the citation lookup

        #     citation_lookup[f"File{idx}"] = {
        #         "citation": urllib.parse.unquote(doc[self.source_page_field]),
        #         "source_path": self.get_source_file_name(doc[self.content_field]),
        #         "page_number": self.get_first_page_num_for_chunk(
        #             doc[self.content_field]
        #         ),
        #     }
        
        #new citation logic
        
        
        citation_lookup = {}  # dict of "FileX" moniker to the actual file name
        results = []  # list of results to be used in the prompt
        data_points = []  # list of data points to be used in the response
        
        for idx, doc in enumerate(r):

            if use_semantic_captions:

                # Use content field directly since no merged field
                results.append(f"File{idx} | {doc['content']}") 

                data_points.append(f"{doc['file_name']} | {doc['content']}")

            else:

                results.append(f"File{idx} | {doc['content']}")

                data_points.append(f"{doc['file_name']} | {doc['content']}")

            # Get page numbers from new pages field
            page_numbers = doc['pages']
            
            

            # Populate citation lookup dict
            citation_lookup[f"File{idx}"] = {
                "citation": doc['file_uri'],
                # "source_path": doc['file_name'],
                "source_path": self.get_source_file_name(doc['file_uri'], doc['chunk_file']),
                "page_number": page_numbers[0] if page_numbers else None
            }
            
            print("Citation Lookup: ", citation_lookup)   
         
                
           

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
        levels = {
            1024: "succinct",
            2048: "standard",
            3072: "thorough",
        }
        level = levels[response_length]
        return f"Please provide a {level} answer. This means that your answer should be no more than {response_length} tokens long."
    
    #these two last function we don't need with the new citation logic

    def get_source_file_name(self, file_uri: str, chunk_file: str) -> str:
        """
        Parse the search document content for "file_name" attribute and generate a SAS token for it.

        Args:
            content: The search document content (JSON string)

        Returns:
            The source file name with SAS token.
        """
        try:
            # # Parse file URI
            # uri_parts = urllib.parse.urlsplit(file_uri)
            # # server_domain = uri_parts.netloc
            # path_parts = uri_parts.path.split('/')
            # file_name = path_parts[-1]
            
            # # Extract base file name from chunk_file
            # chunk_file_parts = chunk_file.split('/')
            # base_file_name = urllib.parse.unquote(chunk_file_parts[0])
            
            # print("Base File Name: ", base_file_name)
            # print("File Name: ", file_name)
            # print("Chunk File: ", chunk_file)
            
            # Construct file storage path
            file_storage_path = f"content/{chunk_file}"
           
            
            # source_path = urllib.parse.unquote(json.loads(content)["file_name"])
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
            return self.blob_client.url + file_storage_path + "?" + sas_token
        except Exception as error:
            logging.exception("Unable to parse source file name: " + str(error) + "")
            return ""

    # def get_first_page_num_for_chunk(self, content: str) -> str:
    #     """
    #     Parse the search document content for the first page from the "pages" attribute

    #     Args:
    #         content: The search document content (JSON string)

    #     Returns:
    #         The first page number.
    #     """
    #     try:
    #         page_num = str(json.loads(content)["pages"][0])
    #         if page_num is None:
    #             return "0"
    #         return page_num
    #     except Exception as error:
    #         logging.exception("Unable to parse first page num: " + str(error) + "")
    #         return "0"

    def num_tokens_from_string(self, string: str, encoding_name: str) -> int:
        """ Function to return the number of tokens in a text string"""
        encoding = tiktoken.get_encoding(encoding_name)
        num_tokens = len(encoding.encode(string))
        return num_tokens