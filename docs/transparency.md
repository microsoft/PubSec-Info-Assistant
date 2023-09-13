# Transparency Note: Information Assistant (IA)

Updated 24 Aug 2023

## Table of Contents

- [What is a Transparency Note?](#what-is-a-transparency-note)
- [The basics of IA Accelerator](#the-basics-of-ia-accelerator)
  - [Introduction](#introduction)
  - [Key Terms](#key-terms)
- [Capabilities](#capabilities)
  - [System behavior](#system-behavior)
    - [Data Preparation](#data-preparation)
    - [Prompt Engineering](#prompt-engineering)
  - [Use Cases](#use-cases)
    - [Intended uses](#intended-uses)
    - [Considerations when choosing a use case](#considerations-when-choosing-a-use-case)
- [Limitations of IA Accelerator](#limitations-of-ia-accelerator)
  - [Qualitative limitations, human oversight requirements](#qualitative-limitations-human-oversight-requirements)
    - [Confidence scoring](#confidence-scoring)
    - [Accuracy](#accuracy)
  - [Technical limitations, operational factors and ranges](#technical-limitations-operational-factors-and-ranges)
    - [Non-Production Status](#non-production-status)
    - [Non-Real Time Usage](#non-real-time-usage)
    - [Request Throttling](#request-throttling)
- [System Performance](#system-performance)
- [Evaluation of IA Accelerator](#evaluation-of-ia-accelerator)
  - [Evaluating and Integrating IA Accelerator for your use](#evaluating-and-integrating-ia-accelerator-for-your-use)
    - [Human-in-the-loop](#human-in-the-loop)
    - [Data Quality Evaluation](#data-quality-evaluation)
    - [Evaluation of system performance](#evaluation-of-system-performance)
    - [Use technical documentation](#use-technical-documentation)
  - [Technical limitations, operational factors and ranges](#technical-limitations-operational-factors-and-ranges-1)
- [Learn more about responsible AI](#learn-more-about-responsible-ai)
- [Learn more about the IA Accelerator](#learn-more-about-the-ia-accelerator)
- [Contact Us](#contact-us)

# What is a Transparency Note?

An AI system includes not only the technology, but also the people who will use it, the people who will be affected by it, and the environment in which it is deployed. Creating a system that is fit for its intended purpose requires an understanding of how the technology works, what its capabilities and limitations are, and how to achieve the best performance. Microsoft’s Transparency Notes are intended to help you understand how our AI technology works, the choices system owners can make that influence system performance and behavior, and the importance of thinking about the whole system, including the technology, the people, and the environment. You can use Transparency Notes when developing or deploying your own system, or share them with the people who will use or be affected by your system.

Microsoft’s Transparency Notes are part of a broader effort at Microsoft to put our AI Principles into practice. To find out more, see the [Microsoft AI principles](https://www.microsoft.com/ai/responsible-ai).

# The basics of IA Accelerator

## Introduction

The IA Accelerator is a system built on top of Azure OpenAI service, Cognitive Search and other Azure services, intended to create a system that allows the end user to ‘have an accurate conversation’ with their data. By uploading supported document types the system makes the data available to the Azure OpenAI service to support a conversational engagement with the data. The system aims to allow the end user to have some controls over how Azure OpenAI service responds, understand how the response was generated (transparency), and verify the response with citations to the specific data the accelerator is referencing.

The system aims to provide the functionality mentioned above while also focusing on the following key areas:

- Accuracy
  - Focusing on the science and technologies required to provide the “right” answer to the prompt
- Context
  - Provide the ability to understand the “chunks” of data within the context of a larger document (Title, section, page, date etc.)
- Confidence
  - Provide the response with a level of confidence
- Control
  - Length of response
  - Data Sources, Date Range, Author etc that are used for the response
  - Role Based Access
- Format
  - Tabular/structured data
- Personalization
  - Tailoring the response with a specific persona in mind (Speaker and Receiver)

**NOTE:** Though we are focusing on the key areas above, **human oversight to confirm accuracy is critical. All responses from the system must be verified with the citations provided**. The responses are only as accurate as the data provided.

## Key Terms

Terminology | Definition
---|---
[Azure OpenAI](https://azure.microsoft.com/en-us/products/cognitive-services/openai-service/#overview) | Collection of large-scale generative AI models available as a service via Azure. 
[ChatGPT](https://en.wikipedia.org/wiki/ChatGPT) | "ChatGPT is an artificial intelligence chatbot developed by OpenAI based on the company's Generative Pre-trained Transformer (GPT) series of large language models (LLMs)."
[Chunking](https://learn.microsoft.com/en-us/samples/azure-samples/azure-search-power-skills/azure-open-ai-embeddings-generator/) | Chunking is a strategy of breaking down large documents into smaller pieces which satisfy the token limits of OpenAI models. 
[Generative AI](https://en.wikipedia.org/wiki/Generative_artificial_intelligence) | "A type of artificial intelligence (AI) system capable of generating text, images, or other media in response to prompts."
[Fabrications (aka Hallucinations)](https://en.wikipedia.org/wiki/Hallucination_(artificial_intelligence)) | "A hallucination or artificial hallucination (also occasionally called confabulation or delusion) is a confident response by an AI that does not seem to be justified by its training data". The term "Fabrication" is prefered as the term "hallucination" may be offensive to people with certain disabilities. 
[Prompt engineering](https://en.wikipedia.org/wiki/Prompt_engineering) | "A concept in artificial intelligence, particularly natural language processing. In prompt engineering, the description of the task that the AI is supposed to accomplish is embedded in the input, e.g. as a question, instead of it being explicitly given. Prompt engineering typically works by converting one or more tasks to a prompt-based dataset and training a language model with what has been called "prompt-based learning" or just "prompt learning"."
[Semantic Search](https://learn.microsoft.com/en-us/azure/search/semantic-search-overview) | "A collection of query-related capabilities that bring semantic relevance and language understanding to textual search results."
[Token](https://help.openai.com/en/articles/4936856-what-are-tokens-and-how-to-count-them) | Input into an OpenAI model is broken down in to tokens. The model has a limit on the number of tokens it can accept. Tokenization is language-dependant. 

# Capabilities
**NOTE:** This project is developed with an agile methodology. As such, features and capabilities are subject to change, and may change faster than the documentation. Those deploying this project should review approved pull requests to understand changes which have been committed since the update of the documentation.
## System behavior

This system is implemented primarily on top of Azure OpenAI service and Azure Cognitive Search service. The system allows the end user to upload documents in specific formats. These documents are processed and made searchable via natural language by leveraging Semantic Search and ChatGPT. This allows end users to "have a conversation" with their data. The system cites the documents from which it generates answers, allowing the end user to verify the results for accuracy.

By design this system should not provide answers that are not available in the data available to it. **The relevance of the answers to the questions asked will depend directly on the data which has been uploaded and successfully processed by the system.** 

### Data Preparation

The system receives and process files from the end user. Data is chunked with strategies to ensure that the data can be used by Azure OpenAI service while maintaining logical relevance based on the input data element (for example, being aware of page breaks in PDF documents to keep related content together). All historically-processed data is available to the end user.

### Prompt Engineering

This system is primarily tuned for accuracy of response based on the data provided to the system. As such, much work goes into prompt engineering to prevent fabrications. The prompt engineering is visible to the end user when looking at the "Thought process" tab (directly from icon, or via Citation view).

**NOTE:** Fabrications may not always be preventable via prompt engineering. End users must always validate results with citations provided. 

## Use cases

### Intended uses

This system is intended for the purpose of enabling ChatGPT capabilities with data provided by the end user. This system leverages prompt engineering to limit the creativity of the OpenAI model(s) and citations to help the end user determine when answers are factual. This system uses private search and is not intended as a replacement for a comprehensive internet-based search engine such as OpenAI-enabled Bing search; this system will not provide up-to-date search results from the Internet. 

### Considerations when choosing a use case

**Avoid using IA Accelerator for identification or verification of identities or processing of biometric information.** Any use cases that seek to incorporate end consumer or citizen data should be carefully evaluated per Microsoft’s Responsible AI guidelines.

# Limitations of IA Accelerator

In this section we describe several known limitations of the IA Accelerator system.

## Qualitative limitations, human oversight requirements

### Confidence Scoring

This system does not provide a confidence score for results returned. It is required that the end user evaluate the response quality to ensure that it is relevant to the asked question.

### Accuracy 

This system provides citations for all answers given. At the time of this writing, this is an early release and the system at times may not give citations. All answers should be validated by a human reviewing the citations. If no citations are given, the answer must not be assumed accurate. 

## Technical limitations, operational factors and ranges

### Non-Production Status

This software is an accelerator codebase that is not configured for production use. Effort must be taken to ensure that appropriate data security practices are followed to be compliant with local regulations in alignment with the classification of data intended to be used with this system.

**Microsoft does not provide technical support for this codebase in a production setting.** 

### Non-Real Time Usage

This software is not intended for real-time data usage. This is a batch-processing system, intended for offline data analysis.  

### Request Throttling

The Azure OpenAI API may be subject to throttling. As such this accelerator may have performance limitations and should not be placed into a mission-critical operation at the time of this writing. 

# System performance

The central part of IA Accelerator (the system) is to produce answers to questions with the data provided by the end user. This relies on the several conditions for accuracy in the response to any given question. At a minimum accurate responses rely on:
- documents with the answers available to the system
- submitted documents having been successfully processed
- input questions with sufficient detail to identify the best source documents available

The system outcomes are evaluated as follows:
Outcomes | Examples
---|---
True Positive | The user asks a question and the most relevant documents are found and returned for the system to summarize and cite. The documents answer the question asked.<br/><br/>Example: A question is asked "Tell me about fresh water supply in Georgia". A document that discusses fresh water availability in Georgia exists, is found, is summarized and cited. 
False Positive | The user asks a question and the most relevant documents are found and returned for the system to summarize and cite. The documents do not answer the question asked.<br/><br/>Example: A question is asked "Tell me about fresh water supply in Tennessee". A document that discusses fresh water availability in Georgia exists, is found, is summarized and cited. 
False Negative | The user asks a question and the system does not find any document available to answer yet the document was available to the system.<br/><br/>Example: A question is asked "Tell me about fresh water supply in Georgia". A document that discusses fresh water availability in Georgia was uploaded, but failed processing. It is not found, summarized or cited.
True Negative | The user asks a question and the system does not find any document available to answer and there was no document available to the system.<br/><br/>Example: A question is asked "Tell me about fresh water supply in Georgia". A document that discusses fresh water availability in Georgia was never uploaded. It is not found, summarized or cited.

All documents submitted to the system should be confirmed to have successfully processed to help eliminate False Negative outcomes. False Positive and True Negative outcomes may be reduced by ensuring that relevant documents are submitted and successfully processed by the system. False Positive outcomes may be mitigated by human review of citations.

**NOTE:** Due to generative AI's capability to fabricate, end users should always leverage citations to verify results.

# Evaluation of IA Accelerator

At the time of this writing, this accelerator is in a **Pre-Release** state. Microsoft has evaluated this codebase to be fit for purpose to a degree where we are comfortable to start engaging 3rd Party organizations and users to help with the evaluation of the system to determine if it is fit for their purposes. There are several backlog features targeted for future sprints which should help address confidence scoring and improve relevance of answers. As these and additional features are developed they, and the system, will continue to be evaluated. 

## Evaluating and Integrating IA Accelerator for your use

This section outlines best practices for using IA Accelerator responsibly to achieve best performance from the system.

### Human-in-the-loop

Always include a human-in-the-loop to evaluate the results against your data. See Limitations section above.

### Data Quality Evaluation

There are **minimal** administrative tools at this early stage which will give insight to the quality of data available to the system. There are **minimal** tools available to the end user at this time which will give insight the quality of the data available to the system. Leverage the administrative interface before use to verify that submitted documents have been successfully processed. 

### Evaluation of system performance

The system outcomes need to be evaluated by the user to determine the accuracy of the system’s answers provided with the data available to the system. Do not assume that the system is performing well with your data. Use the information about system performance listed above to understand the outcomes, both True and False.

### Use technical documentation

The technical documentation provided with this system should be used to achieve the best outcomes. Care should be used when tuning, especially in the form of prompt engineering. Trade-offs between accuracy versus creativity should be understood when choices are made.

You can find the technical documentation in our [Using IA Accelerator for the first time](../README.md#using-IA-for-the-first-time) section.

# Technical limitations, operational factors and ranges

**This system has not been evaluated for its intended purpose against your data!**

This system makes no claim for precision or accuracy. The behaviour and performance of IA Accelerator depends on the type, volume and quality of data ingested to it. This data will differ across end users, and therefore it is not possible to make a generic evaluation of IA Accelerator for your purposes.

# Learn more about responsible AI


[Microsoft AI principles](https://www.microsoft.com/en-us/ai/responsible-ai)

[Microsoft responsible AI resources](https://www.microsoft.com/en-us/ai/responsible-ai-resources)

[Microsoft Azure Learning courses on responsible AI](https://docs.microsoft.com/en-us/learn/paths/responsible-ai-business-principles/)

# Learn more about the IA Accelerator


[Information Assistant Accelerator](https://github.com/microsoft/PubSec-Info-Assistant)


# Contact us

Give us feedback on this document in our [Q&A Discussions](https://github.com/microsoft/PubSec-Info-Assistant/discussions/categories/q-a) on GitHub.

## About this document

© 2023 Microsoft Corporation. All rights reserved. This document is provided "as-is" and for informational purposes only. Information and views expressed in this document, including URL and other Internet Web site references, may change without notice. You bear the risk of using it. Some examples are for illustration only and are fictitious. No real association is intended or inferred.