#!/bin/bash

set -e  # Stop script if any command fails

INFRASTRUCTURE_DIR=~/bizinsight-infrastructure
FRONTEND_DIR=~/bizinsight-frontend
BACKEND_DIR=~/bizinsight-backend

echo "🚀 Starting deployment..."

### BACKEND SETUP START ###

# Load backend Docker image
if [ -f ~/bizinsight-backend.tar.gz ]; then
    echo "🐳 Loading backend Docker image..."
    docker load < ~/bizinsight-backend.tar.gz
    rm -f ~/bizinsight-backend.tar.gz
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