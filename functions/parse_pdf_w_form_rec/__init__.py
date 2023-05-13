""" Python function to read PDF files and extract text using Azure Form Recognizer"""
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
import tiktoken
import nltk
nltk.download('words')
nltk.download('punkt')


XY_ROUNDING_FACTOR = 1
CHUNK_TARGET_SIZE = 750
REAL_WORDS_TARGET = 0.2
FR_API_VERSION = '2023-02-28-preview'
TARGET_PAGES = "ALL"          # ALL or Custom page numbers for multi-page documents(PDF/TIFF). Input the page numbers and/or ranges of pages you want to get in the result. For a range of pages, use a hyphen, like pages="1-3, 5-6". Separate each page number or range with a comma.
#TARGET_PAGES = "3" 
WRITE_DOCUMENT_MAP_JSON = True


azure_blob_storage_account = os.environ["AZURE_BLOB_STORAGE_ACCOUNT"]
azure_blob_drop_storage_container = os.environ["AZURE_BLOB_DROP_STORAGE_CONTAINER"]
azure_blob_content_storage_container = os.environ["AZURE_BLOB_CONTENT_STORAGE_CONTAINER"]
azure_blob_storage_key = os.environ["AZURE_BLOB_STORAGE_KEY"]


def main(myblob: func.InputStream):
    """ Function to read PDF files and extract text using Azure Form Recognizer"""    
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


def is_pdf(file_name):
    """ Function to check whether a file is a PDF """
    # Get the file extension using os.path.splitext
    file_ext = os.path.splitext(file_name)[1]
    # Return True if the extension is .pdf, False otherwise
    return file_ext == ".pdf"


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


def write_chunk(myblob, document_map, file_number, chunk_size, chunk_text, page_list, section_name, title_name):    
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
    separator = "/"
    file_path_w_name_no_cont = separator.join(myblob.name.split(separator)[1:])
    base_filename = os.path.basename(myblob.name)
    # Get the folders to use when creating the new files        
    folder_set = file_path_w_name_no_cont.removesuffix(f'/{base_filename}')
    blob_service_client = BlobServiceClient(
        f'https://{azure_blob_storage_account}.blob.core.windows.net/', azure_blob_storage_key)
    json_str = json.dumps(chunk_output, indent=2)
    output_filename = os.path.splitext(os.path.basename(base_filename))[0] + f'-{file_number}' + '.json'
    block_blob_client = blob_service_client.get_blob_client(
        container=azure_blob_content_storage_container, blob=f'{folder_set}/{os.path.basename(myblob.name)}/{output_filename}')
    block_blob_client.upload_blob(json_str, overwrite=True)   
   
        
