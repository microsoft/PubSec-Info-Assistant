# Copyright (c) DataReason.
### Code for On-Premises Deployment.

# Use the official Python image from the Docker Hub
FROM python:3.10-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Create and set the working directory
WORKDIR /app

# Copy the requirements file into the container
COPY requirements.txt /app/

# Install the dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code into the container
COPY . /app/

# Command to run the application
CMD ["python", "-m", "functions"]

#Explanation
#Base Image: Using the official Python 3.10 slim image.
#Environment Variables: Setting PYTHONUNBUFFERED to ensure the output is sent straight to the terminal without being buffered.
#Working Directory: Creating and setting the working directory to /app.
#Copy Requirements: Copying the requirements.txt file into the container.
#Install Dependencies: Installing the dependencies listed in requirements.txt.
#Copy Application Code: Copying the rest of the application code into the container.
#Command: Setting the default command to run the application.