# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import logging
import os

from sentence_transformers import SentenceTransformer


def load_models():
    available_models = []

    for dirpath, dirnames, filenames in os.walk("models"):
        # Check if the current directory contains a file named "config.json"
        if "pytorch_model.bin" in filenames:
            # If it does, print the path to the directory
            available_models.append(dirpath)

    # Load all models
    models = {}

    for model_path in available_models:
        model = model_path.split("/")[-1]
        models[model] = SentenceTransformer(model_path)
        logging.debug(f"Loaded model {model}")

    # Create model info
    model_info = {}

    for model, model_obj in models.items():
        model_info_entry = {
            "model": model,
            "max_seq_length": model_obj.get_max_seq_length(),
            "vector_size": model_obj.get_sentence_embedding_dimension(),
        }

        model_info[model] = model_info_entry

    return models, model_info
