# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import json
import logging
import os
from typing import Any, Sequence
import urllib.parse
import openai
from openai import AzureOpenAI, BadRequestError
from openai import AsyncAzureOpenAI
from approaches.chatwebretrieveread import ChatWebRetrieveRead
from approaches.approach import Approach
from core.messagebuilder import MessageBuilder
from core.modelhelper import get_token_limit


class CompareWorkWithWeb(Approach):
    """
    Approach class for performing comparative analysis between Generative answer responses based on Bing search results vs. work internal document search results.
    """

    COMPARATIVE_SYSTEM_MESSAGE_CHAT_CONVERSATION = """You are an Azure OpenAI Completion system. Your persona is {systemPersona}. User persona is {userPersona}.
    Compare and contrast the answers provided below from two sources of data. The first source is Work where internal data is indexed using a RAG pattern while the second source Web where results are from an internet search.
    Only explain the differences between the two sources and nothing else. Do not provide personal opinions or assumptions.
    Only answer in the language {query_term_language}.
    If you cannot find answer in below sources, respond with I am not sure. Do not provide personal opinions or assumptions.

    {follow_up_questions_prompt}
    """

    COMPARATIVE_RESPONSE_PROMPT_FEW_SHOTS = [
        {"role": Approach.USER ,'content': 'I am looking to compare and contrast answers obtained from both Work internal documents and Web search results'},
        {'role': Approach.ASSISTANT, 'content': 'User wants to compare and contrast responses from both Work internal documents and Web search results.'},
        {"role": Approach.USER, 'content': "Even if one of the sources doesn't provide a definite answer, I still want to compare and contrast the available information."},
        {'role': Approach.ASSISTANT, 'content': "User emphasizes the importance of comparing and contrasting data even if one of the sources is uncertain about the answer."}
    ]
    
    
    web_citations = {}

    def __init__(self, model_name: str,
                 chatgpt_deployment: str,
                 query_term_language: str,
                 bing_search_endpoint: str,
                 bing_search_key: str,
                 bing_safe_search: bool,
                 oai_endpoint: str,
                 azure_ai_token_provider:str
                 ):
        """
        Initializes the CompareWorkWithWeb approach.

        Args:
            model_name (str): The name of the model to be used for chat-based language model.
            chatgpt_deployment (str): The deployment ID of the chat-based language model.
            query_term_language (str): The language to be used for querying the data.
            bing_search_endpoint (str): The endpoint for the Bing Search API.
            bing_search_key (str): The API key for the Bing Search API.
            bing_safe_search (bool): The flag to enable or disable safe search for the Bing Search API.
        """
        self.name = "CompareWorkWithWeb"
        self.model_name = model_name
        self.chatgpt_deployment = chatgpt_deployment
        self.query_term_language = query_term_language
        self.chatgpt_token_limit = get_token_limit(model_name)
        self.bing_search_endpoint = bing_search_endpoint
        self.bing_search_key = bing_search_key
        self.bing_safe_search = bing_safe_search
        self.oai_endpoint = oai_endpoint
        self.azure_ai_token_provider = azure_ai_token_provider
        
          # openai.api_base = oai_endpoint
        openai.api_type = 'azure'
        openai.api_version = "2024-02-01"
        
        self.client = AsyncAzureOpenAI(
        azure_endpoint = openai.api_base,
        azure_ad_token_provider=azure_ai_token_provider,
        api_version=openai.api_version)

    async def run(self, history: Sequence[dict[str, str]], overrides: dict[str, Any], work_citation_lookup: dict[str, Any], thought_chain: dict[str, Any]) -> Any:
        """
        Runs the comparative analysis between Bing Search Response and Internal Documents.

        Args:
            history (Sequence[dict[str, str]]): The chat conversation history.
            overrides (dict[str, Any]): Overrides for user and system personas, response length, etc.

        Returns:
            Any: The result of the comparative analysis.
        """
        # Step 1: Call bing Search Approach for a Bing LLM Response and Citations
        chat_bing_search = ChatWebRetrieveRead(self.model_name,
                                               self.chatgpt_deployment,
                                               self.query_term_language,
                                               self.bing_search_endpoint,
                                               self.bing_search_key,
                                               self.bing_safe_search,
                                               self.oai_endpoint,
                                               self.azure_ai_token_provider)
        bing_search_response = chat_bing_search.run(history, overrides, {}, thought_chain)
        
        content = ""
        async for event in bing_search_response:
            eventJson = json.loads(event)
            if "web_citation_lookup" in eventJson:
                self.web_citations = eventJson["web_citation_lookup"]
            elif "content" in eventJson and eventJson["content"] != None:
                content += eventJson["content"]

        thought_chain["web_response"] = content
        user_query = history[-1].get("user")
        rag_answer=next((obj['bot'] for obj in reversed(history) if 'bot' in obj), None)
        user_persona = overrides.get("user_persona", "")
        system_persona = overrides.get("system_persona", "")
        response_length = int(overrides.get("response_length") or 1024)

        # Step 2: Contruct the comparative system message with passed Rag response and Bing Search Response from above approach
        bing_compare_query = user_query + "Work internal documents:\n" + rag_answer + "\n\n" + " Web search results:\n" + content + "\n\n"
        thought_chain["work_to_web_compairison_query"] = bing_compare_query
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
                            "work_citation_lookup": work_citation_lookup,
                            "web_citation_lookup": self.web_citations}) + "\n"
            
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
            for idx, url in enumerate(self.web_citations.keys(), start=1):
                yield json.dumps({"content": f"[url{idx}]"}) + "\n"
        except BadRequestError as e:
            logging.error(f"Error generating chat completion: {str(e.body['message'])}")
            yield json.dumps({"error": f"Error generating chat completion: {str(e.body['message'])}"}) + "\n"
            return
        except Exception as e:
            logging.error(f"Error in compare work with web: {e}")
            yield json.dumps({"error": "An error occurred while generating the completion."}) + "\n"
            return

    async def make_chat_completion(self, messages):
        """
        Generates a chat completion response using the chat-based language model.

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
    
    def get_messages_builder(self, system_prompt: str, model_id: str, user_conv: str, few_shots = [dict[str, str]], max_tokens: int = 4096,) -> []:
        """
        Constructs a list of messages for the chat-based language model.

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
      