def build_document_map(myblob, result):
    """ Function to build a json structure representing the paragraphs in a document, including metadata
        such as section heading, title, page number, eal word pernetage etc.
        We construct this map from the Content key/value output of FR, because the paragraphs value does not distinguish between
        a table and a text paragraph"""
        
    logging.info(f"Constructing the JSON structure of the document\n")        
    document_map = {
        'file_name': myblob.name,
        'file_uri': myblob.uri,
        'content': result.content,
        'content_type': list,
        "structure": [],
        "content_type": []
    }
    document_map['content_type'].extend([content_type.not_processed] * len(result.content))
   
    # update content_type array where spans are tables
    for table in result.tables:
        start_char = table.spans[0].offset
        end_char = start_char + table.spans[0].length - 1
        document_map['content_type'][start_char] = content_type.table_start
        for i in range(start_char+1, end_char):
            document_map['content_type'][i] = content_type.table_char                    
        document_map['content_type'][end_char] = content_type.table_end     
    
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
                elif item == content_type.table_end:
                    property_type = 'table'
                else:
                    property_type = 'unknown'
                document_map["structure"].append({
                    'offset': start_position,
                    'text': document_map['content'][start_position:index+1],
                    'type': property_type,
                    'title': current_title,
                    'section': current_section,
                    'page_number': page_number,
                    "bounding_region": polygon_elements   
                })                 
                
    del document_map['content_type']
    # sort to order columns in the document logically
    document_map['structure'].sort(key=sort_key)
    
    if WRITE_DOCUMENT_MAP_JSON is True:
        json_str = json.dumps(document_map, indent=2)
        with open("document_map.json", 'w') as file:
            file.write(json_str)        
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
                
        if index == 16:
            print('hello')
                
                
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
        
        # Now process this paragraph if it passes the minimum threshold for real words - if it is real text
        if contains_real_words(paragraph_element["text"]) is True:
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
            
            
            
            
            
        # If the token max size is reached or if is a new section or title or if this is 
        # the last paragraph in the document map, then write out the file
        # if (target_size_reached == True or 
        #     section_name != previous_section_name or 
        #     title_name != previous_title_name or
        #     index == len(document_map['structure'])
        #     ) and chunk_text != '':
        #     # if it's a new section or new title then write out file and if there is text to write            
        #     chunk_output = {
        #         'file_name': document_map['file_name'],
        #         'file_uri': document_map['file_uri'],
        #         'processed_datetime': datetime.now().isoformat(),
        #         'title': title_name,
        #         'section': section_name,
        #         'pages': page_list,
        #         'token_count': chunk_size,
        #         'content': chunk_text                       
        #    }            
            # json_str = json.dumps(chunk_output, indent=2)
            # output_filename = os.path.splitext(os.path.basename(base_filename))[0] + f'-{file_number}' + '.json'
            # block_blob_client = blob_service_client.get_blob_client(
            #     container=azure_blob_content_storage_container, blob=f'{folder_set}/{os.path.basename(myblob.name)}/{output_filename}')
            # block_blob_client.upload_blob(json_str, overwrite=True)      
            # write_chunk(myblob, chunk_output, file_number)     
 
            # reset counters
            # file_number += 1
            # page_list = [] 
            # previous_section_name = section_name       
            # previous_title_name = title_name
            
            
            
            
            # # if we wrote the file because we hit the token target, then start with the last paragraph processed
            # if target_size_reached is True:
            #     page_list.append(paragraph_element["page_number"]) 
            #     chunk_text = paragraph_element["text"]
            #     chunk_size = paragraph_size   
            #     target_size_reached = False 
            # else:
            #     chunk_text = ""
            #     chunk_size = 0     
                   
                   
                   
                   
        

    

    
    
    
    
    # # extract the content by paragraph with title, sectionHeading & pageHeader and write as a chunk
    # logging.info(f"Extracting chunks form the document json structure \n")
    # blob_service_client = BlobServiceClient(
    # f'https://{azure_blob_storage_account}.blob.core.windows.net/', azure_blob_storage_key)
    # file_number = 0
    # chunk_text = ""
    # chunk_size = 0
    # paragraph_size = 0
    # section_name = ""
    # title_name = ""
    # target_size_reached = False
    
    # for paragraph_element in pargraph_elements:   

    #     if paragraph_element["role"] is None and contains_real_words(paragraph_element["content"]) is True:
    #         title_name = paragraph_element["title"]
    #         section_name = paragraph_element["section_heading"]
    #         # build chunck from paragraphs until target size is reached  
    #         paragraph_size = token_count(paragraph_element["content"])
    #         if chunk_size + paragraph_size <= CHUNK_TARGET_SIZE:
    #             chunk_size = chunk_size + paragraph_size
    #             chunk_text = chunk_text + "\n" + paragraph_element["content"]
    #         else:
    #             # if target chunk size is hit then write out file
    #             target_size_reached = True 

    #     if (paragraph_element["role"] != None or target_size_reached == True) and chunk_text != ""  :
    #         # if its a new section then write out file and if there is text to write
    #         chunk_output = title_name + "\n" + \
    #             section_name + "\n\n" + \
    #             chunk_text       
    #         output_filename = os.path.splitext(os.path.basename(base_filename))[0] + f"-{file_number}" + ".txt"
    #         block_blob_client = blob_service_client.get_blob_client(
    #             container=azure_blob_content_storage_container, blob=f'{folder_set}/{os.path.basename(myblob.name)}/{output_filename}')
    #         block_blob_client.upload_blob(chunk_output.encode('utf-8'), overwrite=True)

    #         # reset counters
    #         file_number += 1            

    #         # if we wrote the file because we hit the token target, then start with the last paragraph porcessed
    #         if target_size_reached is True:
    #             chunk_text = paragraph_element["content"]
    #             chunk_size = paragraph_size   
    #             target_size_reached = False 
    #         else:
    #             chunk_text = ""
    #             chunk_size = 0     
    
    
    
    
    logging.info(f"Chunking is complete \n")
        
        

def analyze_layout(myblob: func.InputStream):
    """ Function to analyze the layout of a PDF file and extract text using Azure Form Recognizer"""
 
    if is_pdf(myblob.name):
        source_blob_path = get_blob_and_sas(myblob)

    # [START extract_layout]
    logging.info(f"Calling form recognizer \n")
    endpoint = os.environ["AZURE_FORM_RECOGNIZER_ENDPOINT"]
    key = os.environ["AZURE_FORM_RECOGNIZER_KEY"]

    document_analysis_client = DocumentAnalysisClient(
        endpoint=endpoint, credential=AzureKeyCredential(key)
    )
 
    if TARGET_PAGES == "ALL":
        poller = document_analysis_client.begin_analyze_document_from_url(
            "prebuilt-layout", document_url=source_blob_path
        )
    else :
        poller = document_analysis_client.begin_analyze_document_from_url(
            "prebuilt-layout", document_url=source_blob_path, pages=TARGET_PAGES, api_version=FR_API_VERSION
        )        
    result = poller.result()
    logging.info(f"Form Recognizer has returned results \n") 

    document_map = build_document_map(myblob, result)        
    build_chunks(document_map, myblob)     
   
    logging.info(f"Done!\n")