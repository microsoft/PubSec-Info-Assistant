import os
import argparse
import glob
import io
import re
import time
import openai
import json
from datetime import datetime
from openai import  AzureOpenAI
from pypdf import PdfReader, PdfWriter
from azure.identity import AzureAuthorityHosts, DefaultAzureCredential, get_bearer_token_provider
from azure.storage.blob import BlobServiceClient, ContentSettings
from azure.search.documents.indexes.models import *
from azure.search.documents import SearchClient

MAX_SECTION_LENGTH = 1000
SENTENCE_SEARCH_LIMIT = 100
SECTION_OVERLAP = 100

parser = argparse.ArgumentParser(
    description="Prepare documents by extracting content from PDFs, splitting content into sections, uploading to blob storage, and indexing in a search index.",
    epilog="Example: load-test-data-direct-to-index.py '..\\*' --storageaccount https://myaccount.blob.core.azure.net --uploadcontainer mycontainer --chunkcontainer mycontainer2 --searchservice https://mysearch.search.windows.net --index myindex -v"
)
parser.add_argument("files", help="Files to be processed")
parser.add_argument("--storageaccount", help="Azure Blob Storage account name")
parser.add_argument("--uploadcontainer", help="Azure Blob Storage container name where the source files will be uploaded")
parser.add_argument("--chunkcontainer", help="Azure Blob Storage container name where the chunked files will be uploaded")
parser.add_argument(
    "--searchservice", help="Name of the Azure Cognitive Search service where content should be indexed (must exist already)")
parser.add_argument(
    "--index", help="Name of the Azure Cognitive Search index where content should be indexed (will be created if it doesn't exist)")
parser.add_argument(
    "--openaiservice", help="Name of the Azure OpenAI service to use for embedding text")
parser.add_argument(
    "--model", help="Name of the OpenAI model to use for embedding text")
parser.add_argument("--remove", action="store_true",
                    help="Remove references to this document from blob storage and the search index")
parser.add_argument("--removeall", action="store_true",
                    help="Remove all blobs from blob storage and documents from the search index")
parser.add_argument(
    "--azurecloud", help="Azure cloud environment (default: AzureCloud)")
parser.add_argument("--verbose", "-v", action="store_true",
                    help="Verbose output")
args = parser.parse_args()

AUTHORITY = AzureAuthorityHosts.AZURE_GOVERNMENT if args.azurecloud == "AzureUSGovernment" else AzureAuthorityHosts.AZURE_PUBLIC_CLOUD
OPENAI_CRED_DOMAIN = "cognitiveservices.azure.us" if args.azurecloud == "AzureUSGovernment" else "cognitiveservices.azure.com"
# Use the current user identity to connect to Azure services unless a key is explicitly set for any of them
default_creds = DefaultAzureCredential(authority=AUTHORITY)
openai.api_version = "2024-02-01"
openai.api_type = "azure"
openai.api_base = args.openaiservice
openai.api_type = "azure_ad"
token_provider = get_bearer_token_provider(default_creds,
                                               f'https://{OPENAI_CRED_DOMAIN}/.default')

def chunk_blob_name_from_file_section(filename, idx):
    return os.path.splitext(os.path.basename(filename))[0] + f"-{idx}" + ".json"


def upload_blobs(filename):
    blob_service = BlobServiceClient(
        account_url=args.storageaccount, credential=default_creds)
    blob_container = blob_service.get_container_client(args.uploadcontainer)
    if not blob_container.exists():
        blob_container.create_container()
    blob_name = os.path.basename(filename)
    if args.verbose:
        print(f"\tUploading blob -> {blob_name}")
        reader = PdfReader(filename)
        f = io.BytesIO()
        writer = PdfWriter()
        for page in reader.pages:
            writer.add_page(page)
        writer.write(f)
        f.seek(0)
        blob_container.upload_blob(blob_name, f, overwrite=True, content_settings=ContentSettings(content_type="application/pdf"))


