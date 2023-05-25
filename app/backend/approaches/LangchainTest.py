from enum import Enum
import openai
from azure.search.documents import SearchClient
from azure.search.documents.models import QueryType
from approaches.approach import Approach
from text import nonewlines

class LangchainPromptTemplates(Enum):
    SystemMessagePromptTemplate = """system {systemPersona}
    you are a  {systemPersona} who helps the analysts with their questions about their agencies data. Be brief in your answers.
    Answer ONLY with the facts listed in the list of sources below. If there isn't enough information below, say you don't know. Do not generate answers that don't use the sources below. For tabular information return it as an html table. Do not return markdown format.
    Each source has a file name followed by a pipe character and the actual information, always include the source name for each fact you use in the response. Use square brakets to reference the source, e.g. [info1.txt]. Don't combine sources, list each source separately, e.g. [info1.txt][info2.pdf].
{follow_up_questions_prompt}
{injected_prompt}
Sources:
{sources}

{chat_history}
"""

    HumanMessagePromptTemplate = """human {userPersona}
{injected_prompt}
{message}
"""

    AIMessagePromptTemplate = """assistant {aiPersona}
{injected_prompt}
{message}
"""

class ChatReadRetrieveReadApproach(Approach):
    prompt_prefix = LangchainPromptTemplates.SystemMessagePromptTemplate.value

    follow_up_questions_prompt_content = LangchainPromptTemplates.SystemMessagePromptTemplate.value

    query_prompt_template = """Below is a history of the conversation so far, and a new question asked by the user that needs to be answered by searching in a knowledge base.
    Generate a search query based on the conversation and the new question. 
    Do not include cited source filenames and document names e.g info.txt or doc.pdf in the search query terms.
    Do not include any text inside [] or <<>> in the search query terms.
    If the question is not in English, translate the question to English before generating the search query.

Chat History:
{chat_history}

Question:
{question}

Search query:
"""

    def __init__(self, search_client: SearchClient, oai_service_name: str, oai_service_key: str, chatgpt_deployment: str, gpt_deployment: str, sourcepage_field: str, content_field: str):
        self.search_client = search_client
        self.chatgpt_deployment = chatgpt_deployment
        self.gpt_deployment = gpt_deployment
        self.sourcepage_field = sourcepage_field
        self.content_field = content_field
        openai.api_base = 'https://' + oai_service_name + '.openai.azure.com/'
        openai.api_type = 'azure'
        openai.api_key = oai_service_key

    def run(self, history: list[dict], overrides: dict) -> any:
        use_semantic_captions = True if overrides.get("semantic_captions") else False
        top = overrides.get("top") or 3
        exclude_category = overrides.get("exclude_category") or None
        filter = "category ne '{}'".format(exclude_category.replace("'", "''")) if exclude_category else None
        userPersona = overrides.get("user_persona") or ""
        systemPersona = overrides.get("system_persona") or ""
        aiPersona = overrides.get("ai_persona") or ""

        # STEP 1: Generate an optimized keyword search query based on the chat history and the last question
        prompt = self.query_prompt_template.format(chat_history=self.get_chat_history_as_text(history, include_last_turn=False), question=history[-1]["user"])
        completion = openai.Completion.create(
            engine=self.chatgpt_deployment, 
            prompt=prompt, 
            temperature=0.0, 
            max_tokens=32, 
            n=1, 
            stop=["\n"])
        q = completion.choices[0].text

        # STEP 2: Retrieve relevant documents from the search index with the GPT optimized query
        if overrides.get("semantic_ranker"):
            r = self.search_client.search(q, 
                                          filter=filter,
                                          query_type=QueryType.SEMANTIC, 
                                          query_language="en-us", 
                                          query_speller="lexicon", 
                                          semantic_configuration_name="default", 
                                          top=top, 
                                          query_caption="extractive|highlight-false" if use_semantic_captions else None)
        else:
            r = self.search_client.search(q, filter=filter, top=top)
        
        citation_lookup = {} # dict of "FileX" monikor to the actual file name
        results = [] # list of results to be used in the prompt
        data_points = [] # list of data points to be used in the response
        for idx,doc in enumerate(r): # for each document in the search results
            if use_semantic_captions:
                # if using semantic captions, use the captions instead of the content
                # include the "FileX" monikor in the prompt, and the actual file name in the response
                results.append(f"File{idx} " + "| " + nonewlines(" . ".join([c.text for c in doc['@search.captions']])))
                data_points.append("/".join(doc[self.sourcepage_field].split("/")[4:]) + "| " + nonewlines(" . ".join([c.text for c in doc['@search.captions']])))
            else:
                # if not using semantic captions, use the content instead of the captions
                # include the "FileX" monikor in the prompt, and the actual file name in the response
                results.append(f"File{idx} " + "| " + nonewlines(doc[self.content_field]))
                data_points.append("/".join(doc[self.sourcepage_field].split("/")[4:]) + "| " + nonewlines(doc[self.content_field]))
            # add the "FileX" monikor and full file name to the citation lookup
            citation_lookup[f"File{idx}"] = doc[self.sourcepage_field]
        # create a single string of all the results to be used in the prompt
        content = "\n".join(results)

        follow_up_questions_prompt = self.follow_up_questions_prompt_content if overrides.get("suggest_followup_questions") else ""
        
        # Allow client to replace the entire prompt, or to inject into the existing prompt using >>>
        prompt_override = overrides.get("prompt_template")
        if prompt_override is None:
            prompt = self.prompt_prefix.format(injected_prompt="", sources=content, chat_history=self.get_chat_history_as_text(history), follow_up_questions_prompt=follow_up_questions_prompt, systemPersona=systemPersona)
        elif prompt_override.startswith(">>>"):
            prompt = self.prompt_prefix.format(injected_prompt=prompt_override[3:] + "\n", sources=content, chat_history=self.get_chat_history_as_text(history), follow_up_questions_prompt=follow_up_questions_prompt, systemPersona=systemPersona)
        else:
            prompt = prompt_override.format(sources=content, chat_history=self.get_chat_history_as_text(history), follow_up_questions_prompt=follow_up_questions_prompt, systemPersona=systemPersona)

        # Add persona to the prompt
        prompt += LangchainPromptTemplates.HumanMessagePromptTemplate.value.format(
            userPersona=userPersona, injected_prompt="", message="")
        prompt += LangchainPromptTemplates.AIMessagePromptTemplate.value.format(
            aiPersona=aiPersona, injected_prompt="", message="")
        prompt += LangchainPromptTemplates.SystemMessagePromptTemplate.value.format(
            systemPersona=systemPersona, follow_up_questions_prompt="", injected_prompt="", sources="",
            chat_history=self.get_chat_history_as_text(history))

        # STEP 3: Generate a contextual and content-specific answer using the search results and chat history
        completion = openai.Completion.create(
            engine=self.chatgpt_deployment, 
            prompt=prompt, 
            temperature=overrides.get("temperature") or 0.7, 
            max_tokens=1024, 
            n=1, 
            stop=["", ""])

        return {"data_points": data_points, "answer": completion.choices[0].text, "thoughts": f"Searched for:<br>{q}<br><br>Prompt:<br>" + prompt.replace('\n', '<br>'), "citation_lookup": citation_lookup}
    
    def get_chat_history_as_text(self, history, include_last_turn=True, approx_max_tokens=1000) -> str:
        history_text = ""
        history_range = reversed(history) if include_last_turn else reversed(history[:-1])
        for h in history_range:
            ai_persona = h.get("aiPersona") or ""
            assistant_response = h.get("assistant", "")

            history_text = f"assistant{ai_persona}\n{assistant_response}\n{history_text}"

            if len(history_text) > approx_max_tokens * 4:
                break

        return history_text



