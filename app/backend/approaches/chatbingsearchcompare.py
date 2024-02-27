

import os
from typing import Any, Sequence
import urllib.parse
from web_search_client import WebSearchClient
from web_search_client.models import SafeSearch
from azure.core.credentials import AzureKeyCredential
import openai
from approaches.approach import Approach
from core.messagebuilder import MessageBuilder
from core.prompt_strings import PromptStrings

SUBSCRIPTION_KEY = "a33c0ffc04144dd2b553f90796f87792"
ENDPOINT = "https://api.bing.microsoft.com"+  "/v7.0/"



class ChatBingSearchCompare(Approach):

    citations = {}
    approach_class = ""

    def __init__(self, model_name: str, chatgpt_deployment: str):
        self.name = "ChatBingSearchCompare"
        self.model_name = model_name
        self.chatgpt_deployment = chatgpt_deployment
        

    async def run(self, history: Sequence[dict[str, str]], overrides: dict[str, Any]) -> Any:  

        user_query = history[-1].get("user")
        rag_answer = history[0].get("bot")

        url_snippet_dict = await self.web_search_with_answer_count_promote_and_safe_search(user_query)
        content = ', '.join(f'{snippet} | {url}' for url, snippet in url_snippet_dict.items())

        bing_search_query = user_query + " Bing Results:\n" + content + "\n\n" #+ "Internal Documents:\n" + rag_answer + "\n\n"
        messages = self.get_messages_builder(
            PromptStrings.SYSTEM_MESSAGE_CHAT_CONVERSATION.get("ChatBingSearch", "Default system message"),
            self.model_name,
            bing_search_query,
            PromptStrings.RESPONSE_PROMPT_FEW_SHOTS.get("ChatBingSearch", "Default system message"),
             max_tokens=4097 - 500
         )
        bing_resp = await self.make_chat_completion(messages)

        # bing_compare_query = user_query + " Bing Search Response:\n" + bing_resp + "\n\n" + "Bing Search Content:\n" + content + "\n\n" + "Internal Documents:\n" + rag_answer + "\n\n"
        bing_compare_query = user_query + " Bing Search Response:\n" + bing_resp + "\n\n" + "Internal Documents:\n" + rag_answer + "\n\n"

        messages = self.get_messages_builder(
            PromptStrings.SYSTEM_MESSAGE_CHAT_CONVERSATION.get(self.__class__.__name__, "Default system message"),
            self.model_name,
            bing_compare_query,
            PromptStrings.RESPONSE_PROMPT_FEW_SHOTS.get(self.__class__.__name__, "Default system message"),
             max_tokens=4097 - 500
         )
        bing_compare_resp = await self.make_chat_completion(messages)

        final_response = f"{urllib.parse.unquote(bing_resp) + ' ' + urllib.parse.unquote(bing_compare_resp)}"

        return {
            "data_points": None,
            "answer": f"{urllib.parse.unquote(final_response)}",
            "thoughts": f"Searched for:<br>{user_query}<br><br>Conversations:<br>",
            "citation_lookup": self.citations
        }
    

    async def web_search_with_answer_count_promote_and_safe_search(self, user_query):
        """ WebSearchWithAnswerCountPromoteAndSafeSearch.
        """

        client = WebSearchClient(AzureKeyCredential(SUBSCRIPTION_KEY))

        try:
            web_data = client.web.search(
                query=user_query,
                answer_count=10,
                promote=["videos"],
                safe_search=SafeSearch.strict 
            )

            if web_data.web_pages.value:

                url_snippet_dict = {}
                for idx, page in enumerate(web_data.web_pages.value):
                    self.citations[f"url{idx}"] = {
                        "citation": page.url,
                        "source_path": "",
                        "page_number": "0",
                    }
                    # self.citations.append(page.url)
                    url_snippet_dict[page.url] = page.snippet.replace("[", "").replace("]", "")

                return url_snippet_dict

            else:
                print("Didn't see any Web data..")

        except Exception as err:
            print("Encountered exception. {}".format(err))

    async def make_chat_completion(self, messages):


        chat_completion = await openai.ChatCompletion.acreate(
            deployment_id=self.chatgpt_deployment,
            model=self.model_name,
            messages=messages,
            temperature=0.6,
            n=1
        )
        return chat_completion.choices[0].message.content
    
    def get_messages_builder(
        self,
        system_prompt: str,
        model_id: str,
        user_conv: str,
        few_shots = [dict[str, str]],
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

        messages = message_builder.messages
        return messages    
      