def remove_blobs(filename):
    if args.verbose:
        print(f"Removing blobs for '{filename or '<all>'}'")
    blob_service = BlobServiceClient(
        account_url=args.storageaccount, credential=default_creds)
    blob_container = blob_service.get_container_client(args.uploadcontainer)
    if blob_container.exists():
        if filename == None:
            blobs = blob_container.list_blob_names()
        else:
            prefix = os.path.splitext(os.path.basename(filename))[0]
            blobs = filter(lambda b: re.match(f"{prefix}-\d+\.pdf", b), blob_container.list_blob_names(
                name_starts_with=os.path.splitext(os.path.basename(prefix))[0]))
        for b in blobs:
            if args.verbose:
                print(f"\tRemoving blob {b}")
            blob_container.delete_blob(b)


def split_text(filename, pages):
    SENTENCE_ENDINGS = [".", "!", "?"]
    WORDS_BREAKS = [",", ";", ":", " ",
                    "(", ")", "[", "]", "{", "}", "\t", "\n"]
    if args.verbose:
        print(f"Splitting '{filename}' into sections")

    page_map = []
    offset = 0
    for i, p in enumerate(pages):
        text = p.extract_text()
        page_map.append((i, offset, text))
        offset += len(text)

    def find_page(offset):
        l = len(page_map)
        for i in range(l - 1):
            if offset >= page_map[i][1] and offset < page_map[i + 1][1]:
                return i
        return l - 1

    all_text = "".join(p[2] for p in page_map)
    length = len(all_text)
    start = 0
    end = length
    while start + SECTION_OVERLAP < length:
        last_word = -1
        end = start + MAX_SECTION_LENGTH

        if end > length:
            end = length
        else:
            # Try to find the end of the sentence
            while end < length and (end - start - MAX_SECTION_LENGTH) < SENTENCE_SEARCH_LIMIT and all_text[end] not in SENTENCE_ENDINGS:
                if all_text[end] in WORDS_BREAKS:
                    last_word = end
                end += 1
            if end < length and all_text[end] not in SENTENCE_ENDINGS and last_word > 0:
                end = last_word  # Fall back to at least keeping a whole word
        if end < length:
            end += 1

        # Try to find the start of the sentence or at least a whole word boundary
        last_word = -1
        while start > 0 and start > end - MAX_SECTION_LENGTH - 2 * SENTENCE_SEARCH_LIMIT and all_text[start] not in SENTENCE_ENDINGS:
            if all_text[start] in WORDS_BREAKS:
                last_word = start
            start -= 1
        if all_text[start] not in SENTENCE_ENDINGS and last_word > 0:
            start = last_word
        if start > 0:
            start += 1

        yield (all_text[start:end], find_page(start))
        start = end - SECTION_OVERLAP

    if start + SECTION_OVERLAP < end:
        yield (all_text[start:end], find_page(start))


def create_sections(filename, pages):
    for i, (section, pagenum) in enumerate(split_text(filename, pages)):
        chunk_file_name = chunk_blob_name_from_file_section(filename, i)
        upload_section_blob(filename, chunk_file_name, pagenum, section)
        yield {
            "id": f"{chunk_file_name}".replace(".", "_").replace(" ", "_"),
            "file_name": f"{args.uploadcontainer}/{filename}",
            "file_uri": f"{args.storageaccount}{args.uploadcontainer}/{filename}",
            "chunk_file": chunk_file_name,
            "file_class": "text",
            "folder": "",
            "tags": [],
            "pages": [pagenum],
            "title": "",
            "translated_title": "",
            "content": section,
            "entities": [],
            "key_phrases": [],            
            "contentVector": embed_section(section)
        }


def embed_section(section_text):
    embedded_text = ""

    client = AzureOpenAI(
        azure_endpoint = openai.api_base,
        azure_ad_token_provider=token_provider,
        api_version=openai.api_version)
    
    response = client.embeddings.create(
                model=args.model,
                input=section_text
            )
    embedded_text = response.data[0].embedding
    return embedded_text

