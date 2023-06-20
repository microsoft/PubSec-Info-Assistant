# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import logging
import os
import json
from azure.storage.blob import generate_blob_sas, BlobSasPermissions, BlobServiceClient
from datetime import datetime, timedelta
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
from nltk.tokenize import sent_tokenize
# from shared_code import status_log as Status
from shared_code.status_log import StatusLog, State, StatusClassification, StatusQueryLevel


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
    


class Utilities:
    
   
    def __init__(self, 
                 azure_blob_storage_account,
                 azure_blob_drop_storage_container,
                 azure_blob_content_storage_container,
                 azure_blob_storage_key
                 ):
        self.azure_blob_storage_account = azure_blob_storage_account
        self.azure_blob_drop_storage_container = azure_blob_drop_storage_container
        self.azure_blob_content_storage_container = azure_blob_content_storage_container
        self.azure_blob_storage_key = azure_blob_storage_key    
        
        
    def write_blob(self, output_container, content, output_filename, folder_set=""):
        """ Function to write a generic blob """
        # folder_set should be in the format of "<my_folder_name>/"
        # Get path and file name minus the root container
        blob_service_client = BlobServiceClient(f'https://{self.azure_blob_storage_account}.blob.core.windows.net/', self.azure_blob_storage_key)
        block_blob_client = blob_service_client.get_blob_client(container=output_container, blob=f'{folder_set}{output_filename}')
        block_blob_client.upload_blob(content, overwrite=True)   
        

    def sort_key(self, element):
        """ Function to sort elements by page number and role priority """
        return (element["page_number"])
        # to do, more complex sorting logic to cope with indented bulleted lists
        # return (element["page_number"], element["role_priority"], element["bounding_region"][0]["x"], element["bounding_region"][0]["y"])
        
    
    def get_filename_and_extension(self, path):
        """ Function to return the file name & type"""
        # Split the path into base and extension
        base_name = os.path.basename(path)
        segments = path.split("/")
        directory = "/".join(segments[1:-1]) + "/"
        file_name, file_extension = os.path.splitext(base_name)    
        return file_name, file_extension, directory
    
    
    def table_to_html(self, table):
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
    
    
    def  get_blob_and_sas(self, blob_path):
        """ Function to retrieve the uri and sas token for a given blob in azure storage"""
        logging.info("processing pdf " + blob_path)
        base_filename = os.path.basename(blob_path)

        # Get path and file name minus the root container
        separator = "/"
        file_path_w_name_no_cont = separator.join(
            blob_path.split(separator)[1:])

        # Gen SAS token
        sas_token = generate_blob_sas(
            account_name=self.azure_blob_storage_account,
            container_name=self.azure_blob_drop_storage_container,
            blob_name=file_path_w_name_no_cont,
            account_key=self.azure_blob_storage_key,
            permission=BlobSasPermissions(read=True),
            expiry=datetime.utcnow() + timedelta(hours=1)
        )
        source_blob_path = f'https://{self.azure_blob_storage_account}.blob.core.windows.net/{blob_path}?{sas_token}'
        source_blob_path = source_blob_path.replace(" ", "%20")        
        logging.info(f"Path and SAS token for file in azure storage are now generated \n")
        return source_blob_path
    
    
    def build_document_map_pdf(self, myblob_name, myblob_uri, result, result_dict, azure_blob_log_storage_container):
        """ Function to build a json structure representing the paragraphs in a document, including metadata
        such as section heading, title, page number, eal word pernetage etc.
        We construct this map from the Content key/value output of FR, because the paragraphs value does not distinguish between
        a table and a text paragraph"""
            
        logging.info(f"Constructing the JSON structure of the document\n")        
        document_map = {
            'file_name': myblob_name,
            'file_uri': myblob_uri,
            'content': result.content,
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
                if hasattr(paragraph, 'role') == False:
                    # no assigned role
                    document_map['content_type'][start_char] = content_type.text_start
                    for i in range(start_char+1, end_char):
                        document_map['content_type'][i] = content_type.text_char
                    document_map['content_type'][end_char] = content_type.text_end 
                    
                elif paragraph.role == 'title':
                    document_map['content_type'][start_char] = content_type.title_start
                    for i in range(start_char+1, end_char):
                        document_map['content_type'][i] = content_type.title_char                    
                    document_map['content_type'][end_char] = content_type.title_end                          
                    
                elif paragraph.role == 'sectionHeading':                               
                    document_map['content_type'][start_char] = content_type.sectionheading_start
                    for i in range(start_char+1, end_char):
                        document_map['content_type'][i] = content_type.sectionheading_char                    
                    document_map['content_type'][end_char] = content_type.sectionheading_end                     
                        
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
                    page_number = result.paragraphs[current_paragraph_index].boundingRegions[0].pageNumber
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
                        output_text = self.table_to_html(table_json)
                    else:
                        property_type = 'unknown'
                    document_map["structure"].append({
                        'offset': start_position,
                        'text': output_text,
                        'type': property_type,
                        'title': current_title,
                        'section': current_section,
                        'page_number': page_number
                    })                 
                    
        del document_map['content_type']
        del document_map['table_index']
        
        # Output document map to log container
        json_str = json.dumps(document_map, indent=2)
        file_name, file_extension, file_directory  = self.get_filename_and_extension(myblob_name)
        output_filename =  file_name + "_Document_Map" + file_extension + ".json"
        self.write_blob(azure_blob_log_storage_container, json_str, output_filename, file_directory)
        
        # Output FR result to log container
        json_str = json.dumps(result_dict, indent=2)
        output_filename =  file_name + '_FR_Result' + file_extension + ".json"
        self.write_blob(azure_blob_log_storage_container, json_str, output_filename, file_directory)
        
        logging.info(f"Constructing the JSON structure of the document complete\n")  
        return document_map      