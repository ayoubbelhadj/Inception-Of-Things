#!/bin/bash

# Get arguments
SERVER_IP=$1
WORKER_IP=$2
LOGIN=$3

# Install packages
echo "[INFO] Installing required packages..."
apk update
apk add --no-cache curl net-tools netcat-openbsd bash

# Add hostnames to /etc/hosts
echo "[INFO] Adding hostname entries..."
echo "${SERVER_IP} ${LOGIN}S" >> /etc/hosts
echo "${WORKER_IP} ${LOGIN}SW" >> /etc/hosts

# Install K3s server
echo "[INFO] Installing K3s in SERVER mode..."
curl -sfL https://get.k3s.io | sh -s - server \
    --node-ip=${SERVER_IP} \
    --write-kubeconfig-mode=644

# Wait for K3s to start
echo "[INFO] Waiting for K3s to start..."
sleep 30

# Create confs directory
echo "[DEBUG] Creating /vagrant/confs directory..."
mkdir -p /vagrant/confs
if [ ! -d /vagrant/confs ]; then
    echo "[ERROR] Failed to create /vagrant/confs!"
    exit 1
fi
chmod 755 /vagrant/confs
echo "[INFO] Directory created"

# Copy token
echo "[DEBUG] Copying token file..."
cp /var/lib/rancher/k3s/server/node-token /vagrant/confs/node-token
chmod 644 /vagrant/confs/node-token


# Setup kubectl alias
echo "alias k='kubectl'" >> /root/.profile
echo "alias k='kubectl'" >> /home/vagrant/.profile 2>/dev/null || true

echo "[INFO] Server ready!"