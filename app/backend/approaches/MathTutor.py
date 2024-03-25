# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#Turn warnings off
#from st_pages import Page, show_pages, add_page_title
import warnings
warnings.filterwarnings('ignore')
import os
# import openai
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

# openai.api_type = "azure"
# openai.api_version = "2023-06-01-preview"
# 
#______________________________________________________________________________________

OPENAI_DEPLOYMENT_NAME =  azure_openai_chatgpt_deployment
from langchain.chat_models import AzureChatOpenAI
from langchain.schema import HumanMessage
from langchain.agents import initialize_agent, load_tools
from langchain.prompts import ChatPromptTemplate


model = AzureChatOpenAI(
    openai_api_version=OPENAI_API_VERSION ,
    deployment_name=OPENAI_DEPLOYMENT_NAME)      

#--------------------------------------------------------------------------------------------------------------------------------------------------
# Addition of custom tools

#1. Tool to calculate pythagorean theorem

from langchain.tools import BaseTool
from typing import Optional
from math import sqrt, cos, sin
from typing import Union
desc = (
    "use this tool when you need to calculate the length of a hypotenuse"
    "given one or two sides of a triangle and/or an angle (in degrees). "
    "To use the tool, you must provide at least two of the following parameters "
    "['adjacent_side', 'opposite_side', 'angle']."
)

class PythagorasTool(BaseTool):
    name = "Hypotenuse calculator"
    description = desc
    
    def _run(
        self,
        adjacent_side: Optional[Union[int, float]] = None,
        opposite_side: Optional[Union[int, float]] = None,
        angle: Optional[Union[int, float]] = None
    ):
        # check for the values we have been given
        if adjacent_side and opposite_side:
            return sqrt(float(adjacent_side)**2 + float(opposite_side)**2)
        elif adjacent_side and angle:
            return adjacent_side / cos(float(angle))
        elif opposite_side and angle:
            return opposite_side / sin(float(angle))
        else:
            return "Could not calculate the hypotenuse of the triangle. Need two or more of `adjacent_side`, `opposite_side`, or `angle`."
    
    def _arun(self, query: str):
        raise NotImplementedError("This tool does not support async")

tools = [PythagorasTool()]

#________________________________________

#2.tool to calculate the area of a circle
from math import pi

  

class CircumferenceTool(BaseTool):
    name = "Circumference calculator"
    description = "use this tool when you need to calculate a circumference using the radius of a circle"

    def _run(self, radius: Union[int, float]):
        return float(radius)*2.0*pi

    def _arun(self, radius: int):
        raise NotImplementedError("This tool does not support async")
    

tools = [CircumferenceTool()]

#add math module from Lanhgchain

tools = load_tools(["llm-math"],  llm=model)

#------------------------------------------------------------------------------------------------------------------------------------------
# Langchain AzureOpenAI testing

# message = HumanMessage(
# content="Translate this sentence from English to French. I love programming.")
# model([message])
# print(message.content)

#-----------------------------------------------------------------------------------------------------------------------------------------------

# # Initialize the agent
zero_shot_agent_math = initialize_agent(
    agent="zero-shot-react-description",
        tools=tools,
    llm=model,
    verbose=True,
    max_iterations=10,
    max_execution_time=120,
    handle_parsing_errors=True,
    return_intermediate_steps=True)

# Prompt template for Zeroshot agent

# print(zero_shot_agent_math.agent.llm_chain.prompt.template)



# function to stream agent response 
def process_agent_scratch_pad( question):
    messages = []
    for chunk in zero_shot_agent_math.stream({"input": question}):
        if "actions" in chunk:
            for action in chunk["actions"]:
                messages.append(f"Calling Tool: `{action.tool}` with input `{action.tool_input}`")
                messages.append(f'I am thinking...: {action.log}')
        elif "steps" in chunk:
            for step in chunk["steps"]:
                messages.append(f"Tool Result: `{step.observation}`")                               
        elif "output" in chunk:
            messages.append(f'Final Output: {chunk["output"]}')
        else:
            raise ValueError()
    return messages
        
