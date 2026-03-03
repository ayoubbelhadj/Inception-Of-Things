#!/bin/bash

# Get arguments
SERVER_IP=$1
WORKER_IP=$2
LOGIN=$3

# Install packages
echo "[INFO] Installing required packages..."
apk update > /dev/null 2>&1
apk add --no-cache curl net-tools netcat-openbsd bash > /dev/null 2>&1

# Add hostnames to /etc/hosts
echo "[INFO] Adding hostname entries..."
echo "${SERVER_IP} ${LOGIN}S" >> /etc/hosts
echo "${WORKER_IP} ${LOGIN}SW" >> /etc/hosts

# Wait for token file from server
echo "[INFO] Waiting for server token..."
until [ -f /vagrant/confs/node-token ]; do
  sleep 3
done

# Read token
TOKEN=$(cat /vagrant/confs/node-token)
if [ -z "$TOKEN" ]; then
    echo "[ERROR] Token is empty!"
    exit 1
fi
echo "[INFO] Token retrieved!"

# Wait for server to be ready
echo "[INFO] Waiting for server to be reachable..."
until nc -z ${SERVER_IP} 6443 > /dev/null 2>&1; do
  sleep 3
done
echo "[INFO] Server is reachable!"

# Install K3s agent
echo "[INFO] Installing K3s agent..."
curl -sfL https://get.k3s.io | K3S_URL="https://${SERVER_IP}:6443" \
    K3S_TOKEN="${TOKEN}" \
    sh -s - agent --node-ip=${WORKER_IP} > /dev/null 2>&1

# Wait for agent service to be active
echo "[INFO] Waiting for agent service..."
until rc-service k3s-agent status > /dev/null 2>&1; do
  sleep 3
done

# Setup kubectl alias
echo "alias k='kubectl'" >> /root/.profile
echo "alias k='kubectl'" >> /home/vagrant/.profile 2>/dev/null || true

echo "[INFO] K3s Agent installed successfully!"