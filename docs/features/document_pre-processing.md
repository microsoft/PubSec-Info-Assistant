# Document Pre-processing

The Information Assistant relies on a multi-step process to preprocess documents in preparation for them being used in the NLP based chat interface. This process includes:

**Document Chunking**: Custom logic to break up text based documents into manageable size document sections with contextual metadata. Manageable size chunks are determined by the prompt engineering strategy. For example, when using the ChatReadRetrieveRead method which depends on STUFFING patterns, the document chunks need to be around 750 tokens each so that we can include a reasonable amount of matching chunks per API call to Azure OpenAI.

**Document Enrichments**: Custom logic that will do things like translate text, generate a description of an image, transcribe the audio from media, etc. This process will leverage the Azure Cognitive Services for most enrichments but will also support both LM and LLM embeddings. We have chosen to make this a custom controlled process rather than use the built-in Skillsets in Azure Cognitive Services.

**Indexing**: Custom search index that will optimize the contextual metadata from chunking, the enrichments from Azure Cognitive Services, and the vector based embeddings of text-based files. This is one of the key factors to ensuring the right document chunks get returned to the user based on their questions.
This sets up the index so that the UX side of the Information Assistant 


The overall flow of the document chunking part of the pipeline is:



### PDF

:::mermaid
graph LR
A[[File]]-->B
AA[Form Recognizer]

subgraph "State (Azure Blob Storage)"
B[Upload Container]
K{{pdf_submit_queue}}
L{{non_pdf_submit_queue}}
M{{image_enrichment_queue}}
N{{media_enrichment_queue}}
P{{pdf_polling_queue}}
R[Logs]
S[Contents]
U{{text_enrichment_queue}}
end

subgraph "Chunking"
B-->|Blob Upload Trigger|C(FileUploadedFunc)
C-->D{Is Text Based}
D-->|Yes|E{File Type}
E-->F[PDF]
E-->G[HTM, HTML, DOCX]
D-->|No|H{FileType}
H-->I[Image]
H-->J[Media]
F-->|queue|K
G-->|queue|L
I-->|queue|M
J-->|queue|N
K-->O(FileFormRecSubmissionPDF)
O-->|queue|P
O-.->|submit|AA
P-->Q(FileFormRecPollingPDF)
Q<-.->|poll|AA
Q & T-->|write FR layout and doc map|R
Q & T-->|write chunks|S
L-->T(FileLayoutParsingOther)
Q & T-->U
end

:::

### HTML

### DOCX