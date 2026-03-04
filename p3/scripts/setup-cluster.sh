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

# Variables
CLUSTER_NAME="iot-cluster"
ARGOCD_NAMESPACE="argocd"
DEV_NAMESPACE="dev"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] Please run as root (use sudo)"
    exit 1
fi

# Check required tools
echo -e "${GREEN}[INFO] Checking required tools...${NC}"
MISSING_TOOLS=0

if ! command -v docker &> /dev/null; then
    echo -e "${RED}[ERROR] Docker not found! Run: sudo ./scripts/install-tools.sh${NC}"
    MISSING_TOOLS=1
fi

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}[ERROR] kubectl not found! Run: sudo ./scripts/install-tools.sh${NC}"
    MISSING_TOOLS=1
fi

if ! command -v k3d &> /dev/null; then
    echo -e "${RED}[ERROR] K3d not found! Run: sudo ./scripts/install-tools.sh${NC}"
    MISSING_TOOLS=1
fi

if [ $MISSING_TOOLS -eq 1 ]; then
    exit 1
fi

echo -e "${GREEN}[✓]${NC} All required tools found!"
echo ""

echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}    Part 3: Setup K3d Cluster${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""

# Create K3d cluster
echo -e "${GREEN}[INFO] Creating K3d cluster:${NC} ${CYAN}${CLUSTER_NAME}${NC}..."

# Delete existing cluster if exists
k3d cluster delete ${CLUSTER_NAME} 2>/dev/null

# Create new cluster
k3d cluster create ${CLUSTER_NAME} \
    --port "8080:80@loadbalancer" \
    --port "8443:443@loadbalancer" \
    --agents 1

echo -e "${GREEN}[✓] K3d cluster created!${NC}"

# Wait for cluster to be ready
echo -e "${GREEN}[INFO] Waiting for cluster to be ready...${NC}"
kubectl wait --for=condition=Ready nodes --all --timeout=120s

echo -e "${GREEN}[✓] Cluster is ready!${NC}"

# Create namespaces
echo -e "${GREEN}[INFO] Creating namespaces:${NC} ${CYAN}${ARGOCD_NAMESPACE}${NC}, ${CYAN}${DEV_NAMESPACE}${NC}..."
kubectl create namespace ${ARGOCD_NAMESPACE}
kubectl create namespace ${DEV_NAMESPACE}

echo -e "${GREEN}[✓] Namespaces created!${NC}"

# Install Argo CD
echo -e "${GREEN}[INFO] Installing Argo CD (this may take 2-3 minutes)...${NC}"
kubectl apply --server-side=true -n ${ARGOCD_NAMESPACE} -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo -e "${GREEN}[INFO] Waiting for Argo CD to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment --all -n ${ARGOCD_NAMESPACE}

echo -e "${GREEN}[✓] Argo CD installed!${NC}"

# Get Argo CD admin password
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
echo -e "  ${YELLOW}sudo kubectl port-forward svc/argocd-server -n argocd 8081:443${NC}"
echo -e "  Then visit: ${MAGENTA}https://localhost:8081${NC}"
echo ""

echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}          Setup Complete!${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""