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

# Install K3s server
echo "[INFO] Installing K3s in SERVER mode..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=${SERVER_IP} --write-kubeconfig-mode=644" sh -

# Wait for K3s to start
echo "[INFO] Waiting for K3s to start..."
sleep 20

# Save token for worker
echo "[INFO] Saving token..."
mkdir -p /vagrant/confs
sudo cp /var/lib/rancher/k3s/server/node-token /vagrant/confs/

# Setup kubectl alias
echo "[INFO] Setting up kubectl alias..."
grep -qxF "alias k='kubectl'" /home/vagrant/.bashrc || echo "alias k='kubectl'" >> /home/vagrant/.bashrc
grep -qxF "alias k='kubectl'" /root/.bashrc || echo "alias k='kubectl'" >> /root/.bashrc


echo "[INFO] Server ready!"