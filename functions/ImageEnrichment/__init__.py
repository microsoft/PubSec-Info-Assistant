import json
import logging
import os

import azure.ai.vision as visionsdk
import azure.functions as func
import requests
from azure.storage.blob import BlobServiceClient
from azure.storage.queue import QueueClient, TextBase64EncodePolicy
from shared_code.status_log import State, StatusClassification, StatusLog
from shared_code.utilities import Utilities, MediaType
from azure.search.documents import SearchClient
from azure.core.credentials import AzureKeyCredential
from datetime import datetime


azure_blob_storage_account = os.environ["BLOB_STORAGE_ACCOUNT"]
azure_blob_drop_storage_container = os.environ[
    "BLOB_STORAGE_ACCOUNT_UPLOAD_CONTAINER_NAME"
]
azure_blob_content_storage_container = os.environ[
    "BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME"
]
azure_blob_storage_endpoint = os.environ["BLOB_STORAGE_ACCOUNT_ENDPOINT"]
azure_blob_storage_key = os.environ["BLOB_STORAGE_ACCOUNT_KEY"]
azure_blob_connection_string = os.environ["BLOB_CONNECTION_STRING"]
azure_blob_content_storage_container = os.environ[
    "BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME"
]
azure_blob_content_storage_container = os.environ[
    "BLOB_STORAGE_ACCOUNT_OUTPUT_CONTAINER_NAME"
]
IS_USGOV_DEPLOYMENT = os.getenv("IS_USGOV_DEPLOYMENT", False)

# Cosmos DB
cosmosdb_url = os.environ["COSMOSDB_URL"]
cosmosdb_key = os.environ["COSMOSDB_KEY"]
cosmosdb_database_name = os.environ["COSMOSDB_DATABASE_NAME"]
cosmosdb_container_name = os.environ["COSMOSDB_CONTAINER_NAME"]

# Cognitive Services
cognitive_services_key = os.environ["ENRICHMENT_KEY"]
cognitive_services_endpoint = os.environ["ENRICHMENT_ENDPOINT"]
cognitive_services_account_location = os.environ["ENRICHMENT_LOCATION"]

# Search Service
AZURE_SEARCH_SERVICE_ENDPOINT = os.environ.get("AZURE_SEARCH_SERVICE_ENDPOINT")
AZURE_SEARCH_INDEX = os.environ.get("AZURE_SEARCH_INDEX") or "gptkbindex"
SEARCH_CREDS = AzureKeyCredential(os.environ.get("AZURE_SEARCH_SERVICE_KEY"))

# Translation params for OCR'd text
targetTranslationLanguage = os.environ["TARGET_TRANSLATION_LANGUAGE"]

# If running in the US Gov cloud, use the US Gov translation endpoint, Default to global
if not IS_USGOV_DEPLOYMENT:
    API_DETECT_ENDPOINT = (
        "https://api.cognitive.microsofttranslator.com/detect?api-version=3.0"
    )
    API_TRANSLATE_ENDPOINT = (
        "https://api.cognitive.microsofttranslator.com/translate?api-version=3.0"
    )
else:
    API_DETECT_ENDPOINT = (
        "https://api.cognitive.microsofttranslator.us/detect?api-version=3.0"
    )
    API_TRANSLATE_ENDPOINT = (
        "https://api.cognitive.microsofttranslator.us/translate?api-version=3.0"
    )


MAX_CHARS_FOR_DETECTION = 1000
translator_api_headers = {
    "Ocp-Apim-Subscription-Key": cognitive_services_key,
    "Content-type": "application/json",
    "Ocp-Apim-Subscription-Region": cognitive_services_account_location,
}

# Vision SDK
vision_service_options = visionsdk.VisionServiceOptions(
    endpoint=cognitive_services_endpoint, key=cognitive_services_key
)

analysis_options = visionsdk.ImageAnalysisOptions()

# Note that "CAPTION" and "DENSE_CAPTIONS" are only supported in Azure GPU regions (East US, France Central,
# Korea Central, North Europe, Southeast Asia, West Europe, West US). Remove "CAPTION" and "DENSE_CAPTIONS"
# from the list below if your Computer Vision key is not from one of those regions.

if cognitive_services_account_location in [
    "eastus",
    "francecentral",
    "koreacentral",
    "northeurope",
    "southeastasia",
    "westeurope",
    "westus",
]:
    GPU_REGION = True
    analysis_options.features = (
        visionsdk.ImageAnalysisFeature.CAPTION
        | visionsdk.ImageAnalysisFeature.DENSE_CAPTIONS
        | visionsdk.ImageAnalysisFeature.OBJECTS
        | visionsdk.ImageAnalysisFeature.TEXT
        | visionsdk.ImageAnalysisFeature.TAGS
    )
