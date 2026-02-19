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

# Read token
echo "[DEBUG] Reading token file..."
TOKEN=$(cat /vagrant/confs/node-token)
if [ -z "$TOKEN" ]; then
    echo "[ERROR] Token is empty!"
    exit 1
fi
echo "[INFO] Token retrieved successfully!"

# Install K3s agent
echo "[INFO] Installing K3s agent..."
curl -sfL https://get.k3s.io | K3S_URL="https://${SERVER_IP}:6443" \
    K3S_TOKEN="${TOKEN}" \
    sh -s - agent --node-ip=${WORKER_IP}

# Wait for agent to start
echo "[INFO] Waiting for agent to start..."
sleep 30

# Setup kubectl alias
echo "alias k='kubectl'" >> /root/.profile
echo "alias k='kubectl'" >> /home/vagrant/.profile 2>/dev/null || true

echo "[INFO] K3s Agent installed successfully!"
