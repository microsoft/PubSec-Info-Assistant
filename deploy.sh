#!/bin/bash

# Extract output.tar.gz to /home/site/wwwroot
tar -xzf /home/site/wwwroot/output.tar.gz -C /home/site/wwwroot

# Install Node.js
apt-get update
apt-get install -y curl
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Build the frontend
cd /home/site/wwwroot/app/frontend
npm install
npm run build

# Copy the built frontend to a persistent location (optional, if needed)
# mkdir -p /home/site/wwwroot/static
# cp -r /home/site/wwwroot/app/frontend/dist/* /home/site/wwwroot/static/