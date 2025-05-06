#!/bin/bash
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
# Sử dụng sudo cho docker-compose để đảm bảo quyền truy cập
sudo docker-compose up -d

# Chờ và kiểm tra dịch vụ đã sẵn sàng
echo "Waiting for services to be ready..."
MAX_WAIT=120  # Tối đa chờ 120 giây
WAIT_TIME=0

while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    # Kiểm tra tất cả các container có đang chạy không
    RUNNING_COUNT=$(sudo docker-compose ps | grep -c "Up")
    EXPECTED_COUNT=5  # postgres, zabbix-server, zabbix-web, zabbix-agent, zabbix-java-gateway
    
    if [ "$RUNNING_COUNT" -eq "$EXPECTED_COUNT" ]; then
        # Thêm kiểm tra Zabbix web có sẵn sàng không
        if curl -s --head http://localhost:80 | grep "200 OK" > /dev/null; then
            echo "All services are up and running!"
            break
        fi
    fi
    
    # Chờ thêm 5 giây
    sleep 5
    WAIT_TIME=$((WAIT_TIME + 5))
    echo "Still waiting for services... ($WAIT_TIME seconds)"
done

if [ $WAIT_TIME -ge $MAX_WAIT ]; then
    echo "Warning: Timeout reached. Some services might not be fully ready yet."
fi

# Get service status
echo "Checking services status..."
sudo docker-compose ps

# Get server IP address
SERVER_IP=$(hostname -I | awk '{print $1}')

# Kiểm tra lại trạng thái cuối cùng
ALL_UP=$(sudo docker-compose ps | grep -c "Up")
EXPECTED_COUNT=5

if [ "$ALL_UP" -eq "$EXPECTED_COUNT" ]; then
    echo "==============================================="
    echo "Zabbix installation completed successfully!"
    echo "You can access Zabbix web interface at: http://$SERVER_IP"
    echo "Default login: Admin/zabbix"
    echo "==============================================="
else
    echo "==============================================="
    echo "Zabbix installation completed with warnings."
    echo "Some services might not be running properly."
    echo "Please check the service status above."
    echo "If all services are running, you can access Zabbix at: http://$SERVER_IP"
    echo "Default login: Admin/zabbix"
    echo "==============================================="
fi