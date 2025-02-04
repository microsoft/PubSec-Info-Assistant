# AI Safety + Security

Microsoft is committed to ensuring the safety and security of AI technologies. Our solutions are powered by **Azure AI Content Safety**, which includes built-in content safety features to evaluate input prompts and outputs, mitigating harmful content.

## Content Filters

We provide default content filters, and you also have the option to create and customize your own content filter options and blocklists to suit your needs. This flexibility allows you to tailor the content safety measures to your specific requirements.

### Default Configurations

**DefaultV2** content filter configuration will be automatically enabled. For more details on which inbound (inputs to the model) and outbound (responses from the model) settings are enabled, please refer to the [inbound and outbound default configurations](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/default-safety-policies#vision-models-gpt-4o-gpt-4-turbo-dall-e-3-dall-e-2).

### Customized Configurations

All customers have the ability to modify content filters and configure severity thresholds for prompts (inbound) and completions (outbound), enabling you to tailor them to your specific use case requirements. However, only customers who have been approved for modified content filtering can choose to partially or fully turn off content filters. Read more about [configuring content filters](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/content-filters).

You can apply for modified content filters via this form: [Azure OpenAI Limited Access Review: Modified Content Filters](https://ncv.microsoft.com/uEfCgnITdR).

Azure Government customers should apply for modified content filters via this form: [Azure Government – Request Modified Content Filtering for Azure OpenAI Service](https://aka.ms/AOAIGovModifyContentFilter).

#### Inbound filtering: Enhancing Input Safety

Inbound filtering ensures that user inputs meet predefined standards before reaching the AI model. Some common practices include:

- **Custom Rules for Input Validation**: Define organizational rules to block or flag specific content types (e.g. offensive language, personally identifiable information).  
- **Dynamic Input Processing**: Apply preprocessing techniques to sanitize or transform inputs as needed, ensuring sensitive or inappropriate content is removed.  
- **Real-Time Monitoring**: Leverage input validation for length, sentiment, or prohibited keywords to control the quality of data sent to the model.  

#### Outbound filtering: Managing Model Responses

Outbound filtering focuses on maintaining safety and compliance in the AI’s outputs. Configurable options include:

- **Response Moderation**: Use content filters to flag or block outputs that violate safety policies, such as offensive or harmful language.  
- **Custom Post-Processing**: Implement business logic to refine or mask flagged outputs, ensuring they meet your organization’s standards.  
- **User Feedback and Adaptation**: Continuously improve filtering effectiveness by integrating user feedback into refinement processes.  
- **Monitoring and Alerts**: Track flagged outputs to identify trends and address recurring issues, ensuring transparency and accountability.  

Read more about [configurability.](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/content-filter?tabs=warning%2Cuser-prompt%2Cpython-new#configurability)

## Extended security and safety options through Azure OpenAI Content Safety APIs

Azure AI Content Safety APIs offer powerful tools for analyzing and moderating harmful content, enabling customers to enhance the safety of their AI applications.

We encourage you to review these capabilities in detail to evaluate their alignment with specific requirements and assess their potential value for various use cases. 

Particular attention may be given to the following:

- **Prompt Shields**: Detect and mitigate risks associated with user prompt attacks and document attacks.
- **Groundedness Detection**: Identifies whether large language model (LLM) responses are grounded in the source materials provided.
- **Protected Material Text Detection**: Scans AI-generated text for known content, such as song lyrics, articles, recipes, or selected web material.

These features can support efforts to maintain accuracy, compliance, and respect for intellectual property, depending on your needs. Read more on [Azure OpenAI Content Safety APIs](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/overview#product-features)

Note that the AI Content Safety APIs are limited to [specific regions](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/overview#region-availability), and have limited [language support](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/concepts/jailbreak-detection#language-availability). 

## Risks & Safety Features in AI Foundry

Azure AI Foundry introduces advanced Risks & Safety monitoring features, including **Content Detection** and **Potentially Abusive User Detection**, designed to enhance the safety and responsible use of AI models. These optional capabilities provide insights into harmful content and user behaviors, enabling you to fine-tune your AI deployments while aligning with Responsible AI principles.

To access Risks & Safety monitoring, you need an Azure OpenAI resource in one of the [supported Azure regions](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/risks-safety-monitor), and a model deployment that uses a content filter configuration. 

### Content Detection

[Content Detection](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/risks-safety-monitor#configure-metrics) provides detailed insights into the performance of content filters applied to Azure OpenAI model deployments. Metrics such as total blocked requests, block rates, category-specific breakdowns (e.g. hate, violence, etc.), and severity trends help you monitor harmful request patterns. These insights enable you to fine-tune filters to better align with your operational needs and Responsible AI principles.

### Potentially Abusive User Detection

[Potentially Abusive User Detection](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/risks-safety-monitor#potentially-abusive-user-detection) identifies users whose behavior results in harmful content being blocked. It assigns an Abuse Score (0-1), tracks abuse trends, and provides detailed user-level data. Results can be stored in Azure Data Explorer for customizable reporting, ensuring compliance and control over data privacy. Organizations can use this data to validate abusive behavior and take actions like throttling or suspending users to ensure responsible AI usage.

To enable Potentially Abusive User Detection, the following are required:

* A content filter configuration applied to your deployment.
* An Azure Data Explorer database set up to store user analysis results.
* User ID information sent in all Chat Completion requests using the user parameter of the Completions API. It's important to use GUID strings to identify users and avoid including sensitive personal information in the "user" field.

The current deployment of Info Assistant does not send user IDs in chat requests, but customers can customize the solution to include these features if required. 

To implement any of these features or learn more, refer to [Azure AI Foundry's Risks & Safety features.](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/risks-safety-monitor)
