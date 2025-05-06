#!/bin/bash

# Update system and install prerequisites
echo "Updating system and installing prerequisites..."
sudo apt update
sudo apt upgrade -y

# Install required packages
echo "Installing required packages..."
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker repository and install Docker
echo "Adding Docker repository..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
echo "Installing Docker..."
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Verify Docker installation
echo "Verifying Docker installation..."
sudo docker --version

# Install Docker Compose
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

# Add current user to docker group
echo "Adding user to docker group..."
sudo usermod -aG docker $USER
newgrp docker

# Create and prepare project directory
echo "Creating project directory..."
mkdir -p ~/zabbix-docker
cd ~/zabbix-docker
sudo chown -R $USER:$USER ~/zabbix-docker
chmod -R 755 ~/zabbix-docker

# Open required ports in firewall
echo "Configuring firewall..."
sudo ufw allow 80/tcp
sudo ufw allow 10051/tcp

# Download configuration files
echo "Downloading configuration files..."
curl -fsSL https://raw.githubusercontent.com/khanhvc-doc/zabbix/refs/heads/master/docker-compose.yml -o docker-compose.yml
curl -fsSL https://raw.githubusercontent.com/khanhvc-doc/zabbix/refs/heads/master/.env -o .env

# Start Zabbix services
echo "Starting Zabbix services..."
docker-compose up -d

# Check if services are running
echo "Checking services status..."
docker-compose ps

# Get server IP address
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "Zabbix installation completed!"
echo "You can access Zabbix web interface at: http://$SERVER_IP"
echo "Default login: Admin/zabbix"