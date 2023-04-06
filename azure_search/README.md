# Azure Cognitive Search - Semantic Search

## Introduction

[Semantic Search](https://docs.microsoft.com/en-us/azure/search/semantic-search-overview) is currently a public preview feature within Azure Cognitive Search.  Semantic search is a collection of query-related capabilities that bring semantic relevance and language understanding to search results.

[Semantic Search](https://docs.microsoft.com/en-us/azure/search/semantic-search-overview) is a premium feature and is a collection of features that improve the quality of search results. When enabled on your search service, it extends the query execution pipeline in two ways. First, it adds secondary ranking over an initial result set, promoting the most semantically relevant results to the top of the list. Second, it extracts and returns captions and answers in the response, which you can render on a search page to improve the user's search experience.

As this is a preview feature, you'll need to sign up for the preview program [here](https://forms.office.com/pages/responsepage.aspx?id=v4j5cvGGr0GRqy180BHbRyhHvXnF8jlIrXhuXLZqYeJUNTNUMEQ2V0NLOU5JVEVBTEU5NkZNUlA3RS4u) which can take 2 days to process.

## Semantic Search Resources

- [Conceptual documentation](https://docs.microsoft.com/en-us/azure/search/semantic-search-overview) and [video](https://www.youtube.com/watch?v=yOf0WfVd_V0&t=2s) explaining the capability.
- Create a [semantic request](https://docs.microsoft.com/en-us/azure/search/semantic-how-to-query-request)
- Create a semantic request to return [answers](https://docs.microsoft.com/en-us/azure/search/semantic-answers) 
- Add spell check to your query requests.
- The following Beta SDKs supporting Semantic Search are available:
- [.NET](https://www.nuget.org/packages/Azure.Search.Documents/11.3.0-beta.2)
- [Java](https://search.maven.org/artifact/com.azure/azure-search-documents/11.4.0-beta.2/jar)
- [Python](https://pypi.org/project/azure-search-documents/11.2.0b3/)

## Semantic Search within DET

DET uses Azure Cognitive Search and can leverage the Semantic Search capability via the following, once Azure Cognitive Search Semantic preview has been enabled on your search instance:

- Files to index are uploaded to the landing `raw\semantic-search` blob container and folder
- An ADF Pipeline will then copy the files into the `published\semantic-search` blob container and folder
- Azure Cognitive Search will monitor the data source (`published\semantic-search`) automatically running the indexers and updating the index
- Your search instance API can then service semantic queries
  
### Supporting automation

The below files automate the provisioning of the necessary components within Cognitive Search.  You do not need to call them individually, as they are orchestrated by the deployment script: [.\scripts\deploy-search-indexes.sh](.\scripts\deploy-search-indexes.sh) which is invoked during the deployment pipeline.

- [./create_all_indexer.json](create_all_indexer.json) - an indexer that indexes over all files
- [./create_html_indexer.json](create_html_indexer.json) - an indexer that indexes only html files
- [./create_skillset.json](create_skillset.json) - defines what cogntive skills to run over each document
- [./create_html_index.json](create_html_index.json) - the name of the index over html documents
- [./create_all_index.json](create_all_index.json) - the name of the index over all documents

The indexers can take a while to complete depending on the size of the data source.  But you can monitor the progress of these within the portal:

![Indexer progress](../docs/images/azure_search_indexer.png)

## Testing Semantic Search in the Azure Portal

Once the indexes are ready, you can test them directly in the [Azure Portal](https://portal.azure.com)

During Semantic Search preview - you'll need to add the following querystring: `?feature.semanticSearch=true` in order to enable the Semantic query options within the Search explorer: [https://portal.azure.com?feature.semanticSearch=true](https://portal.azure.com?feature.semanticSearch=true)

Navigate to your Azure Search instance and select Search Explorer.  From here you can issue a Semantic Search query against your search instance api endpoint eg:

![Azure Search Explorer](../docs/images/azure_search_explorer.png)

## Testing Semantic Search from the devcontainer

You can also create a *.http file and send the HTTP request directly to your search instance endpoint using the REST Client extension for VS Code (already configured in this devcontainer).

A sample request is shown below:

```
POST https://{YOUR-SEARCH-ENDPOINT}/indexes/all-files-index/docs/search?api-version=2020-06-30-Preview
Content-Type: application/json
api-key: {YOUR-SEARCH-API-KEY}

{
    "search": "how many protesters were there in Monrovia?",
    "queryType": "semantic",
    "queryLanguage": "en-us",
    "searchFields": "content",
    "select": "",
    "top": 5,
    "count": true
}
```