def upload_section_blob(filename, chunkfilename, pagenum, section_text):
    # Upload the section to a blob
    blob_service = BlobServiceClient(
        account_url=args.storageaccount, credential=default_creds)
    blob_container = blob_service.get_container_client(args.chunkcontainer)
    if not blob_container.exists():
        blob_container.create_container()
    blob_name = chunkfilename

    # Get the current date and time in the specified format
    current_datetime = datetime.now().isoformat()

    # Create the JSON content
    chunk_content = {
        "file_name": f"{args.uploadcontainer}/{filename}",
        "file_uri": f"{args.storageaccount}{args.uploadcontainer}/{filename}",
        "file_class": "text",
        "processed_datetime": current_datetime,
        "title": "",
        "subtitle": "",
        "section": "",
        "pages": [pagenum],
        "token_count": 999,
        "content": section_text,
        "translated_content": section_text,
        "translated_title": "",
        "translated_subtitle": "",
        "translated_section": "",
        "entities": [],
        "key_phrases": [],
        "contentVector": []
    }

    # Convert the dictionary to a JSON string
    chunk_content_str = json.dumps(chunk_content, indent=2, ensure_ascii=False)

    if args.verbose:
        print(f"\tUploading blob chunk -> {blob_name}")
    
    blob_service.get_blob_client(container=args.chunkcontainer, blob=blob_name).upload_blob(chunk_content_str, overwrite=True)

def remove_chunk_blobs(filename):
    if args.verbose:
        print(f"Removing chunk blobs for '{filename or '<all>'}'")
    blob_service = BlobServiceClient(
        account_url=args.storageaccount, credential=default_creds)
    blob_container = blob_service.get_container_client(
        args.chunkcontainer)
    if blob_container.exists():
        if (filename == None):
            blobs = blob_container.list_blob_names()
        else:
            prefix = os.path.splitext(os.path.basename(filename))[0]
            blobs = filter(lambda b: re.match(
                f"{prefix}-\d+-\d+\.pdf", b), blob_container.list_blob_names(name_starts_with=os.path.splitext(os.path.basename(prefix))[0]))
        for b in blobs:
            if args.verbose:
                print(f"\tRemoving chunk blob {b}")
            blob_container.delete_blob(b)

def index_sections(filename, sections):
    if args.verbose:
        print(
            f"Indexing sections from '{filename}' into search index '{args.index}'")
    search_client = SearchClient(endpoint=f"{args.searchservice}",
                                 index_name=args.index,
                                 credential=default_creds)
    i = 0
    batch = []
    for s in sections:
        batch.append(s)
        i += 1
        if i % 1000 == 0:
            results = search_client.index_documents(batch=batch)
            succeeded = sum([1 for r in results if r.succeeded])
            if args.verbose:
                print(
                    f"\tIndexed {len(results)} sections, {succeeded} succeeded")
            batch = []

    if len(batch) > 0:
        if args.verbose: print("Indexing small batch less than 1000")
        results = search_client.upload_documents(documents=batch)
        succeeded = sum([1 for r in results if r.succeeded])
        if args.verbose:
            print(f"\tIndexed {len(results)} sections, {succeeded} succeeded")


def remove_from_index(filename):
    if args.verbose:
        print(
            f"Removing sections from '{filename or '<all>'}' from search index '{args.index}'")
    search_client = SearchClient(endpoint=f"{args.searchservice}",
                                 index_name=args.index,
                                 credential=default_creds)
    while True:
        filter = None if filename == None else f"sourcefile eq '{os.path.basename(filename)}'"
        r = search_client.search(
            "", filter=filter, top=1000, include_total_count=True)
        if r.get_count() == 0:
            break
        r = search_client.delete_documents(
            documents=[{"id": d["id"]} for d in r])
        if args.verbose:
            print(f"\tRemoved {len(r)} sections from index")
        # It can take a few seconds for search results to reflect changes, so wait a bit
        time.sleep(2)


if args.removeall:
    remove_blobs(None)
    remove_chunk_blobs(None)
    remove_from_index(None)
else:
    print(f"Processing files...")
    for filename in glob.glob(args.files):
        if args.verbose:
            print(f"Processing '{filename}'")
        if args.remove:
            remove_blobs(filename)
            remove_chunk_blobs(filename)
            remove_from_index(filename)
        elif args.removeall:
            remove_blobs(None)
            remove_chunk_blobs(None)
            remove_from_index(None)
        else:
            reader = PdfReader(filename)
            pages = reader.pages
            upload_blobs(filename)
            sections = create_sections(os.path.basename(filename), pages)
            index_sections(os.path.basename(filename), sections)
