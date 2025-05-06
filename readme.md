# Cài tự động:

1. Cài docker
sh <(curl -L https://raw.githubusercontent.com/khanhvc-doc/zabbix/refs/heads/master/install_docker.sh)

2. Cài Zabbix
sh <(curl -L https://raw.githubusercontent.com/khanhvc-doc/zabbix/refs/heads/master/install_zabbix.sh)

3. Thành công:
Truy cập URL IP máy chủ zabbix, nhập thông tin
Admin/zabbix

# Cài từng dòng:


sudo apt update
sudo apt upgrade -y
lsb_release -a

sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo docker --version

sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

## add user to docker group
sudo usermod -aG docker $USER
newgrp docker

mkdir -p ~/zabbix-docker
cd ~/zabbix-docker
sudo chown -R $USER:$USER ~/zabbix-docker
chmod -R 755 ~/zabbix-docker
<!-- mkdir -p ~/zabbix-docker/zbx-data
sudo chown -R $USER:$USER ~/zabbix-docker/zbx-data
chmod -R 755 ~/zabbix-docker/zbx-data -->

sudo ufw allow 80/tcp
sudo ufw allow 10051/tcp

##### Env
nano .env

# PostgreSQL configuration
POSTGRES_USER=zabbix
POSTGRES_PASSWORD=zabbix_pwd
POSTGRES_DB=zabbix

# Zabbix configuration
ZBX_SERVER_HOST=zabbix-server
ZBX_JAVAGATEWAY_ENABLE=true

## YAML config
nano docker-compose.yml

#
version: '3.5'
services:
  postgres:
    image: postgres:15-alpine
    container_name: postgres-server
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - zabbix-net
    restart: always

  zabbix-server:
    image: zabbix/zabbix-server-pgsql:ubuntu-6.4-latest
    container_name: zabbix-server
    environment:
      - DB_SERVER_HOST=postgres
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
      - ZBX_JAVAGATEWAY_ENABLE=${ZBX_JAVAGATEWAY_ENABLE}
      - ZBX_JAVAGATEWAY=zabbix-java-gateway
    depends_on:
      - postgres
    networks:
      - zabbix-net
    ports:
      - "10051:10051"
    restart: always

  zabbix-web:
    image: zabbix/zabbix-web-nginx-pgsql:ubuntu-6.4-latest
    container_name: zabbix-web
    environment:
      - DB_SERVER_HOST=postgres
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
      - ZBX_SERVER_HOST=${ZBX_SERVER_HOST}
      - PHP_TZ=Asia/Ho_Chi_Minh
    depends_on:
      - postgres
      - zabbix-server
    networks:
      - zabbix-net
    ports:
      - "80:8080"
    restart: always

  zabbix-agent:
    image: zabbix/zabbix-agent2:ubuntu-6.4-latest
    container_name: zabbix-agent
    environment:
      - ZBX_HOSTNAME=zabbix-agent
      - ZBX_SERVER_HOST=zabbix-server
    networks:
      - zabbix-net
    restart: always

  zabbix-java-gateway:
    image: zabbix/zabbix-java-gateway:ubuntu-6.4-latest
    container_name: zabbix-java-gateway
    networks:
      - zabbix-net
    restart: always

networks:
  zabbix-net:
    driver: bridge

volumes:
  postgres-data:

#### put container to up
docker-compose up -d

## trouble shooting -- CHEKC
docker-compose ps
docker-compose logs
docker-compose logs zabbix-server

docker exec -it postgres-server psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "\l"

# database
docker exec -it postgres-server psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "\dt"
docker-compose logs zabbix-server

docker network inspect zabbix-net


##  Test
http://<địa_chỉ_IP_server>
Username: Admin
Password: zabbix

## check agent
docker exec -it zabbix-server zabbix_get -s zabbix-agent -k agent.ping
Nếu hoạt động bình thường, kết quả sẽ là "`1`".