else:
    GPU_REGION = False
    analysis_options.features = (
        visionsdk.ImageAnalysisFeature.OBJECTS
        | visionsdk.ImageAnalysisFeature.TEXT
        | visionsdk.ImageAnalysisFeature.TAGS
    )

analysis_options.model_version = "latest"


FUNCTION_NAME = "ImageEnrichment"


utilities = Utilities(
    azure_blob_storage_account=azure_blob_storage_account,
    azure_blob_storage_endpoint=azure_blob_storage_endpoint,
    azure_blob_drop_storage_container=azure_blob_drop_storage_container,
    azure_blob_content_storage_container=azure_blob_content_storage_container,
    azure_blob_storage_key=azure_blob_storage_key
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
    detect the language of the text and translate it to Target Language."""

    message_body = msg.get_body().decode("utf-8")
    message_json = json.loads(message_body)
    blob_path = message_json["blob_name"]
    try:
        statusLog = StatusLog(
            cosmosdb_url, cosmosdb_key, cosmosdb_database_name, cosmosdb_container_name
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
        file_name, file_extension, file_directory  = utilities.get_filename_and_extension(blob_path)
        blob_path_plus_sas = utilities.get_blob_and_sas(blob_path)

        vision_source = visionsdk.VisionSource(url=blob_path_plus_sas)
        image_analyzer = visionsdk.ImageAnalyzer(
            vision_service_options, vision_source, analysis_options
        )
        result = image_analyzer.analyze()

        text_image_summary = ""
        index_content = ""
        complete_ocr_text = None

        if result.reason == visionsdk.ImageAnalysisResultReason.ANALYZED:
            if GPU_REGION:
                if result.caption is not None:
                    text_image_summary += "Caption:\n"
                    text_image_summary += "\t'{}', Confidence {:.4f}\n".format(
                        result.caption.content, result.caption.confidence
                    )
                    index_content += "Caption: {}\n ".format(result.caption.content)

                if result.dense_captions is not None:
                    text_image_summary += "Dense Captions:\n"
                    index_content += "DeepCaptions: "
                    for caption in result.dense_captions:
                        text_image_summary += "\t'{}', Confidence: {:.4f}\n".format(
                            caption.content, caption.confidence
                        )
                        index_content += "{}\n ".format(caption.content)

            if result.objects is not None:
                text_image_summary += "Objects:\n"
                index_content += "Descriptions: "
                for object_detection in result.objects:
                    text_image_summary += "\t'{}', Confidence: {:.4f}\n".format(
                        object_detection.name, object_detection.confidence
                    )
                    index_content += "{}\n ".format(object_detection.name)

            if result.tags is not None:
                text_image_summary += "Tags:\n"
                for tag in result.tags:
                    text_image_summary += "\t'{}', Confidence {:.4f}\n".format(
                        tag.name, tag.confidence
                    )
                    index_content += "{}\n ".format(tag.name)

            if result.text is not None:
                text_image_summary += "Raw OCR Text:\n"
                complete_ocr_text = ""
                for line in result.text.lines:
                    complete_ocr_text += "{}\n".format(line.content)
                text_image_summary += complete_ocr_text

        else:
            error_details = visionsdk.ImageAnalysisErrorDetails.from_result(result)

            statusLog.upsert_document(
                blob_path,
                f"{FUNCTION_NAME} - Image analysis failed: {error_details.error_code} {error_details.error_code} {error_details.message}",
                StatusClassification.ERROR,
                State.ERROR,
            )

        if complete_ocr_text not in [None, ""]:
            # Detect language
            output_text = ""

            detected_language, detection_confidence = detect_language(complete_ocr_text)
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
            myblob_uri=blob_path,
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

    statusLog.save_document()

    try:
        index_section(index_content, file_name, statusLog.encode_document_id(file_name), blob_path)
    except Exception as err:
        statusLog.upsert_document(
            blob_path,
            f"{FUNCTION_NAME} - An error occurred while indexing - {str(err)}",
            StatusClassification.ERROR,
            State.ERROR,
        )
    statusLog.save_document()


def index_section(index_content, file_name, chunk_id, blob_path):
    """ Pushes a batch of content to the search index
    """

    index_chunk = {}
    batch = []
    index_chunk['id'] = chunk_id
    azure_datetime = datetime.now().astimezone().isoformat()
    index_chunk['processed_datetime'] = azure_datetime
    index_chunk['file_name'] = blob_path
    index_chunk['file_uri'] = blob_path
    index_chunk['title'] = file_name
    index_chunk['content'] = index_content
    index_chunk['file_class'] = MediaType.IMAGE
    batch.append(index_chunk)

    search_client = SearchClient(endpoint=AZURE_SEARCH_SERVICE_ENDPOINT,
                                    index_name=AZURE_SEARCH_INDEX,
                                    credential=SEARCH_CREDS)

    search_client.upload_documents(documents=batch)
