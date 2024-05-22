# Use the official Python image for Azure Functions
FROM mcr.microsoft.com/azure-functions/python:3.0-python3.7

# Set the working directory
WORKDIR /home/site/wwwroot

COPY app/backend /home/site/wwwroot

# Expose the port the app runs on
EXPOSE 80