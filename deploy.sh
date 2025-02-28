#!/bin/bash

set -e  # Stop script if any command fails

INFRASTRUCTURE_DIR=~/bizinsight-infrastructure
FRONTEND_DIR=~/bizinsight-frontend
BACKEND_DIR=~/bizinsight-backend

echo "🚀 Starting deployment..."

### DOCKER SETUP START ###
echo "🐳 Setting up Docker..."

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    # Add Docker's official GPG key
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker packages
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add current user to docker group
    sudo usermod -aG docker $USER
    echo "✅ Docker installed successfully"
else
    echo "✅ Docker already installed"
fi

# Ensure Docker is running
if ! sudo systemctl is-active --quiet docker; then
    echo "Starting Docker service..."
    sudo systemctl start docker
fi

echo "✅ Docker setup completed"
### DOCKER SETUP END ###

### BACKEND SETUP START ###

# Load backend Docker image
if [ -f ~/bizinsight-backend.tar.gz/bizinsight-backend.tar.gz ]; then
    echo "🐳 Loading backend Docker image..."
    docker load < ~/bizinsight-backend.tar.gz/bizinsight-backend.tar.gz
    rm -rf ~/bizinsight-backend.tar.gz
    echo "✅ Backend image loaded successfully"
else
    echo "⚠️ Backend Docker image not found!"
    exit 1
fi

# Setup backend configuration
echo "⚙️ Setting up backend configuration..."
mkdir -p $BACKEND_DIR/config
mkdir -p $BACKEND_DIR/uploads

# Copy Firebase credentials
if [ -f ~/firebase-service-account.json ]; then
    echo "🔑 Installing Firebase credentials..."
    mv ~/firebase-service-account.json $BACKEND_DIR/config/
else
    echo "⚠️ Firebase credentials not found!"
    exit 1
fi

### BACKEND SETUP END ###

### FRONTEND SETUP START ###


if [ -f ~/frontend-build.tar.gz ]; then
    echo "📦 Extracting frontend build..."
    mkdir -p $FRONTEND_DIR/dist
    tar -xzf ~/frontend-build.tar.gz -C $FRONTEND_DIR/dist
    rm -f ~/frontend-build.tar.gz
    echo "✅ Frontend build extracted successfully"
else
    echo "⚠️ Frontend build not found!"
    exit 1
fi

### FRONTEND SETUP END ###

# Restart services with Docker Compose
echo "🔄 Restarting services with Docker Compose..."
cd $INFRASTRUCTURE_DIR
cp -r ../ssl .
docker compose down
docker compose up -d --force-recreate

echo "✅ Deployment completed successfully!" 