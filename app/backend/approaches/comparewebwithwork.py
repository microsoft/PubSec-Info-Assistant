# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.


import json
import logging
import re
import urllib.parse
from typing import Any, Sequence
import openai
from openai import AzureOpenAI, BadRequestError
from openai import  AsyncAzureOpenAI
from approaches.chatreadretrieveread import ChatReadRetrieveReadApproach
from approaches.approach import Approach
from azure.search.documents import SearchClient  
from core.messagebuilder import MessageBuilder
from azure.storage.blob import (
    BlobServiceClient
)
from core.modelhelper import get_token_limit

class CompareWebWithWork(Approach):
    """
    Approach for comparing and contrasting generative response answers based on web search results vs. based on work search results.
    """

    COMPARATIVE_SYSTEM_MESSAGE_CHAT_CONVERSATION = """You are an Azure OpenAI Completion system. Your persona is {systemPersona}. User persona is {userPersona}.
    Compare and contrast the answers provided below from two sources of data. The first source is Web where data is retrieved from an internet search while the second source is Work where internal data indexed using a RAG pattern.
    Only explain the differences between the two sources and nothing else. Do not provide personal opinions or assumptions.
    Only answer in the language {query_term_language}.
    If you cannot find answer in below sources, respond with I am not sure. Do not provide personal opinions or assumptions.

    {follow_up_questions_prompt}
    """

    COMPARATIVE_RESPONSE_PROMPT_FEW_SHOTS = [
        # {"role": Approach.USER ,'content': 'I am looking for comparative information on an answer based on Web search results and want to compare against an answer based on Work internal documents'},
        # {'role': Approach.ASSISTANT, 'content': 'User is looking to compare an answer based on Web search results against an answer based on Work internal documents.'}
        {"role": Approach.USER, 'content': 'I am looking to compare and contrast answers obtained from both web search results and internal work documents.'},
        {'role': Approach.ASSISTANT, 'content': 'User wants to compare and contrast responses from both web search results and internal work documents.'},
        {"role": Approach.USER, 'content': "Even if one of the sources doesn't provide a definite answer, I still want to compare and contrast the available information."},
        {'role': Approach.ASSISTANT, 'content': "User emphasizes the importance of comparing and contrasting data even if one of the sources is uncertain about the answer."}
    ]
    
    def __init__(
        self,
        search_client: SearchClient,
        oai_service_name: str,
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
        enrichment_appservice_url: str,
        target_translation_language: str,
        azure_ai_endpoint:str,
        azure_ai_location: str,
        azure_ai_token_provider: str,
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
        self.escaped_target_model = re.sub(r'[^a-zA-Z0-9_\-.]', '_', target_embedding_model)
        self.target_translation_language=target_translation_language
        self.azure_ai_endpoint=azure_ai_endpoint
        self.azure_ai_location = azure_ai_location
        self.azure_ai_token_provider=azure_ai_token_provider
        self.oai_service_name = oai_service_name
        self.model_name = model_name
        self.model_version = model_version
        self.enrichment_appservice_url = enrichment_appservice_url
        self.use_semantic_reranker = use_semantic_reranker
        
          # openai.api_base = oai_endpoint
        openai.api_type = 'azure'
        openai.api_version = "2024-02-01"
               
        self.client = AsyncAzureOpenAI(
        azure_endpoint = openai.api_base, 
        azure_ad_token_provider=azure_ai_token_provider,  
        api_version=openai.api_version)

    async def run(self, history: Sequence[dict[str, str]], overrides: dict[str, Any], web_citation_lookup: dict[str, Any], thought_chain: dict[str, Any]) -> Any:
        """
        Runs the approach to compare and contrast answers from internal data and Web Search results.

        Args:
            history (Sequence[dict[str, str]]): The conversation history.
            overrides (dict[str, Any]): The overrides for the approach.

        Returns:
            Any: The result of the approach.
        """
        chat_rrr_approach = ChatReadRetrieveReadApproach(
                                    self.search_client,
                                    self.oai_service_name,
                                    self.chatgpt_deployment,
                                    self.source_file_field,
                                    self.content_field,
                                    self.page_number_field,
                                    self.chunk_file_field,
                                    self.content_storage_container,
                                    self.blob_client,
                                    self.query_term_language,
                                    self.model_name,
                                    self.model_version,
                                    self.escaped_target_model,
                                    self.enrichment_appservice_url,
                                    self.target_translation_language,
                                    self.azure_ai_endpoint,
                                    self.azure_ai_location,
                                    self.azure_ai_token_provider,
                                    self.use_semantic_reranker
                                )
        rrr_response = chat_rrr_approach.run(history, overrides, {}, thought_chain)
        content = ""
        work_citations = {}
        async for event in rrr_response:
            eventJson = json.loads(event)
            if "work_citation_lookup" in eventJson:
                work_citations = eventJson["work_citation_lookup"]
            elif "content" in eventJson and eventJson["content"] != None:
                content += eventJson["content"]

        thought_chain["work_response"] = content
        user_query = history[-1].get("user")
        web_answer = next((obj['bot'] for obj in reversed(history) if 'bot' in obj), None)
        user_persona = overrides.get("user_persona", "")
        system_persona = overrides.get("system_persona", "")
        response_length = int(overrides.get("response_length") or 1024)

        # Step 2: Contruct the comparative system message with passed Rag response and Bing Search Response from above approach
        bing_compare_query = user_query + " Web search results:\n" + web_answer + "\n\n" + "Work internal Documents:\n" + content + "\n\n"
        thought_chain["web_to_work_comparison_query"] = bing_compare_query
        messages = self.get_messages_builder(
            self.COMPARATIVE_SYSTEM_MESSAGE_CHAT_CONVERSATION.format(
                query_term_language=self.query_term_language,
                follow_up_questions_prompt='',
                response_length_prompt=self.get_response_length_prompt_text(
                    response_length
                ),
                userPersona=user_persona,
                systemPersona=system_persona,
            ),
            self.model_name,
            bing_compare_query,
            self.COMPARATIVE_RESPONSE_PROMPT_FEW_SHOTS,
             max_tokens=4097 - 500
         )
        msg_to_display = '\n\n'.join([str(message) for message in messages])
        try:
            # Step 3: Final comparative analysis using OpenAI Chat Completion
            chat_completion = await self.client.chat.completions.create(
                model=self.chatgpt_deployment,
                messages=messages,
                temperature=float(overrides.get("response_temp")) or 0.6,
                n=1,
                stream=True)

            yield json.dumps({"data_points": {},
                            "thoughts": "Searched for:<br>A Comparitive Analysis<br><br>Conversations:<br>" + msg_to_display.replace('\n', '<br>'),
                            "thought_chain": thought_chain,
                            "work_citation_lookup": work_citations,
                            "web_citation_lookup": web_citation_lookup}) + "\n"
            
            # STEP 4: Format the response
            async for chunk in chat_completion:
                # Check if there is at least one element and the first element has the key 'delta'
                if len(chunk.choices) > 0:
                    filter_reasons = []
                    # Check for content filtering
                    if chunk.choices[0].finish_reason == 'content_filter':
                        for category, details in chunk.choices[0].content_filter_results.items():
                            if details['filtered']:
                                filter_reasons.append(f"{category} ({details['severity']})")

                    # Raise an error if any filters are triggered
                    if filter_reasons:
                        error_message = "The generated content was filtered due to triggering Azure OpenAI's content filtering system. Reason(s): The response contains content flagged as " + ", ".join(filter_reasons)
                        raise ValueError(error_message)
                    yield json.dumps({"content": chunk.choices[0].delta.content}) + "\n"
            # Step 4: Append web citations from the Bing Search approach
            for idx, url in enumerate(work_citations.keys(), start=1):
                yield json.dumps({"content": f"[File{idx}]"}) + "\n"
        except BadRequestError as e:
            logging.error(f"Error generating chat completion: {str(e.body['message'])}")
            yield json.dumps({"error": f"Error generating chat completion: {str(e.body['message'])}"}) + "\n"
            return
        except Exception as e:
            logging.error(f"Error in compare web with work: {e}")
            yield json.dumps({"error": "An error occurred while generating the completion."}) + "\n"
            return
            
    
    async def make_chat_completion(self, messages) -> str:
        """
        Generates a chat completion response using the chat-based language model.

        Args:
            messages (List[dict[str, str]]): The list of messages for the chat-based language model.

        Returns:
            str: The generated chat completion response.
        """
        
        chat_completion= await self.client.chat.completions.create(
            model=self.chatgpt_deployment,
            messages=messages,
            temperature=0.6,
            n=1
        )
        filter_reasons = []

        # Check for content filtering
        if chat_completion.choices[0].finish_reason == 'content_filter':
            for category, details in chat_completion.choices[0].content_filter_results.items():
                if details['filtered']:
                    filter_reasons.append(f"{category} ({details['severity']})")

        # Raise an error if any filters are triggered
        if filter_reasons:
            error_message = "The generated content was filtered due to triggering Azure OpenAI's content filtering system. Reason(s): The response contains content flagged as " + ", ".join(filter_reasons)
            raise ValueError(error_message)
        return chat_completion.choices[0].message.content
    
    def get_messages_builder(self, system_prompt: str, model_id: str, user_conv: str, few_shots = [dict[str, str]], max_tokens: int = 4096) -> []:
        """
        Constructs a list of messages for the chat-based language model.

        Args:
            system_prompt (str): The system prompt for the chat-based language model.
            model_id (str): The ID of the model to be used for chat-based language model.
            user_conv (str): The user conversation for the chat-based language model.
            few_shots (List[dict[str, str]]): Few shot prompts for the chat-based language model.
            max_tokens (int): The maximum number of tokens allowed for the chat-based language model.

        Returns:
            List[dict[str, str]]: The list of messages for the chat-based language model.
        """
        message_builder = MessageBuilder(system_prompt, model_id)

        # Few Shot prompting. Add examples to show the chat what responses we want. It will try to mimic any responses and make sure they match the rules laid out in the system message.
        for shot in few_shots:
            message_builder.append_message(shot.get('role'), shot.get('content'))

        user_content = user_conv
        append_index = len(few_shots) + 1

        message_builder.append_message(self.USER, user_content, index=append_index)

        messages = message_builder.messages
        return messages
