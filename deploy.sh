#!/bin/bash

set -e  # Stop script if any command fails

INFRASTRUCTURE_DIR=~/bizinsight-infrastructure
FRONTEND_DIR=~/bizinsight-frontend
BACKEND_DIR=~/bizinsight-backend

# Validate directory setup
echo "🔍 Validating directory setup..."
if [ "$INFRASTRUCTURE_DIR" = "$BACKEND_DIR" ]; then
    echo "⚠️ Infrastructure and backend directories cannot be the same!"
    exit 1
fi

# Check required environment variables at the start
if [ -z "${OPENAI_API_KEY}" ]; then
    echo "⚠️ OPENAI_API_KEY is not set!"
    exit 1
fi

if [ -z "${JWT_SECRET_KEY}" ]; then
    echo "⚠️ JWT_SECRET_KEY is not set!"
    exit 1
fi

echo "🚀 Starting deployment..."

### DOCKER SETUP START ###
echo "🐳 Setting up Docker..."

# Install required system packages
echo "📦 Installing required system packages..."
sudo apt-get update

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
    # Remove existing directory or file if it exists
    rm -rf $BACKEND_DIR/config/firebase-service-account.json
    # Copy the file
    cp ~/firebase-service-account.json $BACKEND_DIR/config/
    echo "✅ Firebase credentials installed successfully"
    rm -f ~/firebase-service-account.json
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

# Create .env file for Docker Compose
echo "Creating .env file for Docker Compose..."
cat > $INFRASTRUCTURE_DIR/.env << EOL
OPENAI_API_KEY=${OPENAI_API_KEY}
JWT_SECRET_KEY=${JWT_SECRET_KEY}
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=${POSTGRES_DB}
EOL

# Restart services with Docker Compose
echo "🔄 Restarting services with Docker Compose..."
cd $INFRASTRUCTURE_DIR
cp -r ../ssl .

# Function to check if all containers are healthy
check_containers_health() {
    echo "Checking containers health..."
    for i in {1..30}; do  # Try for 5 minutes (30 * 10 seconds)
        if docker compose ps --format json | grep -q '"Health": "unhealthy"\|"Health": "starting"'; then
            echo "Waiting for containers to be healthy... (Attempt $i/30)"
            sleep 10
        else
            echo "✅ All containers are healthy!"
            return 0
        fi
    done
    echo "❌ Containers failed to become healthy within timeout"
    docker compose logs
    return 1
}

# Start services
docker compose down
docker compose up -d

# Wait for containers to be healthy
check_containers_health
if [ $? -ne 0 ]; then
    echo "❌ Deployment failed due to unhealthy containers"
    exit 1
fi

echo "✅ Deployment completed successfully!" 