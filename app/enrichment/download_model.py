# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import os
import re

from sentence_transformers import SentenceTransformer

MODEL_NAMES = os.getenv(
    "MODEL_NAMES_TO_LOAD", "all-mpnet-base-v2|paraphrase-multilingual-MiniLM-L12-v2|BAAI/bge-small-en-v1.5"
)

print("Downloading models: ", MODEL_NAMES)

models_to_download = MODEL_NAMES.split("|")

models_path = "models/"

for model_name in models_to_download:
    model = SentenceTransformer(model_name)
    sanitized_model_name = re.sub(r'[^a-zA-Z0-9_\-.]', '_', model_name)
    model.save(os.path.join(models_path,sanitized_model_name))
