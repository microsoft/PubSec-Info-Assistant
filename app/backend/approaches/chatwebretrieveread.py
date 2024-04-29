# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import os
import re
from typing import Any, Sequence
import urllib.parse
from web_search_client import WebSearchClient
from web_search_client.models import SafeSearch
from azure.core.credentials import AzureKeyCredential
import openai
from approaches.approach import Approach
from core.messagebuilder import MessageBuilder
from core.modelhelper import get_token_limit

class ChatWebRetrieveRead(Approach):
    """Class to help perform RAG based on Bing Search and ChatGPT."""

    SYSTEM_MESSAGE_CHAT_CONVERSATION = """You are an Azure OpenAI Completion system. Your persona is a {systemPersona} who helps answer questions. {response_length_prompt}
    User persona is {userPersona}. Answer ONLY with the facts listed in the source URLs below in {query_term_language} with citations. If there isn't enough information below, say "I don't know" and do not give citations. For tabular information, return it as an HTML table. Do not return markdown format.
    Your goal is to provide answers based on the facts listed below in the provided URLs and content. Avoid making assumptions, generating speculative or generalized information, or adding personal opinions.

    Each source has content followed by a pipe character and the URL. When citing sources, do not write out the URL or use any formatting other than [url1], [url2], etc., based on their order in the list. For example, instead of writing "[Microsoft Azure](https://en.wikipedia.org/wiki/Microsoft_Azure)", you should write "[url1]".
    Sources:
    - Content about topic A | http://example.com/link1
    - Content about topic B | http://example.com/link2

    Reference these as [url1] and [url2] respectively in your answers.

    Here is how you should answer every question:

    - Look for information in the provided content to answer the question in {query_term_language}.
    - If the provided content has an answer, please respond with a citation. You must include a citation to each URL referenced only once when you find an answer in source URLs.
    - If you cannot find an answer in the below sources, respond with "I am not sure." Do not provide personal opinions or assumptions and do not include citations.
    - Identify the language of the user's question and translate the final response to that language. If the final answer is "I am not sure," then also translate it to the language of the user's question and display the translated response only.

    {follow_up_questions_prompt}   
    """

    FOLLOW_UP_QUESTIONS_PROMPT_CONTENT = """ALWAYS generate three very brief unordered follow-up questions surrounded by triple chevrons (<<<Are there exclusions for prescriptions?>>>) that the user would likely ask next about their agencies data. 
    Surround each follow-up question with triple chevrons (<<<Are there exclusions for prescriptions?>>>). Try not to repeat questions that have already been asked.
    Only generate follow-up questions and do not generate any text before or after the follow-up questions, such as 'Next Questions'
    """

    QUERY_PROMPT_TEMPLATE = """Below is a history of the conversation so far, and a new question asked by the user that needs to be answered by searching in Bing Search.
    Generate a search query based on the conversation and the new question. Treat each search term as an individual keyword. Do not combine terms in quotes or brackets.
    Do not include cited sources in the search query terms.
    Do not include any brackets or text within [] or <<<>>> in the search query terms.
    Do not include any special characters like '+'.
    If you cannot generate a search query, return just the number 0.
    """
    
     
    QUERY_PROMPT_FEW_SHOTS = [
    {'role': Approach.USER, 'content': 'Could you search the web for information on the latest advancements in artificial intelligence,citing the provided URLs.?'},
    {'role': Approach.ASSISTANT, 'content': 'User wants to know about recent advancements in artificial intelligence,with citations from the provided URLs.'},
    {'role': Approach.USER, 'content': 'can you search the web and provide information on impact of climate change on global agriculture,citing the content from the URLs provided. ?'},
    {'role': Approach.ASSISTANT, 'content': 'User is seeking information about the effects of climate change on global agriculture,with citations from the content provided in the URLs.'}
]
       

    RESPONSE_PROMPT_FEW_SHOTS = [
        {"role": Approach.USER ,'content': 'I am looking for information in source urls and its snippets'},
        {'role': Approach.ASSISTANT, 'content': 'user is looking for information in source urls and its snippets.'},
        {"role": Approach.USER, 'content': 'I need data extracted from the URLs and their corresponding snippets.'},
        {'role': Approach.ASSISTANT, 'content': 'User requires data extracted from the URLs and their snippets.'}
    ]
    
 
    citations = {}
    approach_class = ""

    def __init__(self, model_name: str, chatgpt_deployment: str, query_term_language: str, bing_search_endpoint: str, bing_search_key: str, bing_safe_search: bool):
        self.name = "ChatBingSearch"
        self.model_name = model_name
        self.chatgpt_deployment = chatgpt_deployment
        self.query_term_language = query_term_language
        self.chatgpt_token_limit = get_token_limit(model_name)
        self.bing_search_endpoint = bing_search_endpoint
        self.bing_search_key = bing_search_key
        self.bing_safe_search = bing_safe_search
        

    async def run(self, history: Sequence[dict[str, str]],overrides: dict[str, Any], citation_lookup: dict[str, Any], thought_chain: dict[str, Any]) -> Any:
        """
        Runs the approach to simulate experience with Bing Chat.

        Args:
            history (Sequence[dict[str, str]]): The conversation history.
            overrides (dict[str, Any]): The overrides for the approach.

        Returns:
            Any: The result of the approach.
        """

        user_query = history[-1].get("user")
        user_persona = overrides.get("user_persona", "")
        system_persona = overrides.get("system_persona", "")
        response_length = int(overrides.get("response_length") or 1024)
        thought_chain["web_query"] = user_query

        follow_up_questions_prompt = (
            self.FOLLOW_UP_QUESTIONS_PROMPT_CONTENT
            if overrides.get("suggest_followup_questions")
            else ""
        )

        # STEP 1: Generate an optimized keyword search query based on the chat history and the last question
        messages = self.get_messages_from_history(
            self.QUERY_PROMPT_TEMPLATE,
            self.model_name,
            history,
            user_query,
            self.QUERY_PROMPT_FEW_SHOTS,
            self.chatgpt_token_limit - len(user_query)
            )
        
        query_resp = await self.make_chat_completion(messages)
        thought_chain["web_search_term"] = query_resp
        # STEP 2: Use the search query to get the top web search results
        url_snippet_dict = await self.web_search_with_safe_search(query_resp)
        content = ', '.join(f'{snippet} | {url}' for url, snippet in url_snippet_dict.items())
        user_query += "Url Sources:\n" + content + "\n\n"

        # Use re.sub to replace anything within square brackets with an empty string
        query_resp = re.sub(r'\[.*?\]', '', query_resp)

        messages = self.get_messages_builder(
            self.SYSTEM_MESSAGE_CHAT_CONVERSATION.format(
                query_term_language=self.query_term_language,
                follow_up_questions_prompt=follow_up_questions_prompt,
                response_length_prompt=self.get_response_length_prompt_text(
                    response_length
                ),
                userPersona=user_persona,
                systemPersona=system_persona,
            ),
            self.model_name,
            user_query,
            self.RESPONSE_PROMPT_FEW_SHOTS,
             max_tokens=4097 - 500
         )
        msg_to_display = '\n\n'.join([str(message) for message in messages])
        # STEP 3: Use the search results to answer the user's question
        resp = await self.make_chat_completion(messages)  
        thought_chain["web_response"] = resp
        return {
            "data_points": None,
            "answer": f"{urllib.parse.unquote(resp)}",
            "thoughts": f"Searched for:<br>{query_resp}<br><br>Conversations:<br>" + msg_to_display.replace('\n', '<br>'),
            "thought_chain": thought_chain,
            "work_citation_lookup": {},
            "web_citation_lookup": self.citations
        }
    

    async def web_search_with_safe_search(self, user_query):
        """
        Performs a web search with specified parameters.

        Args:
            user_query (str): The query string for the web search.

        Returns:
            dict: A dictionary containing URL snippets as values and corresponding URLs as keys.
        """
        client = WebSearchClient(AzureKeyCredential(self.bing_search_key), endpoint=self.bing_search_endpoint)

        try:
            if self.bing_safe_search:
                safe_search = SafeSearch.STRICT
            else:
                safe_search = SafeSearch.OFF

            web_data = client.web.search(
                query=user_query,
                answer_count=10,
                safe_search=safe_search
            )

            if web_data.web_pages.value:

                url_snippet_dict = {}
                for idx, page in enumerate(web_data.web_pages.value):
                    self.citations[f"url{idx}"] = {
                        "citation": page.url,
                        "source_path": "",
                        "page_number": "0",
                    }

                    url_snippet_dict[page.url] = page.snippet.replace("[", "").replace("]", "")

                return url_snippet_dict

            else:
                print("Didn't see any Web data..")

        except Exception as err:
            print("Encountered exception. {}".format(err))

    async def make_chat_completion(self, messages):
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
      


