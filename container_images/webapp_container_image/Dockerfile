# Use the official Node.js image
FROM mcr.microsoft.com/devcontainers/python:3.10

# Set the working directory
WORKDIR /home/site/wwwroot

# Copy the package.json
COPY app/backend /home/site/wwwroot

# Install the dependencies
RUN pip install -r /home/site/wwwroot/requirements.txt

# Expose the port the app runs on
EXPOSE 5000

# Run the application
CMD ["uvicorn", "app:app", "--reload", "--port", "5000"]