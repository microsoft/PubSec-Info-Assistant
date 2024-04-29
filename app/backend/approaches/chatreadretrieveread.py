# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import re
import logging
import urllib.parse
from datetime import datetime, timedelta
from typing import Any, Sequence

import openai
from approaches.approach import Approach
from azure.search.documents import SearchClient  
from azure.search.documents.models import RawVectorQuery
from azure.search.documents.models import QueryType
from azure.storage.blob import (
    AccountSasPermissions,
    BlobServiceClient,
    ResourceTypes,
    generate_account_sas,
)
from text import nonewlines
from core.modelhelper import get_token_limit
import requests

class ChatReadRetrieveReadApproach(Approach):
    """Approach that uses a simple retrieve-then-read implementation, using the Azure AI Search and
    Azure OpenAI APIs directly. It first retrieves top documents from search,
    then constructs a prompt with them, and then uses Azure OpenAI to generate
    an completion (answer) with that prompt."""
     


    SYSTEM_MESSAGE_CHAT_CONVERSATION = """You are an Azure OpenAI Completion system. Your persona is {systemPersona} who helps answer questions about an agency's data. {response_length_prompt}
    User persona is {userPersona} Answer ONLY with the facts listed in the list of sources below in {query_term_language} with citations.If there isn't enough information below, say you don't know and do not give citations. For tabular information return it as an html table. Do not return markdown format.
    Your goal is to provide answers based on the facts listed below in the provided source documents. Avoid making assumptions,generating speculative or generalized information or adding personal opinions.
   
    Each source has content followed by a pipe character and the URL. Instead of writing the full URL, cite it using placeholders like [File1], [File2], etc., based on their order in the list. Do not combine sources; list each source URL separately, e.g., [File1] [File2].
    Never cite the source content using the examples provided in this paragraph that start with info.
    Sources:
    - Content about topic A | info.pdf
    - Content about topic B | example.txt

    Reference these as [File1] and [File2] respectively in your answers.

    Here is how you should answer every question:
    
    -Look for information in the source documents to answer the question in {query_term_language}.
    -If the source document has an answer, please respond with citation.You must include a citation to each document referenced only once when you find answer in source documents.      
    -If you cannot find answer in below sources, respond with I am not sure.Do not provide personal opinions or assumptions and do not include citations.
    -Identify the language of the user's question and translate the final response to that language.if the final answer is " I am not sure" then also translate it to the language of the user's question and then display translated response only. nothing else.

    {follow_up_questions_prompt}
    {injected_prompt}
    """

    FOLLOW_UP_QUESTIONS_PROMPT_CONTENT = """ALWAYS generate three very brief unordered follow-up questions surrounded by triple chevrons (<<<Are there exclusions for prescriptions?>>>) that the user would likely ask next about their agencies data. 
    Surround each follow-up question with triple chevrons (<<<Are there exclusions for prescriptions?>>>). Try not to repeat questions that have already been asked.
    Only generate follow-up questions and do not generate any text before or after the follow-up questions, such as 'Next Questions'
    """

    QUERY_PROMPT_TEMPLATE = """Below is a history of the conversation so far, and a new question asked by the user that needs to be answered by searching in source documents.
    Generate a search query based on the conversation and the new question. Treat each search term as an individual keyword. Do not combine terms in quotes or brackets.
    Do not include cited source filenames and document names e.g info.txt or doc.pdf in the search query terms.
    Do not include any text inside [] or <<<>>> in the search query terms.
    Do not include any special characters like '+'.
    If you cannot generate a search query, return just the number 0.
    """

    QUERY_PROMPT_FEW_SHOTS = [
        {'role' : Approach.USER, 'content' : 'What are the future plans for public transportation development?' },
        {'role' : Approach.ASSISTANT, 'content' : 'Future plans for public transportation' },
        {'role' : Approach.USER, 'content' : 'how much renewable energy was generated last year?' },
        {'role' : Approach.ASSISTANT, 'content' : 'Renewable energy generation last year' }
    ]

    RESPONSE_PROMPT_FEW_SHOTS = [
        {"role": Approach.USER ,'content': 'I am looking for information in source documents'},
        {'role': Approach.ASSISTANT, 'content': 'user is looking for information in source documents. Do not provide answers that are not in the source documents'},
        {'role': Approach.USER, 'content': 'What steps are being taken to promote energy conservation?'},
        {'role': Approach.ASSISTANT, 'content': 'Several steps are being taken to promote energy conservation including reducing energy consumption, increasing energy efficiency, and increasing the use of renewable energy sources.Citations[File0]'}
    ]
    
    
    def __init__(
        self,
        search_client: SearchClient,
        oai_endpoint: str,
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
        target_embedding_model: str,
        enrichment_appservice_uri: str,
        target_translation_language: str,
        enrichment_endpoint:str,
        enrichment_key:str,
        azure_ai_translation_domain: str,
        use_semantic_reranker: bool
        
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
        self.escaped_target_model = re.sub(r'[^a-zA-Z0-9_\-.]', '_', target_embedding_model)
        self.target_translation_language=target_translation_language
        self.enrichment_endpoint=enrichment_endpoint
        self.enrichment_key=enrichment_key
        self.oai_endpoint=oai_endpoint
        self.embedding_service_url = enrichment_appservice_uri
        self.azure_ai_translation_domain=azure_ai_translation_domain
        self.use_semantic_reranker=use_semantic_reranker
        
        openai.api_base = oai_endpoint
        openai.api_type = 'azure'
        openai.api_key = oai_service_key

        self.model_name = model_name
        self.model_version = model_version
        
    # def run(self, history: list[dict], overrides: dict) -> any:
    async def run(self, history: Sequence[dict[str, str]], overrides: dict[str, Any], citation_lookup: dict[str, Any], thought_chain: dict[str, Any]) -> Any:

        log = logging.getLogger("uvicorn")
        log.setLevel('DEBUG')
        log.propagate = True

        use_semantic_captions = True if overrides.get("semantic_captions") else False
        top = overrides.get("top") or 3
        user_persona = overrides.get("user_persona", "")
        system_persona = overrides.get("system_persona", "")
        response_length = int(overrides.get("response_length") or 1024)
        folder_filter = overrides.get("selected_folders", "")
        tags_filter = overrides.get("selected_tags", "")

        user_q = 'Generate search query for: ' + history[-1]["user"]
        thought_chain["work_query"] = user_q

        # Detect the language of the user's question
        detectedlanguage = self.detect_language(user_q)

        if detectedlanguage != self.target_translation_language:
            user_question = self.translate_response(user_q, self.target_translation_language)
        else:
            user_question = user_q

        query_prompt=self.QUERY_PROMPT_TEMPLATE.format(query_term_language=self.query_term_language)

        # STEP 1: Generate an optimized keyword search query based on the chat history and the last question
        messages = self.get_messages_from_history(
            query_prompt,
            self.model_name,
            history,
            user_question,
            self.QUERY_PROMPT_FEW_SHOTS,
            self.chatgpt_token_limit - len(user_question)
            )

        chat_completion = await openai.ChatCompletion.acreate(
            deployment_id=self.chatgpt_deployment,
            model=self.model_name,
            messages=messages,
            temperature=0.0,
            # max_tokens=32, # setting it too low may cause malformed JSON
            max_tokens=100,
            n=1)

        generated_query = chat_completion.choices[0].message.content
        
        #if we fail to generate a query, return the last user question
        if generated_query.strip() == "0":
            generated_query = history[-1]["user"]

        thought_chain["work_search_term"] = generated_query
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
            log.error(f"Error generating embedding:: {response.status_code}")
            raise Exception('Error generating embedding:', response.status_code)

        #vector set up for pure vector search & Hybrid search & Hybrid semantic
        vector = RawVectorQuery(vector=embedded_query_vector, k=top, fields="contentVector")

        #Create a filter for the search query
        if (folder_filter != "") & (folder_filter != "All"):
            search_filter = f"search.in(folder, '{folder_filter}', ',')"
        else:
            search_filter = None
        if tags_filter != "" :
            if search_filter is not None:
                search_filter = search_filter + f" and tags/any(t: search.in(t, '{tags_filter}', ','))"
            else:
                search_filter = f"tags/any(t: search.in(t, '{tags_filter}', ','))"

        # Hybrid Search
        # r = self.search_client.search(generated_query, vector_queries =[vector], top=top)

        # Pure Vector Search
        # r=self.search_client.search(search_text=None,vector_queries =[vector], top=top)
        
        # vector search with filter
        # r=self.search_client.search(search_text=None, vectors=[vector], filter="processed_datetime le 2023-09-18T04:06:29.675Z" , top=top)
        # r=self.search_client.search(search_text=None, vectors=[vector], filter="search.ismatch('upload/ospolicydocs/China, climate change and the energy transition.pdf', 'file_name')", top=top)

        #  hybrid semantic search using semantic reranker
        if (self.use_semantic_reranker and overrides.get("semantic_ranker")):
            r = self.search_client.search(
                generated_query,
                query_type=QueryType.SEMANTIC,
                semantic_configuration_name="default",
                top=top,
                query_caption="extractive|highlight-false"
                if use_semantic_captions else None,
                vector_queries =[vector],
                filter=search_filter
            )
        else:
            r = self.search_client.search(
                generated_query, top=top,vector_queries=[vector], filter=search_filter
            )

        citation_lookup = {}  # dict of "FileX" moniker to the actual file name
        results = []  # list of results to be used in the prompt
        data_points = []  # list of data points to be used in the response

        #  #print search results with score
        # for idx, doc in enumerate(r):  # for each document in the search results
        #     print(f"File{idx}: ", doc['@search.score'])

        # cutoff_score=0.01
        # # Only include results where search.score is greater than cutoff_score
        # filtered_results = [doc for doc in r if doc['@search.score'] > cutoff_score]
        # # print("Filtered Results: ", len(filtered_results))

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
            self.FOLLOW_UP_QUESTIONS_PROMPT_CONTENT
            if overrides.get("suggest_followup_questions")
            else ""
        )

        # Allow client to replace the entire prompt, or to inject into the existing prompt using >>>
        prompt_override = overrides.get("prompt_template")

        if prompt_override is None:
            system_message = self.SYSTEM_MESSAGE_CHAT_CONVERSATION.format(
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
            system_message = self.SYSTEM_MESSAGE_CHAT_CONVERSATION.format(
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
            system_message = self.SYSTEM_MESSAGE_CHAT_CONVERSATION.format(
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
                history[-1]["user"] + "Sources:\n" + content + "\n\n", # 3.5 has recency Bias that is why this is here
                self.RESPONSE_PROMPT_FEW_SHOTS,
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
            chat_completion = await openai.ChatCompletion.acreate(
            deployment_id=self.chatgpt_deployment,
            model=self.model_name,
            messages=messages,
            temperature=float(overrides.get("response_temp")) or 0.6,
            n=1
        )

        elif self.model_name.startswith("gpt-4"):
            messages = self.get_messages_from_history(
                system_message,
                # "Sources:\n" + content + "\n\n" + system_message,
                self.model_name,
                history,
                # history[-1]["user"],
                history[-1]["user"] + "Sources:\n" + content + "\n\n", # GPT 4 starts to degrade with long system messages. so moving sources here 
                self.RESPONSE_PROMPT_FEW_SHOTS,
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

            chat_completion = await openai.ChatCompletion.acreate(
            deployment_id=self.chatgpt_deployment,
            model=self.model_name,
            messages=messages,
            temperature=float(overrides.get("response_temp")) or 0.6,
            max_tokens=1024,
            n=1
        )
        # STEP 4: Format the response
        msg_to_display = '\n\n'.join([str(message) for message in messages])
        generated_response=chat_completion.choices[0].message.content

        # # Detect the language of the response
        response_language = self.detect_language(generated_response)
        #if response is not in user's language, translate it to user's language
        if response_language != detectedlanguage:
            translated_response = self.translate_response(generated_response, detectedlanguage)
        else:
            translated_response = generated_response
        thought_chain["work_response"] = urllib.parse.unquote(translated_response)
        
        return {
            "data_points": data_points,
            "answer": f"{urllib.parse.unquote(translated_response)}",
            "thoughts": f"Searched for:<br>{generated_query}<br><br>Conversations:<br>" + msg_to_display.replace('\n', '<br>'),
            "thought_chain": thought_chain,
            "work_citation_lookup": citation_lookup,
            "web_citation_lookup": {}
        }

    def detect_language(self, text: str) -> str:
        """ Function to detect the language of the text"""
        try:
            endpoint_region = self.enrichment_endpoint.split("https://")[1].split(".api")[0]
            api_detect_endpoint = f"https://{self.azure_ai_translation_domain}/detect?api-version=3.0"
            headers = {
                'Ocp-Apim-Subscription-Key': self.enrichment_key,
                'Content-type': 'application/json',
                'Ocp-Apim-Subscription-Region': endpoint_region
            }
            data = [{"text": text}]
            response = requests.post(api_detect_endpoint, headers=headers, json=data)

            if response.status_code == 200:
                detected_language = response.json()[0]['language']
                return detected_language
            else:
                raise Exception(f"Error detecting language: {response.status_code}")
        except Exception as e:
            raise Exception(f"An error occurred during language detection: {str(e)}") from e
     
    def translate_response(self, response: str, target_language: str) -> str:
        """ Function to translate the response to target language"""
        endpoint_region = self.enrichment_endpoint.split("https://")[1].split(".api")[0]      
        api_translate_endpoint = f"https://{self.azure_ai_translation_domain}/translate?api-version=3.0"
        headers = {
            'Ocp-Apim-Subscription-Key': self.enrichment_key,
            'Content-type': 'application/json',
            'Ocp-Apim-Subscription-Region': endpoint_region
        }
        params={'to': target_language }
        data = [{
            "text": response
        }]          
        response = requests.post(api_translate_endpoint, headers=headers, json=data, params=params)
        
        if response.status_code == 200:
            translated_response = response.json()[0]['translations'][0]['text']
            return translated_response
        else:
            raise Exception(f"Error translating response: {response.status_code}")

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