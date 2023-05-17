""" Python function to read HTML files and extract text using Azure Form Recognizer"""
import azure.functions as func
from azure.storage.blob import generate_blob_sas, BlobSasPermissions, BlobServiceClient
from azure.core.credentials import AzureKeyCredential
from azure.ai.formrecognizer import DocumentAnalysisClient
from azure.core.exceptions import HttpResponseError
import logging
import os
import numpy as np
from enum import Enum
from datetime import datetime, timedelta
import json
import html
from bs4 import BeautifulSoup
import codecs
import requests
import json
from decimal import Decimal
import tiktoken
import nltk
nltk.download('words')
nltk.download('punkt')


azure_blob_storage_account = os.environ["AZURE_BLOB_STORAGE_ACCOUNT"]
azure_blob_drop_storage_container = os.environ["AZURE_BLOB_DROP_STORAGE_CONTAINER"]
azure_blob_content_storage_container = os.environ["AZURE_BLOB_CONTENT_STORAGE_CONTAINER"]
azure_blob_storage_key = os.environ["AZURE_BLOB_STORAGE_KEY"]
XY_ROUNDING_FACTOR = int(os.environ["XY_ROUNDING_FACTOR"])
CHUNK_TARGET_SIZE = int(os.environ["CHUNK_TARGET_SIZE"])
REAL_WORDS_TARGET = Decimal(os.environ["REAL_WORDS_TARGET"])
FR_API_VERSION = os.environ["FR_API_VERSION"]
TARGET_PAGES = os.environ["TARGET_PAGES"]     # ALL or Custom page numbers for multi-page documents(PDF/TIFF). Input the page numbers and/or ranges of pages you want to get in the result. For a range of pages, use a hyphen, like pages="1-3, 5-6". Separate each page number or range with a comma.
azure_blob_log_storage_container = os.environ["AZURE_BLOB_LOG_STORAGE_CONTAINER"]

def main(myblob: func.InputStream):
    """ Function to read HTML files and extract text using Azure Form Recognizer"""
    logging.info(f"Python blob trigger function processed blob \n"
                 f"Name: {myblob.name}\n"
                 f"Blob Size: {myblob.length} bytes")

    from azure.core.exceptions import HttpResponseError
    try:
        analyze_layout(myblob)
    except HttpResponseError as error:
        # Check by error code:
        if error.error is not None:
            raise
        # If the inner error is None and then it is possible to check the message to get more information:
        if "Invalid request".casefold() in error.message.casefold():
            print(f"Uh-oh! Seems there was an invalid request: {error}")
        # Raise the error again
        raise
    
    logging.info(f"chunking complete for file {myblob.name}")


def sort_key(element):
    """ Function to sort elements by page number and role priority """
    return (element["page_number"])
    # to do, more complex sorting logic to cope with indented bulleted lists
    return (element["page_number"], element["role_priority"], element["bounding_region"][0]["x"], element["bounding_region"][0]["y"])


def num_tokens_from_string(string: str, encoding_name: str) -> int:
    """ Function to return the number of tokens in a text string"""
    encoding = tiktoken.get_encoding(encoding_name)
    num_tokens = len(encoding.encode(string))
    return num_tokens


class paragraph_roles(Enum):
    """ Enum to define the priority of paragraph roles """
    pageHeader      = 1
    title           = 2
    sectionHeading  = 3
    other           = 3
    footnote        = 5
    pageFooter      = 6
    pageNumber      = 7
    
    
class content_type(Enum):
    """ Enum to define the types for various content chars returned from FR """
    not_processed           = 0
    title_start             = 1
    title_char              = 2
    title_end               = 3
    sectionheading_start    = 4
    sectionheading_char     = 5
    sectionheading_end      = 6
    text_start              = 7
    text_char               = 8
    text_end                = 9
    table_start             = 10
    table_char              = 11
    table_end               = 12
        
 
def role_prioroty(role):
    """ Function to return the priority of a paragraph role"""
    priority = 0
    match role:
        case "title":
            priority = paragraph_roles.title.value
        case "sectionHeading":
            priority = paragraph_roles.sectionHeading.value
        case "footnote":
            priority = paragraph_roles.footnote.value
        case "pageHeader" :
            priority = paragraph_roles.pageHeader.value           
        case "pageFooter" :
            priority = paragraph_roles.pageFooter.value
        case "pageNumber" :
            priority = paragraph_roles.pageNumber.value
        case other:     # content
            priority = paragraph_roles.other.value         
    return (priority)


# Load a pre-trained tokenizer
tokenizer = nltk.tokenize.word_tokenize


