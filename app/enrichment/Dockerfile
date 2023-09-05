FROM mcr.microsoft.com/devcontainers/python:3.11

ARG MODEL_NAMES=all-mpnet-base-v2|paraphrase-multilingual-MiniLM-L12-v2

# Install requirements

COPY requirements.txt /tmp/pip-tmp/
RUN pip install --requirement /tmp/pip-tmp/requirements.txt \
    && rm -rf /tmp/pip-

COPY download_model.py /download_model.py
RUN mkdir models
RUN python download_model.py

COPY app.py /app.py

EXPOSE 5000

# Run FastAPI

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "5000"]



