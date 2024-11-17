# Copyright (c) DataReason.
### Code for On-Premises Deployment.

import os
import glob
import warnings
import io
import tempfile
import pandas as pd
from dotenv import load_dotenv
from PIL import Image
from langchain_experimental.agents.agent_toolkits import create_pandas_dataframe_agent
from langchain.agents.agent_types import AgentType
from transformers import pipeline

warnings.filterwarnings('ignore')
load_dotenv()

# Load environment variables
MODEL_PATH = os.getenv("MODEL_PATH", "Llama-3.2-1B")

# Load the model
model = pipeline('text-generation', model=MODEL_PATH)

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
    q_s = f'''You are an assistant to help analyze CSV data that is placed in a dataframe and are a dataframe ally. You analyze every row, addressing all queries with unwavering precision. Make sure that you pass in valid JSON if required.
    You DO NOT answer based on a subset of the dataframe or top 5 or based on head() output. Do not create an example dataframe. Use the dataframe provided to you. You need to look at all rows and then answer questions based on the entire dataframe and ensure the input to any tool is valid. Data is case insensitive.
    Normalize column names by converting them to lowercase and replacing spaces with underscores to handle discrepancies in column naming conventions.
    If any charts or graphs or plots were created save them in the {temp_dir} directory. Make sure the output of the result includes the final result and not just the chart or graph. Put the charts in the {temp_dir} directory and not the final output.
    Remember, you can handle both singular and plural forms of queries.
    For example:
    - If you ask 'How many thinkpads do we have?' or 'How many thinkpad do we have?', you will address both forms in the same manner.
    - Similarly, for other queries involving counts, averages, or any other operations.'''
    
    query += ' . ' + q_s
    return query

def get_images_in_temp():
    temp_dir = tempfile.gettempdir()
    image_files = glob.glob(os.path.join(temp_dir, '*.[pjJ][npNP][gG]*'))
    image_data = [get_image_data(file) for file in image_files]
    for file in image_files:
        os.remove(file)
    return image_data

def save_df(dff):
    global dffinal
    dffinal = dff

def process_agent_scratch_pad(question, df):
    question = save_chart(question)
    pdagent = create_pandas_dataframe_agent(model, df, verbose=True, agent_type=AgentType.LANGCHAIN_FUNCTIONS, allow_dangerous_code=True, agent_executor_kwargs={"handle_parsing_errors": True})
    for chunk in pdagent.stream({"input": question}):
        if "actions" in chunk:
            for action in chunk["actions"]:
                yield f'data: Calling Tool: `{action.tool}` with input `{action.tool_input}`\n'
                yield f'data: \nProcessing...: {action.log}\n'
        elif "steps" in chunk:
            for step in chunk["steps"]:
                yield f'data: Tool Result: `{step.observation}` \n\n'
        elif "output" in chunk:
            output = chunk["output"].replace("\n", "")
            yield f'data: Final Output: {output}\n\n'
            yield (f'event: end\ndata: Stream ended\n\n')
            return
        else:
            raise ValueError()

def process_agent_response(question, df):
    question = save_chart(question)
    pdagent = create_pandas_dataframe_agent(model, df, verbose=True, agent_type=AgentType.LANGCHAIN_FUNCTIONS, allow_dangerous_code=True, agent_executor_kwargs={"handle_parsing_errors": True})
    for chunk in pdagent.stream({"input": question}):
        if "output" in chunk:
            output = f'Final Output: ```{chunk["output"]}```'
            return output
			
#Explanation
#Model Loading: Using the transformers library to load a local Llama 3.2 1B model.
#Data Manipulation: Using pandas for data manipulation.
#Image Handling: Using PIL for image handling.
#Environment Variables: Loading environment variables using dotenv.
#Agent Creation: Creating a pandas dataframe agent using the local model.
#Model Path: Changed the MODEL_PATH environment variable to "Llama-3.2-1B".
#Model Loading: Updated the model loading to use the Llama 3.2 1B model from Hugging Face.
#Agent Type: Changed AgentType.OPENAI_FUNCTIONS to AgentType.LANGCHAIN_FUNCTIONS.