# Load a set of known English words
word_set = set(nltk.corpus.words.words())


# Define a function to check whether a token is a real English word
def is_real_word(token):
    """ Function to check whether a token is a real English word"""
    return token.lower() in word_set


# Define a function to check whether a string contains real English words
def contains_real_words(string):
    """ Function to check whether a string contains real English words"""
    tokens = tokenizer(string)
    real_word_count = sum(1 for token in tokens if is_real_word(token))
    return (real_word_count / len(tokens) > REAL_WORDS_TARGET) and (len(tokens) >= 1)  # Require at least 50% of tokens to be real words and at least one word


def token_count(input_text):
    """ Function to return the number of tokens in a text string"""
    # calc token count
    encoding = "cl100k_base"    # For gpt-4, gpt-3.5-turbo, text-embedding-ada-002, you need to use cl100k_base
    token_count = num_tokens_from_string(input_text, encoding)
    return token_count 


def  get_blob_and_sas(myblob):
    """ Function to retrieve the uri and sas token for a given blob in azure storage"""
    logging.info("processing pdf " + myblob.name)
    base_filename = os.path.basename(myblob.name)

    # Get path and file name minus the root container
    separator = "/"
    file_path_w_name_no_cont = separator.join(
        myblob.name.split(separator)[1:])

    # Gen SAS token
    sas_token = generate_blob_sas(
        account_name=azure_blob_storage_account,
        container_name=azure_blob_drop_storage_container,
        blob_name=file_path_w_name_no_cont,
        account_key=azure_blob_storage_key,
        permission=BlobSasPermissions(read=True),
        expiry=datetime.utcnow() + timedelta(hours=1)
    )
    source_blob_path = f'https://{azure_blob_storage_account}.blob.core.windows.net/{myblob.name}?{sas_token}'
    source_blob_path = source_blob_path.replace(" ", "%20")        
    logging.info(f"Path and SAS token for file in azure storage are now generated \n")
    return source_blob_path


def table_to_html(table):
    """ Function to take an output FR table json structure and convert to HTML """
    table_html = "<table>"
    rows = [sorted([cell for cell in table.cells if cell.row_index == i], key=lambda cell: cell.column_index) for i in range(table.row_count)]
    for row_cells in rows:
        table_html += "<tr>"
        for cell in row_cells:
            tag = "th" if (cell.kind == "columnHeader" or cell.kind == "rowHeader") else "td"
            cell_spans = ""
            if cell.column_span > 1: cell_spans += f" colSpan={cell.column_span}"
            if cell.row_span > 1: cell_spans += f" rowSpan={cell.row_span}"
            table_html += f"<{tag}{cell_spans}>{html.escape(cell.content)}</{tag}>"
        table_html +="</tr>"
    table_html += "</table>"
    return table_html


def get_filename_and_extension(path):
    """ Function to return the file name & type"""
    # Split the path into base and extension
    base_name = os.path.basename(path)
    file_name, file_extension = os.path.splitext(base_name)
    return file_name, file_extension


def write_chunk(myblob, document_map, file_number, chunk_size, chunk_text, page_list, section_name, title_name):
    """ Function to write a json chunk to blob"""
    chunk_output = {
        'file_name': document_map['file_name'],
        'file_uri': document_map['file_uri'],
        'processed_datetime': datetime.now().isoformat(),
        'title': title_name,
        'section': section_name,
        'pages': page_list,
        'token_count': chunk_size,
        'content': chunk_text                       
    }                
    # Get path and file name minus the root container
    file_name, file_extension = get_filename_and_extension(myblob.name)
    # Get the folders to use when creating the new files        
    folder_set = file_name + "." + file_extension + "/"
    blob_service_client = BlobServiceClient(
        f'https://{azure_blob_storage_account}.blob.core.windows.net/', azure_blob_storage_key)
    json_str = json.dumps(chunk_output, indent=2)
    output_filename = file_name + f'-{file_number}' + '.json'
    block_blob_client = blob_service_client.get_blob_client(
        container=azure_blob_content_storage_container, blob=f'{folder_set}{output_filename}')
    block_blob_client.upload_blob(json_str, overwrite=True)   
    
    
def write_blob(output_container, content, output_filename, folder_set=""):
    """ Function to write a generic blob """
    # folder_set should be in the format of "<my_folder_name>/"
    # Get path and file name minus the root container
    blob_service_client = BlobServiceClient(
        f'https://{azure_blob_storage_account}.blob.core.windows.net/', azure_blob_storage_key)
    block_blob_client = blob_service_client.get_blob_client(
        container=output_container, blob=f'{folder_set}{output_filename}')
    block_blob_client.upload_blob(content, overwrite=True)   
       
        
