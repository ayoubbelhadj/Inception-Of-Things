#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Variables
CLUSTER_NAME="iot-cluster"

echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}        Part 3 Cleanup Script${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""

# Stop port-forwards
echo -e "${GREEN}[INFO] Stopping port-forward processes...${NC}"
pkill -f "port-forward.*argocd" 2>/dev/null || true

# Delete K3d cluster
echo -e "${GREEN}[INFO] Deleting K3d cluster:${NC} ${CYAN}${CLUSTER_NAME}${NC}..."
if k3d cluster list 2>/dev/null | grep -q ${CLUSTER_NAME}; then
    k3d cluster delete ${CLUSTER_NAME}
    echo -e "${GREEN}[✓] Cluster deleted!${NC}"
else
    echo -e "${GREEN}[INFO] No cluster found to delete${NC}"
fi

# Clean up kubeconfig
echo -e "${GREEN}[INFO] Cleaning up kubeconfig...${NC}"
kubectl config delete-context k3d-${CLUSTER_NAME} 2>/dev/null || true
kubectl config delete-cluster k3d-${CLUSTER_NAME} 2>/dev/null || true

# Clean Docker networks
echo -e "${GREEN}[INFO] Cleaning up Docker networks...${NC}"
docker network prune -f 2>/dev/null || true

echo ""
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}         Cleanup Complete!${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""
echo -e "${GREEN}[✓] Cluster removed successfully!${NC}"
echo -e "${YELLOW}[NOTE]${NC} To recreate cluster: ${CYAN}sudo ./setup-cluster.sh${NC}"
echo ""