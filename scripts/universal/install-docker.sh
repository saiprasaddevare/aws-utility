#!/bin/bash
# Universal Docker & Docker Compose Installer for AWS (Ubuntu & Amazon Linux)
set -e

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
else
    OS=$(uname -s)
fi

echo "Detected OS: $OS"

# 1. UBUNTU INSTALLATION
if [[ "$OS" == *"Ubuntu"* ]]; then
    echo "Starting Ubuntu Setup..."
    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 2. AMAZON LINUX INSTALLATION
elif [[ "$OS" == *"Amazon Linux"* ]]; then
    echo "Starting Amazon Linux Setup..."
    sudo dnf update -y || sudo yum update -y
    sudo dnf install -y docker || sudo yum install -y docker
    
    # Install Docker Compose V2 manually for Amazon Linux
    ARCH=$(uname -m)
    sudo mkdir -p /usr/local/lib/docker/cli-plugins
    sudo curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$ARCH" -o /usr/local/lib/docker/cli-plugins/docker-compose
    sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

else
    echo "❌ Unsupported OS: $OS"
    exit 1
fi

# 3. UNIVERSAL CONFIGURATION (Runs on all)
echo "Enabling and starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

echo "Adding user '$USER' to the docker group..."
sudo usermod -aG docker $USER

echo "--------------------------------------------------------"
echo "✅ Installation complete!"
echo "⚠️ IMPORTANT: Close your SSH session and reconnect for group changes to take effect."
echo "--------------------------------------------------------"