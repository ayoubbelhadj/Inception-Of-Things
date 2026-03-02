#!/bin/bash

# Get arguments
SERVER_IP=$1
LOGIN=$2

# Install packages
echo "[INFO] Installing required packages..."
apk update
apk add --no-cache curl bash

# Add hostname
echo "[INFO] Adding hostname to /etc/hosts..."
echo "${SERVER_IP} ${LOGIN}S" >> /etc/hosts

# Install K3s server
echo "[INFO] Installing K3s server..."
curl -sfL https://get.k3s.io | sh -s - server \
    --node-ip=${SERVER_IP} \
    --write-kubeconfig-mode=644

# Wait for K3s to initialize
echo "[INFO] Waiting for K3s to start..."
sleep 30

# Wait for kubectl to be ready
echo "[INFO] Waiting for kubectl to be ready..."
until kubectl get nodes 2>/dev/null; do
  echo "[INFO] kubectl not ready yet, waiting..."
  sleep 5
done

echo "[INFO] K3s is ready!"

# Deploy applications
echo "[INFO] Deploying applications..."
kubectl apply -f /vagrant/confs/deployments.yaml
kubectl apply -f /vagrant/confs/services.yaml
kubectl apply -f /vagrant/confs/ingress.yaml

# Wait for all deployments to be ready
echo "[INFO] Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=180s deployment --all -n iot-part2

# Show status
echo ""
echo "[INFO] ========== DEPLOYMENT STATUS =========="
kubectl get all

echo ""
echo "[INFO] ========== INGRESS =========="
kubectl get ingress

# Setup kubectl alias
echo "alias k='kubectl'" >> /root/.profile
echo "alias k='kubectl'" >> /home/vagrant/.profile 2>/dev/null || true

# Success message
echo ""
echo "[INFO] setup complete!"
echo ""
echo "[INFO] Access your apps:"
echo "[INFO]   App 1: curl -H 'Host: app1.com' http://192.168.56.110"
echo "[INFO]   App 2: curl -H 'Host: app2.com' http://192.168.56.110"
echo "[INFO]   App 3: curl http://192.168.56.110"
echo ""