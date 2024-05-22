# Use the official Node.js image
FROM node:14

# Set the working directory
WORKDIR /app

# Copy the package.json
COPY app/frontend/package*.json /app/
COPY app/frontend /app

# Expose the port the app runs on
EXPOSE 3000