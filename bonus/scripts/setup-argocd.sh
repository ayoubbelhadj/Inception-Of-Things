#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

ARGOCD_NAMESPACE="argocd"
DEV_NAMESPACE="dev"
CLUSTER_NAME="iot-cluster"

echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}    Bonus: Install Argo CD${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""

# Check cluster exists
if ! k3d cluster list | grep -q ${CLUSTER_NAME}; then
    echo -e "${RED}[ERROR] Cluster '${CLUSTER_NAME}' not found!${NC}"
    echo -e "${YELLOW}[INFO] Run: ./setup-cluster.sh${NC}"
    exit 1
fi

# Create namespaces
echo -e "${GREEN}[INFO] Creating namespaces...${NC}"
kubectl create namespace ${ARGOCD_NAMESPACE} 2>/dev/null || true
kubectl create namespace ${DEV_NAMESPACE} 2>/dev/null || true

# Install Argo CD
echo -e "${GREEN}[INFO] Installing Argo CD (this may take 2-3 minutes)...${NC}"
kubectl apply --server-side=true -n ${ARGOCD_NAMESPACE} -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo -e "${GREEN}[INFO] Waiting for Argo CD to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment --all -n ${ARGOCD_NAMESPACE}

echo -e "${GREEN}[✓] Argo CD installed!${NC}"

# Get admin password
echo -e "${GREEN}[INFO] Getting Argo CD admin password...${NC}"
sleep 10
ARGOCD_PASSWORD=$(kubectl -n ${ARGOCD_NAMESPACE} get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}      Argo CD Installation Complete${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""
echo -e "${CYAN}${BOLD}Argo CD Admin Credentials:${NC}"
echo -e "  ${BOLD}Username:${NC} ${GREEN}admin${NC}"
echo -e "  ${BOLD}Password:${NC} ${GREEN}${ARGOCD_PASSWORD}${NC}"
echo ""
echo -e "${CYAN}${BOLD}To access Argo CD UI:${NC}"
echo -e "  ${YELLOW}kubectl port-forward svc/argocd-server -n argocd 8081:443${NC}"
echo -e "  Then visit: ${MAGENTA}https://localhost:8081${NC}"
echo ""
echo -e "${GREEN}[NEXT]${NC} Run: ${CYAN}./deploy-app.sh${NC}"
echo ""
