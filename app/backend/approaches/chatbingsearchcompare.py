# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import os
from typing import Any, Sequence
import urllib.parse
import openai
from approaches.chatbingsearch import ChatBingSearch
from approaches.approach import Approach
from core.messagebuilder import MessageBuilder
from core.modelhelper import get_token_limit

SUBSCRIPTION_KEY = "YourKeyHere"
ENDPOINT = "https://api.bing.microsoft.com"+  "/v7.0/"


class ChatBingSearchCompare(Approach):
    """
    Approach class for performing comparative analysis between Bing Search Response and Internal Documents.
    """

    COMPARATIVE_SYSTEM_MESSAGE_CHAT_CONVERSATION = """You are an Azure OpenAI Completion system. Your persona is {systemPersona}. User persona is {userPersona}.
    Compare and contrast the answers provided below from two sources of data. The first source is internal data indexed using a RAG pattern while the second source is from Bing Chat.
    Only explain the differences between the two sources and nothing else. Do not provide personal opinions or assumptions.
    Only answer in the language {query_term_language}.
    If you cannot find answer in below sources, respond with I am not sure. Do not provide personal opinions or assumptions.

    {follow_up_questions_prompt}
    """

    COMPARATIVE_RESPONSE_PROMPT_FEW_SHOTS = [
        {"role": Approach.USER ,'content': 'I am looking for comparative information in the Bing Search Response and want to compare against the Internal Documents'},
        {'role': Approach.ASSISTANT, 'content': 'user is looking to compare information in Bing Search Response against Internal Documents.'}
    ]

    citations = {}

    def __init__(self, model_name: str, chatgpt_deployment: str, query_term_language: str):
        """
        Initializes the ChatBingSearchCompare approach.

        Args:
            model_name (str): The name of the model to be used for chat-based language model.
            chatgpt_deployment (str): The deployment ID of the chat-based language model.
            query_term_language (str): The language to be used for querying the data.
        """
        self.name = "ChatBingSearchCompare"
        self.model_name = model_name
        self.chatgpt_deployment = chatgpt_deployment
        self.query_term_language = query_term_language
        self.chatgpt_token_limit = get_token_limit(model_name)

    async def run(self, history: Sequence[dict[str, str]], overrides: dict[str, Any]) -> Any:
        """
        Runs the comparative analysis between Bing Search Response and Internal Documents.

        Args:
            history (Sequence[dict[str, str]]): The chat conversation history.
            overrides (dict[str, Any]): Overrides for user and system personas, response length, etc.

        Returns:
            Any: The result of the comparative analysis.
        """
        # Step 1: Call bing Search Approach for a Bing LLM Response and Citations
        chat_bing_search = ChatBingSearch(self.model_name, self.chatgpt_deployment, self.query_term_language)
        bing_search_response = await chat_bing_search.run(history, overrides)
        self.citations = bing_search_response.get("citation_lookup")

        user_query = history[-1].get("user")
        rag_answer = history[0].get("bot")
        user_persona = overrides.get("user_persona", "")
        system_persona = overrides.get("system_persona", "")
        response_length = int(overrides.get("response_length") or 1024)

        # Step 2: Contruct the comparative system message with passed Rag response and Bing Search Response from above approach
        bing_compare_query = user_query + "Internal Documents:\n" + rag_answer + "\n\n" + " Bing Search Response:\n" + bing_search_response.get("answer") + "\n\n"

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
        for idx, url in enumerate(self.citations.keys(), start=1):
            final_response += f" [url{idx}]"

        return {
            "data_points": None,
            "answer": f"{urllib.parse.unquote(final_response)}",
            "thoughts": "Searched for:<br>A Comparitive Analysis<br><br>Conversations:<br>" + msg_to_display.replace('\n', '<br>'),
            "citation_lookup": self.citations
        }

    async def make_chat_completion(self, messages):
        """
        Generates a chat completion response using the chat-based language model.

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
      


