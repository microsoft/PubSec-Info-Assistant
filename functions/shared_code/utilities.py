# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import logging
import json
import html
from datetime import datetime
from enum import Enum
import zipfile
import os
from azure.storage.blob import BlobServiceClient
from shared_code.utilities_helper import UtilitiesHelper
from nltk.tokenize import sent_tokenize
import tiktoken
import nltk
# Try to download using nltk.download
nltk.download('punkt')
from bs4 import BeautifulSoup

punkt_dir = os.path.join(nltk.data.path[0], 'tokenizers/punkt')

# Check if the 'punkt' directory exists
if not os.path.exists(punkt_dir):
    punkt_zip_path = os.path.join(nltk.data.path[0], 'tokenizers/punkt.zip')

    # If the 'punkt.zip' file exists, unzip it
    if os.path.exists(punkt_zip_path):
        with zipfile.ZipFile(punkt_zip_path, 'r') as zip_ref:
            zip_ref.extractall(os.path.join(nltk.data.path[0], 'tokenizers/'))
    else:
        raise Exception("Failed to download 'punkt' package")

class ParagraphRoles(Enum):
    """ Enum to define the priority of paragraph roles """
    PAGE_HEADER      = 1
    TITLE           = 2
    SECTION_HEADING  = 3
    OTHER           = 3
    FOOTNOTE        = 5
    PAGE_FOOTER      = 6
    PAGE_NUMBER      = 7

class ContentType(Enum):
    """ Enum to define the types for various content chars returned from FR """
    NOT_PROCESSED           = 0
    TITLE_START             = 1
    TITLE_CHAR              = 2
    TITLE_END               = 3
    SECTIONHEADING_START    = 4
    SECTIONHEADING_CHAR     = 5
    SECTIONHEADING_END      = 6
    TEXT_START              = 7
    TEXT_CHAR               = 8
    TEXT_END                = 9
    TABLE_START             = 10
    TABLE_CHAR              = 11
    TABLE_END               = 12

class MediaType:
    """ Helper class for standard media values"""
    TEXT = "text"
    IMAGE = "image"
    MEDIA = "media"    

