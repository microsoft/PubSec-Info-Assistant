# Enhancing IA: Architectural Decisions

We've looked into various technical areas to make informed architectural decisions. We've investigated the merits of different approaches across our solution, ensuring our architectural decisions are not just informed but fine-tuned for the unique demands of generative AI use cases.

## Document Processing

We looked into Azure cognitive search text splitter skillset but it was not able to extract unstructured data from docs such as tables. Instead, we decided to go with Azure Document Intelligence formally known as Form recognizer and unstructured.io for document processing and document chunking. With powerful OCR capabilities, Document Intelligence extracts text, numbers, dates, and tables making it a robust solution for document processing. With unstructured.io, we extended file type support to total of 20 different file types where data exists in difficult-to-use formats such as HTML, csv, docx etc. Older file types such as doc and ppt won't be supported in this release due to issue of processing them. Unstructured.io is an open source so it gave us customizations, transparency, flexibility benefits that come with open-source software.

## Document Chunking

We conducted a comprehensive experimentation process to refine our chunking strategy. Initially, we explored per-page chunking but found it didn't produce high-quality responses. Recognizing the importance of maintaining content semantics, we shifted to chunking based on logical structures, such as sections. The goal was to preserve the coherence and completeness of content. The less fragmented the chunks, the better, as they serve as cohesive units for retrieving expected answer content. Additional context, including document title, section, and subsection, is incorporated into each chunk.

In terms of chunk size, we varied it from 250 to 1000 tokens, ultimately finding that a chunk size of 750 tokens consistently yielded optimal results. We also experimented with content overlap to address potential context loss between chunks, using "Overlap= one section from the prior chunk + current chunk + one section from the next chunk." However, given our section-based chunking approach, maintaining logical context together rendered overlap unnecessary. Consequently, we allocated the entire 750 tokens to actual chunk content.

To summarize, our chunking strategy involves segmenting content by section, ensuring each chunk is limited to 750 tokens with no overlap. Additionally, each chunk includes the document title, section, and subsection for enhanced context.

## Document Contextual Understanding for Search and Retrieval

In Retrieval Augmented Generation applications, a thorough grasp of context is essential for accurately interpreting data, ensuring precise information retrieval and generation.

Initially, we explored Azure Cognitive Services' built-in skillset for tasks like entity recognition and key phrase extraction. However, due to the additional overhead of utilizing the skillset from Cognitive Search, we opted for custom data processing to extract key phrases and entities such as organizations, locations, and events. This approach enriched the search index by providing additional metadata and context, thereby enhancing retrieval effectiveness. Additionally, we employed embeddings to capture semantic relationships and contextual nuances, improving our understanding of textual data.

To generate embeddings, we empowered users to choose the embedding model that best suits their content and use case, acknowledging that a one-size-fits-all approach is not ideal. Users have the flexibility to opt for the closed-source Azure Open AI embedding or one of the open-source embedding models, including the multilingual embedding model.

## Document Indexing (Vector Store)

We explored various open-source vector store solutions, including Pinecone, Faiss, and Weaviate. However, each presented limitations such as being unmanaged, potential vendor lock-in, specific hosting requirements, a lack of advanced security features, limited support for embedding management, cost inefficiency in terms of cloud resources, and challenges in efficient scaling concerning data volume and types.

After careful consideration, we opted for Azure Cognitive Search for several reasons mentioned earlier, with a significant factor being that while some alternatives offered hybrid search, none provided out-of-the-box hybrid search capabilities with reranking. Cognitive Search addresses this gap by offering level 2 semantic reranking on top of hybrid vector search. Moreover, its seamless integration with other AI services in Azure further solidified our decision.

## Search Techniques (Querying)

We initially conducted experiments using cosine similarity search and Azure Cognitive Keyword Search with semantic search. Relying solely on cosine similarity overlooked considerations such as term frequency and document length normalization, while relying on keywords with semantic search had limitations in capturing nuanced relationships and semantic meaning within the data. Recognizing the shortcomings of these individual approaches, we ultimately decided to use a hybrid search strategy.

Through a process of trial and error, our custom hybrid attempts were refined, leading us to adopt Azure Cognitive Search Hybrid Search. This solution seamlessly integrates the strengths of both keyword and similarity searches, providing a comprehensive and flexible approach. Notably, Azure Cognitive Search allows us to employ different search techniques, such as keyword, vector, hybrid, and hybrid with semantic reranking, all within the same index. This enhances the precision and adaptability of our search functionality.

## Prompt Engineering

For prompt engineering, we considered Lanchain's "Refine" chain, which updates responses iteratively for each document chunk in a loop, making it suitable for tasks with more chunks than can fit in the model's context. However, due to its iterative nature and numerous language model (LLM) calls, it potentially impacts efficiency.Also we saw loss of accuracy/fidelity of content as were getting summaries of summaries. Instead, we opted for the "Stuff" prompt, incorporating all retrieved sources/document chunks in a prompt to generate answers. This choice was driven by the efficiency and simplicity of the "Stuff" approach, aligning better with our requirements, especially for questions involving cross-referencing documents or requiring detailed information from multiple sources.

We also implemented the Chain of Thought prompting, leveraging few-shot learning. This encourages LLMs to break down complex thoughts or responses into intermediate steps by providing instructions and a few examples. This few-shot learning along with Chain Of Thought technique significantly contributed to mitigating fabrication by prompting the LLM to maintain consistency and logical progression in its answers. This approach reduced the likelihood of generating inaccurate and misleading information.