#Function to stream final output       
def process_agent_response( question):
    stream = zero_shot_agent_math.stream({"input": question})
    output = "No output"
    if stream:
        for chunk in stream:
            if "output" in chunk:
                output =    f'Final Output: {chunk["output"]}'
    return output
  

#Function to process clues
def generate_response(question):
    model = AzureChatOpenAI(
        openai_api_version=OPENAI_API_VERSION ,
        deployment_name=OPENAI_DEPLOYMENT_NAME)   
    prompt_template = ChatPromptTemplate.from_template(template=prompt)
    messages = prompt_template.format_messages(
    question=question
    )
    response = model(messages)
    return response.content

#prompt for clues

prompt = """
Act as a tutor that helps students solve math and arithmetic reasoning questions.
Students will ask you questions. Think step-by-step to reach the answer. Write down each reasoning step.
You will be asked to show the answer or give clues that help students reach the answer on their own.
Always list clues under Clues keyword

Here are a few example questions with expected answer and clues:

Question: John has 2 houses. Each house has 3 bedrooms and there are 2 windows in each bedroom.
Each house has 1 kitchen with 2 windows. Also, each house has 5 windows that are not in the bedrooms or kitchens.
How many windows are there in John's houses?
Answer: Each house has 3 bedrooms with 2 windows each, so that's 3 x 2 = 6 windows per house. \
Each house also has 1 kitchen with 2 windows, so that's 2 x 1 = 2 windows per house. \
Each house has 5 windows that are not in the bedrooms or kitchens, so that's 5 x 1 = 5 windows per house. \
In total, each house has 6 + 2 + 5 = 13 windows. \
Since John has 2 houses, he has a total of 2 x 13 = 26 windows. The answer is 26.
Clues: 1. Find the number of bedroom windows, kitchen windows, and other windows separately \
2. Add them together to find the total number of windows at each house \
3. Find the total number of windows for all the houses.

Question: There are 15 trees in the grove. Grove workers will plant trees in the grove today. After they are done, there will be 21 trees. How many trees did the grove workers plant today?
Answer: There are originally 15 trees. After the workers plant some trees, \
there are 21 trees. So the workers planted 21 - 15 = 6 trees. The answer is 6.",
Clues: 1. Start with the total number of trees after planting and subtract the original \
number of trees to find how many were planted. \
2. Use subtraction to find the difference between the two numbers.

Question: Leah had 32 chocolates and her sister had 42. If they ate 35, how many pieces do they have left in total? 
Answer: Originally, Leah had 32 chocolates. Her sister had 42. \
So in total they had 32 + 42 = 74. After eating 35, they \
had 74 - 35 = 39. The answer is 39.
Clues: 1. Start with the total number of chocolates they had. \
2. Subtract the number of chocolates they ate.

Question: Find the derivative of f(x) = x^2 with respect to x.
Answer: The derivative of f(x) = x^2 with respect to x is f'(x) = 2x.
Clues: 
1. Use the power rule for differentiation: d/dx(x^n) = nx^(n-1).
2. Apply the power rule to each term in the function.

Question: Find the integral of f(x) = 3x^2 with respect to x.
Answer: The integral of f(x) = 3x^2 with respect to x is F(x) = x^3 + C, where C is the constant of integration.
Clues: 
1. Use the power rule for integration: ∫x^n dx = (1/(n+1)) * x^(n+1) + C.
2. Apply the power rule to each term in the function.
3. Add the constant of integration, C, to the result.

Question: Find the limit of f(x) = (x^2 - 1) / (x - 1) as x approaches 1.
Answer: The limit of f(x) = (x^2 - 1) / (x - 1) as x approaches 1 is 2.
Clues: 
1. Try direct substitution first.
2. If direct substitution results in an indeterminate form (0/0 or ∞/∞), try factoring or rationalizing the expression.
3. If factoring or rationalizing doesn't work, try simplifying the expression using algebraic manipulation.

Question: {question}

"""


        
   
        
        

        



            
   
