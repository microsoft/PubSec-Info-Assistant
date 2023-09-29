#!/bin/bash

pip install --requirement /tmp/pip-tmp/requirements.txt && rm -rf /tmp/pip-

echo "Downloading model: $MODEL_NAMES"
mkdir models
python download_model.py

# Run FastAPI
exec uvicorn app:app --host 0.0.0.0 --port 5000