# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.
from core.messagebuilder import MessageBuilder
from typing import Any, Sequence
import tiktoken
from enum import Enum

#This class must match the Enum in app\frontend\src\api
class Approaches(Enum):
    RetrieveThenRead = 0
    ReadRetrieveRead = 1
    ReadDecomposeAsk = 2
    GPTDirect = 3

class PromptTemplate:

    # Chat roles
    System = "system"
    User = "user"
    Assistant = "assistant"

    System_Message_Chat_Conversation = ""
    Follow_Up_Questions_Prompt_Content = ""
    Query_Prompt_Template = ""
    Query_Prompt_Few_Shots = []
    Response_Prompt_Few_Shots = []


class Approach:
    """
    An approach is a method for answering a question from a query and a set of
    documents.
    """

    async def run(self, history: list[dict], overrides: dict) -> any:
        """
        Run the approach on the query and documents. Not implemented.

        Args:
            history: The chat history. (e.g. [{"user": "hello", "bot": "hi"}])
            overrides: Overrides for the approach. (e.g. temperature, etc.)
        """
        raise NotImplementedError

     #Aparmar. Custom method to construct Chat History as opposed to single string of chat History.
    def get_messages_from_history(
        self,
        prompt_template: PromptTemplate,
        system_prompt: str,
        model_id: str,
        history: Sequence[dict[str, str]],
        user_conv: str,
        few_shots = [],
        max_tokens: int = 4096,
        ) -> []:
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