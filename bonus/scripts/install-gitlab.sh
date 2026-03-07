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
GITLAB_NAMESPACE="gitlab"
CLUSTER_NAME="iot-cluster"
VALUES_FILE="../confs/gitlab-values.yaml"

echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}    Bonus: Install GitLab Locally${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""

# Check if values file exists
if [ ! -f "$VALUES_FILE" ]; then
    echo -e "${RED}[ERROR] Values file not found: ${VALUES_FILE}${NC}"
    echo -e "${YELLOW}[INFO] Make sure gitlab-values.yaml exists in confs/${NC}"
    exit 1
fi

# Check if cluster exists
echo -e "${GREEN}[INFO] Checking cluster...${NC}"
if ! k3d cluster list | grep -q ${CLUSTER_NAME}; then
    echo -e "${RED}[ERROR] Cluster '${CLUSTER_NAME}' not found!${NC}"
    echo -e "${YELLOW}[INFO] First run: ./setup-cluster.sh${NC}"
    exit 1
fi

echo -e "${GREEN}[✓] Cluster found!${NC}"

# Install Helm
echo -e "${GREEN}[INFO] Checking Helm installation...${NC}"
if ! command -v helm &> /dev/null; then
    echo -e "${GREEN}[INFO] Installing Helm...${NC}"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash > /dev/null 2>&1
    echo -e "${GREEN}[✓] Helm installed!${NC}"
else
    echo -e "${GREEN}[✓] Helm already installed${NC}"
fi

# Create GitLab namespace
echo -e "${GREEN}[INFO] Creating namespace:${NC} ${CYAN}${GITLAB_NAMESPACE}${NC}..."
kubectl create namespace ${GITLAB_NAMESPACE} 2>/dev/null || echo -e "${YELLOW}[INFO] Namespace already exists${NC}"

echo -e "${GREEN}[✓] Namespace ready!${NC}"

# Add GitLab Helm repository
echo -e "${GREEN}[INFO] Adding GitLab Helm repository...${NC}"
helm repo add gitlab https://charts.gitlab.io/ > /dev/null 2>&1
helm repo update > /dev/null 2>&1

echo -e "${GREEN}[✓] Helm repository added!${NC}"

# Install GitLab using values file
echo -e "${GREEN}[INFO] Installing GitLab ...${NC}"

helm install gitlab gitlab/gitlab \
  --namespace ${GITLAB_NAMESPACE} \
  --values ${VALUES_FILE} \
  --timeout 30m

if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR] GitLab installation failed!${NC}"
    echo -e "${YELLOW}[INFO] Run cleanup and try again:${NC}"
    echo -e "  ${CYAN}./cleanup-gitlab.sh${NC}"
    exit 1
fi

echo -e "${GREEN}[✓] GitLab installed!${NC}"
echo ""
echo -e "${GREEN}[INFO] Waiting for GitLab pods to be ready...${NC}"
echo -e "${YELLOW}[INFO] Monitor progress with:${NC}"
echo -e "  ${CYAN}kubectl get pods -n gitlab -w${NC}"
echo ""

# Wait for webservice to be ready
echo -e "${GREEN}[INFO] Waiting for webservice pod (timeout: 30 minutes)...${NC}"
kubectl wait --for=condition=ready pod -l app=webservice -n ${GITLAB_NAMESPACE} --timeout=1800s 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}[✓] GitLab is ready!${NC}"
else
    echo -e "${YELLOW}[WARN] GitLab may still be starting.${NC}"
    echo -e "${YELLOW}[INFO] Check status: kubectl get pods -n gitlab${NC}"
fi

echo ""
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}      GitLab Installation Complete${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""
echo -e "${GREEN}[NEXT]${NC} Run: ${CYAN}./setup-gitlab.sh${NC}"
echo ""
