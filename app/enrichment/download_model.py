# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import os

from sentence_transformers import SentenceTransformer

MODEL_NAMES = os.getenv(
    "MODEL_NAMES", "all-mpnet-base-v2|paraphrase-multilingual-MiniLM-L12-v2"
)

models_to_download = MODEL_NAMES.split("|")

models_path = "models/"

for model in models_to_download:
    model = SentenceTransformer(model, cache_folder=models_path)