def build_document_map(myblob, source_blob_path):
    """ Function to build a json structure representing the paragraphs in a document, including metadata
        such as section heading, title, page number, eal word pernetage etc."""
        
    logging.info(f"Constructing the JSON structure of the document\n")   
         
    # html_file
    # Download the content from the URL
    response = requests.get(source_blob_path)
    if response.status_code == 200:
        html = response.text
        soup = BeautifulSoup(html, 'lxml')
    
    # with codecs.open(content, "r", encoding='utf-8', errors='replace') as page:
    #     soup = bs4.BeautifulSoup(page, 'lxml')
        
    # with codecs.open(content, "r", encoding='utf-8', errors='replace') as page:
    #     soup = bs4.BeautifulSoup(page, 'lxml')

    # soup = bs4.BeautifulSoup(content, 'lxml')
    
    document_map = {
        'file_name': myblob.name,
        'file_uri': myblob.uri,
        'content': soup.text,
        "structure": []
    }      

    title = '' 
    section = ''   
    title = soup.title.string if soup.title else "No title"
    
    for tag in soup.find_all(['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p']):
        if tag.name in ['h1', 'h2', 'h3', 'h4', 'h5', 'h6']:
            section = tag.get_text(strip=True)
        elif tag.name == 'p' and tag.get_text(strip=True):
            document_map["structure"].append({
                "type": "text", 
                "text": tag.get_text(strip=True),
                "type": "text",
                "title": title.text.strip(),
                "section": section,
                "page_number": 1                
                })            
            
    
    # Output document map to log container
    json_str = json.dumps(document_map, indent=2)
    base_filename = os.path.basename(myblob.name)
    file_name, file_extension = get_filename_and_extension(os.path.basename(base_filename))
    output_filename =  file_name + "_Document_Map" + file_extension + ".json"
    write_blob(azure_blob_log_storage_container, json_str, output_filename)
  
    logging.info(f"Constructing the JSON structure of the document complete\n")  
    return document_map      
        
        
def build_chunks(document_map, myblob):
    """ Function to build chunk outputs based on the document map """
    
    chunk_text = ''
    chunk_size = 0    
    file_number = 0
    page_number = 0
    previous_section_name = document_map['structure'][0]['section']
    previous_title_name = document_map['structure'][0]["title"]
    page_list = []   
    
    # iterate over the paragraphs and build a chuck bae don a section and/or title of teh document
    for index, paragraph_element in enumerate(document_map['structure']):          
        # if this paragraph would put the chunk_size greater than the target token size, OR
        # if this is a new (section OR title)
        # then write out the stash of content from previous loops and start a new chunk
        paragraph_size = token_count(paragraph_element["text"])
        section_name = paragraph_element["section"]
        title_name = paragraph_element["title"]
            
        if (chunk_size + paragraph_size >= CHUNK_TARGET_SIZE) or section_name != previous_section_name or title_name != previous_title_name:
            write_chunk(myblob, document_map, file_number, chunk_size, chunk_text, page_list, previous_section_name, previous_title_name) 
            # reset chunk specific variables 
            file_number += 1
            page_list = [] 
            chunk_text = ''
            chunk_size = 0  
            page_number = 0   
        
        # Now process this paragraph if it passes the minimum threshold for real words, 
        # only for textual paragraphs not tables - if it is real text
        if (contains_real_words(paragraph_element['text']) is True) or (paragraph_element['type'] != 'text'):
            if page_number != paragraph_element["page_number"]:
                page_list.append(paragraph_element["page_number"])
                page_number = paragraph_element["page_number"]   

            # add paragraph to the chunk
            chunk_size = chunk_size + paragraph_size
            chunk_text = chunk_text + "\n" + paragraph_element["text"]

        # If this is the last paragraph then write the chunk
        if index == len(document_map['structure'])-1:
            write_chunk(myblob, document_map, file_number, chunk_size, chunk_text, page_list, section_name, title_name) 
            
        previous_section_name = section_name
        previous_title_name = title_name    
    
    logging.info(f"Chunking is complete \n")
        
        

def analyze_layout(myblob: func.InputStream):
    """ Function to analyze the layout of a PDF file and extract text using Azure Form Recognizer"""
 
    source_blob_path = get_blob_and_sas(myblob)
    document_map = build_document_map(myblob, source_blob_path)
    build_chunks(document_map, myblob)
   
    logging.info(f"Done!\n")