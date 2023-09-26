FROM mcr.microsoft.com/devcontainers/python:3.11

ARG MODEL_NAMES=all-mpnet-base-v2|paraphrase-multilingual-MiniLM-L12-v2|BAAI/bge-small-en-v1.5

# Install requirements

COPY requirements.txt /tmp/pip-tmp/
RUN pip install --requirement /tmp/pip-tmp/requirements.txt \
    && rm -rf /tmp/pip-

RUN echo "Downloading model: $MODEL_NAMES"
COPY download_model.py /download_model.py
RUN mkdir models
RUN python download_model.py

COPY *.py /
COPY shared_code/status_log.py /shared_code/status_log.py
COPY shared_code/utilities_helper.py /shared_code/utilities_helper.py

EXPOSE 5000

# Run FastAPI
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "5000"]