# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#Turn warnings off
#from st_pages import Page, show_pages, add_page_title
import os
import warnings
from dotenv import load_dotenv
from typing import ClassVar

from langchain_openai import AzureChatOpenAI
from langchain.agents import initialize_agent, AgentType
from langchain.prompts import ChatPromptTemplate
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

#--------------------------------------------------------------------------------------------------------------------------------------------------
# Addition of custom tools

#1. Tool to calculate pythagorean theorem

from langchain.tools import BaseTool
from pydantic import BaseModel
from langchain.chains import LLMMathChain
from typing import Optional
from math import sqrt, cos, sin
from typing import Union
desc = (
    "use this tool when you need to calculate the length of a hypotenuse"
    "given one or two sides of a triangle and/or an angle (in degrees). "
    "To use the tool, you must provide at least two of the following parameters "
    "['adjacent_side', 'opposite_side', 'angle']."
)

# Define the BaseCache to make the tool compatible with the Langchain
class BaseCache(BaseModel):
    pass
class Callbacks(BaseModel):
    pass

# Call model_rebuild for LLMMathChain
LLMMathChain.model_rebuild()

class PythagorasTool(BaseTool):
    name: ClassVar[str] = "Hypotenuse calculator"
    description: ClassVar[str] = desc
    
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


#________________________________________

#2.tool to calculate the area of a circle
from math import pi

  

class CircumferenceTool(BaseTool):
    name: ClassVar[str] = "Circumference calculator"
    description: ClassVar[str] = "use this tool when you need to calculate a circumference using the radius of a circle"

    def _run(self, radius: Union[int, float]):
        return float(radius)*2.0*pi

    def _arun(self, radius: int):
        raise NotImplementedError("This tool does not support async")
    

# Examples of built-in tools
llm_math_tool = load_tools(["llm-math"], llm=model)
llm_wiki_tool = load_tools(["wikipedia"], llm=model)
# Examples of custom tools
llm_pythag_tool = [PythagorasTool()]
llm_circumference_tool = [CircumferenceTool()]


PREFIX = """Act as a math tutor that helps students solve a wide array of mathematical challenges, including arithmetic problems, algebraic equations, geometric proofs, calculus, and statistical analysis, as well as word problems.
Students will ask you math questions. When faced with math-related questions, always refer to your tools first. LLM-Math and wikipedia are tools that can help you solve math problems.
If you cannot find a solution through your tools, then offer explanation or methodologies on how to tackle the problem on your own.

In handling math queries, try using your tools initially. If no solution is found, then attempt to solve the problem on your own.
"""

# Initialize the agent with a single input tool
# You can choose which of the tools to use or create separate agents for different tools
zero_shot_agent_math = initialize_agent(
    agent=AgentType.ZERO_SHOT_REACT_DESCRIPTION,
        tools=llm_math_tool,
    llm=model,
    verbose=True,
    max_iterations=10,
    max_execution_time=120,
    handle_parsing_errors=True,
    return_intermediate_steps=True,
    agent_kwargs={ 'prefix':PREFIX})

# Prompt template for Zeroshot agent

async def stream_agent_responses(question):
    zero_shot_agent_math = initialize_agent(
        agent="zero-shot-react-description",
        tools=llm_math_tool,
        llm=model,
        verbose=True,
        max_iterations=10,
        max_execution_time=120,
        handle_parsing_errors=True,
        agent_kwargs={ 'prefix':PREFIX}
    )
    for chunk in zero_shot_agent_math.stream({"input": question}):
        if "actions" in chunk:
            for action in chunk["actions"]:
                yield f'data: Calling Tool: `{action.tool}` with input `{action.tool_input}`\n\n'
                yield f'data: Processing...: {action.log} \n\n'
        elif "steps" in chunk:
            for step in chunk["steps"]:
                yield f'data: Tool Result: `{step.observation}` \n\n'
        elif "output" in chunk:
            output =   f'data: Final Output: `{chunk["output"]}`\n\n'
            yield output
            yield (f'event: end\ndata: Stream ended\n\n')
            return
        else:
            raise ValueError()



# function to stream agent response 
def process_agent_scratch_pad( question):
    messages = []
    for chunk in zero_shot_agent_math.stream({"input": question}):
        if "actions" in chunk:
            for action in chunk["actions"]:
                messages.append(f"Calling Tool: `{action.tool}` with input `{action.tool_input}`\n")
                messages.append(f'Processing: {action.log} \n')
        elif "steps" in chunk:
            for step in chunk["steps"]:
                messages.append(f"Tool Result: `{step.observation}`\n")                               
        elif "output" in chunk:
            messages.append(f'Final Output: {chunk["output"]}')
        else:
            raise ValueError()
    return messages
        
#Function to stream final output       
def process_agent_response( question):
    stream = zero_shot_agent_math.stream({"input": question})
    if stream:
        for chunk in stream:
            if "output" in chunk:
                output =    f'Final Output: {chunk["output"]}'
    return output
  

#Function to process clues
def generate_response(question):    
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
Answer: Each house has 3 bedrooms with 2 windows each, so that's 3 * 2 = 6 windows per house. \
Each house also has 1 kitchen with 2 windows, so that's 2 * 1 = 2 windows per house. \
Each house has 5 windows that are not in the bedrooms or kitchens, so that's 5 x 1 = 5 windows per house. \
In total, each house has 6 + 2 + 5 = 13 windows. \
Since John has 2 houses, he has a total of 2 * 13 = 26 windows. The answer is 26.
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


        
   
        
        

        



            
   
