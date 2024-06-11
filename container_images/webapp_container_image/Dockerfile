# Use the official Node.js image
FROM mcr.microsoft.com/devcontainers/python:3.10

# Set the working directory
WORKDIR /home/site/wwwroot

# Copy the package.json
COPY app/backend /home/site/wwwroot

# Install the dependencies
RUN pip install -r /home/site/wwwroot/requirements.txt

# Run the application
# CMD ["uvicorn", "app:app", "--reload", "--port", "5000"]
CMD ["gunicorn", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "app:app", "-b", "0.0.0.0:5000"]

# Expose the port the app runs on
EXPOSE 5000