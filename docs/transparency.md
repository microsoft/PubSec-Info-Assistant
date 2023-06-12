# Transparency Note: Electronic-Invoicing Anomaly Detector (IA)

Updated 14 Jun 2023

## Table of Contents

- [What is a Transparency Note?](#what-is-a-transparency-note)
- [The basics of IA Accelerator](#the-basics-of-ia-accelerator)
  - [Introduction](#introduction)
  - [Key Terms](#key-terms)
- [Capabilities](#capabilities)
  - [System behavior](#system-behavior)
    - [Data Preparation](#data-preparation)
    - [Anomaly Detection](#anomaly-detection)
  - [Use Cases](#use-cases)
    - [Intended uses](#intended-uses)
    - [Considerations when choosing a use case](#considerations-when-choosing-a-use-case)
- [Limitations of IA](#limitations-of-ia)
  - [Technical limitations, operational factors and ranges](#technical-limitations-operational-factors-and-ranges)
    - [Non-Production Status](#non-production-status)
    - [Non-Real Time Usage](#non-real-time-usage)
    - [Anomalous transactions](#anomalous-transactions)
    - [Feature extraction](#feature-extraction)
- [System Performance](#system-performance)
- [Evaluation of e-AID](#evaluation-of-ia)
  - [Evaluating and Integrating IA for your use](#evaluating-and-integrating-ia-for-your-use)
    - [Human-in-the-loop](#human-in-the-loop)
    - [Data Quality Evaluation](#data-quality-evaluation)
    - [Model Training](#model-training)
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

The IA Accelerator is a system built on top of Azure OpenAI service, Cognitive Search and other Azure services, intended to create a system that allows the end user to ‘have an accurate conversation’ with your data. By uploading supported document types the system makes the data available to the Azure OpenAI service to support a conversational engagement with the data. The system aims to allow the end user to have some controls over how Azure OpenAI service responds, understand how the response was generated (transparency), and verify the response with citations to the specific data the accelerator is referencing.

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
[Hallucinations](https://en.wikipedia.org/wiki/Hallucination_(artificial_intelligence)) | "A hallucination or artificial hallucination (also occasionally called confabulation or delusion) is a confident response by an AI that does not seem to be justified by its training data."
[Prompt engineering](https://en.wikipedia.org/wiki/Prompt_engineering) | "A concept in artificial intelligence, particularly natural language processing. In prompt engineering, the description of the task that the AI is supposed to accomplish is embedded in the input, e.g. as a question, instead of it being explicitly given. Prompt engineering typically works by converting one or more tasks to a prompt-based dataset and training a language model with what has been called "prompt-based learning" or just "prompt learning"."
[Semantic Search](https://learn.microsoft.com/en-us/azure/search/semantic-search-overview) | "A collection of query-related capabilities that bring semantic relevance and language understanding to textual search results."
[Token](https://help.openai.com/en/articles/4936856-what-are-tokens-and-how-to-count-them) | Input into an OpenAI model is broken down in to tokens. The model has a limit on the number of tokens it can accept. Tokenization is language-dependant. 

# Capabilities

## System behavior

This system is implemented primarily on top of Azure OpenAI service and Azure Cognitive Search service. The system allows the end user to upload documents in specific formats. These documents are processed and made searchable via natural language by leveraging Semantic Search and ChatGPT. This allows end users to "have a conversation" with their data. The system cites the documents from which it generates answers, allowing the end user to verify the results for accuracy.

#### Data Preparation

The system receives and process files from the end user. Data is chunked with strategies to ensure that the data can be used by Azure OpenAI service while maintaining logical relevance based on the input data element (for example, being aware of page breaks in PDF documents to keep related content together). All historically-processed data is available to the end user.

### Prompt Engineering

This system is primarily tuned for accuracy of response based on the data provided to the system. As such, much work goes into prompt engineering to ensure prevent hallucinations. The prompt engineering is visible to the end user when looking at the provided citations and choosing the "Thought process" tab. 

## Use cases

### Intended uses

This system is intended for the purpose of enabling ChatGPT capabilities with data provided by the end user. This system leverages prompt engineering to limit the creativity of the OpenAI model(s) and citations to help the end user determine when answers are factual. This system uses private search and is not intended as a replacement for a comprehensive internet-based search engine such as OpenAI-enabled Bing search; this system will not provide up-to-date search results from the Internet. 

### Considerations when choosing a use case

**Avoid using IA for identification or verification of identities or processing of biometric information.** Any use cases that seek to incorporate end consumer or citizen data should be carefully evaluated per Microsoft’s Responsible AI guidelines.

# Limitations of IA

In this section we describe several known limitations of the IA system.

## Technical limitations, operational factors and ranges

### Non-Production Status

This software is an accelerator codebase that is not configured for production use. Effort must be taken to ensure that appropriate data security practices are followed to be compliant with local regulations in alignment with the classification of data intended to be used with this system.

**Microsoft does not provide technical support for this codebase in a production setting.** 

### Non-Real Time Usage

This software is not intended for real-time data usage. This is a batch-processing system, intended for offline data analysis.  

### Anomalous transactions

This system was not designed to detect anomalous business-to-business transactions, rather it identifies anomalous businesses based on the transaction data and the feature set that is extracted from the data input to the system.

### Feature extraction

A core component to detecting anomalies are the features which are extracted from the data. These features are used as inputs to the anomaly detection. To improve anomaly detection, users of the system should understand their local economic drivers and policies and understand if additional features are desired to be considered for anomaly detection. These economic drivers and policies often include incentives, export or import policies, and other activities related directly to taxation. We advise careful consideration of the features with respect to your local policies and activities.

**This system has not been evaluated for its intended purpose against your data!** This system makes no claim for precision or accuracy. The behavior and performance of IA depends on the type, volume and quality of electronic invoicing data ingested to it. This data will differ across countries, and therefore it is not possible to make a generic evaluation of IA for your purposes.

# System performance

The central part of IA (the system) is to produce anomaly detection capabilities at the company (business) level. The two primary outputs for anomaly detection are (a) the score of those results marked as an anomaly and (b) the list of features with their weights that influenced the score.

The system detects an anomaly at the company level for a summarized time period. Individual electronic invoicing transactions are not flagged as an anomaly.

The better the tax user establishes data segmentation criteria to filter out what they already knows to be irregular, the better the system will detect unknown irregular transactions in the invoicing data.

The system outcomes are evaluated as follows:
Outcomes | Examples
---|---
True positive | - The company issues irregular e-Invoicing transactions in a period. <br>- The system detects irregular invoicing transactions. <br>- The outcome is an anomaly score detected.
False positive | - The company does not issue irregular e-Invoicing transactions in a period.<br>- The system detects irregular invoicing transactions. <br>- The outcome is an incorrect anomaly detected.
False Negative | - The company issues irregular e-Invoicing transactions in a period. <br>- The system does not detect irregular invoicing transactions. <br>- The outcome is an anomaly score that is not detected.
True Negative | - The company does not issue irregular e-Invoicing transactions in a period. <br>- The system does not detect irregular invoicing transactions. <br>- The outcome is an anomaly that is not detected.

Data with known anomalies should be used to evaluate the performance of the system. The synthetic data provided with the system may be used for this purpose. With real data it is suggested that humans verify outputs from the system to determine if they fit within one of the categories listed above.

# Evaluation of IA

Microsoft and CIAT ([Inter-American Center of Tax Administrations](https://www.ciat.org/)) team members worked with the Government of Costa Rica to evaluate initial system output compared to known anomalies in a shared dataset from the year 2021 as well as anomalies in the sample datasets provided with this project.

Initial results from evaluation with the Government of Costa Rica have demonstrated the system’s effectiveness at detecting anomalous events. Future efforts will be conducted with CIAT member(s) to continue evaluation of this system via investigation of real customer data. This document will be updated over time as future evaluations are performed.

## Evaluating and Integrating IA for your use

This section outlines best practices for using IA responsibly to achieve best performance from the system.

### Human-in-the-loop

Always include a human-in-the-loop to evaluate the results against your data. See Limitations section above.

### Data Quality Evaluation

The supplied reports should be used to understand the quality of the input data. If the reports show that there are significant amounts of data cleanliness issues, the data should be investigated before attempting to investigate anomalies; low quality datasets should not be applied to a machine learning system.

### Model Training

Once cleaned and valid data is confirmed, the iJungle toolkit is used to train models on a sample of the data. It is critical to train models on the supplied data as anomalies in economies may differ between countries and across timespans (especially when economic policies change). The models must be tuned for the specific data provided, and documentation provided on tuning this system should be reviewed before operating. It is also suggested that you review the documentation of iJungle (linked above).

### Evaluation of system performance

The system outcomes need to be evaluated by the user to determine the accuracy of the system’s anomaly detection against the user’s data. Do not assume that the system is performing well with your data. Use the information about system performance listed above to understand the outcomes, both True and False.

### Use technical documentation

The technical documentation provided with this system and the iJungle toolkit should be used when tuning the system to the best outcomes. Care should be used when tuning. Trade-offs between accuracy versus computational performance should be understood and stated explicitly when choices are made.

You can find the technical documentation on preparing your data and tuning the accelerator in our [Using IA for the first time](../README.md#using-IA-for-the-first-time) section.

# Technical limitations, operational factors and ranges

**This system has not been evaluated for its intended purpose against your data!**

This system makes no claim for precision or accuracy. The behaviour and performance of IA depends on the type, volume and quality of electronic invoicing data ingested to it. This data will differ across countries, and therefore it is not possible to make a generic evaluation of IA for your purposes.

# Learn more about responsible AI

---

[Microsoft AI principles](https://www.microsoft.com/en-us/ai/responsible-ai)

[Microsoft responsible AI resources](https://www.microsoft.com/en-us/ai/responsible-ai-resources)

[Microsoft Azure Learning courses on responsible AI](https://docs.microsoft.com/en-us/learn/paths/responsible-ai-business-principles/)

# Learn more about the IA Accelerator

---

[e-EIAD Accelerator](https://github.com/microsoft/eIAD)

[iJungle](https://github.com/microsoft/dstoolkit-anomaly-detection-ijungle)

# Contact us

Give us feedback on this document in our [Q&A Discussions](https://github.com/microsoft/eIAD/discussions/categories/q-a) on GitHub.

## About this document

© 2023 Microsoft Corporation. All rights reserved. This document is provided "as-is" and for informational purposes only. Information and views expressed in this document, including URL and other Internet Web site references, may change without notice. You bear the risk of using it. Some examples are for illustration only and are fictitious. No real association is intended or inferred.

Published: 14 Jun 2023
