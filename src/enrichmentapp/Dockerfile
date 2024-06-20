# Use the official Python image from Microsoft for Azure App Service
FROM mcr.microsoft.com/devcontainers/python:3.10

# Set the working directory
WORKDIR /app

COPY . /app

# Install any needed packages specified in requirements.txt
RUN pip install -r /app/requirements.txt

# Expose the port the app runs on
EXPOSE 6000

# Run the application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "6000"]