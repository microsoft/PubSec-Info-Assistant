# # Copyright (c) Microsoft Corporation.
# # Licensed under the MIT license.

import openai
from azure.search.documents import SearchClient
from azure.search.documents.models import QueryType
from approaches.approach import Approach
from text import nonewlines
from datetime import datetime, timedelta
import urllib.parse
import json
import logging
from azure.storage.blob import BlobServiceClient, generate_account_sas, ResourceTypes, AccountSasPermissions
import re

from typing import Any, Sequence
import tiktoken
from core.messagebuilder import MessageBuilder
from core.modelhelper import get_token_limit
from core.modelhelper import num_tokens_from_messages

# Simple retrieve-then-read implementation, using the Cognitive Search and OpenAI APIs directly. It first retrieves
# top documents from search, then constructs a prompt with them, and then uses OpenAI to generate an completion 
# (answer) with that prompt.

class ChatReadRetrieveReadApproach(Approach):
    
     # Chat roles
    SYSTEM = "system"
    USER = "user"
    ASSISTANT = "assistant"
    
    
                                
    system_message_chat_conversation = """You are an Azure OpenAI Completion system. Your persona is {systemPersona} who helps answer questions about an agency's data. {response_length_prompt}
    Emphasize the use of facts listed in the provided source documents.Instruct the model to use source name for each fact used in the response.  Avoid generating speculative or generalized information. Each source has a file name followed by a pipe character and 
    the actual information.Use square brackets to reference the source, e.g. [info1.txt]. Don't combine sources, list each source separately, e.g. [info1.txt][info2.pdf].
    Treat each search term as an individual keyword. Do not combine terms in quotes or brackets.
    Your goal is to provide accurate and relevant answers based on the information available in the provided source documents. Make sure to reference the source documents appropriately and avoid making assumptions or adding personal opinions.
    User persona is {userPersona}
    
    Here is how you should answer every question:
    
    -Look for relevant information in the provided source document to answer the question.       
    -If there is specific information related to question available in the source document, provide an answer along with the appropriate citation.Do not exclude citation if you are using the source document to answer your question.
    -If there is no specific information related to question available in the source document, respond with "I\'m not sure" without providing any citation. Do not provide personal opinions or assumptions.
    
    {follow_up_questions_prompt}
    {injected_prompt}
    
    """
    follow_up_questions_prompt_content = """
    Generate three very brief follow-up questions that the user would likely ask next about their agencies data. Use triple angle brackets to reference the questions, e.g. <<<Are there exclusions for prescriptions?>>>. Try not to repeat questions that have already been asked.
    Only generate questions and do not generate any text before or after the questions, such as 'Next Questions'
    """
    query_prompt_template = """Below is a history of the conversation so far, and a new question asked by the user that needs to be answered by searching in source documents.
    Generate a search query based on the conversation and the new question. 
    Do not include cited source filenames and document names e.g info.txt or doc.pdf in the search query terms.
    Do not include any text inside [] or <<<>>> in the search query terms.
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
    {"role": USER ,'content': 'I am looking for information in source documents'},
    {'role': ASSISTANT, 'content': 'user is looking for information in source documents. Do not provide answers that are not in the source documents'},
    {'role': USER, 'content': 'What steps are being taken to promote energy conservation?'}, 
    {'role': ASSISTANT, 'content': 'I am not sure. The provided source document does not include information about the current status of your specific flight'}
    ]
    
       

    def __init__(self, search_client: SearchClient, oai_service_name: str, oai_service_key: str, chatgpt_deployment: str, gpt_deployment: str, sourcepage_field: str, content_field: str, blob_client: BlobServiceClient, query_term_language: str):
        self.search_client = search_client
        self.chatgpt_deployment = chatgpt_deployment
        self.gpt_deployment = gpt_deployment
        self.sourcepage_field = sourcepage_field
        self.content_field = content_field
        self.blob_client = blob_client
        self.query_term_language = query_term_language
        self.chatgpt_token_limit = get_token_limit(chatgpt_deployment)
       
        openai.api_base = 'https://' + oai_service_name + '.openai.azure.com/'
        openai.api_type = 'azure'
        openai.api_key = oai_service_key
        
       


    # def run(self, history: list[dict], overrides: dict) -> any:
    def run(self, history: Sequence[dict[str, str]], overrides: dict[str, Any]) -> Any:
        use_semantic_captions = True if overrides.get("semantic_captions") else False
        top = overrides.get("top") or 3
        exclude_category = overrides.get("exclude_category") or None
        filter = "category ne '{}'".format(exclude_category.replace("'", "''")) if exclude_category else None
        user_persona = overrides.get("user_persona", "")
        system_persona = overrides.get("system_persona", "")
        response_length = int(overrides.get("response_length") or 1024)
        
        user_q = 'Generate search query for: ' + history[-1]["user"]
        
        query_prompt=self.query_prompt_template.format(query_term_language=self.query_term_language)
        
        
        # STEP 1: Generate an optimized keyword search query based on the chat history and the last question
        messages = self.get_messages_from_history(
            query_prompt,
            self.gpt_deployment,
            history,
            user_q,
            self.query_prompt_few_shots,
            self.chatgpt_token_limit - len(user_q)
            )
        
        chat_completion = openai.ChatCompletion.create(
            
            deployment_id=self.gpt_deployment,
            model=self.gpt_deployment,
            messages=messages, 
            temperature=0.0, 
            max_tokens=32, 
            n=1)
        
        generated_query = chat_completion.choices[0].message.content
        
        #if we fail to generate a query, return the last user question
        
        if generated_query.strip() == "0":
            generated_query = history[-1]["user"] 
        
        #remove any special characters from the query. Commenting below beacuse with gpt-4 we dont need this.
        
        # generated_query = q.strip('\"')

        # STEP 2: Retrieve relevant documents from the search index with the GPT optimized query
        if overrides.get("semantic_ranker"):
            r = self.search_client.search(generated_query,
                                          filter=filter,
                                          query_type=QueryType.SEMANTIC,
                                          query_language="en-us",
                                          query_speller="lexicon",
                                          semantic_configuration_name="default",
                                          top=top,
                                          query_caption="extractive|highlight-false" if use_semantic_captions else None)
        else:
            r = self.search_client.search(generated_query, filter=filter, top=top)

               
    
           
        citation_lookup = {}  # dict of "FileX" monikor to the actual file name
        results = []  # list of results to be used in the prompt
        data_points = []  # list of data points to be used in the response
        
       
            
        for idx, doc in enumerate(r):  # for each document in the search results
           
            if use_semantic_captions:
                # if using semantic captions, use the captions instead of the content
                # include the "FileX" monikor in the prompt, and the actual file name in the response
                results.append(f"File{idx} " + "| " + nonewlines(" . ".join([c.text for c in doc['@search.captions']])))
                data_points.append("/".join(doc[self.sourcepage_field].split("/")[4:]) + "| " + nonewlines(" . ".join([c.text for c in doc['@search.captions']])))
            else:
                # if not using semantic captions, use the content instead of the captions
                # include the "FileX" monikor in the prompt, and the actual file name in the response
                results.append(f"File{idx} " + "| " + nonewlines(doc[self.content_field]))
                data_points.append("/".join(urllib.parse.unquote(doc[self.sourcepage_field]).split("/")[4:]) + "| " + nonewlines(doc[self.content_field]))
            # add the "FileX" monikor and full file name to the citation lookup
           
            citation_lookup[f"File{idx}"] = {'citation': urllib.parse.unquote(doc[self.sourcepage_field]), 
                                             'source_path': self.get_source_file_name(doc[self.content_field]), 
                                             'page_number': self.get_first_page_num_for_chunk(doc[self.content_field])}
           
                                       
        # create a single string of all the results to be used in the prompt
        results_text = "".join(results)
        if results_text == "":
            content = "\n NONE"
        else:
            content = "\n " + results_text

        # STEP 3: Generate the prompt to be sent to the GPT model
        follow_up_questions_prompt = self.follow_up_questions_prompt_content if overrides.get("suggest_followup_questions") else ""

        # Allow client to replace the entire prompt, or to inject into the existing prompt using >>>
        prompt_override = overrides.get("prompt_template")
                                
        if prompt_override is None:
            system_message = self.system_message_chat_conversation.format(
                injected_prompt="",
                follow_up_questions_prompt=follow_up_questions_prompt,
                response_length_prompt=self.get_repsonse_lenth_prompt_text(response_length),
                userPersona=user_persona,
                systemPersona=system_persona
            )
        elif prompt_override.startswith(">>>"):
            system_message = self.system_message_chat_conversation.format(
                injected_prompt=prompt_override[3:] + "\n ",
                follow_up_questions_prompt=follow_up_questions_prompt,
                response_length_prompt=self.get_repsonse_lenth_prompt_text(response_length),
                userPersona=user_persona,
                systemPersona=system_persona
            )
        else:
            system_message = self.system_message_chat_conversation.format(
                follow_up_questions_prompt=follow_up_questions_prompt,
                response_length_prompt=self.get_repsonse_lenth_prompt_text(response_length),             
                userPersona=user_persona,
                systemPersona=system_persona
            )

        # STEP 3: Generate a contextual and content-specific answer using the search results and chat history
        messages = self.get_messages_from_history(
            system_message + "\n\nSources:\n" + content,
            self.chatgpt_deployment,
            history,
            history[-1]["user"],
            self.response_prompt_few_shots,
            max_tokens=self.chatgpt_token_limit
            )
        
        #Aparmar.Token Debugging Code. Uncomment to debug token usage.
        
        # print(messages)
        # total_prompt_tokens = sum(len(token.split()) for token in (system_message + "\n\nSources:\n" + content).split())
        # print("Total Prompt Tokens:", total_prompt_tokens)                         
        
        
        chat_completion = openai.ChatCompletion.create(
            
            deployment_id=self.chatgpt_deployment,
            model=self.chatgpt_deployment,
            messages=messages,
            temperature=float(overrides.get("response_temp")) or 0.6,
            max_tokens=response_length,
            n=1
            
        )
        # generated_response = chat_completion.choices[0].message.content
        
        #Aparmar.Token Debugging Code. Uncomment to debug token usage.
        
        # generated_response_message = chat_completion.choices[0].message
        # # Count the tokens in the generated response message
        # token_count = num_tokens_from_messages(generated_response_message, 'gpt-4')
        # print("Generated Response Tokens:", token_count)

        msg_to_display = '\n\n'.join([str(message) for message in messages])
  
      
    
        return {
            "data_points": data_points,
            "answer": f"{urllib.parse.unquote(chat_completion.choices[0].message.content)}",
            "thoughts": f"Searched for:<br>{generated_query}<br><br>Conversations:<br>" + msg_to_display.replace('\n', '<br>'),
            "citation_lookup": citation_lookup
        }
       
        #Aparmar. Custom method to construct Chat History as opposed to single string of chat History.
    def get_messages_from_history(
        self, 
        system_prompt: str,
        model_id: str, 
        history: Sequence[dict[str, str]], 
        user_conv: str, 
        few_shots = [], 
        max_tokens: int = 4096) -> []:
        
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
    
    def get_repsonse_lenth_prompt_text(self, response_length: int):
        levels = {
            1024: "succinct",
            2048: "standard",
            3072: "thorough",
        }
        level = levels[response_length]
        return f"Please provide a {level} answer. This means that your answer should be no more than {response_length} tokens long."   
    
    
    
    # Parse the search document content for "file_name" attribute
    def get_source_file_name(self, content: str) -> str:
        try:
            source_path = urllib.parse.unquote(json.loads(content)['file_name'])
            sas_token = generate_account_sas(self.blob_client.account_name, self.blob_client.credential.account_key, 
                                     resource_types=ResourceTypes(object=True,service=True,container=True), 
                                     permission=AccountSasPermissions(read=True,write=True,list=True,delete=False,add=True,create=True,update=True,process=False), 
                                     expiry=datetime.utcnow() + timedelta(hours=1))
            return self.blob_client.url + source_path + "?" + sas_token
        except Exception as e:
            logging.exception("Unable to parse source file name: " + str(e) + "")
            return ""
    
    # Parse the search document content for the first page from the "pages" attribute
    def get_first_page_num_for_chunk(self, content: str) -> str:
        try:
            page_num = str(json.loads(content)['pages'][0])
            if page_num is None:
                return "0"
            return page_num
        except Exception as e:
            logging.exception("Unable to parse first page num: " + str(e) + "")
            return "0"










  
        
      
