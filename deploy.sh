#!/bin/bash

set -e  # Stop script if any command fails

DEPLOY_DIR=~/bizinsight-infrastructure
FRONTEND_DIR=$DEPLOY_DIR/frontend/dist
BACKEND_DIR=$DEPLOY_DIR/bizinsight-backend
BACKEND_IMAGE="bizinsight-backend:latest"

echo "🚀 Starting deployment..."

# 1. Clone backend repository for compose file and config
echo "📥 Cloning backend repository..."
rm -rf $BACKEND_DIR
git clone https://${{ secrets.GITHUB_TOKEN }}@github.com/${{ secrets.GH_USERNAME }}/bizinsight-backend.git $BACKEND_DIR

# 2. Extract frontend artifact
if [ -f ~/frontend-build.tar.gz ]; then
    echo "📦 Extracting frontend build..."
    mkdir -p $FRONTEND_DIR
    tar -xzf ~/frontend-build.tar.gz -C $FRONTEND_DIR
    rm ~/frontend-build.tar.gz
    echo "✅ Frontend artifact extracted successfully"
else
    echo "⚠️ Frontend artifact not found!"
    exit 1
fi

# 3. Load backend Docker image
if [ -f ~/backend-image/backend-image.tar ]; then
    echo "🐳 Loading backend Docker image..."
    docker load < ~/backend-image/backend-image.tar
    rm -f ~/backend-image/backend-image.tar
    echo "✅ Backend image loaded successfully"
else
    echo "⚠️ Backend Docker image not found!"
    exit 1
fi

# 4. Setup backend configuration
echo "⚙️ Setting up backend configuration..."
mkdir -p $BACKEND_DIR/config
mkdir -p $BACKEND_DIR/uploads

# Copy Firebase credentials from GitHub secrets
if [ -f ~/firebase-service-account.json ]; then
    echo "🔑 Installing Firebase credentials..."
    cp ~/firebase-service-account.json $BACKEND_DIR/config/
    rm ~/firebase-service-account.json  # Clean up sensitive file
else
    echo "⚠️ Firebase credentials not found!"
    exit 1
fi

# 5. Restart infrastructure with Docker Compose
echo "🔄 Restarting services with Docker Compose..."
cd $DEPLOY_DIR
docker compose down
docker compose up -d --force-recreate

echo "✅ Deployment completed successfully!" 