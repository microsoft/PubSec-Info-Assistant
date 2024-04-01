# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.


import re
import urllib.parse
from typing import Any, Sequence
import openai
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
    
    web_citations = {}

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
        target_embedding_model: str,
        enrichment_appservice_url: str,
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
        self.escaped_target_model = re.sub(r'[^a-zA-Z0-9_\-.]', '_', target_embedding_model)
        self.target_translation_language=target_translation_language
        self.enrichment_endpoint=enrichment_endpoint
        self.enrichment_key=enrichment_key
        self.oai_service_name = oai_service_name
        self.oai_service_key = oai_service_key
        self.model_name = model_name
        self.model_version = model_version
        self.enrichment_appservice_url = enrichment_appservice_url
        self.azure_ai_translation_domain = azure_ai_translation_domain
        self.use_semantic_reranker = use_semantic_reranker

    async def run(self, history: Sequence[dict[str, str]], citation_lookup: dict[str, Any], overrides: dict[str, Any]) -> Any:
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
                                    self.oai_service_key,
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
                                    self.enrichment_endpoint,
                                    self.enrichment_key,
                                    self.azure_ai_translation_domain,
                                    self.use_semantic_reranker
                                )
        rrr_response = await chat_rrr_approach.run(history, overrides)
        

        self.web_citations = rrr_response.get("citation_lookup")

        user_query = history[-1].get("user")
        web_answer = next((obj['bot'] for obj in history if 'bot' in obj), None)
        user_persona = overrides.get("user_persona", "")
        system_persona = overrides.get("system_persona", "")
        response_length = int(overrides.get("response_length") or 1024)

        # Step 2: Contruct the comparative system message with passed Rag response and Bing Search Response from above approach
        bing_compare_query = user_query + " Web search results:\n" + web_answer + "\n\n" + "Work internal Documents:\n" + rrr_response.get("answer") + "\n\n"

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

        # Step 3: Final comparative analysis using OpenAI Chat Completion
        bing_compare_resp = await self.make_chat_completion(messages)

        final_response = f"{urllib.parse.unquote(bing_compare_resp)}"

        # Step 4: Append web citations from the Bing Search approach
        for idx, url in enumerate(self.web_citations.keys(), start=1):
            final_response += f" [File{idx}]"

        
        return {
            "data_points": None,
            "answer": f"{urllib.parse.unquote(final_response)}",
            "thoughts": "Searched for:<br>A Comparitive Analysis<br><br>Conversations:<br>" + msg_to_display.replace('\n', '<br>'),
            "citation_lookup": self.web_citations,

            "compare_citation_lookup": citation_lookup
        }
    
    async def make_chat_completion(self, messages) -> str:
        """
        Generates a chat completion response using the chat-based language model.

        Args:
            messages (List[dict[str, str]]): The list of messages for the chat-based language model.

        Returns:
            str: The generated chat completion response.
        """
        chat_completion = await openai.ChatCompletion.acreate(
            deployment_id=self.chatgpt_deployment,
            model=self.model_name,
            messages=messages,
            temperature=0.6,
            n=1
        )
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
