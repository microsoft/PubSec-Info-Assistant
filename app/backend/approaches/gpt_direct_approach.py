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
from approaches.approach import PromptTemplate

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
        is_gov_cloud_deployment: str,
        TARGET_EMBEDDING_MODEL: str,
        ENRICHMENT_APPSERVICE_NAME: str
    ):
        self.chatgpt_deployment = chatgpt_deployment
        self.query_term_language = query_term_language
        self.chatgpt_token_limit = get_token_limit(model_name)
        #escape target embeddiong model name
        self.escaped_target_model = re.sub(r'[^a-zA-Z0-9_\-.]', '_', TARGET_EMBEDDING_MODEL)
        
        if is_gov_cloud_deployment:
            self.embedding_service_url = f'https://{ENRICHMENT_APPSERVICE_NAME}.azurewebsites.us'
        else:
            self.embedding_service_url = f'https://{ENRICHMENT_APPSERVICE_NAME}.azurewebsites.net'
        
        openai.api_base = 'https://' + oai_service_name + '.openai.azure.com/'
        openai.api_type = 'azure'
        openai.api_key = oai_service_key

        self.model_name = model_name
        self.model_version = model_version
        self.is_gov_cloud_deployment = is_gov_cloud_deployment

    # def run(self, history: list[dict], overrides: dict) -> any:
    def run(self, history: Sequence[dict[str, str]], overrides: dict[str, Any]) -> Any:
        use_semantic_captions = True if overrides.get("semantic_captions") else False
        top = overrides.get("top") or 3
        user_persona = overrides.get("user_persona", "")
        system_persona = overrides.get("system_persona", "")
        response_length = int(overrides.get("response_length") or 1024)

        user_q = 'Generate search query for: ' + history[-1]["user"]

        prompt_template = self.get_prompt_template()

        query_prompt=prompt_template.Query_Prompt_Template.format(query_term_language=self.query_term_language)

        # STEP 1: Generate an optimized keyword search query based on the chat history and the last question
        messages = self.get_messages_from_history(
            prompt_template,
            query_prompt,
            self.model_name,
            history,
            user_q,
            prompt_template.Query_Prompt_Few_Shots,
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

        # Generate embedding using REST API
        url = f'{self.embedding_service_url}/models/{self.escaped_target_model}/embed'
        data = [f'"{generated_query}"']
        headers = {
                'Accept': 'application/json',  
                'Content-Type': 'application/json',
            }

        response = requests.post(url, json=data,headers=headers,timeout=300)
        if response.status_code == 200:
            response_data = response.json()
            embedded_query_vector =response_data.get('data')          
        else:
            print('Error generating embedding:', response.status_code)
            raise Exception('Error generating embedding:', response.status_code)

        results = []  # list of results to be used in the prompt

        # create a single string of all the results to be used in the prompt
        results_text = "".join(results)
        if results_text == "":
            content = "\n NONE"
        else:
            content = "\n " + results_text

        # STEP 3: Generate the prompt to be sent to the GPT model
        follow_up_questions_prompt = (
            prompt_template.Follow_Up_Questions_Prompt_Content
            if overrides.get("suggest_followup_questions")
            else ""
        )

        # Allow client to replace the entire prompt, or to inject into the existing prompt using >>>
        prompt_override = overrides.get("prompt_template")

        if prompt_override is None:
            system_message = prompt_template.System_Message_Chat_Conversation.format(
                injected_prompt="",
                follow_up_questions_prompt=follow_up_questions_prompt,
                response_length_prompt=self.get_response_length_prompt_text(
                    response_length
                ),
                userPersona=user_persona,
                systemPersona=system_persona,
            )
        elif prompt_override.startswith(">>>"):
            system_message = prompt_template.System_Message_Chat_Conversation.format(
                injected_prompt=prompt_override[3:] + "\n ",
                follow_up_questions_prompt=follow_up_questions_prompt,
                response_length_prompt=self.get_response_length_prompt_text(
                    response_length
                ),
                userPersona=user_persona,
                systemPersona=system_persona,
            )
        else:
            system_message = prompt_template.System_Message_Chat_Conversation.format(
                follow_up_questions_prompt=follow_up_questions_prompt,
                response_length_prompt=self.get_response_length_prompt_text(
                    response_length
                ),
                userPersona=user_persona,
                systemPersona=system_persona,
            )

        # STEP 3: Generate a contextual and content-specific answer using the search results and chat history.
        #Added conditional block to use different system messages for different models.
        if self.model_name.startswith("gpt-35-turbo"):
            messages = self.get_messages_from_history(
                prompt_template,
                system_message,
                self.model_name,
                history,
                history[-1]["user"] + "Sources:\n" + content + "\n\n",
                prompt_template.Response_Prompt_Few_Shots,
                max_tokens=self.chatgpt_token_limit - 500
            )

            chat_completion = openai.ChatCompletion.create(
                deployment_id=self.chatgpt_deployment,
                model=self.model_name,
                messages=messages,
                temperature=float(overrides.get("response_temp")) or 0.6,
                n=1
            )
        elif self.model_name.startswith("gpt-4"):
            messages = self.get_messages_from_history(
                prompt_template,
                "Sources:\n" + content + "\n\n" + system_message,
                self.model_name,
                history,
                history[-1]["user"],
                prompt_template.Response_Prompt_Few_Shots,
                max_tokens=self.chatgpt_token_limit
            )

            chat_completion = openai.ChatCompletion.create(
                deployment_id=self.chatgpt_deployment,
                model=self.model_name,
                messages=messages,
                temperature=float(overrides.get("response_temp")) or 0.6,
                max_tokens=1024,
                n=1
            )

        # STEP 4: Format the response
        msg_to_display = '\n\n'.join([str(message) for message in messages])

        return {
            "data_points": [],
            "answer": f"{urllib.parse.unquote(chat_completion.choices[0].message.content)}",
            "thoughts": f"Searched for:<br>{generated_query}<br><br>Conversations:<br>" + msg_to_display.replace('\n', '<br>'),
            "citation_lookup": {}
        }
    
    def get_prompt_template(self) -> PromptTemplate:      
        template = PromptTemplate()

        template.System_Message_Chat_Conversation = """You are an Azure OpenAI Completion system. Your persona is {systemPersona} who helps answer questions about an agency's data. {response_length_prompt}
        User persona is {userPersona} 
        Your goal is to provide accurate and relevant answers based on the facts. Make sure to avoid making assumptions or adding personal opinions.
        
        Emphasize the use of facts.
        
        Here is how you should answer every question:
        -Please respond with relevant information from the data in the response along with citation if able.    
        
        {follow_up_questions_prompt}
        {injected_prompt}
        
        """
        template.Follow_Up_Questions_Prompt_Content = """
        Generate three very brief follow-up questions that the user would likely ask next about their agencies data. Use triple angle brackets to reference the questions, e.g. <<<Are there exclusions for prescriptions?>>>. Try not to repeat questions that have already been asked.
        Only generate questions and do not generate any text before or after the questions, such as 'Next Questions'
        """

        template.Query_Prompt_Template = """Below is a history of the conversation so far, and a new question asked by the user that needs to be answered.
        Generate a search query based on the conversation and the new question. Treat each search term as an individual keyword. Do not combine terms in quotes or brackets.
        Do not include cited sources e.g info or doc in the search query terms.
        Do not include any text inside [] or <<<>>> in the search query terms.
        Do not include any special characters like '+'.
        If the question is not in {query_term_language}, translate the question to {query_term_language} before generating the search query.
        If you cannot generate a search query, return just the number 0.
        """

        #Few Shot prompting for Keyword Search Query
        template.Query_Prompt_Few_Shots = [
        {'role' : template.User, 'content' : 'What are the future plans for public transportation development?' },
        {'role' : template.Assistant, 'content' : 'Future plans for public transportation' },
        {'role' : template.User, 'content' : 'how much renewable energy was generated last year?' },
        {'role' : template.Assistant, 'content' : 'Renewable energy generation last year' }
        ]

        #Few Shot prompting for Response. This will feed into Chain of thought system message.
        template.Response_Prompt_Few_Shots = [
        {'role': template.User, 'content': 'What steps are being taken to promote energy conservation?'},
        {'role': template.Assistant, 'content': 'Several steps are being taken to promote energy conservation including reducing energy consumption, increasing energy efficiency, and increasing the use of renewable energy sources. Citations[info1.json]'}
        ]

        return template