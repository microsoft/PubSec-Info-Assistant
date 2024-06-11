# Use the official Python image from Microsoft for Azure App Service
FROM mcr.microsoft.com/devcontainers/python:3.10

# Set the working directory
WORKDIR /app

COPY app/enrichment /app

# Install any needed packages specified in requirements.txt
RUN pip install -r /app/requirements.txt

# Run the application
# CMD ["uvicorn", "app:app", "--reload", "--port", "5001"]
CMD ["gunicorn", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "app:app", "-b", "0.0.0.0:5001"]

# Expose the port the app runs on
EXPOSE 5001