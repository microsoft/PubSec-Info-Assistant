import json
import logging
import os

import azure.functions as func
import requests
from azure.ai.vision.imageanalysis import ImageAnalysisClient
from azure.ai.vision.imageanalysis.models import VisualFeatures
from azure.storage.blob import BlobServiceClient
from azure.identity import ManagedIdentityCredential, DefaultAzureCredential, get_bearer_token_provider, AzureAuthorityHosts
from shared_code.status_log import State, StatusClassification, StatusLog
from shared_code.utilities import Utilities, MediaType
from azure.search.documents import SearchClient
from datetime import datetime

azure_blob_storage_account = os.environ["BLOB_STORAGE_ACCOUNT"]
azure_blob_drop_storage_container = os.environ[
    "BLOB_STORAGE_ACCOUNT_UPLOAD_CONTAINER_NAME"
]
azure_blob_content_storage_container = os.environ[
    "BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME"
]
azure_blob_storage_endpoint = os.environ["BLOB_STORAGE_ACCOUNT_ENDPOINT"]
azure_blob_content_storage_container = os.environ[
    "BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME"
]
azure_blob_content_storage_container = os.environ[
    "BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME"
]
# Authentication settings
azure_authority_host = os.environ["AZURE_OPENAI_AUTHORITY_HOST"]
local_debug = os.environ.get("LOCAL_DEBUG", False)

# Cosmos DB
cosmosdb_url = os.environ["COSMOSDB_URL"]
cosmosdb_key = os.environ["COSMOSDB_KEY"]
cosmosdb_log_database_name = os.environ["COSMOSDB_LOG_DATABASE_NAME"]
cosmosdb_log_container_name = os.environ["COSMOSDB_LOG_CONTAINER_NAME"]

# Cognitive Services
azure_ai_endpoint = os.environ["AZURE_AI_ENDPOINT"]
azure_ai_location = os.environ["AZURE_AI_LOCATION"]
azure_ai_credential_domain = os.environ["AZURE_AI_CREDENTIAL_DOMAIN"]

# Search Service
AZURE_SEARCH_SERVICE_ENDPOINT = os.environ.get("AZURE_SEARCH_SERVICE_ENDPOINT")
AZURE_SEARCH_INDEX = os.environ.get("AZURE_SEARCH_INDEX") or "gptkbindex"

if azure_authority_host == "AzureUSGovernment":
    AUTHORITY = AzureAuthorityHosts.AZURE_GOVERNMENT
else:
    AUTHORITY = AzureAuthorityHosts.AZURE_PUBLIC_CLOUD
if local_debug:
    azure_credential = DefaultAzureCredential(authority=AUTHORITY)
else:
    azure_credential = ManagedIdentityCredential(authority=AUTHORITY)
token_provider = get_bearer_token_provider(azure_credential,
                                           f'https://{azure_ai_credential_domain}/.default')

# Translation params for OCR'd text
targetTranslationLanguage = os.environ["TARGET_TRANSLATION_LANGUAGE"]

API_DETECT_ENDPOINT = (
    f"{azure_ai_endpoint}translator/text/v3.0/detect"
)
API_TRANSLATE_ENDPOINT = (
    f"{azure_ai_endpoint}translator/text/v3.0/translate"
)

MAX_CHARS_FOR_DETECTION = 1000
translator_api_headers = {
    "Auhorization": f"Bearer {token_provider()}",
    "Content-type": "application/json",
    "Ocp-Apim-Subscription-Region": azure_ai_location,
}

# Note that "cation" and "denseCaptions" are only supported in Azure GPU regions (East US, France Central,
# Korea Central, North Europe, Southeast Asia, West Europe, West US). Remove "caption" and "denseCaptions"
# from the list below if your Computer Vision key is not from one of those regions.

if azure_ai_location in [
    "eastus",
    "francecentral",
    "koreacentral",
    "northeurope",
    "southeastasia",
    "westeurope",
    "westus",
]:
    GPU_REGION = True
    visual_features = [VisualFeatures.CAPTION,
                          VisualFeatures.DENSE_CAPTIONS,
                          VisualFeatures.OBJECTS,
                          VisualFeatures.TAGS,
                          VisualFeatures.READ]
else:
    GPU_REGION = False
    visual_features = [VisualFeatures.OBJECTS,
                       VisualFeatures.TAGS,
                       VisualFeatures.READ]

vision_client = ImageAnalysisClient(
        endpoint=azure_ai_endpoint,
        credential=azure_credential
    )

