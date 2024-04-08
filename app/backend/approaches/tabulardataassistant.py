# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import base64
import os
import glob
from PIL import Image
import io
import warnings
import re
import pandas as pd
from langchain.chat_models import ChatOpenAI
from langchain_experimental.agents.agent_toolkits import create_pandas_dataframe_agent
from langchain.agents.agent_types import AgentType
from langchain.chat_models import AzureChatOpenAI
from langchain.agents import load_tools
import matplotlib.pyplot as plt
import tempfile
warnings.filterwarnings('ignore')
from dotenv import load_dotenv



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
def get_image_data(image_path):
    with Image.open(image_path) as img:
        img_byte_arr = io.BytesIO()
        img.save(img_byte_arr, format='PNG')
        img_byte_arr = img_byte_arr.getvalue()
        img_base64 = base64.b64encode(img_byte_arr)
    return img_base64.decode('utf-8')

def save_chart(query):
    temp_dir = tempfile.gettempdir()
    q_s = f' If any charts or graphs or plots were created save them in the {temp_dir} directory".'
    query += ' . '+ q_s
    return query

def get_images_in_temp():
    temp_dir = tempfile.gettempdir()
    image_files = glob.glob(os.path.join(temp_dir, '*.[pjJ][npNP][gG]*'))
    image_data = [get_image_data(file) for file in image_files]

    # Delete the files after reading them
    for file in image_files:
        os.remove(file)
        
    return image_data
 
def save_df(dff):
    global dffinal
    dffinal = dff      



      
# function to stream agent response 
def process_agent_scratch_pad(question, df):
    chat = AzureChatOpenAI(
                openai_api_version=OPENAI_API_VERSION,
                deployment_name=OPENAI_DEPLOYMENT_NAME)
    if 'chart' or 'charts' or 'graph' or 'graphs' or 'plot' or 'plt' in question:
        question = save_chart(question)
    pdagent = create_pandas_dataframe_agent(chat, df, verbose=True,handle_parsing_errors=True,agent_type=AgentType.OPENAI_FUNCTIONS, save_charts=True)
    for chunk in pdagent.stream({"input": question}):
        if "actions" in chunk:
            for action in chunk["actions"]:
                yield f'data: Calling Tool: `{action.tool}` with input `{action.tool_input}`\n'
                yield f'data: \nProcessing...: {action.log}\n'
        elif "steps" in chunk:
            for step in chunk["steps"]:
                yield f'data: Tool Result: `{step.observation}` \n\n'
        elif "output" in chunk:
            output = chunk["output"].replace("\n", "<br>")
            yield f'data: Final Output: {output}\n\n'
            yield 'data: Stream ended\n\n'
            return
        else:
            raise ValueError()

#Function to stream final output       
def process_agent_response(question):
    if 'chart' or 'charts' or 'graph' or 'graphs' or 'plot' or 'plt' in question:
        question = save_chart(question)
    chat = AzureChatOpenAI(
                openai_api_version=OPENAI_API_VERSION,                        
                deployment_name=OPENAI_DEPLOYMENT_NAME)
    
    pdagent = create_pandas_dataframe_agent(chat, dffinal, verbose=True,handle_parsing_errors=True,agent_type=AgentType.OPENAI_FUNCTIONS, save_charts=True)
    for chunk in pdagent.stream({"input": question}):
        if "output" in chunk:
            output = f'Final Output: ```{chunk["output"]}```'
            return output

    
   
    
    
    
