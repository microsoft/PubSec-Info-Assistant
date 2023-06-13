""" Python function to read PDF files and extract text using Azure Form Recognizer"""
import azure.functions as func
from azure.storage.blob import generate_blob_sas, BlobSasPermissions, BlobServiceClient
from azure.core.credentials import AzureKeyCredential
from azure.ai.formrecognizer import DocumentAnalysisClient
from azure.core.exceptions import HttpResponseError
import logging
import os
from enum import Enum
from datetime import datetime, timedelta
import json
import html
from bs4 import BeautifulSoup
import mammoth
from io import BytesIO
import requests
import json
from decimal import Decimal
import tiktoken
import nltk
nltk.download('words')
nltk.download('punkt')
# from shared_code import status_log as Status
from shared_code.status_log import StatusLog, State, StatusClassification, StatusQueryLevel


azure_blob_storage_account = os.environ["BLOB_STORAGE_ACCOUNT"]
azure_blob_drop_storage_container = os.environ["BLOB_STORAGE_ACCOUNT_UPLOAD_CONTAINER_NAME"]
azure_blob_content_storage_container = os.environ["BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME"]
azure_blob_storage_key = os.environ["BLOB_STORAGE_ACCOUNT_KEY"]
XY_ROUNDING_FACTOR = int(os.environ["XY_ROUNDING_FACTOR"])
CHUNK_TARGET_SIZE = int(os.environ["CHUNK_TARGET_SIZE"])
REAL_WORDS_TARGET = Decimal(os.environ["REAL_WORDS_TARGET"])
FR_API_VERSION = os.environ["FR_API_VERSION"]
# ALL or Custom page numbers for multi-page documents(PDF/TIFF). Input the page numbers and/or
# ranges of pages you want to get in the result. For a range of pages, use a hyphen, like pages="1-3, 5-6".
# Separate each page number or range with a comma.
TARGET_PAGES = os.environ["TARGET_PAGES"]
azure_blob_log_storage_container = os.environ["BLOB_STORAGE_ACCOUNT_LOG_CONTAINER_NAME"]
cosmosdb_url = os.environ["COSMOSDB_URL"]
cosmosdb_key = os.environ["COSMOSDB_KEY"]
cosmosdb_database_name = os.environ["COSMOSDB_DATABASE_NAME"]
cosmosdb_container_name = os.environ["COSMOSDB_CONTAINER_NAME"]
statusLog = StatusLog(cosmosdb_url, cosmosdb_key, cosmosdb_database_name, cosmosdb_container_name)


def main(myblob: func.InputStream):

    
    """ Function to read PDF files and extract text using Azure Form Recognizer"""
    statusLog.state = State.STARTED
    statusLog.upsert_document(myblob.name, 'File Uploaded', StatusClassification.INFO, True)
    
    logging.info(f"Python blob trigger function processed blob \n"
                 f"Name: {myblob.name}\n"
                 f"Blob Size: {myblob.length} bytes")
    statusLog.upsert_document(myblob.name, 'Parser function started', StatusClassification.INFO)    
    try:
        analyze_layout(myblob)
        statusLog.state = State.COMPLETE
        statusLog.state_description = ""
        statusLog.upsert_document(myblob.name, 'Processing complete', StatusClassification.INFO)
        
    except Exception as e:
        statusLog.state = State.ERROR
        statusLog.state_description = str(e)
        statusLog.upsert_document(myblob.name, f"An error occurred - {str(e)}", StatusClassification.ERROR)
        raise
    

