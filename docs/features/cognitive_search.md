# Azure AI Search Integration

**Vector Hybrid Search**

Vector Hybrid Search combines vector similarity with keyword matching to enhance search accuracy. This approach empowers you to find relevant information efficiently by combining the strengths of both semantic vectors and keywords.

## How It Works

- **Documents to vectors**: Documents are first chunked and then encoded into dense vectors using techniques like word embeddings. You have the flexibility to choose from a variety of embedding models in Information Assistant. They are listed below in a table.

- **Similarity Search**: At search time, the vector representing the query is compared to vectors for documents to find semantically similar results. Keywords are extracted separately from the search query. Keyword matching serves as a signal to boost results containing the query keywords.

- **Scoring**: Documents are scored using RRF (Reciprocal Rank Fusion), which combines the cosine similarity score and a BM25 keyword matching score. Documents with high scores for both vectors and keywords are ranked higher, ensuring the most relevant results.


* **Data Enrichments:** Uses many Out-of-the-box skillsets to extract enrichments from files such as utilizing Optical Character Recognition (OCR) to process images or converting tables within text into searchable text.

* **Multilingual Translation:** Leverages the Text Translation skill to interact with your data in supported native languages*, expanding your application's global reach.

  * See [Configuring your own language ENV file](/docs/features/configuring_language_env_files.md) for supported languages*

- **Conceptual Matching**: This hybrid approach allows you to discover results that are conceptually related to the query, even if they don't contain the exact keywords. Keywords provide an additional relevance check, improving the precision of your search results.

![How Does Vector Search work](/docs/images/VectorSearch.png)

### Use Cases

This approach is well-suited for  search scenarios where the user expresses their intent in natural language, and the documents may not precisely match the query's keywords. It enables you to find relevant information efficiently and accurately.

### Choosing an Embedding Model

In Information Assistant, we empower users to select the embedding model that works best for their content and use case. Different embedding models have various strengths and weaknesses in encoding semantics and capturing meaning from text.

| Model                                    | Dimensions | Accessibility | Strengths                                             | Considerations                                      |
|-----------------------------------------|------------|--------------|------------------------------------------------------|-----------------------------------------------------|
| text-embedding-ada-002 (Azure Open AI)   | 1536       | Closed Source | Effective with rare and uncommon words, higher dimension allows capturing more semantic nuance | Larger model size, slower inference, Throttling, Cost |
| sentence-transformers/all-mpnet-base-v2  | 768        | Open Source   | Captures semantics, benefits from an established pre-trained BERT Model, easy implementation/out of the box usage | Requires more compute resources, less optimized than Ada |
| sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2 | 384 | Open Source | Handles multiple languages | Lower dimensionality misses some semantics |
| BAII/bge-small-en-v1.5                   | 384        | Open Source   | Rated top for Retrieval tasks. Very efficient for scaling with massive document size. Enables fast document embedding. Lower cost. | Lower dimensionality misses some semantics, May suffer from limited linguistic knowledge |

Choose the embedding model that best aligns with your content and use case, considering the strengths, accessibility, and considerations outlined above.
