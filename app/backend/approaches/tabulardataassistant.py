# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import base64
import os
import glob
import warnings
import io
import tempfile
from dotenv import load_dotenv
from PIL import Image
from langchain_experimental.agents.agent_toolkits import create_pandas_dataframe_agent
from langchain.agents.agent_types import AgentType
from langchain_openai import AzureChatOpenAI
from langchain_community.agent_toolkits.load_tools import load_tools
from azure.identity import ManagedIdentityCredential, AzureAuthorityHosts, DefaultAzureCredential, get_bearer_token_provider

warnings.filterwarnings('ignore')
load_dotenv()

OPENAI_API_BASE = os.environ.get("AZURE_OPENAI_ENDPOINT")
OPENAI_DEPLOYMENT_NAME =  os.getenv("AZURE_OPENAI_CHATGPT_DEPLOYMENT")

if os.environ.get("AZURE_OPENAI_AUTHORITY_HOST") == "AzureUSGovernment":
    AUTHORITY = AzureAuthorityHosts.AZURE_GOVERNMENT
else:
    AUTHORITY = AzureAuthorityHosts.AZURE_PUBLIC_CLOUD

if os.environ.get("LOCAL_DEBUG") == "true":
    azure_credential = DefaultAzureCredential(authority=AUTHORITY)
else:
    azure_credential = ManagedIdentityCredential(authority=AUTHORITY)
token_provider = get_bearer_token_provider(azure_credential, f'https://{os.environ.get("AZURE_AI_CREDENTIAL_DOMAIN")}/.default')

model = AzureChatOpenAI(
    azure_ad_token_provider=token_provider,
    azure_endpoint=OPENAI_API_BASE,
    openai_api_version="2024-02-01" ,
    deployment_name=OPENAI_DEPLOYMENT_NAME)

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
    q_s = f'''You are a assistant to help analyze CSV data that is placed in a dataframe and are a dataframe ally. You analyze every row, addressing all queries with unwavering precision. Make sure that you pass in valid json to if required.
    You DO NOT answer based on subset of the dataframe or top 5 or based on head() output. Do not create an example dataframe. Use the dataframe provided to you. You need to look at all rows and then answer questions based on the entire dataframe and ensure the input to any tool is valid. Data is case insensitive.
    Normalize column names by converting them to lowercase and replacing spaces with underscores to handle discrepancies in column naming conventions.
    If any charts or graphs or plots were created save them in the {temp_dir} directory. Make sure the output of the result includes the final result and not just the chart or graph. Put the charts in the {temp_dir} directory and not the final output.
    Remember, you can handle both singular and plural forms of queries. 
    
    For example:
    - If you ask \'How many thinkpads do we have?\' or \'How many thinkpad do we have?\', you will address both forms in the same manner.
    - Similarly, for other queries involving counts, averages, or any other operations.'''
    
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
         
    question = save_chart(question)
    # This agent relies on access to a python repl tool which can execute arbitrary code.
    # This can be dangerous and requires a specially sandboxed environment to be safely used.
    # Failure to properly sandbox this class can lead to arbitrary code execution vulnerabilities,
    # which can lead to data breaches, data loss, or other security incidents. You must opt in
    # to use this functionality by setting allow_dangerous_code=True.
    # https://api.python.langchain.com/en/latest/agents/langchain_experimental.agents.agent_toolkits.pandas.base.create_pandas_dataframe_agent.html
    pdagent = create_pandas_dataframe_agent(model, df, verbose=True,agent_type=AgentType.OPENAI_FUNCTIONS,allow_dangerous_code=True , agent_executor_kwargs={"handle_parsing_errors": True})
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
            yield (f'event: end\ndata: Stream ended\n\n')
            return
        else:
            raise ValueError()

#Function to stream final output       
def process_agent_response(question, df):
    question = save_chart(question)

    pdagent = create_pandas_dataframe_agent(model,
                                            df,
                                            verbose=True,
                                            agent_type=AgentType.OPENAI_FUNCTIONS,
                                            allow_dangerous_code=True,
                                            agent_executor_kwargs={"handle_parsing_errors": True})
    for chunk in pdagent.stream({"input": question}):
        if "output" in chunk:
            output = f'Final Output: ```{chunk["output"]}```'
            return output
