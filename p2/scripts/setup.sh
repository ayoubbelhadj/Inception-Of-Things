#!/bin/bash

# Get arguments
SERVER_IP=$1
LOGIN=$2

# Install packages
echo "[INFO] Installing required packages..."
apk update  > /dev/null 2>&1
apk add --no-cache curl bash  > /dev/null 2>&1

# Add hostname
echo "[INFO] Adding hostname to /etc/hosts..."
echo "${SERVER_IP} ${LOGIN}S" >> /etc/hosts

# Install K3s server
echo "[INFO] Installing K3s server..."
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

# Deploy applications
echo "[INFO] Deploying applications..."
kubectl apply -f /vagrant/confs/deployments.yaml > /dev/null 2>&1
kubectl apply -f /vagrant/confs/services.yaml > /dev/null 2>&1
kubectl apply -f /vagrant/confs/ingress.yaml > /dev/null 2>&1

# Wait for all deployments to be ready
echo "[INFO] Waiting for pods to be ready..."
kubectl wait --for=condition=available --timeout=180s deployment --all > /dev/null 2>&1

# Wait for ingress to be configured
echo "[INFO] Configuring ingress routes..."
sleep 15

# Test connectivity
echo "[INFO] Testing ingress connectivity..."
COUNTER=0
until curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null | grep -q "200"; do
  sleep 5
  COUNTER=$((COUNTER+1))
  if [ $COUNTER -gt 60 ]; then
    echo "[ERROR] Ingress failed to respond after 5 minutes"
    exit 1
  fi
done

echo "[INFO] Ingress is ready!"


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