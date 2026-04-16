#!/bin/bash
set -e

echo "================================================================"
echo " CÀI ĐẶT DOCKER"
echo "================================================================"

echo ""
echo "[1/4] Cập nhật hệ thống..."
sudo apt update && sudo apt upgrade -y

echo ""
echo "[2/4] Cài Docker Engine..."
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo docker --version

echo ""
echo "[3/4] Cấu hình Docker data-root → /data/docker (Disk 2)..."
sudo mkdir -p /data/docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "data-root": "/data/docker",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
EOF
sudo systemctl restart docker
sudo systemctl enable docker

echo ""
echo "[4/4] Cài Docker Compose plugin..."
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

# Thêm user vào group docker
sudo usermod -aG docker $USER

echo ""
echo "================================================================"
echo " ✅ Docker đã cài xong!"
echo "    data-root : /data/docker  (Disk 2 - 200GB)"
echo "    ⚠️  Vui lòng LOGOUT và LOGIN lại để áp dụng group docker"
echo "================================================================"
