# Configuring IA to use your own language

Within the IA copilot template you can customize the language settings of the search index, search skillsets, and Azure OpenAI prompts. To do this you must set Azure Developer CLI (azd) parameters for your specific language. This documentation will explain how to set up your azd parameters.

## Identifying your custom language azd parameter values

The next step is to populate the required values of your custom language azd parameters. The required values are:

Parameter | Description
---|---
PROMPT_QUERYTERM_LANGUAGE | The language that Azure OpenAI will be prompted to generate the search terms in. This is used in the natural language prompt so example values would be "English" or "Greek".
SEARCH_INDEX_ANALYZER | The analyzer that the search index will use for all "searchable" fields except "translated_text". Supported analyzers can be found at <https://learn.microsoft.com/azure/search/index-add-language-analyzers#language-analyzer-list>
TARGET_TRANSLATION_LANGUAGE | The language that the cognitive service will use to translate text to if required. Supported languages and associated codes can be found at <https://learn.microsoft.com/azure/ai-services/translator/language-support>

*NOTE: It is important that all parameters have a value. In some cases your language of choice may not be available for one or more options, you must choose a supported value. In our example, for the Greek language, not all values were supported in Greek so we used English where Greek was not supported.*

## Setting your custom language azd parameters

In order to set the parameters for your custom language, run the following commands in your codespace terminal before running `azd up`:

``` shell
  azd env set PROMPT_QUERYTERM_LANGUAGE "English"
  azd env set SEARCH_INDEX_ANALYZER "standard.lucene"
  azd env set TARGET_TRANSLATION_LANGUAGE "en" 
```

*Example for Portuguese (Brazil):*

``` shell
  azd env set PROMPT_QUERYTERM_LANGUAGE "Portuguese"
  azd env set SEARCH_INDEX_ANALYZER "pt-Br.lucene"
  azd env set TARGET_TRANSLATION_LANGUAGE "es"
```

*Example for Greek:*

``` shell
  azd env set PROMPT_QUERYTERM_LANGUAGE "Greek"
  azd env set SEARCH_INDEX_ANALYZER "el.lucene"
  azd env set TARGET_TRANSLATION_LANGUAGE "el"
```
