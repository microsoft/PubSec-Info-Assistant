# Use the official Node.js image
FROM mcr.microsoft.com/devcontainers/python:3.12

# Set the working directory
WORKDIR /home/site/wwwroot

# Copy the package.json
COPY app/backend /home/site/wwwroot

# Install the dependencies
RUN pip install -r /home/site/wwwroot/requirements.txt

# Expose the port the app runs on
EXPOSE 6000

# Run the application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "6000"]