def sort_key(element):
    """ Function to sort elements by page number and role priority """
    return (element["page_number"])
    # to do, more complex sorting logic to cope with indented bulleted lists
    # return (element["page_number"], element["role_priority"], element["bounding_region"][0]["x"], element["bounding_region"][0]["y"])


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
    segments = path.split("/")
    directory = "/".join(segments[1:-1]) + "/"
    file_name, file_extension = os.path.splitext(base_name)    
    return file_name, file_extension, directory


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
    file_name, file_extension, file_directory = get_filename_and_extension(myblob.name)
    # Get the folders to use when creating the new files        
    folder_set = file_directory + file_name + file_extension + "/"
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
       
        
def build_document_map_pdf(myblob, result):
    """ Function to build a json structure representing the paragraphs in a document, including metadata
        such as section heading, title, page number, eal word pernetage etc.
        We construct this map from the Content key/value output of FR, because the paragraphs value does not distinguish between
        a table and a text paragraph"""
        
    logging.info(f"Constructing the JSON structure of the document\n")        
    document_map = {
        'file_name': myblob.name,
        'file_uri': myblob.uri,
        'content': result.content,
        # 'content_type': list,
        "structure": [],
        "content_type": [],
        "table_index": []
    }
    document_map['content_type'].extend([content_type.not_processed] * len(result.content))
    document_map['table_index'].extend([-1] * len(result.content))
   
    # update content_type array where spans are tables
    for index, table in enumerate(result.tables):
        start_char = table.spans[0].offset
        end_char = start_char + table.spans[0].length - 1
        document_map['content_type'][start_char] = content_type.table_start
        document_map['content_type'][start_char]
        for i in range(start_char+1, end_char):
            document_map['content_type'][i] = content_type.table_char                    
        document_map['content_type'][end_char] = content_type.table_end 
        # tag the end point in content of a table with the index of which table this is
        document_map['table_index'][end_char] = index        

    
    # update content_type array where spans are titles, section headings or regular content, BUT skip over the table paragraphs
    for paragraph in result.paragraphs:
        start_char = paragraph.spans[0].offset
        end_char = start_char + paragraph.spans[0].length - 1
        
        # if this span has already been identified as a non textual paragraph such as a table, then skip over it
        if document_map['content_type'][start_char] == content_type.not_processed:
            # only process content, titles and sectionHeading
            match paragraph.role:
                case 'title':
                    document_map['content_type'][start_char] = content_type.title_start
                    for i in range(start_char+1, end_char):
                        document_map['content_type'][i] = content_type.title_char                    
                    document_map['content_type'][end_char] = content_type.title_end                    
                case 'sectionHeading':
                    document_map['content_type'][start_char] = content_type.sectionheading_start
                    for i in range(start_char+1, end_char):
                        document_map['content_type'][i] = content_type.sectionheading_char                    
                    document_map['content_type'][end_char] = content_type.sectionheading_end                    
                case None:
                    document_map['content_type'][start_char] = content_type.text_start
                    for i in range(start_char+1, end_char):
                        document_map['content_type'][i] = content_type.text_char
                    document_map['content_type'][end_char] = content_type.text_end
    
    # iterate through the content_type and build the document paragraph catalog of content tagging paragrahs with title and section    
    current_title = ''
    current_section = ''
    current_paragraph_index = 0
    for index, item in enumerate(document_map['content_type']):
       
        # identify the current paragraph being referenced for use in enriching the document_map metadata
        if current_paragraph_index <= len(result.paragraphs)-1:
            if index == result.paragraphs[current_paragraph_index].spans[0].offset:
                # we have reached a new paragraph, so collect its metadata
                current_paragraph_offset = result.paragraphs[current_paragraph_index].spans[0].offset    
                polygon_elements = []
                for point in result.paragraphs[current_paragraph_index].bounding_regions[0].polygon:
                    polygon_elements.append({
                        "x": round(point.x, XY_ROUNDING_FACTOR),
                        "y": round(point.y, XY_ROUNDING_FACTOR)
                    })
                page_number = result.paragraphs[current_paragraph_index].bounding_regions[0].page_number
                current_paragraph_index += 1
                    
        match item:
            case content_type.title_start | content_type.sectionheading_start | content_type.text_start | content_type.table_start:
                start_position = index            
            case content_type.title_end:
                current_title =  document_map['content'][start_position:index+1]
            case content_type.sectionheading_end:
                current_section = document_map['content'][start_position:index+1]
            case content_type.text_end | content_type.table_end:
                if item == content_type.text_end:
                    property_type = 'text'
                    output_text = document_map['content'][start_position:index+1]
                elif item == content_type.table_end:
                    # now we have reached the end of the table in the content dictionary, write out 
                    # the table text to the output json document map
                    property_type = 'table'
                    table_index = document_map['table_index'][index]
                    table_json = result.tables[table_index] 
                    output_text = table_to_html(table_json)
                else:
                    property_type = 'unknown'
                document_map["structure"].append({
                    'offset': start_position,
                    'text': output_text,
                    'type': property_type,
                    'title': current_title,
                    'section': current_section,
                    'page_number': page_number,
                    "bounding_region": polygon_elements   
                })                 
                
    del document_map['content_type']
    del document_map['table_index']
    # sort to order columns in the document logically
    document_map['structure'].sort(key=sort_key)
       
    # Output document map to log container
    json_str = json.dumps(document_map, indent=2)
    file_name, file_extension, file_directory  = get_filename_and_extension(myblob.name)
    output_filename =  file_name + "_Document_Map" + file_extension + ".json"
    write_blob(azure_blob_log_storage_container, json_str, output_filename, file_directory)
    
    # Output FR result to log container
    result_dict = result.to_dict() 
    json_str = json.dumps(result_dict, indent=2)
    output_filename =  file_name + '_FR_Result' + file_extension + ".json"
    write_blob(azure_blob_log_storage_container, json_str, output_filename, file_directory)
    
    logging.info(f"Constructing the JSON structure of the document complete\n")  
    return document_map      
        

