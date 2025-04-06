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
# 2. Check Node version
###########################################
echo "Checking Node.js version..."
if ! command -v node >/dev/null 2>&1; then
    echo "Node.js not found. Please ensure your Azure App Service has Node installed (e.g. Node 18+)."
    exit 1
else
    node --version
    npm --version
fi

NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "Error: Node.js version $NODE_VERSION is too old. Vite typically requires Node.js 18 or higher."
    exit 1
fi

###########################################
# 3. Check Python environment
###########################################
echo "----- Checking Python environment -----"
which python || true
python --version || true
which python3 || true
python3 --version || true

###########################################
# 4. Install Python dependencies
###########################################
echo "----- Installing Python dependencies -----"
# Use 'python -m pip' to avoid relying on a 'pip' binary in PATH
python -m pip install --upgrade pip
python -m pip install -r /home/site/wwwroot/app/backend/requirements.txt

###########################################
# 5. Build the frontend
###########################################
echo "----- Building frontend -----"
cd /home/site/wwwroot/app/frontend

npm install
npm run build

echo "Contents of dist after build:"
ls -la dist

###########################################
# 6. Return to the original folder
###########################################
cd /home/site/wwwroot

echo "===== Deployment script completed successfully ====="
