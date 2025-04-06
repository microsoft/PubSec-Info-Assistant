#!/bin/bash

# Exit immediately if any command fails
set -e  

###########################################
# 1. Show that we are running the script
###########################################
echo "===== Running deploy.sh ====="
echo "Current working directory: $(pwd)"
echo "Contents of /home/site/wwwroot before build:"
ls -la /home/site/wwwroot

###########################################
# 2. Check Node version (optional but helpful)
###########################################
echo "Checking Node.js version..."
if ! command -v node >/dev/null 2>&1; then
    echo "Node.js not found. Please ensure your Azure App Service has Node installed (e.g. Node 18+)."
    exit 1
else
    node --version
    npm --version
fi

# If you specifically need Node 18 or higher:
NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "Error: Node.js version $NODE_VERSION is too old. Vite typically requires Node.js 18 or higher."
    exit 1
fi

###########################################
# 3. Install Python dependencies
###########################################
echo "Installing Python dependencies..."
# Adjust the path if your requirements.txt is located elsewhere
pip install -r /home/site/wwwroot/app/backend/requirements.txt

###########################################
# 4. Build the frontend
###########################################
echo "Building frontend..."
cd /home/site/wwwroot/app/frontend

npm install
npm run build

# If your 'dist/' folder is created here, you might want to see what's in it:
echo "Contents of dist after build:"
ls -la dist

###########################################
# 5. Return to the original folder (optional)
###########################################
cd /home/site/wwwroot

echo "===== Deployment script completed successfully ====="
