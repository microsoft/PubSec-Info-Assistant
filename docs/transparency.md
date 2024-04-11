
<!-- TOC ignore:true -->
# Transparency Note: Information Assistant (IA)

Updated 25 Mar 2024

<!-- TOC ignore:true -->
## Table of Contents
<!-- TOC -->

- [What is a Transparency Note?](#what-is-a-transparency-note)
- [The basics of IA Accelerator](#the-basics-of-ia-accelerator)
    - [Introduction](#introduction)
    - [Key Terms](#key-terms)
- [Capabilities](#capabilities)
    - [System behavior: Internal Document-based RAG](#system-behavior-internal-document-based-rag)
        - [Overview](#overview)
        - [Data Preparation](#data-preparation)
        - [Prompt Engineering](#prompt-engineering)
    - [System behavior: External Web-based RAG](#system-behavior-external-web-based-rag)
        - [Overview](#overview)
        - [Data Preparation](#data-preparation)
        - [Content Controls](#content-controls)
    - [System behavior: Compare Internally- to Externally-grounded RAG](#system-behavior-compare-internally--to-externally-grounded-rag)
        - [Overview](#overview)
        - [Data Preparation](#data-preparation)
        - [Prompt Engineering](#prompt-engineering)
    - [System behavior: Ungrounded Chat](#system-behavior-ungrounded-chat)
        - [Overview](#overview)
        - [Data Preparation](#data-preparation)
        - [Prompt Engineering](#prompt-engineering)
    - [System behavior: PREVIEW - Autonomous Agents](#system-behavior-preview---autonomous-agents)
        - [Overview](#overview)
        - [Math Assistant](#math-assistant)
        - [Tabular Data Assistant](#tabular-data-assistant)
- [Intended uses](#intended-uses)
    - [Considerations when choosing a use case](#considerations-when-choosing-a-use-case)
        - [Identity Applications](#identity-applications)
        - [Age Appropriateness/Exposure to Minors](#age-appropriatenessexposure-to-minors)
- [Limitations of IA Accelerator](#limitations-of-ia-accelerator)
    - [Qualitative limitations, human oversight requirements](#qualitative-limitations-human-oversight-requirements)
        - [Confidence Scoring](#confidence-scoring)
        - [Accuracy](#accuracy)
    - [Technical limitations, operational factors and ranges](#technical-limitations-operational-factors-and-ranges)
        - [Non-Production Status](#non-production-status)
        - [Non-Real Time Usage](#non-real-time-usage)
        - [Request Throttling](#request-throttling)
- [System performance](#system-performance)
    - [Grounded experiences](#grounded-experiences)
    - [Ungrounded experiences](#ungrounded-experiences)
- [Evaluation of IA Accelerator](#evaluation-of-ia-accelerator)
    - [Evaluating and Integrating IA Accelerator for your use](#evaluating-and-integrating-ia-accelerator-for-your-use)
        - [Human-in-the-loop](#human-in-the-loop)
        - [Data Quality Evaluation](#data-quality-evaluation)
        - [Evaluation of system performance](#evaluation-of-system-performance)
        - [Use technical documentation](#use-technical-documentation)
- [Technical limitations, operational factors and ranges](#technical-limitations-operational-factors-and-ranges)
- [Learn more about responsible AI](#learn-more-about-responsible-ai)
- [Learn more about the IA Accelerator](#learn-more-about-the-ia-accelerator)
- [Contact us](#contact-us)
    - [About this document](#about-this-document)

<!-- /TOC -->

# What is a Transparency Note?
An AI system includes not only the technology, but also the people who will use it, the people who will be affected by it, and the environment in which it is deployed. Creating a system that is fit for its intended purpose requires an understanding of how the technology works, what its capabilities and limitations are, and how to achieve the best performance. Microsoft’s Transparency Notes are intended to help you understand how our AI technology works, the choices system owners can make that influence system performance and behavior, and the importance of thinking about the whole system, including the technology, the people, and the environment. You can use Transparency Notes when developing or deploying your own system, or share them with the people who will use or be affected by your system.

Microsoft’s Transparency Notes are part of a broader effort at Microsoft to put our AI Principles into practice. To find out more, see the [Microsoft AI principles](https://www.microsoft.com/ai/responsible-ai).

# The basics of IA Accelerator

## Introduction

The IA Accelerator is a system built on top of Azure OpenAI service, Azure AI Search and other Azure services. This system showcases capabilites possible with the emerging technologies related to Generative AI and how they may be applied for specific functionality. This accelerator has been designed with Public Sector applications in mind, but has been found to be applicable to additional industries and applications. The user should be aware that Microsoft has evaluated this accelerator for a limited set of use cases. Use cases outside of those which have been evaluated need to be considered and evaluated by those using this accelerator for their intended use cases. 

At its core, the IA Accelerator is an implementation of the [Retrieval Augmented Generation (RAG) pattern](https://learn.microsoft.com/en-us/azure/search/retrieval-augmented-generation-overview) and is intended to create a system that allows the end user to ‘have an accurate conversation’ with their data. By uploading supported document types the system makes the data available to the Azure OpenAI service to support a conversational engagement with the data. The system aims to allow the end user to have some controls over how Azure OpenAI service responds, understand how the response was generated (transparency), and verify the response with citations to the specific data the accelerator is referencing.

The 1.1 release of the IA Accelerator introduces new technologies and use cases on top of the original scope which are covered in this updated Transparency Note. Become familiar with these new system capabilities and use cases to understand their responsible application to your intended use cases before proceeding. This release adds in Bing Web Search API for LLM results to enable grounding via content from the Internet, support for SharePoint as a document source, ability to interact directly with LLMs for purely generative capabilities (ungrounded), and preview agent-based features enabled through the use of [LangChain](https://www.langchain.com/) toolkit. 

The system aims to provide the functionality mentioned above while also focusing on the following key areas:

- Accuracy
  - Focusing on the science and technologies required to provide the “right” answer to the prompt
- Context
  - Provide the ability to understand the “chunks” of data within the context of a larger document (Title, section, page, date etc.)
- Confidence
  - Provide the response with a level of confidence - **Work in Progress**
- Control
  - Length of response
  - Data Sources, Date Range, Author etc that are used for the response
- Format
  - Multiple common file types
  - Tabular and structured data within documents
- Personalization
  - Tailoring the response with a specific persona in mind (Speaker and Receiver)

**NOTE:** Though we are focusing on the key areas above, **human oversight to confirm accuracy is critical. All responses from the system MUST BE verified with the citations provided. Ungrounded experiences MUST BE verified**. The grounded responses are only as accurate as the data provided.

## Key Terms

Terminology | Definition
---|---
[Azure OpenAI](https://azure.microsoft.com/en-us/products/cognitive-services/openai-service/#overview) | Collection of large-scale generative AI models available as a service via Azure. 
[ChatGPT](https://en.wikipedia.org/wiki/ChatGPT) | "ChatGPT is an artificial intelligence chatbot developed by OpenAI based on the company's Generative Pre-trained Transformer (GPT) series of large language models (LLMs)."
[Chunking](https://learn.microsoft.com/en-us/samples/azure-samples/azure-search-power-skills/azure-open-ai-embeddings-generator/) | Chunking is a strategy of breaking down large documents into smaller pieces which satisfy the token limits of OpenAI models. 
[Fabrications (aka Hallucinations)](https://en.wikipedia.org/wiki/Hallucination_(artificial_intelligence)) | "A hallucination or artificial hallucination (also occasionally called confabulation or delusion) is a confident response by an AI that does not seem to be justified by its training data". The term "Fabrication" is preferred as the term "hallucination" may be offensive to people with certain disabilities. 
[Generative AI](https://en.wikipedia.org/wiki/Generative_artificial_intelligence) | "A type of artificial intelligence (AI) system capable of generating text, images, or other media in response to prompts."
[Grounding](https://www.expert.ai/glossary-of-ai-terms/grounding/) | "The ability of generative applications to map the factual information contained in a generative output or completion. It links generative applications to available factual sources — for example, documents or knowledge bases — as a direct citation, or it searches for new links."
[Prompt engineering](https://en.wikipedia.org/wiki/Prompt_engineering) | "A concept in artificial intelligence, particularly natural language processing. In prompt engineering, the description of the task that the AI is supposed to accomplish is embedded in the input, e.g. as a question, instead of it being explicitly given. Prompt engineering typically works by converting one or more tasks to a prompt-based dataset and training a language model with what has been called "prompt-based learning" or just "prompt learning"."
[RAG](https://learn.microsoft.com/en-us/azure/search/retrieval-augmented-generation-overview) | Retrieval Augmented Generation; a pattern where data is retrieved (such as from a search system) and sent to Generative AI with a prompt to provide specific data to answer a question. 
[Semantic Search](https://learn.microsoft.com/en-us/azure/search/semantic-search-overview) | "A collection of query-related capabilities that bring semantic relevance and language understanding to textual search results."
[Token](https://help.openai.com/en/articles/4936856-what-are-tokens-and-how-to-count-them) | Input into an OpenAI model is broken down in to tokens. The model has a limit on the number of tokens it can accept. Tokenization is language-dependant.
[Vector Search](https://learn.microsoft.com/en-us/azure/search/vector-search-overview) | "Vector search is an approach in information retrieval that stores numeric representations of content for search scenarios. Because the content is numeric rather than plain text, the search engine matches on vectors that are the most similar to the query, with no requirement for matching on exact terms."

# Capabilities

**NOTE:** This project is developed with an agile methodology. As such, features and capabilities are subject to change, and may change faster than the documentation. Those deploying this project should review approved pull requests to understand changes which have been committed since the update of the documentation.

## System behavior: Internal Document-based RAG

### Overview
This capability is implemented primarily on top of Azure OpenAI service and Azure AI Search service. The system allows the end user to upload documents in specific formats either via direct upload or via integration with SharePoint connector. These documents are processed and made searchable via natural language by leveraging Azure AI Search and GPT via Azure AI Services. This allows end users to "have a conversation" with their data. The system cites the documents from which it generates answers, allowing the end user to verify the results for accuracy.

The system differentiates the internally-grounded answers from the other answers provided by the system via visual cues and system messages presented to the end user. If modifying the user experience, care should be taken to ensure that end users can easily distinguish where the grounding is coming from, or if the answer is ungrounded. 

By design this system should not provide answers that are not available in the data available to it. **The relevance of the answers to the questions asked will depend directly on the data which has been uploaded and successfully processed by the system.**

### Data Preparation

The system receives and process files from the end user. Data is chunked with various strategies in an attempt to ensure that the data can be used by Azure OpenAI service while maintaining logical relevance based on the input data element (for example, being aware of page breaks in PDF documents to keep related content together). All historically-processed data is available to the end user.

### Prompt Engineering

This system is primarily tuned for accuracy of response based on the data provided to the system. As such, much work has gone in to prompt engineering to prevent fabrications. The prompt engineering is visible to the end user when looking at the "Thought process" tab (directly from icon, or via Citation view).

**NOTE:** Fabrications may not always be preventable via prompt engineering. End users MUST always validate results with citations provided. 

## System behavior: External Web-based RAG

### Overview
This capability is implemented with [Bing Web Search for LLMs API](https://www.microsoft.com/en-us/bing/apis/llm) (Bing Web Search) and Azure OpenAI service. The system allows the end user to ask questions in natural language via the Azure OpenAI service, and grounds the answer via responses to the question from Bing Web Search. This allows end users to "have a conversation" with data from recent information found on the public Internet. The system cites the web sites from which it generates answers, allowing the end user to verify the results for accuracy. This system does not use Bing "Answers" which are curated facts available through the Bing web interface and potentially other non-LLM APIs. 

This system behavior is similar to Copilot in Bing. We suggest reviewing their [Transparency Note](https://support.microsoft.com/en-us/topic/copilot-in-bing-our-approach-to-responsible-ai-45b5eae8-7466-43e1-ae98-b48f8ff8fd44) as well when considering if you want to deploy this solution for your end users. From their Transparency Note you can read about what the Copilot in Bing team has done from a Responsible AI perspective, and what you may want to consider doing to help improve the safety of your solution.

The system differentiates the externally-grounded answers from the other answers provided by the system via visual cues and system messages presented to the end user. If modifying the user experience, care should be taken to ensure that end users can easily distinguish where the grounding is coming from, or if the answer is ungrounded. 

Due to the nature of the content available on the public Internet, it is likely that most questions will have one or more responses and that those responses will change over time. This is especially important for web-based results which are subject to real-time changes due to current events. **The relevance and accuracy of the answers to the questions asked will need to be evaluated at all times by the end user.**

### Data Preparation

The system receives and process top responses from Bing Web Search each time a question is asked; the system does NOT cache response for reuse. Due to the nature of the public Internet and continuous search indexing by the Bing service, it should be expected that answers to questions will change over time as new, potentially more relevant or updated results are returned from the Bing Web Search service.

### Content Controls
The [Bing Web Search for LLM API](https://www.microsoft.com/en-us/bing/apis/llm) (Bing Web Search) supports the Bing "Safe Search" content filtering features, which can be configured for the system at deployment time. The feature currently supports three settings {Off, Moderate, Strict} which **apply ONLY to Adult content**. At the time of this writing there is no ability within the Bing Web Search API to filter or restrict content further. This fact should be considered when evaluating your specific use case. **Microsoft does not believe that the current content controls on Bing Web Search are sufficient for minors; this capability SHOULD NOT be exposed to minors at this time**.

## System behavior: Compare Internally- to Externally-grounded RAG

### Overview
This capability is implemented by composing the [internally-grounded](#system-behavior-internal-document-based-rag) and [externally-grounded](#system-behavior-external-web-based-rag) features to answer a question, then compare the answers via a prompt made to the LLM. To implement this feature, the system makes separate calls to both features (internal and external), then creates a prompt to compare the answers. This answer is displayed to the end user.

The system differentiates the compared answers from the other answers provided by the system via visual cues and system messages presented to the end user. If modifying the user experience, care should be taken to ensure that end users can easily distinguish where the grounding is coming from, or if the answer is ungrounded.

As this system makes new calls to these services each time they are invoked (no caching is enabled), it is important to note that the answers to the same question may change over time based on new data being indexed or changes in search relevance. This is especially important for web-based results which are subject to real-time changes due to current events. **The relevance and accuracy of the answers to the questions asked will need to be evaluated at all times by the end user.**

### Data Preparation

The system receives responses from the internal document set, and the external web-based results. After receiving the separate responses, the system prepares a prompt to combine the responses with direction to the LLM to compare them and provide an output answer. The system does not use cached responses and the resulting compared answer may differ from the content of individual internally-grounded and externally-grounded answers.

### Prompt Engineering

This capability leverages the individual prompts for internally-grounded and externally-grounded answers with a specific prompt designed to compare the two. This prompt is primarily tuned for accuracy of response based on the data provided to the system. As such, much work has gone in to prompt engineering to prevent fabrications. The prompt engineering is visible to the end user when looking at the "Thought process" tab (directly from icon, or via Citation view).

**NOTE:** Fabrications may not always be preventable via prompt engineering. End users MUST always validate results with citations provided.

## System behavior: Ungrounded Chat

### Overview
This capability leverages the capabilities of a large language model (LLM) to generate responses in an ungrounded manner, without relying on external data sources or retrieval-augmented generation techniques. This approach allows for open-ended and creative generation, making it suitable for tasks such as ideation, brainstorming, and exploring hypothetical scenarios.

As users may ask questions in the ungrounded experience, ungrounded responses are not grounded in specific factual data and should be evaluated critically, especially in domains where accuracy and verifiability are paramount. Ungrounded responses will NOT have citations available for verification.

The system differentiates the ungrounded answers from the other answers provided by the system via visual cues and system messages presented to the end user. If modifying the user experience, care should be taken to ensure that end users can easily distinguish that the answer is ungrounded.

**Microsoft does not believe that current content controls on LLMs are sufficient for exposure to minors; this capability SHOULD NOT be exposed to minors at this time**.

### Data Preparation

The system does no data preparation for ungrounded chat conversations.

### Prompt Engineering

There is minimal propmt engineering provided by the system for this capability. **Fabrications are highly likely.**

## System behavior: PREVIEW - Autonomous Agents

### Overview
These capabilities include tabular data processing and a math assistant which generate responses by using an LLM as a reasoning engine. The key strength lies in agent's ability to autonomously reason about tasks, decompose them into steps, and determine the appropriate tools and data sources to leverage, all without the need for predefined task definitions or rigid workflows. This approach allows for a dynamic and adaptive response generation process.

These agents are being **released in preview mode as we continue to evaluate and mitigate the potential risks associated with autonomous reasoning**, such as misuse of external tools, lack of transparency, biased outputs, privacy concerns, and remote code execution vulnerabilities. With future releases, we plan to work to enhance the safety and robustness of these autonomous reasoning capabilities. Specific information on our preview agents can be found in [Autonomous Agents](/docs/features/features.md#autonomous-reasoning-with-agents).

**Usage of these features MUST BE carefully evaluated.**

### Math Assistant

This capability leverages the LangChain technology to enable LLMs to assist with math questions. This is an experimental feature which is primarily intended for younger audiences. **Care MUST BE taken with building a solution targeted to minors. Please see the section below that discusses [age appropriatness](#age-appropriatenessexposure-to-minors)**.

This capability presents several potential real harms to students in particular which should be mitigated if used in an education setting. At a minimum, this system may have the following harms:
1) Incorrect Answers - This capability may generate incorrect answers which may have follow-on impact on a student's grades. Establishing a system verification process would be critical for use in an education setting.
2) Incorrect process - As this capability is able to show the steps to generate an answer, there is a real possibility that it generates processes which are incorrect. This may have a follow-on impact to students who learn an incorrect process for answering similar types of math problems.
3) Undefined resolution process - Educators should establish an agreed upon resolution process for incorrect answers and incorrect process trainings before using this capability in a production setting. This system does not capture questions or responses, and at a minimum the solution should keep records for verification of incorrect answers or incorrect process delivered to an individual student. 

Note that there are several potential security concerns with LangChain and the ability for agents to enable unintended consequences. Usage of this feature should be carefully evaluated.

### Tabular Data Assistant

This capability leverages the LangChain technology to enable LLMs to assist with tabular data processing questions. This is an experimental feature which may provide incorrect answers, or partial answers if data is not available at the time of calculation. This feature is not a replacement for dedicated tabular data processing tools.

Note that there are several potential security concerns with LangChain and the ability for agents to enable unintended consequences. Usage of this feature should be carefully evaluated.

# Intended uses

This system is intended for the purpose of exploring LLM capabilities across several data sources (internal and exteral) and engagement methods. Engagement methods range from heavily controlled to completely uncontrolled, sometimes leveraging prompt engineering to limit the creativity of the model(s) and citations to help the end user determine when answers are factual, while other times being minimally controlling (ungrounded responses). As such, much care has been taken to build the system with best practices in mind as a means to help the end user understand what it happening when they see responses from the system. 

As features in this accelerator may be turned on/off at deployment time, it allows customizability for the design of the system which will be presented to the end user (the solution). Additionally this accelerator leverages many core product features such as Bing Web Search API for LLMs and Content Safety (filtering) to allow varying levels of control in the system which can not be accounted for in this Transparency Note. It is imperative to consider your specific use case when combining features, along with the resources available in the [Responsible AI guideance](#learn-more-about-responsible-ai) as you prepare your individual solution. 

## Considerations when choosing a use case

### Identity Applications
**Avoid using IA Accelerator for identification or verification of identities or processing of biometric information.** Any use cases that seek to incorporate end consumer or citizen data should be carefully evaluated per Microsoft’s Responsible AI guidelines.

### Age Appropriateness/Exposure to Minors

This accelerator contains features which have been requested by our Education industry leaders and customers. Microsoft is aware that **there are significant potential harms when exposing minors to Generative AI and Internet content** (as may be provided via Bing Web Search API for LLMs). Microsoft is also aware that there are regional legal limitations which may govern the application of these technologies, especially when delivered to minors. The technology **systems available at the time of this writing are unable to mitigate all potential harms and meet all legal limitations. This accelerator does not address these concerns.**

**At this time, these capabilities SHOULD NOT be targeted to minors.** The capabilities in this accelerator should only be targeted to adult users.

Current known limitations with respect to minors:
* Bing Safe Search is limited to filtering Adult Content in text and image form
* Content Safety features may be enabled but are not comprehensive enough to limit all potential harms related to self harm, hate speech, racism, terrorism and violence
* Content Safety does not support some regional legal requirements including ability to limit religious content and content related to sexual oreintation 
* Age-adaptive prompting is not implemented in this accelerator
* This accelerator does not have age awareness
* This accelerator does not utilize, collect or store guardian consent
* This accelerator does not store user interaction history in any form including user identifiers, queries or responses
* This accelerator may not have adequate features to prevent "jailbraking" of the system to bypass harm mitigation's

# Limitations of IA Accelerator

In this section we describe several known limitations of the IA Accelerator system.

## Qualitative limitations, human oversight requirements

### Confidence Scoring

This system does not provide a confidence score for results returned. It is required that the end user evaluate the response quality to ensure that it is relevant to the asked question.

### Accuracy

This system provides citations for all grounded answers given. All answers, grounded or ungrounded should be validated by a human either by reviewing the citations or via external verification with additional sources. If no citations are given, the answer **MUST NOT** be assumed accurate.

## Technical limitations, operational factors and ranges

### Non-Production Status

This software is an accelerator codebase that is not configured for production use. Effort MUST BE taken to ensure that appropriate data security practices are followed to be compliant with local regulations in alignment with the classification of data intended to be used with this system.

**Microsoft does not provide technical support for this codebase in a production setting.**

### Non-Real Time Usage

This software is not intended for real-time data processing. This is a batch-processing system, intended for offline data analysis.  

### Request Throttling

The Azure OpenAI API and other systems may be subject to throttling. As such this accelerator may have performance limitations and should not be placed into a mission-critical operation without confirmed provisioned throughput (PTU) or appropriate service agreements in place.

# System performance

## Grounded experiences

The central part of IA Accelerator (the system) is to produce answers to questions with the data provided, either by the end user or web results (grounded). This relies on several conditions for accuracy in the response to any given question. At a minimum accurate responses rely on:

- documents with the answers available to the system
- submitted documents having been successfully processed
- input questions with sufficient detail to identify the best source documents available

The system outcomes are evaluated as follows:
Outcomes | Examples
---|---
True Positive | The user asks a question and the most relevant documents are found and returned for the system to summarize and cite. The documents answer the question asked.<br/><br/>Example: A question is asked "Tell me about fresh water supply in Georgia". A document that discusses fresh water availability in Georgia exists, is found, is summarized and cited. 
False Positive | The user asks a question and the most relevant documents are found and returned for the system to summarize and cite. The documents do not answer the question asked.<br/><br/>Example: A question is asked "Tell me about fresh water supply in Tennessee". A document that discusses fresh water availability in Georgia exists, is found, is summarized and cited. 
False Negative | The user asks a question and the system does not find any document available to answer yet the document was available to the system.<br/><br/>Example: A question is asked "Tell me about fresh water supply in Georgia". A document that discusses fresh water availability in Georgia was uploaded, but failed processing. It is not found, summarized or cited.
True Negative | The user asks a question and the system does not find any document available to answer and there was no document available to the system.<br/><br/>Example: A question is asked "Tell me about fresh water supply in Georgia". A document that discusses fresh water availability in Georgia was never uploaded. It is not found, summarized or cited. The system responds that it is unable to answer the question.

All documents submitted to the system should be confirmed to have successfully processed to help eliminate False Negative outcomes. False Positive and True Negative outcomes may be reduced by ensuring that relevant documents are submitted and successfully processed by the system. False Positive outcomes may be mitigated by human review of citations.

During web-grounded interactions, human oversight is required to verify the validity of the source data; web content should not be innately trusted. 

**NOTE:** Due to generative AI's capability to fabricate, end users should always leverage citations to verify results.

## Ungrounded experiences

There have been no performance criteria established for the ungrounded experiences presented in this accelerator. Performance criteria SHOULD BE established for your intended use case.

# Evaluation of IA Accelerator

At the time of this writing, this accelerator is in a **Released state with Preview features**. Microsoft has evaluated this codebase to be fit for purpose to a degree where we are comfortable to start engaging 3rd Party organizations and users to help with the evaluation of the system to determine if it is fit for their purposes. There are several backlog features targeted for future sprints which should help address confidence scoring and improve relevance of answers. As these and additional features are developed they, and the system, will continue to be evaluated.

## Evaluating and Integrating IA Accelerator for your use

This section outlines best practices for using IA Accelerator responsibly to achieve best performance from the system.

### Human-in-the-loop

Always include a human-in-the-loop to evaluate the results against your data. See Limitations section above.

### Data Quality Evaluation

There are **minimal** administrative tools which will give insight to the quality of data available to the system. There are **minimal** tools available to the end user which will give insight the quality of the data available to the system. Leverage the administrative interface before use to verify that submitted documents have been successfully processed.

### Evaluation of system performance

The system outcomes need to be evaluated by the user to determine the accuracy of the system’s answers provided as compared to the data available to the system. **Do not assume that the system is performing well with your data.** Use the information about system performance listed above to understand the outcomes, both True and False. As this system does not record inputs or outputs, it does not support post-action validation.

### Use technical documentation

The technical documentation provided with this system should be used to achieve the best outcomes. Care should be used when tuning, especially in the form of prompt engineering. Trade-offs between accuracy versus creativity should be understood when choices are made.

You can find the technical documentation in our [Using IA Accelerator for the first time](../README.md#using-IA-for-the-first-time) section.

# Technical limitations, operational factors and ranges

**This system has not been evaluated for its intended purpose against your data!**

This system makes no claim for precision or accuracy. The behavior and performance of IA Accelerator depends on the type, volume and quality of data ingested to it. This data will differ across end users, and therefore it is not possible to make a generic evaluation of IA Accelerator for your purposes.

# Learn more about responsible AI


[Microsoft AI principles](https://www.microsoft.com/en-us/ai/responsible-ai)

[Microsoft responsible AI resources](https://www.microsoft.com/en-us/ai/responsible-ai-resources)

[Microsoft Azure Learning courses on responsible AI](https://docs.microsoft.com/en-us/learn/paths/responsible-ai-business-principles/)

# Learn more about the IA Accelerator


[Information Assistant Accelerator](https://github.com/microsoft/PubSec-Info-Assistant)


# Contact us

Give us feedback on this document in our [Q&A Discussions](https://github.com/microsoft/PubSec-Info-Assistant/discussions/categories/q-a) on GitHub.

## About this document

© 2024 Microsoft Corporation. All rights reserved. This document is provided "as-is" and for informational purposes only. Information and views expressed in this document, including URL and other Internet Web site references, may change without notice. You bear the risk of using it. Some examples are for illustration only and are fictitious. No real association is intended or inferred.