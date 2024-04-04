# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import base64
import os
import glob
import warnings
import re
import pandas as pd
from langchain.chat_models import ChatOpenAI
from langchain_experimental.agents.agent_toolkits import create_pandas_dataframe_agent
from langchain.agents.agent_types import AgentType
from langchain.chat_models import AzureChatOpenAI
from langchain.agents import load_tools
import matplotlib.pyplot as plt

warnings.filterwarnings('ignore')
from dotenv import load_dotenv

# Initialize session state
# if 'show_images' not in st.session_state:
#     st.session_state.show_images = False

#--------------------------------------------------------------------------
#variables needed for testing
OPENAI_API_TYPE = "azure"
OPENAI_API_VERSION = "2023-06-01-preview"
OPENAI_API_BASE = " "
OPENAI_API_KEY = " "
OPENAI_DEPLOYMENT_NAME = " "
MODEL_NAME = " "
AZURE_OPENAI_ENDPOINT = ' '
AZURE_OPENAI_SERVICE_KEY = ' '

os.environ["OPENAI_API_TYPE"] = OPENAI_API_TYPE
os.environ["OPENAI_API_VERSION"] = OPENAI_API_VERSION


load_dotenv()

#Environment variables when integrated into the app
#_________________________________________________________________________


azure_openai_chatgpt_deployment = os.getenv("AZURE_OPENAI_CHATGPT_DEPLOYMENT")


deployment_name = azure_openai_chatgpt_deployment
OPENAI_DEPLOYMENT_NAME = deployment_name


# Page title


dffinal = None
pdagent = None
agent_imgs = []

def refreshagent():
    global pdagent
    pdagent = None



 
def save_df(dff):
    global dffinal
    dffinal = dff      


def is_base64(s):
    pattern = r'^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{4})$'
    if s.startswith('base64 string:') and s.endswith('end of base 64 string'):
        return True
    elif bool(re.fullmatch(pattern, s)):
        return True
    return False


      
# function to stream agent response 
def process_agent_scratch_pad(question, df):
    chat = AzureChatOpenAI(
                openai_api_version=OPENAI_API_VERSION,
                deployment_name=OPENAI_DEPLOYMENT_NAME)
    
    pdagent = create_pandas_dataframe_agent(chat, df, verbose=True,handle_parsing_errors=True,agent_type=AgentType.OPENAI_FUNCTIONS)
    for chunk in pdagent.stream({"input": question}):
        if "actions" in chunk:
            for action in chunk["actions"]:
                yield f'data: Calling Tool: `{action.tool}` with input `{action.tool_input}`\n'
                yield f'data:\nProcessing...: {action.log}\n'
        elif "steps" in chunk:
            for step in chunk["steps"]:
                if isinstance(step.observation, str):
                    if step.observation:
                        # Check for multiple strings surrounded by parentheses and separated by commas
                        pattern = r'\(([^)]+)\)'
                        matches = re.findall(pattern, step.observation)
                        if matches:
                            print("step.observation contains multiple strings")
                            for match in matches:
                                strings = match.split(',')
                                for s in strings:
                                    if is_base64(s.strip()):
                                        print("s is a base64 string")
                                        agent_imgs.append(s.strip())
                                    else:
                                        print("s is not a base64 string")
                                        yield f'data: Tool Result: `{step.observation}` \n\n'  
                        else:
                            if is_base64(step.observation):
                                print("step.observation is a base64 string")
                                agent_imgs.append(step.observation)
                            else:
                                print("step.observation is not a base64 string")
                                yield f'data: Tool Result: `{step.observation}` \n\n'                              
        elif "output" in chunk:
            output = f'Final Output: {chunk["output"]}'
            pattern = r'data:image\/[a-zA-Z]*;base64,[^\s]*'
            output = re.sub(pattern, '', output)
            output = re.sub(r'string:[^\s]*', '', output)
            yield output
            return
        else:
            raise ValueError()
        
def is_base64out(s):
    try:
        return base64.b64encode(base64.b64decode(s)) == s
    except Exception:
        return False
#Function to stream final output       
def process_agent_response(question):
    chat = AzureChatOpenAI(
                openai_api_version=OPENAI_API_VERSION,                        
                deployment_name=OPENAI_DEPLOYMENT_NAME)
    
    pdagent = create_pandas_dataframe_agent(chat, dffinal, verbose=True,handle_parsing_errors=True,agent_type=AgentType.OPENAI_FUNCTIONS)
    for chunk in pdagent.stream({"input": question}):
        message = chunk["messages"]
        curr = message[0]
        if (curr.content.startswith('(') and curr.content.endswith(')')):
            # Check for multiple strings surrounded by parentheses and separated by commas
            pattern = r'\(([^)]+)\)'
            matches = re.findall(pattern, curr.content)
            if matches:
                print("curr.content contains multiple strings")
                for match in matches:
                    strings = match.split(',')
                    for s in strings:
                        if is_base64out(s.strip()):
                            print("s is a base64 string")
                            agent_imgs.append(s.strip())
                        else:
                            print("s is not a base64 string")
            else:
                if is_base64out(curr.content):
                    print("curr.content is a base64 string")
                    agent_imgs.append(curr.content)
                else:
                    print("curr.content is not a base64 string")
        elif("base64 string:" in curr.content and "output" not in chunk) :
            base64_string = curr.content
            
            match = re.search(r'base64 string:(.*?)end of base 64 string', base64_string)
            if match:
                # Extract the base64 strings
                base64_strings = match.group(1).strip().split(',')
                # Set the agent_img global variable to the list of base64 strings
                for img in base64_strings:
                    agent_imgs.append(img)
        elif "output" in chunk:
            output = f'Final Output: {chunk["output"]}'
            pattern = r'data:image\/[a-zA-Z]*;base64,[^\s]*'
            output = re.sub(pattern, '', output)
            output = re.sub(r'string:[^\s]*', '', output)
            
            # Remove the base64 strings from the output
            
            return output

    
   
    
    
    