class Utilities:
       
    """ Class to hold utility functions """
    def __init__(self,
                 azure_blob_storage_account,
                 azure_blob_storage_endpoint,
                 azure_blob_drop_storage_container,
                 azure_blob_content_storage_container,
                 azure_blob_storage_key
                 ):
        self.azure_blob_storage_account = azure_blob_storage_account
        self.azure_blob_storage_endpoint = azure_blob_storage_endpoint
        self.azure_blob_drop_storage_container = azure_blob_drop_storage_container
        self.azure_blob_content_storage_container = azure_blob_content_storage_container
        self.azure_blob_storage_key = azure_blob_storage_key
        self.utilities_helper = UtilitiesHelper(azure_blob_storage_account,
                                                azure_blob_storage_endpoint,
                                                azure_blob_storage_key)

    def write_blob(self, output_container, content, output_filename, folder_set=""):
        """ Function to write a generic blob """
        # folder_set should be in the format of "<my_folder_name>/"
        # Get path and file name minus the root container
        blob_service_client = BlobServiceClient(
            self.azure_blob_storage_endpoint,
            self.azure_blob_storage_key)
        block_blob_client = blob_service_client.get_blob_client(
            container=output_container, blob=f'{folder_set}{output_filename}')
        block_blob_client.upload_blob(content, overwrite=True)

    def sort_key(self, element):
        """ Function to sort elements by page number and role priority """
        return element["page_number"]
        # to do, more complex sorting logic to cope with indented bulleted lists
        # return (element["page_number"], element["role_priority"],
        # element["bounding_region"][0]["x"], element["bounding_region"][0]["y"])

    def get_filename_and_extension(self, path):
        """ Function to return the file name & type"""
        return self.utilities_helper.get_filename_and_extension(path)
    
    def  get_blob_and_sas(self, blob_path):
        """ Function to retrieve the uri and sas token for a given blob in azure storage"""
        return self.utilities_helper.get_blob_and_sas(blob_path)

    # def table_to_html(self, table):
    #     """ Function to take an output FR table json structure and convert to HTML """
    #     header_processing_complete = False
    #     table_html = "<table>"
    #     rows = [sorted([cell for cell in table["cells"] if cell["rowIndex"] == i],
    #                    key=lambda cell: cell["columnIndex"]) for i in range(table["rowCount"])]
    #     for row_cells in rows:
    #         is_row_a_header = False
    #         row_html = "<tr>"
    #         for cell in row_cells:
    #             tag = "td"
    #             #if hasattr(cell, 'kind'):
    #             if 'kind' in cell:                      
    #                 if (cell["kind"] == "columnHeader" or cell["kind"] == "rowHeader"):
    #                     tag = "th"
    #                 if (cell["kind"] == "columnHeader"):
    #                     is_row_a_header = True
    #             else:
    #                 # we have encountered a cell that isn't tagged as a header, 
    #                 # so assume we have now rerached regular table cells
    #                 header_processing_complete = True
    #             cell_spans = ""
    #             #if hasattr(cell, 'columnSpan'):
    #             if 'columnSpan' in cell:
    #                 if cell["columnSpan"] > 1:
    #                     cell_spans += f" colSpan={cell['columnSpan']}"
    #             #if hasattr(cell, 'rowSpan'):
    #             if 'rowSpan' in cell:
    #                 if cell["rowSpan"] > 1:
    #                     cell_spans += f" rowSpan={cell['rowSpan']}"
    #             row_html += f"<{tag}{cell_spans}>{html.escape(cell['content'])}</{tag}>"
    #         row_html += "</tr>"
            
    #         if is_row_a_header and header_processing_complete == False:
    #             row_html = "<thead>" + row_html + "</thead>"     
    #         table_html += row_html
    #     table_html += "</table>"
    #     return table_html






    def table_to_html(self, table):
        """ Function to take an output FR table json structure and convert to HTML """
        table_html = "<table>"
        rows = [sorted([cell for cell in table["cells"] if cell["rowIndex"] == i],
                       key=lambda cell: cell["columnIndex"]) for i in range(table["rowCount"])]
        thead_open_added = False
        thead_closed_added = False 

        for i, row_cells in enumerate(rows):
            is_row_a_header = False
            row_html = "<tr>"
            for cell in row_cells:
                tag = "td"
                if 'kind' in cell:                      
                    if (cell["kind"] == "columnHeader" or cell["kind"] == "rowHeader"):
                        tag = "th"
                    if (cell["kind"] == "columnHeader"):
                        is_row_a_header = True
                cell_spans = ""
                if 'columnSpan' in cell:
                    if cell["columnSpan"] > 1:
                        cell_spans += f" colSpan={cell['columnSpan']}"
                if 'rowSpan' in cell:
                    if cell["rowSpan"] > 1:
                        cell_spans += f" rowSpan={cell['rowSpan']}"
                row_html += f"<{tag}{cell_spans}>{html.escape(cell['content'])}</{tag}>"
            row_html += "</tr>"
            
            # add the opening thead if this is the first row and the first header row encountered
            if is_row_a_header and i == 0 and not thead_open_added:
                row_html = "<thead>" + row_html 
                thead_open_added = True 
                            
            # add the closing thead if we have added an opening thead and if this is not a header row
            if not is_row_a_header and thead_open_added and not thead_closed_added:
                row_html = "</thead>" + row_html                 
                thead_closed_added = True
                
            table_html += row_html
        table_html += "</table>"
        return table_html






    def build_document_map_pdf(self, myblob_name, myblob_uri, result, azure_blob_log_storage_container, enable_dev_code):
        """ Function to build a json structure representing the paragraphs in a document, 
        including metadata such as section heading, title, page number, etc.
        We construct this map from the Content key/value output of FR, because the paragraphs 
        value does not distinguish between a table and a text paragraph"""

        document_map = {
            'file_name': myblob_name,
            'file_uri': myblob_uri,
            'content': result["content"],
            "structure": [],
            "content_type": [],
            "table_index": []
        }
        document_map['content_type'].extend([ContentType.NOT_PROCESSED] * len(result['content']))
        document_map['table_index'].extend([-1] * len(result["content"]))

        # update content_type array where spans are tables
        for index, table in enumerate(result["tables"]):
            # initialize start_char and end_char based on the first span
            start_char = table["spans"][0]["offset"]
            end_char = start_char + table["spans"][0]["length"] - 1
            
            # iterate over the remaining spans
            for span in table["spans"][1:]:
                span_start = span["offset"]
                # update start_char to the minimum offset
                start_char = min(start_char, span_start)
                # update total_length by adding the length of the current span
                end_char += span["length"] -1
            
            # update the content_type array
            document_map['content_type'][start_char] = ContentType.TABLE_START
            for i in range(start_char + 1, end_char):
                document_map['content_type'][i] = ContentType.TABLE_CHAR
            document_map['content_type'][end_char] = ContentType.TABLE_END
            # tag the end point in content of a table with the index of which table this is
            document_map['table_index'][end_char] = index


        # update content_type array where spans are titles, section headings or regular content,
        # BUT skip over the table paragraphs
        for paragraph in result["paragraphs"]:
            start_char = paragraph["spans"][0]["offset"]
            end_char = start_char + paragraph["spans"][0]["length"] - 1

            # if this span has already been identified as a non textual paragraph
            # such as a table, then skip over it
            if document_map['content_type'][start_char] == ContentType.NOT_PROCESSED:
                #if not hasattr(paragraph, 'role'):
                if 'role' not in paragraph:
                    # no assigned role
                    document_map['content_type'][start_char] = ContentType.TEXT_START
                    for i in range(start_char+1, end_char):
                        document_map['content_type'][i] = ContentType.TEXT_CHAR
                    document_map['content_type'][end_char] = ContentType.TEXT_END

                elif paragraph['role'] == 'title':
                    document_map['content_type'][start_char] = ContentType.TITLE_START
                    for i in range(start_char+1, end_char):
                        document_map['content_type'][i] = ContentType.TITLE_CHAR
                    document_map['content_type'][end_char] = ContentType.TITLE_END

                elif paragraph['role'] == 'sectionHeading':
                    document_map['content_type'][start_char] = ContentType.SECTIONHEADING_START
                    for i in range(start_char+1, end_char):
                        document_map['content_type'][i] = ContentType.SECTIONHEADING_CHAR
                    document_map['content_type'][end_char] = ContentType.SECTIONHEADING_END

        # store page number metadata by paragraph object
        page_number_by_paragraph = {}
        for _, paragraph in enumerate(result["paragraphs"]):
            start_char = paragraph["spans"][0]["offset"]
            page_number_by_paragraph[start_char] = paragraph["boundingRegions"][0]["pageNumber"]

        # iterate through the content_type and build the document paragraph catalog of content
        # tagging paragraphs with title and section
        main_title = ''
        current_title = ''
        current_section = ''
        start_position = 0
        page_number = 0
        for index, item in enumerate(document_map['content_type']):

            # collect page number metadata
            page_number = page_number_by_paragraph.get(index, page_number)

            match item:
                case ContentType.TITLE_START | ContentType.SECTIONHEADING_START | ContentType.TEXT_START | ContentType.TABLE_START:
                    start_position = index
                case ContentType.TITLE_END:
                    current_title =  document_map['content'][start_position:index+1]
                    # set the main title from any title elemnts on the first page concatenated
                    if main_title == '':
                        main_title = current_title
                    elif page_number == 1:
                        main_title = main_title + "; " + current_title
                case ContentType.SECTIONHEADING_END:
                    current_section = document_map['content'][start_position:index+1]
                case ContentType.TEXT_END | ContentType.TABLE_END:
                    if item == ContentType.TEXT_END:
                        property_type = 'text'
                        output_text = document_map['content'][start_position:index+1]
                    elif item == ContentType.TABLE_END:
                        # now we have reached the end of the table in the content dictionary,
                        # write out the table text to the output json document map
                        property_type = 'table'
                        table_index = document_map['table_index'][index]
                        table_json = result["tables"][table_index]
                        output_text = self.table_to_html(table_json)
                    else:
                        property_type = 'unknown'
                    document_map["structure"].append({
                        'offset': start_position,
                        'text': output_text,
                        'type': property_type,
                        'title': main_title,
                        'subtitle': current_title,
                        'section': current_section,
                        'page_number': page_number
                    })

        del document_map['content_type']
        del document_map['table_index']

        if enable_dev_code:
            # Output document map to log container
            json_str = json.dumps(document_map, indent=2)
            file_name, file_extension, file_directory  = self.get_filename_and_extension(myblob_name)
            output_filename =  file_name + "_Document_Map" + file_extension + ".json"
            self.write_blob(azure_blob_log_storage_container, json_str, output_filename, file_directory)

            # Output FR result to log container
            json_str = json.dumps(result, indent=2)
            output_filename =  file_name + '_FR_Result' + file_extension + ".json"
            self.write_blob(azure_blob_log_storage_container, json_str, output_filename, file_directory)

        return document_map

    def num_tokens_from_string(self, string: str, encoding_name: str) -> int:
        """ Function to return the number of tokens in a text string"""
        encoding = tiktoken.get_encoding(encoding_name)
        num_tokens = len(encoding.encode(string))
        return num_tokens

    def token_count(self, input_text):
        """ Function to return the number of tokens in a text string"""
        # calc token count
        # For gpt-4, gpt-3.5-turbo, text-embedding-ada-002, you need to use cl100k_base
        encoding = "cl100k_base"
        token_count = self.num_tokens_from_string(input_text, encoding)
        return token_count

    def write_chunk(self, myblob_name, myblob_uri, file_number, chunk_size, chunk_text, page_list, 
                    section_name, title_name, subtitle_name, file_class):
        """ Function to write a json chunk to blob"""
        chunk_output = {
            'file_name': myblob_name,
            'file_uri': myblob_uri,
            'file_class': file_class,
            'processed_datetime': datetime.now().isoformat(),
            'title': title_name,
            'subtitle': subtitle_name,
            'section': section_name,
            'pages': page_list,
            'token_count': chunk_size,
            'content': chunk_text                       
        }
        # Get path and file name minus the root container
        file_name, file_extension, file_directory = self.get_filename_and_extension(myblob_name)
        blob_service_client = BlobServiceClient(
            self.azure_blob_storage_endpoint,
            self.azure_blob_storage_key)
        json_str = json.dumps(chunk_output, indent=2, ensure_ascii=False)
        block_blob_client = blob_service_client.get_blob_client(
            container=self.azure_blob_content_storage_container,
            blob=self.build_chunk_filepath(file_directory, file_name, file_extension, file_number))
        block_blob_client.upload_blob(json_str, overwrite=True)

    def build_chunk_filepath (self, file_directory, file_name, file_extension, file_number):
        """ Get the folders and filename to use when creating the new file chunks """
        folder_set = file_directory + file_name + file_extension + "/"
        output_filename = file_name + f'-{file_number}' + '.json'
        return f'{folder_set}{output_filename}'
    
    previous_table_header = ""
    
    def chunk_table_with_headers(self, prefix_text, table_html, standard_chunk_target_size, 
                                 previous_paragraph_element_is_a_table):
        soup = BeautifulSoup(table_html, 'html.parser')
        thead = str(soup.find('thead'))
          
        # check if this table is a continuation of a table on a previous page. 
        # If yes then apply the header row from the previous table
        if previous_paragraph_element_is_a_table:
            if thead != "":
                # update thead to include the main table header
                thead = thead.replace("<thead>", "<thead>"+self.previous_table_header)
            
            else:
                # just use the previoud thead
                thead = "<thead>"+self.previous_table_header+"</thead>"    

        def add_current_table_chunk(chunk):
            # Close the table tag for the current chunk and add it to the chunks list
            if chunk.strip() and not chunk.endswith("<table>"):
                chunk = '<table>' + chunk + '</table>'
                chunks.append(chunk)
                # Start a new chunk with header if it exists                
        
        # Initialize chunks list
        chunks = []
        current_chunk = prefix_text
        # set the target size of the first chunk 
        chunk_target_size = standard_chunk_target_size - self.token_count(prefix_text)
        rows = soup.find_all('tr')
        # Filter out rows that are part of thead block
        filtered_rows = [row for row in rows if row.parent.name != "thead"] 
               
        for i, row in enumerate(filtered_rows):
            row_html = str(row)

            # If adding this row to the current chunk exceeds the target size, start a new chunk
            if self.token_count(current_chunk + row_html) > chunk_target_size:
                add_current_table_chunk(current_chunk)    
                current_chunk = thead
                chunk_target_size = standard_chunk_target_size                

            # Add the current row to the chunk
            current_chunk += row_html

        # Add the final chunk if there's any content left
        add_current_table_chunk(current_chunk)      

        return chunks
    
    def build_chunks(self, document_map, myblob_name, myblob_uri, chunk_target_size):
        """ Function to build chunk outputs based on the document map """

        chunk_text = ''
        chunk_size = 0
        file_number = 0
        page_number = 0
        previous_section_name = document_map['structure'][0]['section']
        previous_title_name = document_map['structure'][0]["title"]
        previous_subtitle_name = document_map['structure'][0]["subtitle"]
        page_list = []
        chunk_count = 0
        previous_paragraph_element_is_a_table = False
        
        # iterate over the paragraphs and build a chuck based on a section
        # and/or title of the document
        for index, paragraph_element in enumerate(document_map['structure']):
            paragraph_size = self.token_count(paragraph_element["text"])
            paragraph_text = paragraph_element["text"]
            section_name = paragraph_element["section"]
            title_name = paragraph_element["title"]
            subtitle_name = paragraph_element["subtitle"]

            #if the collected tokens in the current in-memory chunk + the next paragraph
            # will be larger than the allowed chunk size prepare to write out the total chunk
            if (chunk_size + paragraph_size >= chunk_target_size) or section_name != previous_section_name or title_name != previous_title_name or subtitle_name != previous_subtitle_name:
                
                # If the current paragraph just by itself is larger than CHUNK_TARGET_SIZE,
                # then we need to split this up and treat each slice as a new in-memory chunk
                if paragraph_size >= chunk_target_size:
                    
                    # We will process tables and regular text differently as text can be split by sentence boundaries, 
                    # but tables fail as the code sees a table as a single sentence.
                    # We need a speciality way of splitting a table that is greater than
                    # our target chunk size                    
                    if paragraph_element["type"] == "table":
                        # table processing & splitting
                        table_chunks = self.chunk_table_with_headers(chunk_text, 
                                                                     paragraph_text, 
                                                                     chunk_target_size,
                                                                     previous_paragraph_element_is_a_table)
                        
                        for i, table_chunk in enumerate(table_chunks):
                                                   
                            # write out each table chunk, apart from the last, as this will be less than or
                            # equal to CHUNK_TARGET_SIZE the last chunk will be processed like
                            # a regular paragraph
                            if i < len(table_chunks) - 1:
                                self.write_chunk(myblob_name, myblob_uri,
                                                f"{file_number}.{i}",
                                                self.token_count(table_chunk),
                                                table_chunk, page_list,
                                                previous_section_name, previous_title_name, previous_subtitle_name, 
                                                MediaType.TEXT)
                                chunk_count += 1      
                            else:
                                # Reset the paragraph token count to just the tokens left in the last
                                # chunk and leave the remaining text from the large paragraph to be
                                # combined with the next in the outer loop
                                paragraph_size = self.token_count(table_chunk)
                                paragraph_text = table_chunk
                                chunk_text = ''
                                file_number += 1                                
                                        
                    else:
                        # text processing & splitting
                        # start by keeping the existing in-memory chunk in front of the large paragraph
                        # and begin to process it on sentence boundaries to break it down into
                        # sub-chunks that are below the CHUNK_TARGET_SIZE
                        sentences = sent_tokenize(chunk_text + paragraph_text)
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

                        # Now write out each chunk, apart from the last, as this will be less than or
                        # equal to CHUNK_TARGET_SIZE the last chunk will be processed like
                        # a regular paragraph
                        for i, chunk_text_p in enumerate(chunks):
                            if i < len(chunks) - 1:
                                # Process all but the last chunk in this large para
                                self.write_chunk(myblob_name, myblob_uri,
                                                f"{file_number}.{i}",
                                                self.token_count(chunk_text_p),
                                                chunk_text_p, page_list,
                                                previous_section_name, previous_title_name, previous_subtitle_name, 
                                                MediaType.TEXT)
                                chunk_count += 1
                            else:
                                # Reset the paragraph token count to just the tokens left in the last
                                # chunk and leave the remaining text from the large paragraph to be
                                # combined with the next in the outer loop
                                paragraph_size = self.token_count(chunk_text_p)
                                paragraph_text = chunk_text_p
                                chunk_text = ''
                                file_number += 1
                else:
                    # if this para is not large by itself but will put us over the max token count
                    # or it is a new section, then write out the chunk text we have to this point
                    self.write_chunk(myblob_name, myblob_uri, file_number,
                                     chunk_size, chunk_text, page_list,
                                     previous_section_name, previous_title_name, previous_subtitle_name,
                                     MediaType.TEXT)
                    chunk_count += 1

                    # reset chunk specific variables
                    file_number += 1
                    page_list = []
                    chunk_text = ''
                    chunk_size = 0
                    page_number = 0

            if page_number != paragraph_element["page_number"]:
                # increment page number if necessary
                page_list.append(paragraph_element["page_number"])
                page_number = paragraph_element["page_number"]

            # add paragraph to the chunk
            chunk_size = chunk_size + paragraph_size
            chunk_text = chunk_text + "\n" + paragraph_text
            
            # store the type of paragraph and content, to be used if a table crosses page boundaries and
            # we need to apply the column headings to subsequent pages

            if paragraph_element["type"] == "table":
                previous_paragraph_element_is_a_table = True
                if self.previous_table_header == "":
                    # Stash the current tables heading to apply to subsequent page tables if they are missing column headings,
                    # but only for the first page of the multi-page table
                    soup = BeautifulSoup(paragraph_text, 'html.parser')
                    # Extract the thead and strip the thead wrapper to just leave the header cells
                    self.previous_table_header = str(soup.find('thead'))
                    self.previous_table_header = self.previous_table_header.replace("<thead>", "").replace("</thead>", "")
            else:
                previous_paragraph_element_is_a_table = False
                self.previous_table_header = ""
            
            # If this is the last paragraph then write the chunk
            if index == len(document_map['structure'])-1:
                self.write_chunk(myblob_name, myblob_uri, file_number, chunk_size,
                                 chunk_text, page_list, section_name, title_name, previous_subtitle_name,
                                 MediaType.TEXT)
                chunk_count += 1

            previous_section_name = section_name
            previous_title_name = title_name
            previous_subtitle_name = subtitle_name

        logging.info("Chunking is complete \n")
        return chunk_count
