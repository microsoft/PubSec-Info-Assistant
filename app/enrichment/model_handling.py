# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import logging
import os
import re

from sentence_transformers import SentenceTransformer


def load_models():
    model_names = os.getenv(
        "TARGET_EMBEDDINGS_MODEL", "all-mpnet-base-v2|paraphrase-multilingual-MiniLM-L12-v2|BAAI/bge-small-en-v1.5"
    )
    print("Downloading models: ", model_names)

    models_to_download = model_names.split("|")

    models_path = "models/"
    models = {}
    model_info = {}

    try:
        for model_name in models_to_download:
            # Ignore AOAI models as they are downloaded elsewhere
            if model_name.startswith("azure-openai"):
                continue
            model = SentenceTransformer(model_name)
            sanitized_model_name = re.sub(r'[^a-zA-Z0-9_\-.]', '_', model_name)
            model.save(os.path.join(models_path,sanitized_model_name))
            models[sanitized_model_name] = model
            logging.debug(f"Loaded model {model_name}")

            model_info_entry = {
                "model": sanitized_model_name,
                "vector_size": model.get_sentence_embedding_dimension(),
            }
            model_info[sanitized_model_name] = model_info_entry
    except Exception as error:
        logging.error(f"Failed to retrieve models - {str(error)}")

    return models, model_info
