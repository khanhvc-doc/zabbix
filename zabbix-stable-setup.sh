#!/bin/bash
# Script cài đặt Zabbix ổn định bằng Docker
set -e

echo "===== Cleaning up any existing installation ====="
sudo docker-compose down -v 2>/dev/null || true
sudo docker system prune -f 2>/dev/null || true

echo "===== Creating installation directory ====="
mkdir -p ~/zabbix-stable
cd ~/zabbix-stable

echo "===== Creating docker-compose.yml file ====="
cat > docker-compose.yml << 'EOF'
version: '3'

networks:
  zabbix-net:
    driver: bridge

services:
  postgres:
    image: postgres:13-alpine
    container_name: postgres-server
    restart: always
    networks:
      - zabbix-net
    environment:
      - POSTGRES_PASSWORD=zabbix
      - POSTGRES_USER=zabbix
      - POSTGRES_DB=zabbix
    volumes:
      - ./pgdata:/var/lib/postgresql/data
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  zabbix-server:
    image: zabbix/zabbix-server-pgsql:alpine-6.0.7
    container_name: zabbix-server
    restart: always
    networks:
      - zabbix-net
    depends_on:
      - postgres
    environment:
      - DB_SERVER_HOST=postgres
      - POSTGRES_USER=zabbix
      - POSTGRES_PASSWORD=zabbix
      - POSTGRES_DB=zabbix
      - ZBX_CACHESIZE=128M
      - ZBX_STARTPOLLERS=10
      - ZBX_TIMEOUT=10
    volumes:
      - ./zbx_env/usr/lib/zabbix/alertscripts:/usr/lib/zabbix/alertscripts:ro
      - ./zbx_env/usr/lib/zabbix/externalscripts:/usr/lib/zabbix/externalscripts:ro
      - ./zbx_env/var/lib/zabbix/export:/var/lib/zabbix/export:rw
      - ./zbx_env/var/lib/zabbix/modules:/var/lib/zabbix/modules:ro
      - ./zbx_env/var/lib/zabbix/enc:/var/lib/zabbix/enc:ro
      - ./zbx_env/var/lib/zabbix/ssh_keys:/var/lib/zabbix/ssh_keys:ro
      - ./zbx_env/var/lib/zabbix/mibs:/var/lib/zabbix/mibs:ro
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    ports:
      - "10051:10051"

  zabbix-web:
    image: zabbix/zabbix-web-nginx-pgsql:alpine-6.0.7
    container_name: zabbix-web
    restart: always
    networks:
      - zabbix-net
    depends_on:
      - postgres
      - zabbix-server
    environment:
      - DB_SERVER_HOST=postgres
      - POSTGRES_USER=zabbix
      - POSTGRES_PASSWORD=zabbix
      - POSTGRES_DB=zabbix
      - ZBX_SERVER_HOST=zabbix-server
      - PHP_TZ=Asia/Ho_Chi_Minh
    ports:
      - "80:8080"
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  zabbix-agent:
    image: zabbix/zabbix-agent:alpine-6.0.7
    container_name: zabbix-agent
    restart: always
    networks:
      - zabbix-net
    depends_on:
      - zabbix-server
    environment:
      - ZBX_SERVER_HOST=zabbix-server
      - ZBX_SERVER_PORT=10051
      - ZBX_HOSTNAME=zabbix-agent
    volumes:
      - ./zbx_env/etc/zabbix/zabbix_agentd.d:/etc/zabbix/zabbix_agentd.d:ro
      - ./zbx_env/var/lib/zabbix/modules:/var/lib/zabbix/modules:ro
      - ./zbx_env/var/lib/zabbix/enc:/var/lib/zabbix/enc:ro
    privileged: true
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
EOF

echo "===== Creating directories for volumes ====="
mkdir -p pgdata zbx_env/usr/lib/zabbix/alertscripts \
         zbx_env/usr/lib/zabbix/externalscripts \
         zbx_env/var/lib/zabbix/export \
         zbx_env/var/lib/zabbix/modules \
         zbx_env/var/lib/zabbix/enc \
         zbx_env/var/lib/zabbix/ssh_keys \
         zbx_env/var/lib/zabbix/mibs \
         zbx_env/etc/zabbix/zabbix_agentd.d

echo "===== Setting correct permissions ====="
sudo chown -R 1995:1995 pgdata/ || true
sudo chmod -R 777 pgdata/ zbx_env/ || true

echo "===== Starting Zabbix containers ====="
sudo docker-compose up -d postgres
echo "Waiting for PostgreSQL to initialize (30 seconds)..."
sleep 30

echo "===== Starting remaining services ====="
sudo docker-compose up -d

echo "===== Installation completed ====="
echo "Zabbix should be running at http://$(hostname -I | awk '{print $1}')"
echo "Default login: Admin / zabbix"
echo ""
echo "To check logs if you have issues:"
echo "sudo docker logs zabbix-web"
echo "sudo docker logs zabbix-server"
echo "sudo docker logs postgres-server"