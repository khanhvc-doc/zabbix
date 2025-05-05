#!/bin/bash

set -e

echo "Installing Docker and Docker Compose..."
if ! command -v docker &> /dev/null; then
    sudo apt update
    sudo apt install -y docker.io
    sudo systemctl enable --now docker
fi

if ! command -v docker-compose &> /dev/null; then
    sudo apt install -y docker-compose
fi

echo "Creating zabbix-docker directory..."
mkdir -p ~/zabbix-docker
cd ~/zabbix-docker

echo "Downloading docker-compose.yml..."
curl -fsSL https://raw.githubusercontent.com/khanhvc-doc/zabbix/refs/heads/master/docker-compose.yml -o compose.yml
curl -fsSL https://raw.githubusercontent.com/khanhvc-doc/zabbix/refs/heads/master/.env -o .env

echo "Creating volume directories if not exist..."
mkdir -p mysql zbx_server zbx_agent

echo "Starting Zabbix containers..."
docker-compose up -d

echo "Zabbix is running at http://localhost:8080"
echo "Default login: Admin / zabbix"
