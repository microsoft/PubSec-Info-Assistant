FROM mcr.microsoft.com/devcontainers/python:3.11

ARG MODEL_NAMES=all-mpnet-base-v2|paraphrase-multilingual-MiniLM-L12-v2|BAAI/bge-small-en-v1.5
ENV MODEL_NAMES_TO_LOAD=$MODEL_NAMES

# Copy requirements for install
COPY requirements.txt /tmp/pip-tmp/

# Copy the entrypoint.sh script into the container
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY *.py /
COPY shared_code/status_log.py /shared_code/status_log.py
COPY shared_code/utilities_helper.py /shared_code/utilities_helper.py

EXPOSE 5000

# Startup script
ENTRYPOINT ["/entrypoint.sh"]