FUNCTION_NAME = "ImageEnrichment"

utilities = Utilities(
    azure_blob_storage_account=azure_blob_storage_account,
    azure_blob_storage_endpoint=azure_blob_storage_endpoint,
    azure_blob_drop_storage_container=azure_blob_drop_storage_container,
    azure_blob_content_storage_container=azure_blob_content_storage_container,
    azure_credential=azure_credential
)


def detect_language(text):
    data = [{"text": text[:MAX_CHARS_FOR_DETECTION]}]
    response = requests.post(
        API_DETECT_ENDPOINT, headers=translator_api_headers, json=data
    )
    if response.status_code == 200:
        print(response.json())
        detected_language = response.json()[0]["language"]
        detection_confidence = response.json()[0]["score"]

    return detected_language, detection_confidence


def translate_text(text, target_language):
    data = [{"text": text}]
    params = {"to": target_language}

    response = requests.post(
        API_TRANSLATE_ENDPOINT, headers=translator_api_headers, json=data, params=params
    )
    if response.status_code == 200:
        translated_content = response.json()[0]["translations"][0]["text"]
        return translated_content
    else:
        raise Exception(response.json())


def main(msg: func.QueueMessage) -> None:
    """This function is triggered by a message in the image-enrichment-queue.
    It will first analyse the image. If the image contains text, it will then
    detect the language of the text and translate it to Target Language. """

    message_body = msg.get_body().decode("utf-8")
    message_json = json.loads(message_body)
    blob_path = message_json["blob_name"]
    blob_uri = message_json["blob_uri"]
    try:
        statusLog = StatusLog(
            cosmosdb_url, cosmosdb_key, cosmosdb_log_database_name, cosmosdb_log_container_name
        )
        logging.info(
            "Python queue trigger function processed a queue item: %s",
            msg.get_body().decode("utf-8"),
        )
        # Receive message from the queue
        statusLog.upsert_document(
            blob_path,
            f"{FUNCTION_NAME} - Received message from image-enrichment-queue ",
            StatusClassification.DEBUG,
            State.PROCESSING,
        )

        # Run the image through the Computer Vision service
        file_name, file_extension, file_directory = utilities.get_filename_and_extension(
            blob_path)
        path = blob_path.split("/", 1)[1]

        try:
            blob_service_client = BlobServiceClient(account_url=azure_blob_storage_endpoint,
                                                    credential=azure_credential)
            blob_client = blob_service_client.get_blob_client(container=azure_blob_drop_storage_container,
                                                              blob=path)
            image_data = blob_client.download_blob().readall()
            response = vision_client.analyze(image_data=image_data,
                                             visual_features=visual_features,
                                             gender_neutral_caption=True)
            
            print(response)

            text_image_summary = ""
            index_content = ""
            complete_ocr_text = None

            if GPU_REGION:
                if response.caption is not None:
                    text_image_summary += "Caption:\n"
                    text_image_summary += "\t'{}', Confidence {:.4f}\n".format(
                        response.caption.text, response.caption.confidence
                    )
                    index_content += "Caption: {}\n ".format(
                        response.caption.text)

                if response.dense_captions is not None:
                    text_image_summary += "Dense Captions:\n"
                    index_content += "DeepCaptions: "
                    for caption in response.dense_captions.values:
                        text_image_summary += "\t'{}', Confidence: {:.4f}\n".format(
                            caption.text, caption.confidence
                        )
                        index_content += "{}\n ".format(caption.text)

            if response.objects is not None:
                text_image_summary += "Objects:\n"
                index_content += "Descriptions: "
                for object_detection in response.objects.values:
                    text_image_summary += "\t'{}', Confidence: {:.4f}\n".format(
                        object_detection.tags[0].name, object_detection.tags[0].confidence
                    )
                    index_content += "{}\n ".format(
                        object_detection.tags[0].name)

            if response.tags is not None:
                text_image_summary += "Tags:\n"
                for tag in response.tags.values:
                    text_image_summary += "\t'{}', Confidence {:.4f}\n".format(
                        tag.name, tag.confidence
                    )
                    index_content += "{}\n ".format(tag.name)

            if response.read is not None:
                text_image_summary += "Raw OCR Text:\n"
                complete_ocr_text = ""
                for line in response.read.blocks[0].lines:
                    complete_ocr_text += "{}\n".format(line.text)
                text_image_summary += complete_ocr_text

        except Exception as ex:
            logging.error(f"{FUNCTION_NAME} - Image analysis failed for {blob_path}: {str(ex)}")
            statusLog.upsert_document(
                blob_path,
                f"{FUNCTION_NAME} - Image analysis failed: {str(ex)}",
                StatusClassification.ERROR,
                State.ERROR,
            )
            raise ex

        if complete_ocr_text not in [None, ""]:
            # Detect language
            output_text = ""

            detected_language, detection_confidence = detect_language(
                complete_ocr_text)
            text_image_summary += f"Raw OCR Text - Detected language: {detected_language}, Confidence: {detection_confidence}\n"

            if detected_language != targetTranslationLanguage:
                # Translate text
                output_text = translate_text(
                    text=complete_ocr_text, target_language=targetTranslationLanguage
                )
                text_image_summary += f"Translated OCR Text - Target language: {targetTranslationLanguage}\n"
                text_image_summary += output_text
                index_content += "OCR Text: {}\n ".format(output_text)

            else:
                # No translation required
                output_text = complete_ocr_text
                index_content += "OCR Text: {}\n ".format(complete_ocr_text)

        else:
            statusLog.upsert_document(
                blob_path,
                f"{FUNCTION_NAME} - No OCR text detected",
                StatusClassification.INFO,
                State.PROCESSING,
            )

        # Upload the output as a chunk to match document model
        utilities.write_chunk(
            myblob_name=blob_path,
            myblob_uri=blob_uri,
            file_number=0,
            chunk_size=utilities.token_count(text_image_summary),
            chunk_text=text_image_summary,
            page_list=[0],
            section_name="",
            title_name=file_name,
            subtitle_name="",
            file_class=MediaType.IMAGE
        )

        statusLog.upsert_document(
            blob_path,
            f"{FUNCTION_NAME} - Image enrichment is complete",
            StatusClassification.DEBUG,
            State.QUEUED,
        )

    except Exception as error:
        statusLog.upsert_document(
            blob_path,
            f"{FUNCTION_NAME} - An error occurred - {str(error)}",
            StatusClassification.ERROR,
            State.ERROR,
        )

    try:
        file_name, file_extension, file_directory = utilities.get_filename_and_extension(
            blob_path)

        # Get the tags from metadata on the blob
        path = file_directory + file_name + file_extension
        blob_service_client = BlobServiceClient(
            account_url=azure_blob_storage_endpoint, credential=azure_credential)
        blob_client = blob_service_client.get_blob_client(
            container=azure_blob_drop_storage_container, blob=path)
        blob_properties = blob_client.get_blob_properties()
        tags = blob_properties.metadata.get("tags")
        if tags is not None:
            if isinstance(tags, str):
                tags_list = [tags]
            else:
                tags_list = tags.split(",")
        else:
            tags_list = []
        # Write the tags to cosmos db
        statusLog.update_document_tags(blob_path, tags_list)

        # Only one chunk per image currently.
        chunk_file = utilities.build_chunk_filepath(
            file_directory, file_name, file_extension, '0')

        index_section(index_content, file_name, file_directory[:-1], statusLog.encode_document_id(
            chunk_file), chunk_file, blob_path, blob_uri, tags_list)

        statusLog.upsert_document(
            blob_path,
            f"{FUNCTION_NAME} - Image added to index.",
            StatusClassification.INFO,
            State.COMPLETE,
        )
    except Exception as err:
        statusLog.upsert_document(
            blob_path,
            f"{FUNCTION_NAME} - An error occurred while indexing - {str(err)}",
            StatusClassification.ERROR,
            State.ERROR,
        )

    statusLog.save_document(blob_path)


def index_section(index_content, file_name, file_directory, chunk_id, chunk_file, blob_path, blob_uri, tags):
    """ Pushes a batch of content to the search index
    """

    index_chunk = {}
    batch = []
    index_chunk['id'] = chunk_id
    azure_datetime = datetime.now().astimezone().isoformat()
    index_chunk['processed_datetime'] = azure_datetime
    index_chunk['file_name'] = blob_path
    index_chunk['file_uri'] = blob_uri
    index_chunk['folder'] = file_directory
    index_chunk['title'] = file_name
    index_chunk['content'] = index_content
    index_chunk['pages'] = [0]
    index_chunk['chunk_file'] = chunk_file
    index_chunk['file_class'] = MediaType.IMAGE
    index_chunk['tags'] = tags
    batch.append(index_chunk)

    search_client = SearchClient(endpoint=AZURE_SEARCH_SERVICE_ENDPOINT,
                                 index_name=AZURE_SEARCH_INDEX,
                                 credential=azure_credential)

    search_client.upload_documents(documents=batch)
