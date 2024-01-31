

import os
from typing import Any, Sequence
import urllib.parse
from web_search_client import WebSearchClient
from web_search_client.models import SafeSearch
from azure.core.credentials import AzureKeyCredential
import openai
from approaches.approach import Approach

SUBSCRIPTION_KEY = "4525e27a0c4247a7b5306d20cf8ccec5"
ENDPOINT = "https://api.bing.microsoft.com"+  "/v7.0/"



class ChatBingSearch(Approach):


    response_prompt_few_shots = [
        {"role": Approach.USER ,'content': 'I am looking for information in source urls and its snippets'},
        {'role': Approach.ASSISTANT, 'content': 'user is looking for information in source urls and its snippets.'}
    ]

    system_message_chat_conversation = """You are an Azure OpenAI Completion system. Your persona is Assistant who helps answer questions about an agency's data.
    User persona is Assistant Answer ONLY with the facts listed in the list of sources below in english with citations.If there isn't enough information below, say you don't know and do not give citations. For tabular information return it as an html table. Do not return markdown format.
    Your goal is to provide answers based on the facts listed below in the provided source documents. Avoid making assumptions,generating speculative or generalized information or adding personal opinions.
    
    Each source has a file name followed by a pipe character and the actual information.Use square brackets to reference the source, e.g. [url1]. Do not combine sources, list each source separately, e.g. [url1][url2].
    Never cite the source content using the examples provided in this paragraph that start with info.
      
    Here is how you should answer every question:
        
    -Look for information in the source documents to answer the question in english.
    -If the source document has an answer, please respond with citation.You must include a citation to each document referenced only once when you find answer in source documents.      
    -If you cannot find answer in below sources, respond with I am not sure.Do not provide personal opinions or assumptions and do not include citations.
    -Identify the language of the user's question and translate the final response to that language.if the final answer is " I am not sure" then also translate it to the language of the user's question and then display translated response only. nothing else.    
    """

    citations = {}

    def __init__(self):
        self.name = "ChatBingSearch"

    async def search(self, history, chatgpt_deployment, model_name) -> Any:

        user_query = history[-1]["user"]
        resp = await self.web_search_with_answer_count_promote_and_safe_search(user_query, chatgpt_deployment, model_name, history)


        return {
            "data_points": None,
            "answer": f"{urllib.parse.unquote(resp)}",
            "thoughts": f"Searched for:<br>{user_query}<br><br>Conversations:<br>",
            "citation_lookup": self.citations
        }
    

    async def web_search_with_answer_count_promote_and_safe_search(self, user_query, chatgpt_deployment, model_name, history):
        """ WebSearchWithAnswerCountPromoteAndSafeSearch.
        """

        client = WebSearchClient(AzureKeyCredential(SUBSCRIPTION_KEY))

        try:
            web_data = client.web.search(
                query=user_query,
                answer_count=10,
                promote=["videos"],
                safe_search=SafeSearch.strict  # or directly "Strict"
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

                return await self.make_chat_completion(url_snippet_dict, chatgpt_deployment, model_name, history)    

            else:
                print("Didn't see any Web data..")

        except Exception as err:
            print("Encountered exception. {}".format(err))

    async def make_chat_completion(self, url_snippet_dict, chatgpt_deployment, model_name, history):
        content = ', '.join(f'{snippet} | {url}' for url, snippet in url_snippet_dict.items())

        messages = self.get_messages_from_history(
            self.system_message_chat_conversation,
            model_name,
            history,
            history[-1]["user"] + "Sources:\n" + content + "\n\n", # 3.5 has recency Bias that is why this is here
            self.response_prompt_few_shots,
             max_tokens=4097 - 500
         )

        # messages = []
        # for url, snippet in url_snippet_dict.items():
        #     # message = f"{snippet}\nSource: {url}"
        #     message = snippet
        #     messages.append(message)

        chat_completion = await openai.ChatCompletion.acreate(
            deployment_id=chatgpt_deployment,
            model=model_name,
            messages=messages,
            temperature=0.6,
            n=1
        )
        return chat_completion.choices[0].message.content
      