def build_document_map_html(myblob, html):
    """ Function to build a json structure representing the paragraphs in a document, including metadata
        such as section heading, title, page number, eal word pernetage etc."""
        
    logging.info(f"Constructing the JSON structure of the document\n")   

    soup = BeautifulSoup(html, 'lxml')
    document_map = {
        'file_name': myblob.name,
        'file_uri': myblob.uri,
        'content': soup.text,
        "structure": []
    }      

    title = '' 
    section = ''   
    title = soup.title.string if soup.title else "No title"
    
    for tag in soup.find_all(['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', 'table']):
        if tag.name in ['h2', 'h3', 'h4', 'h5', 'h6']:
            section = tag.get_text(strip=True)
        elif tag.name == 'h1':
            title = tag.get_text(strip=True)  
        elif tag.name == 'p' and tag.get_text(strip=True):
            document_map["structure"].append({
                "type": "text", 
                "text": tag.get_text(strip=True),
                "title": title,
                "section": section,
                "page_number": 1                
                })       
        elif tag.name == 'table' and tag.get_text(strip=True):
            document_map["structure"].append({
                "type": "table", 
                "text": str(tag),
                "title": title,
                "section": section,
                "page_number": 1                
                })           
            
    
    # Output document map to log container
    json_str = json.dumps(document_map, indent=2)
    file_name, file_extension, file_directory  = get_filename_and_extension(myblob.name)
    output_filename =  file_name + "_Document_Map" + file_extension + ".json"
    write_blob(azure_blob_log_storage_container, json_str, output_filename, file_directory)  
  
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
    
    # Get file extension
    file_extension = os.path.splitext(myblob.name)[1][1:].lower()
    
    if file_extension == 'pdf':
        statusLog.upsert_document(myblob.name, 'Analyzing PDF', StatusClassification.INFO)
        # Process pdf file        
        # [START extract_layout]
        logging.info("PDF file detected")        
        endpoint = os.environ["AZURE_FORM_RECOGNIZER_ENDPOINT"]
        key = os.environ["AZURE_FORM_RECOGNIZER_KEY"]
        logging.info(f"Calling form recognizer \n")
        document_analysis_client = DocumentAnalysisClient(
            endpoint=endpoint, credential=AzureKeyCredential(key)
        ) 
        statusLog.upsert_document(myblob.name, 'Calling Form Recognizer', StatusClassification.INFO)               
        if TARGET_PAGES == "ALL":
            poller = document_analysis_client.begin_analyze_document_from_url(
                "prebuilt-layout", document_url=source_blob_path
            )
        else :
            poller = document_analysis_client.begin_analyze_document_from_url(
                "prebuilt-layout", document_url=source_blob_path, pages=TARGET_PAGES, api_version=FR_API_VERSION
            )        
        result = poller.result()
        statusLog.upsert_document(myblob.name, 'Form Recognizer response received', StatusClassification.INFO)
        logging.info(f"Form Recognizer has returned results \n")
        statusLog.upsert_document(myblob.name, 'Starting document map build', StatusClassification.INFO)
        document_map = build_document_map_pdf(myblob, result)
        statusLog.upsert_document(myblob.name, 'Starting document map build complete, starting chunking', StatusClassification.INFO)
        build_chunks(document_map, myblob)
        statusLog.upsert_document(myblob.name, 'Chunking complete', StatusClassification.INFO)    
        
    elif file_extension in ['htm', 'html']:
        # Process html file
        logging.info("PDF file detected")
        statusLog.upsert_document(myblob.name, 'Analyzing HTML', StatusClassification.INFO)
        # Download the content from the URL
        response = requests.get(source_blob_path)
        if response.status_code == 200:
            html = response.text   
            statusLog.upsert_document(myblob.name, 'Starting document map build', StatusClassification.INFO)
            document_map = build_document_map_html(myblob, html)
            statusLog.upsert_document(myblob.name, 'Document map build complete, starting chunking', StatusClassification.INFO)
            build_chunks(document_map, myblob) 
            statusLog.upsert_document(myblob.name, 'Chunking complete', StatusClassification.INFO)
        
    elif file_extension in ['docx']:      
        logging.info("Office file detected")
        statusLog.upsert_document(myblob.name, 'Analyzing DocX', StatusClassification.INFO)
        response = requests.get(source_blob_path)
        # Ensure the request was successful
        response.raise_for_status()
        # Create a BytesIO object from the content of the response
        docx_file = BytesIO(response.content)
        # Convert the downloaded Word document to HTML
        result = mammoth.convert_to_html(docx_file)
        statusLog.upsert_document(myblob.name, 'HTML generated from DocX', StatusClassification.INFO)
        html = result.value # The generated HTML
        statusLog.upsert_document(myblob.name, 'Starting document map build', StatusClassification.INFO)
        document_map = build_document_map_html(myblob, html)
        statusLog.upsert_document(myblob.name, 'Document map build complete, starting chunking', StatusClassification.INFO)
        build_chunks(document_map, myblob) 
        statusLog.upsert_document(myblob.name, 'Chunking complete', StatusClassification.INFO)

           
        
    else:
        # Unknown file type
        logging.info("Unknown file type")
 
    statusLog.upsert_document(myblob.name, 'Chunking complete', StatusClassification.INFO)
    logging.info(f"Done!\n")