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

# Install K3s server
echo "[INFO] Installing K3s in SERVER mode..."
curl -sfL https://get.k3s.io | sh -s - server \
    --node-ip=${SERVER_IP} \
    --write-kubeconfig-mode=644 > /dev/null 2>&1

# Wait for K3s API server to be ready
echo "[INFO] Waiting for K3s API server..."
until curl -k -s https://localhost:6443/readyz > /dev/null 2>&1; do
  sleep 3
done

# Wait for kubectl to work
echo "[INFO] Waiting for kubectl..."
until kubectl get nodes > /dev/null 2>&1; do
  sleep 3
done

echo "[INFO] K3s is ready!"

# Wait for token file to be created
echo "[INFO] Waiting for token file..."
until [ -f /var/lib/rancher/k3s/server/node-token ]; do
  sleep 2
done

# Create confs directory
echo "[INFO] Saving token for worker..."
mkdir -p /vagrant/confs
cp /var/lib/rancher/k3s/server/node-token /vagrant/confs/node-token
chmod 644 /vagrant/confs/node-token

# Verify token was saved
if [ -f /vagrant/confs/node-token ]; then
    echo "[INFO] Token saved successfully!"
else
    echo "[ERROR] Failed to save token!"
    exit 1
fi

# Setup kubectl alias
echo "alias k='kubectl'" >> /root/.profile
echo "alias k='kubectl'" >> /home/vagrant/.profile 2>/dev/null || true

echo "[INFO] Server ready!"