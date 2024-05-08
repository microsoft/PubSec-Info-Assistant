# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import json
import re
import logging
import urllib.parse
from datetime import datetime, timedelta
from typing import Any, Sequence

import openai
from openai import AzureOpenAI
from openai import AsyncAzureOpenAI
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
     
    system_message_chat_conversation = """You are an Azure OpenAI Completion system. Your persona is {systemPersona} who helps users interact with a Large Language Model. {response_length_prompt}
        User persona is {userPersona}. You are having a conversation with a user and you need to provide a response.    
        
        {follow_up_questions_prompt}
        {injected_prompt}
        
        """
    follow_up_questions_prompt_content = """
        Generate three very brief follow-up questions that the user would likely ask next about their previous chat context. Use triple angle brackets to reference the questions, e.g. <<<Are there exclusions for prescriptions?>>>. Try not to repeat questions that have already been asked.
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
        azure_openai_endpoint: str
    ):
        self.chatgpt_deployment = chatgpt_deployment
        self.query_term_language = query_term_language
        self.chatgpt_token_limit = get_token_limit(model_name)
        
        openai.api_base = azure_openai_endpoint
        openai.api_type = 'azure'
        openai.api_key = oai_service_key

        self.model_name = model_name
        self.model_version = model_version
        
          
        openai.api_type = 'azure'
        openai.api_version = "2024-02-01"
        
        self.client = AsyncAzureOpenAI(
        azure_endpoint = openai.api_base, 
        api_key=openai.api_key,  
        api_version=openai.api_version)

    # def run(self, history: list[dict], overrides: dict) -> any:
    async def run(self, history: Sequence[dict[str, str]], overrides: dict[str, Any], citation_lookup: dict[str, Any], thought_chain: dict[str, Any]) -> Any:
        user_persona = overrides.get("user_persona", "")
        system_persona = overrides.get("system_persona", "")
        response_length = int(overrides.get("response_length") or 1024)

        user_q = 'Generate response for: ' + history[-1]["user"]
        thought_chain["user_query"] = history[-1]["user"]
        #Generate the follow up prompt to be sent to the GPT model
        follow_up_questions_prompt = (
            self.follow_up_questions_prompt_content
            if overrides.get("suggest_followup_questions")
            else ""
        )

        system_message = self.system_message_chat_conversation.format(
            injected_prompt="",
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

        try:
            chat_completion= await self.client.chat.completions.create(
                model=self.chatgpt_deployment,
                messages=messages,
                temperature=0.6,
                n=1,
                stream=True
            ) 
            msg_to_display = '\n\n'.join([str(message) for message in messages])
                    # Return the data we know
            yield json.dumps({"data_points": {},
                            "thoughts": f"Searched for:<br>{user_q}<br><br>Conversations:<br>" + msg_to_display.replace('\n', '<br>'),
                            "thought_chain": thought_chain,
                            "work_citation_lookup": {},
                            "web_citation_lookup": {}}) + "\n"
            
            # STEP 4: Format the response
            async for chunk in chat_completion:
                # Check if there is at least one element and the first element has the key 'delta'
                if len(chunk.choices) > 0:
                    yield json.dumps({"content": chunk.choices[0].delta.content}) + "\n"
        except Exception as e:
            logging.error(f"Error in GPTDirectApproach: {e}")
            yield json.dumps({"error": "An error occurred while generating the completion."}) + "\n"
            return

    
