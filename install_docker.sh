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
echo "Docker installation completed successfully!"

# Add current user to docker group
echo "Adding user to docker group..."
sudo usermod -aG docker $USER
newgrp docker
# Không sử dụng newgrp docker vì nó sẽ tạo shell mới và dừng script
# Thay vào đó, thông báo cho người dùng cần đăng nhập lại sau khi cài đặt hoàn tất
# echo "Note: You may need to log out and back in for docker group changes to take effect."
