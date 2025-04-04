#!/bin/bash

set -e  # Exit on error

# Extract output.tar.gz to /home/site/wwwroot
echo "Extracting output.tar.gz..."
tar -xzf /home/site/wwwroot/output.tar.gz -C /home/site/wwwroot

# List contents of frontend directory for debugging
echo "Contents of /home/site/wwwroot/app/frontend/:"
ls -la /home/site/wwwroot/app/frontend/

# Install Node.js
echo "Installing Node.js..."
apt-get update
apt-get install -y curl
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Build the frontend
echo "Building frontend..."
cd /home/site/wwwroot/app/frontend
npm install || { echo "npm install failed"; exit 1; }
npm run build || { echo "npm run build failed"; exit 1; }

echo "Frontend build completed successfully."