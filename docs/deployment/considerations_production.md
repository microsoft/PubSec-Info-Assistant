# Considerations For Adopting Into Production

This documentation highlights key considerations for transitioning from an Intelligent Applications (IA) accelerator to a production-ready deployment. Emphasizing scalability, high availability, security, and proactive management, the recommendations cover components such as App Server scaling, Load Balancing strategies, and global-scale content delivery. Additional guidance addresses GPT Model throttling, security enhancements, proactive monitoring, and redundancy. It stresses the importance of safeguarding against cyber threats, seamless integration with existing ecosystems, and proactive environment management through monitoring and alerts.

##  Scalability and High Availability

These recommendations offer options for load balancing and high availability, catering to the scalability needs and global distribution requirements of your IA application.

### App Server - Scaling

**Consideration:** As the load on the App Server increases, scaling becomes crucial to handle varying levels of traffic efficiently.

**Recommendation:** Refer to the Azure [Autoscaling documentation](/docs/deployment/autoscale_sku.md) to set up dynamic scaling based on demand. Configure autoscaling rules to automatically adjust the number of instances in response to changes in load. You can also adjust the sku to scale vertically and adjust the number of workers in the app server. Alternatively, you could  consider deploying the App to a container orchestration platform like Azure Kubernetes Service (AKS) for management and scaling.

### App Gateway
**Consideration:** Ensure App Gateway handles increased traffic and maintains high availability. Learn more about App Gateway [here](https://learn.microsoft.com/en-us/azure/application-gateway/overview).
    
**Recommendation:**
    Explore horizontal scaling with multiple instances.
    Use Azure Traffic Manager for global distribution.

### Load Balancing - Distribution of Workload
**Consideration:** Efficient workload distribution for optimal performance.

**Recommendation:**
Utilize Azure Load Balancer for even traffic distribution.
Adjust load balancing rules and implement health probes.
Learn more about load balancing options in Azure [here](https://learn.microsoft.com/en-us/azure/architecture/guide/technology-choices/load-balancing-overview).

### Front Door - Global Scale and Content Delivery

**Consideration:** Address global-scale distribution and content delivery concerns.
    
**Recommendation:**
Implement Azure Front Door for global load balancing and improved content delivery.
Configure regional routing and caching for optimized user experience.
Learn more about Frontdoor [here](https://learn.microsoft.com/en-us/azure/frontdoor/front-door-overview).

## Security 

### Private Endpoints

**Consideration:** Enhancing the security posture of your deployment is crucial, especially when dealing with sensitive data or services.

**Recommendation:** Consider implementing Private Endpoints to establish a private connection between public ingress points and related services, like storage accounts. By avoiding exposure to the public internet, you reduce the attack surface and enhance data privacy. Ensure that only necessary traffic is allowed through the Private Endpoint for increased security.
Learn more [here](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview).

### Web Application Firewall (WAF) 

**Consideration:** Safeguarding your IA application from cyber threats is crucial for protecting sensitive data and maintaining user trust.

**Recommendation:** Implement Azure WAF to protect against common web vulnerabilities and attacks. Regularly update WAF rules and policies to stay resilient against evolving security threats. Integrate with Azure Security Center for comprehensive threat detection and response. Learn more [here](https://learn.microsoft.com/en-us/azure/web-application-firewall/overview).


## AOAI Instances - Redundancy and Reliability

**Consideration:** To enhance system reliability and ensure business continuity, consider implementing multiple instances of your Azure OpenAI (AOAI).

**Recommendation:** You could deploy AOAI instances across multiple Azure regions for geographic redundancy. Leverage Azure Traffic Manager for global distribution and failover capabilities, ensuring uninterrupted service even in the event of a regional failure. Learn more about potential strategies [here](https://techcommunity.microsoft.com/t5/ai-azure-ai-services-blog/azure-openai-architecture-patterns-and-implementation-steps/ba-p/3979934).


## GPT Model - Throttling

**Consideration:** Throttling is essential to control the rate at which requests are sent to the GPT model, preventing overload and maintaining performance.

**Recommendation**: Microsoft offers Provisioned Throughput options, allowing you to specify the maximum request rate for your GPT model. Define appropriate throughput limits based on the model's capacity and resource availability. Adjust throttling settings as needed to ensure optimal performance without risking service degradation. Learn more [here](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/provisioned-throughput).


## Monitoring And Alerting

**Consideration:** Proactively monitoring the IA environment is crucial for identifying performance issues, bottlenecks, and potential security threats.

**Recommendation:** Leverage Azure Monitor to gain insights into the performance and health of your entire IA ecosystem. Set up custom alerts based on key performance indicators and metrics. Utilize Azure Log Analytics for in-depth analysis and troubleshooting. Integrate Azure Security Center to monitor and respond to security threats in real-time.
Learn more [here](https://azure.microsoft.com/en-us/products/monitor/?ef_id=_k_2bb24bd93ec91aeba1fe2e4c90190298_k_&OCID=AIDcmm5edswduu_SEM__k_2bb24bd93ec91aeba1fe2e4c90190298_k_&msclkid=2bb24bd93ec91aeba1fe2e4c90190298).

## Document Ingestion Limitations

**Consideration:** This accelerator uses Azure Document Intelligence for PDF's and Unstructured.io for document processing. These tools have their own limitations when it comes to document sizes they can handle. The page limit and document size limits for PDFs on Document Intelligence can vary by subscription tier. Learn more about Document Intelligence [here](https://learn.microsoft.com/en-us/legal/cognitive-services/document-intelligence/characteristics-and-limitations).

More info on unstructured.io for other supported document types can be found [here](https://unstructured-io.github.io/unstructured/introduction.html).

**Recommendation:** If you see issues with the chunking or processing of very large documents, we recommend splitting those into a sensible format of multiple documents for ingestion.

## Custom Branding

If you would like to give custom branding to the Front End Web App interface, there are a couple ways this might be accomplished.

### Configuring Existing UI

**Consideration:** To give custom branding to the existing Front End Web App interface.
This can be achieved by modifying the currently provided UI by making a couple of configuration changes.

**Recommendation:** In the local.env used to deploy the solution, there exists a parameter called "APPLICATION_TITLE" that can be given any string value to change the title that appears on the title bar of the existing UI. See [this section](/docs/deployment/deployment.md#configure-env-files) for a list of configurable environment variables. You may also change the image files displayed by replacing them in the /app/frontend/src/assets folder. You may need to change the reference names in the code where it is refferencing if you change the file name of the referenced image file. The sky is the limit when it comes to modifying the existing front end source code for your own use cases.

### Replacing Existing UI

**Consideration:** When considering the replacement of the existing UI, it is important to assess the potential for enabling token OAuth implementation on the API. This could allow for the integration of a distinct custom UI to call the web app backend API.

**Recommendation:** To securely invoke the API with an alternative interface, it is recommended to implement the [Client Credentials Flow](/docs/deployment/client_credentials_flow.md). This approach facilitates OAuth token authentication for the API, requiring subsequent integration into your own UI or processes.


## In Summary
 Ensure that your IA accelerator seamlessly integrates into your existing ecosystem, considering compatibility and interoperability. Use the IA accelerator as a blueprint to plan integration into your ecosystem.