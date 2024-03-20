# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.


import streamlit as st
import pandas as pd
from langchain.chat_models import ChatOpenAI
from langchain_experimental.agents.agent_toolkits import create_pandas_dataframe_agent
from langchain.agents.agent_types import AgentType
from langchain.chat_models import AzureChatOpenAI
import os
import matplotlib.pyplot as plt
from streamlit_image_select import image_select
import glob
from langchain.agents import load_tools
import warnings
warnings.filterwarnings('ignore')
from dotenv import load_dotenv

# Initialize session state
if 'show_images' not in st.session_state:
    st.session_state.show_images = False

#--------------------------------------------------------------------------
#variables needed for testing
OPENAI_API_TYPE = "azure"
OPENAI_API_VERSION = "2023-06-01-preview"
OPENAI_API_BASE = " "
OPENAI_API_KEY = " "
OPENAI_DEPLOYMENT_NAME = "gpt-4"
MODEL_NAME = "gpt-4"

os.environ["OPENAI_API_TYPE"] = OPENAI_API_TYPE
os.environ["OPENAI_API_VERSION"] = OPENAI_API_VERSION
#os.environ["OPENAI_API_BASE"] = OPENAI_API_BASE
#os.environ["AZURE_OPENAI_ENDPOINT"] = OPENAI_API_BASE
#os.environ["OPENAI_API_KEY"] = OPENAI_API_KEY
os.environ["OPENAI_DEPLOYMENT_NAME"] = OPENAI_DEPLOYMENT_NAME

load_dotenv()

#Environment variables when integrated into the app
#_________________________________________________________________________

# # Access environment variables
# azure_openai_service_key = os.getenv("AZURE_OPENAI_SERVICE_KEY")
# azure_openai_service = os.getenv("AZURE_OPENAI_SERVICE")
# azure_openai_chatgpt_deployment = os.getenv("AZURE_OPENAI_CHATGPT_DEPLOYMENT")

# openai.api_key = azure_openai_service_key
# openai.api_base = f"https://{azure_openai_service}.openai.azure.com/"
# deployment_name = azure_openai_chatgpt_deployment

# openai.api_type = "azure"
# openai.api_version = "2023-06-01-preview"
# 
#______________________________________________________________________________________




# Page title


uploaded_file = st.file_uploader('Upload a CSV file', type=['csv'])


def save_chart(query):
    q_s = ' If any charts or graphs or plots were created save them localy and include the save file names in your response.'
    query += ' . '+ q_s
    return query

 
       
# Function to chat with CSV

def chat_with_csv(df):
    
    st.header('Output')
    df = pd.read_csv(uploaded_file)
    with st.expander('See DataFrame'):
       st.write(df)
   
       
    pdagent = create_pandas_dataframe_agent(
            AzureChatOpenAI(
                        openai_api_version=OPENAI_API_VERSION,                        
                        deployment_name=OPENAI_DEPLOYMENT_NAME), df, verbose=True,handle_parsing_errors=True,agent_type=AgentType.OPENAI_FUNCTIONS,save_charts=True)
        
   
    
    with st.form('myform'):
        if query_text == 'Other':
            user_question = st.text_input('Ask a question about your CSV:','')
        else:
            user_question = query_text
        
        analysis = st.form_submit_button('Here is my analysis')
        answer = st.form_submit_button('Show me the answer ')   
        
        if 'chart' or 'charts' or 'graph' or 'graphs' or 'plot' or 'plt' in user_question:
            user_question = save_chart(user_question)
             
       

        if user_question is not None and user_question != "":
            
            with st.spinner(text="In progress..."):
                if analysis:
                    process_agent_scratch_pad(pdagent, user_question)
        
                if answer:
                    process_agent_response(pdagent, user_question)
             
           
                    
        imgs_png = glob.glob('*.png')
        imgs_jpg = glob.glob('*.jpg')
        imgs_jpeeg = glob.glob('*.jpeg')
        imgs_ = imgs_png + imgs_jpg + imgs_jpeeg
        if len(imgs_) > 0:
            img = image_select("Generated Charts/Graphs", imgs_, captions =imgs_, return_value = 'index')
            st.write(img)             
         
           
# function to stream agent response 
def process_agent_scratch_pad(agent_executor, question):
    for chunk in agent_executor.stream({"input": question}):
        if "actions" in chunk:
            for action in chunk["actions"]:
                st.write(f"Calling Tool: `{action.tool}` with input `{action.tool_input}`")
                st.write(f'I am thinking...: {action.log}')
        elif "steps" in chunk:
            for step in chunk["steps"]:
                st.write(f"Tool Result: `{step.observation}`")                               
        elif "output" in chunk:
            st.write(f'Final Output: {chunk["output"]}')
        else:
            raise ValueError()
        
#Function to stream final output       
def process_agent_response(agent_executor, question):
    for chunk in agent_executor.stream({"input": question}):
        if "output" in chunk:
            st.write(f'Final Output: {chunk["output"]}')


# App logic
if uploaded_file is not None:
    df = pd.read_csv(uploaded_file,encoding='unicode_escape')
    # df = pd.read_csv(uploaded_file)
    question_list = [
        'How many rows are there?',
        'What is the data type of each column?',
        'What are the summary statistics for categorical data?',
        'Other']
    query_text = st.selectbox('Select an example query:', question_list)
    query_key = "query_select_" + str(hash(query_text))
    chat_with_csv(df)
    
   
    
    
    
