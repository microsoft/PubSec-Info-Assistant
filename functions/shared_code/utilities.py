# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import logging
import os
import json
from azure.storage.blob import generate_blob_sas, BlobSasPermissions, BlobServiceClient
from datetime import datetime, timedelta
from azure.storage.blob import generate_blob_sas, BlobSasPermissions, BlobServiceClient
import logging
import os
from enum import Enum
from datetime import datetime, timedelta
import json
import html
import json
import tiktoken
from nltk.tokenize import sent_tokenize


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

        if directory == "/": directory = ""

        file_name, file_extension = os.path.splitext(base_name)    

        return file_name, file_extension, directory
    
    # def get_filename_and_extension(self, path):
    #     """ Function to return the file name & type"""
    #     # Split the path into base and extension
    #     base_name = os.path.basename(path)
    #     segments = path.split("/")
    #     directory = "/".join(segments[1:-1]) + "/"
    #     file_name, file_extension = os.path.splitext(base_name)    
    #     return file_name, file_extension, directory
    
    
    def table_to_html(self, table):
        """ Function to take an output FR table json structure and convert to HTML """
        table_html = "<table>"
        rows = [sorted([cell for cell in table.cells if cell.rowIndex == i], key=lambda cell: cell.columnIndex) for i in range(table.rowCount)]
        for row_cells in rows:
            table_html += "<tr>"
            for cell in row_cells:
                tag = "td"
                if hasattr(cell, 'kind'):
                    if (cell.kind == "columnHeader" or cell.kind == "rowHeader"):
                        tag = "th"                   
                cell_spans = ""
                if hasattr(cell, 'columnSpan'):
                    if cell.columnSpan > 1: cell_spans += f" colSpan={cell.columnSpan}"
                if hasattr(cell, 'rowSpan'):             
                    if cell.rowSpan > 1: cell_spans += f" rowSpan={cell.rowSpan}"
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
    
    
    def num_tokens_from_string(self, string: str, encoding_name: str) -> int:
        """ Function to return the number of tokens in a text string"""
        encoding = tiktoken.get_encoding(encoding_name)
        num_tokens = len(encoding.encode(string))
        return num_tokens

    
    def token_count(self, input_text):
        """ Function to return the number of tokens in a text string"""
        # calc token count
        encoding = "cl100k_base"    # For gpt-4, gpt-3.5-turbo, text-embedding-ada-002, you need to use cl100k_base
        token_count = self.num_tokens_from_string(input_text, encoding)
        return token_count 
        
        
    def write_chunk(self, myblob_name, myblob_uri, file_number, chunk_size, chunk_text, page_list, section_name, title_name):
        """ Function to write a json chunk to blob"""
        chunk_output = {
            'file_name': myblob_name,
            'file_uri': myblob_uri,
            'processed_datetime': datetime.now().isoformat(),
            'title': title_name,
            'section': section_name,
            'pages': page_list,
            'token_count': chunk_size,
            'content': chunk_text                       
        }                
        # Get path and file name minus the root container
        file_name, file_extension, file_directory = self.get_filename_and_extension(myblob_name)
        # Get the folders to use when creating the new files        
        folder_set = file_directory + file_name + file_extension + "/"
        blob_service_client = BlobServiceClient(
            f'https://{self.azure_blob_storage_account}.blob.core.windows.net/',self.azure_blob_storage_key)
        json_str = json.dumps(chunk_output, indent=2, ensure_ascii=False)
        output_filename = file_name + f'-{file_number}' + '.json'
        block_blob_client = blob_service_client.get_blob_client(
            container=self.azure_blob_content_storage_container, blob=f'{folder_set}{output_filename}')
        block_blob_client.upload_blob(json_str, overwrite=True)   
        
        
    def build_chunks(self, document_map, myblob_name, myblob_uri, chunk_target_size):
        """ Function to build chunk outputs based on the document map """
        
        chunk_text = ''
        chunk_size = 0    
        file_number = 0
        page_number = 0
        previous_section_name = document_map['structure'][0]['section']
        previous_title_name = document_map['structure'][0]["title"]
        page_list = []   
        
        # iterate over the paragraphs and build a chuck based on a section and/or title of the document
        for index, paragraph_element in enumerate(document_map['structure']):          
            # if this paragraph would put the chunk_size greater than the target token size, OR
            # if this is a new (section OR title)
            # then write out the stash of content from previous loops and start a new chunk
            paragraph_size = self.token_count(paragraph_element["text"])
            section_name = paragraph_element["section"]
            title_name = paragraph_element["title"]
            
            # If this para just by itself is larger than CHUNK_TARGET_SIZE, then we need to split this up 
            # and treat each slice as a new para and. Build a list of chunks that fall under the max size
            # and ensure the first chunk, which will be added to the current                
            if (chunk_size + paragraph_size >= chunk_target_size and index > 0) or section_name != previous_section_name or title_name != previous_title_name:
                # if this para will put us over the max token count or it is a new section, then write out the chunk text we have to this point 
                self.write_chunk(myblob_name, myblob_uri, file_number, chunk_size, chunk_text, page_list, previous_section_name, previous_title_name) 
                # reset chunk specific variables 
                file_number += 1
                page_list = [] 
                chunk_text = ''
                chunk_size = 0  
                page_number = 0   

            if paragraph_size >= chunk_target_size:
                # If this para just by itself is larger than CHUNK_TARGET_SIZE, then we need to split this up 
                # and treat each slice as a new para 
                    
                sentences = sent_tokenize(paragraph_element["text"])
                chunks = []
                chunk = ""
                for sentence in sentences:
                    temp_chunk = chunk + " " + sentence if chunk else sentence
                    if self.token_count(temp_chunk) <= chunk_target_size:
                        chunk = temp_chunk
                    else:
                        chunks.append(chunk)
                        chunk = sentence
                if chunk:
                    chunks.append(chunk)
            
                # Now write out each chunk, apart from teh last, as this will be less than or equal to CHUNK_TARGET_SIZE
                # the last chunk will be processed like a regular para
                for i, chunk_text in enumerate(chunks):
                    if i < len(chunks) - 1:
                        # Process all but the ;ast chunk in this large para
                        self.write_chunk(myblob_name, myblob_uri, f"{file_number}.{i}", self.token_count(chunk_text), chunk_text, page_list, previous_section_name, previous_title_name) 
                    else:
                        # Reset the paragraph token count to just the tokens left in the last chunk
                        paragraph_size = self.token_count(chunk_text)          
            
            if page_number != paragraph_element["page_number"]:
                # increment page number if necessary
                page_list.append(paragraph_element["page_number"])
                page_number = paragraph_element["page_number"]   

            # add paragraph to the chunk
            chunk_size = chunk_size + paragraph_size
            chunk_text = chunk_text + "\n" + paragraph_element["text"]

            # If this is the last paragraph then write the chunk
            if index == len(document_map['structure'])-1:
                self.write_chunk(myblob_name, myblob_uri, file_number, chunk_size, chunk_text, page_list, section_name, title_name) 
                
            previous_section_name = section_name
            previous_title_name = title_name    
        
        logging.info(f"Chunking is complete \n")