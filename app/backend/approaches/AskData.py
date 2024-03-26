# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

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
#os.environ["OPENAI_API_BASE"] = OPENAI_API_BASE
#os.environ["AZURE_OPENAI_ENDPOINT"] = AZURE_OPENAI_ENDPOINT
#os.environ["AZURE_OPENAI_SERVICE_KEY"] = AZURE_OPENAI_SERVICE_KEY
#os.environ["OPENAI_DEPLOYMENT_NAME"] = OPENAI_DEPLOYMENT_NAME

load_dotenv()

#Environment variables when integrated into the app
#_________________________________________________________________________

# # Access environment variables
# azure_openai_service_key = os.getenv("AZURE_OPENAI_SERVICE_KEY")
# azure_openai_service = os.getenv("AZURE_OPENAI_SERVICE")
azure_openai_chatgpt_deployment = os.getenv("AZURE_OPENAI_CHATGPT_DEPLOYMENT")

# openai.api_key = azure_openai_service_key
# openai.api_base = f"https://{azure_openai_service}.openai.azure.com/"
deployment_name = azure_openai_chatgpt_deployment
OPENAI_DEPLOYMENT_NAME = deployment_name

# openai.api_type = "azure"
# openai.api_version = "2023-06-01-preview"
# 
#______________________________________________________________________________________


# Page title


# uploaded_file = st.file_uploader('Upload a CSV file', type=['csv'])
dffinal = None
pdagent = None
agent_imgs = []


def save_chart(query):
    q_s = ' If any charts or graphs or plots were created save them as a base 64 encoded bytestrings. Start the base64 strings with "base64 string:" and end with "end of base 64 string, splitting them by using a comma. Do not inclue the string in the final output".'
    query += ' . '+ q_s
    return query

 
def save_df(dff):
    global pdagent
    global dffinal
    dffinal = dff
    pdagent = create_pandas_dataframe_agent(
            AzureChatOpenAI(
                        openai_api_version=OPENAI_API_VERSION,                        
                        deployment_name=OPENAI_DEPLOYMENT_NAME), dffinal, verbose=True,handle_parsing_errors=True,agent_type=AgentType.OPENAI_FUNCTIONS,save_charts=True)

# Function to chat with CSV
    


# def chat_with_csv(df):
#     # st.header('Output')
#     # with st.expander('See DataFrame'):
#     #    st.write(df)
   
        
   
    
#     # with st.form('myform'):
#     #     if query_text == 'Other':
#     #         user_question = st.text_input('Ask a question about your CSV:','')
#     #     else:
#     #         user_question = query_text
        
#     #     analysis = st.form_submit_button('Here is my analysis')
#     #     answer = st.form_submit_button('Show me the answer ')   
        
#         if 'chart' or 'charts' or 'graph' or 'graphs' or 'plot' or 'plt' in user_question:
#             user_question = save_chart(user_question)
             
       

#         if user_question is not None and user_question != "":
            
#             with st.spinner(text="In progress..."):
#                 if analysis:
#                     process_agent_scratch_pad( user_question)
        
#                 if answer:
#                     process_agent_response( user_question)
             
           
                    
#         imgs_png = glob.glob('*.png')
#         imgs_jpg = glob.glob('*.jpg')
#         imgs_jpeeg = glob.glob('*.jpeg')
#         imgs_ = imgs_png + imgs_jpg + imgs_jpeeg
#         if len(imgs_) > 0:
#             img = image_select("Generated Charts/Graphs", imgs_, captions =imgs_, return_value = 'index')
#             st.write(img)             

def getimgs():
    global agent_imgs
    # Flatten the list of lists into a single list
    return agent_imgs



      
# function to stream agent response 
def process_agent_scratch_pad( question):
    messages = []
    for chunk in pdagent.stream({"input": question}):
        if "actions" in chunk:
            for action in chunk["actions"]:
                messages.append(f"Calling Tool: `{action.tool}` with input `{action.tool_input}`")
                messages.append(f'\nI am thinking...: {action.log}')
        elif "steps" in chunk:
            for step in chunk["steps"]:
                messages.append(f"Tool Result: `{step.observation}`")                               
        elif "output" in chunk:
            messages.append(f'Final Output: {chunk["output"]}')
        else:
            raise ValueError()
    return messages
        
#Function to stream final output       
def process_agent_response(question):
    global agent_imgs
    if 'chart' or 'charts' or 'graph' or 'graphs' or 'plot' or 'plt' in question:
        question = save_chart(question)
    for chunk in pdagent.stream({"input": question}):
        message = chunk["messages"] 
        curr = message[0]
        if "base64 string:" in curr.content and "output" not in chunk:
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
            
            # Remove the base64 strings from the output
            
            return output


# App logic
# if uploaded_file is not None:
#     df = pd.read_csv(uploaded_file,encoding='unicode_escape')
#     question_list = [
#         'How many rows are there?',
#         'What is the data type of each column?',
#         'What are the summary statistics for categorical data?',
#         'Other']
#     query_text = st.selectbox('Select an example query:', question_list)
#     query_key = "query_select_" + str(hash(query_text))
#     chat_with_csv(df)
    
   
    
    
    
