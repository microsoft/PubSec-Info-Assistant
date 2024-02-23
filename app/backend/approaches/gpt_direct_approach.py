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

from text import nonewlines
from datetime import datetime, timedelta

from text import nonewlines

from core.messagebuilder import MessageBuilder
from core.modelhelper import get_token_limit
from core.modelhelper import num_tokens_from_messages
import requests
from urllib.parse import quote

# Simple retrieve-then-read implementation, using the Cognitive Search and
# OpenAI APIs directly. It first retrieves top documents from search,
# then constructs a prompt with them, and then uses OpenAI to generate
# an completion (answer) with that prompt.

class GPTDirectApproach(Approach):

       # Chat roles
    SYSTEM = "system"
    USER = "user"
    ASSISTANT = "assistant"
     
    system_message_chat_conversation = """You are an Azure OpenAI Completion system. Your persona is {systemPersona} who helps answer questions about an agency's data. {response_length_prompt}
        User persona is {userPersona} 
        Your goal is to provide accurate and relevant answers based on the facts. Make sure to avoid making assumptions or adding personal opinions.
        
        Emphasize the use of facts.
        
        Here is how you should answer every question:
        -Please respond with relevant information from the data in the response.    
        
        {follow_up_questions_prompt}
        {injected_prompt}
        
        """
    follow_up_questions_prompt_content = """
        Generate three very brief follow-up questions that the user would likely ask next about their agencies data. Use triple angle brackets to reference the questions, e.g. <<<Are there exclusions for prescriptions?>>>. Try not to repeat questions that have already been asked.
        Only generate questions and do not generate any text before or after the questions, such as 'Next Questions'
        """
    
    query_prompt_template = """Below is a history of the conversation so far, and a new question asked by the user that needs to be answered.
        Generate a search query based on the conversation and the new question. Treat each search term as an individual keyword. Do not combine terms in quotes or brackets.
        Do not include cited sources e.g info or doc in the search query terms.
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
        {'role': USER, 'content': 'What steps are being taken to promote energy conservation?'},
        {'role': USER, 'content': 'Several steps are being taken to promote energy conservation including reducing energy consumption, increasing energy efficiency, and increasing the use of renewable energy sources. Citations[info1.json]'}
        ]
    
    # # Define a class variable for the base URL
    # EMBEDDING_SERVICE_BASE_URL = 'https://infoasst-cr-{}.azurewebsites.net'
    
    def __init__(
        self,
        oai_service_name: str,
        oai_service_key: str,
        chatgpt_deployment: str,
        query_term_language: str,
        model_name: str,
        model_version: str,
        is_gov_cloud_deployment: str
    ):
        self.chatgpt_deployment = chatgpt_deployment
        self.query_term_language = query_term_language
        self.chatgpt_token_limit = get_token_limit(model_name)
        
        if is_gov_cloud_deployment:
            openai.api_base = 'https://' + oai_service_name + '.openai.azure.us/'
        else:
            openai.api_base = 'https://' + oai_service_name + '.openai.azure.com/'
        
        openai.api_type = 'azure'
        openai.api_key = oai_service_key

        self.model_name = model_name
        self.model_version = model_version
        self.is_gov_cloud_deployment = is_gov_cloud_deployment

    # def run(self, history: list[dict], overrides: dict) -> any:
    async def run(self, history: Sequence[dict[str, str]], overrides: dict[str, Any]) -> Any:
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


        #Generate the follow up prompt to be sent to the GPT model
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

        #Generate a contextual and content-specific answer using the search results and chat history.
        #Added conditional block to use different system messages for different models.
        messages = self.get_messages_from_history(
            system_message,
            self.model_name,
            history,
            history[-1]["user"] + "\n\n",
            self.response_prompt_few_shots,
            max_tokens=self.chatgpt_token_limit - 500
        )

        chat_completion = openai.ChatCompletion.create(
            deployment_id=self.chatgpt_deployment,
            model=self.model_name,
            messages=messages,
            temperature=float(overrides.get("response_temp")) or 0.6,
            n=1
        )  

        #Format the response
        msg_to_display = '\n\n'.join([str(message) for message in messages])

        return {
            "data_points": [],
            "answer": f"{urllib.parse.unquote(chat_completion.choices[0].message.content)}",
            "thoughts": f"Searched for:<br>{generated_query}<br><br>Conversations:<br>" + msg_to_display.replace('\n', '<br>'),
            "citation_lookup": {}
        }
    
