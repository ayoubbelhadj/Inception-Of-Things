#!/bin/bash

# Get arguments
SERVER_IP=$1
WORKER_IP=$2
LOGIN=$3

# Install packages
echo "[INFO] Installing required packages..."
apt-get update
apt-get install -y curl net-tools

# Add hostnames to /etc/hosts
echo "[INFO] Adding hostname entries..."
echo "${SERVER_IP} ${LOGIN}S" >> /etc/hosts
echo "${WORKER_IP} ${LOGIN}SW" >> /etc/hosts

# Wait for token file from server
echo "[INFO] Waiting for server token..."
while [ ! -f /vagrant/confs/node-token ]; do
  echo "[INFO] Token not found, waiting..."
  sleep 5
done

# Read token
TOKEN=$(cat /vagrant/confs/node-token)
echo "[INFO] Token retrieved!"

# Wait for server to be ready
echo "[INFO] Testing server connectivity..."
until nc -z ${SERVER_IP} 6443; do
  echo "[INFO] Waiting for server port 6443..."
  sleep 5
done
echo "[INFO] Server is reachable!"

# Install K3s agent
echo "[INFO] Installing K3s agent..."
curl -sfL https://get.k3s.io | \
    K3S_URL="https://${SERVER_IP}:6443" \
    K3S_TOKEN="${TOKEN}" \
    INSTALL_K3S_EXEC="agent --node-ip=${WORKER_IP}" sh -

# Setup kubectl alias
echo "[INFO] Setting up kubectl alias..."
grep -qxF "alias k='kubectl'" /home/vagrant/.bashrc || echo "alias k='kubectl'" >> /home/vagrant/.bashrc
grep -qxF "alias k='kubectl'" /root/.bashrc || echo "alias k='kubectl'" >> /root/.bashrc


echo "[INFO] K3s Agent installed successfully!"