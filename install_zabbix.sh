#!/bin/bash

# Dừng script nếu có lỗi xảy ra
set -e

echo "=========================================================="
echo "🚀 BẮT ĐẦU TRIỂN KHAI ZABBIX QUA DOCKER COMPOSE"
echo "=========================================================="

echo "[1/5] Tạo cấu trúc thư mục Zabbix trên Disk 2 (/data/zabbix/)..."
sudo mkdir -p /data/zabbix/postgres
sudo mkdir -p /data/zabbix/server/{alertscripts,externalscripts,export,modules,enc,ssh_keys}
sudo mkdir -p /data/zabbix/log/{zabbix-server,zabbix-web}

echo "[2/5] Phân quyền thư mục cho các Container để tránh lỗi Permission Denied..."
# UID 70 (postgres), UID 199 (zabbix), UID 101 (nginx)
sudo chown -R 70:70 /data/zabbix/postgres
sudo chown -R 199:199 /data/zabbix/server
sudo chown -R 199:199 /data/zabbix/log/zabbix-server
sudo chown -R 199:199 /data/zabbix/log/zabbix-web
sudo chmod -R 777 /data/zabbix/log/zabbix-web

echo "[3/5] Tạo thư mục làm việc và tải file cấu hình từ GitHub..."
sudo mkdir -p /opt/zabbix-docker
cd /opt/zabbix-docker

# Tải file docker-compose.yml và file biến môi trường .env
sudo curl -sO https://raw.githubusercontent.com/khanhvc-doc/zabbix/master/docker-compose.yml
sudo curl -sO https://raw.githubusercontent.com/khanhvc-doc/zabbix/master/.env

echo "[4/5] Kích hoạt hệ thống Zabbix..."
# Chạy Docker Compose tại thư mục /opt/zabbix-docker
sudo docker compose up -d

echo "[5/5] Đang kiểm tra trạng thái sẵn sàng của hệ thống..."
# Chờ cho đến khi zabbix-web báo trạng thái "healthy"
until [ "$(sudo docker inspect -f '{{.State.Health.Status}}' zabbix-web)" == "healthy" ]; do
    printf "\r⏳ Đang khởi tạo các dịch vụ... Vui lòng đợi trong giây lát "
    sleep 2
done
echo -e "\n✅ Hệ thống đã đạt trạng thái Healthy!"

# Tự động lấy IP của máy chủ để in ra màn hình
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "=========================================================="
echo "✅ CÀI ĐẶT HOÀN TẤT VÀ ĐÃ SẴN SÀNG!"
echo "----------------------------------------------------------"
echo "- Thư mục quản lý Compose : /opt/zabbix-docker"
echo "- Thư mục dữ liệu (Disk 2): /data/zabbix"
echo "----------------------------------------------------------"
echo "🌐 Truy cập Web UI tại : http://$SERVER_IP"
echo "👤 User mặc định       : Admin"
echo "🔑 Password mặc định   : zabbix"
echo "=========================================================="
