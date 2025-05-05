#!/bin/bash
set -e

echo "===== Installing Docker and Docker Compose ====="
if ! command -v docker &> /dev/null; then
    sudo apt update
    sudo apt install -y docker.io
    sudo systemctl enable --now docker
    sudo usermod -aG docker $USER
    echo "Docker installed successfully"
else
    echo "Docker already installed"
fi

if ! command -v docker-compose &> /dev/null; then
    sudo apt install -y docker-compose
    echo "Docker Compose installed successfully"
else
    echo "Docker Compose already installed"
fi

# Create project directory
echo "===== Creating zabbix-docker directory ====="
mkdir -p ~/zabbix-docker
cd ~/zabbix-docker

# Download configuration files
echo "===== Downloading configuration files ====="
curl -fsSL https://raw.githubusercontent.com/khanhvc-doc/zabbix/refs/heads/master/docker-compose.yml -o docker-compose.yml
curl -fsSL https://raw.githubusercontent.com/khanhvc-doc/zabbix/refs/heads/master/.env -o .env

# Create volume directories with proper permissions
echo "===== Creating volume directories ====="
mkdir -p mysql zbx_server zbx_agent
sudo chown -R 1997:1995 mysql/
sudo chmod -R 777 mysql/ zbx_server/ zbx_agent/

# Stop any existing containers and clean up
echo "===== Cleaning up existing containers ====="
sudo docker-compose down -v 2>/dev/null || true
sudo docker volume prune -f

# Start Zabbix containers with dependency check
echo "===== Starting Zabbix containers ====="
sudo docker-compose up -d mysql-server
echo "Waiting for MySQL to initialize (30 seconds)..."
sleep 30

# Check if MySQL is ready
echo "===== Checking MySQL connection ====="
MAX_RETRIES=5
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if sudo docker-compose exec mysql-server mysqladmin ping -h mysql-server -u root -p$(grep MYSQL_ROOT_PASSWORD .env | cut -d= -f2) --silent; then
        echo "MySQL is ready"
        break
    else
        echo "MySQL not ready yet, waiting..."
        sleep 10
        RETRY_COUNT=$((RETRY_COUNT+1))
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "Warning: MySQL may not be fully initialized yet, but continuing anyway"
fi

# Start the remaining services
echo "===== Starting remaining Zabbix services ====="
sudo docker-compose up -d

echo "===== Installation completed ====="
echo "Zabbix should be running at http://localhost:8080"
echo "Default login: Admin / zabbix"
echo ""
echo "Check logs if you have issues:"
echo "sudo docker-compose logs zabbix-web"
echo "sudo docker-compose logs zabbix-server"
echo "sudo docker-compose logs mysql-server"