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

echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}    Bonus: Install GitLab Locally${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR]${NC} Please run as root (use sudo)"
    exit 1
fi

# Check if cluster exists
echo -e "${GREEN}[INFO]${NC} Checking cluster..."
if ! k3d cluster list | grep -q ${CLUSTER_NAME}; then
    echo -e "${RED}[ERROR]${NC} Cluster '${CLUSTER_NAME}' not found!"
    echo -e "${YELLOW}[INFO]${NC} First run: cd ../p3 && sudo ./scripts/setup-cluster.sh"
    exit 1
fi

echo -e "${GREEN}[✓]${NC} Cluster found!"

# Check resources
echo -e "${YELLOW}[WARN]${NC} GitLab requires significant resources:"
echo -e "  - Minimum: 4GB RAM, 2 CPUs"
echo -e "  - Recommended: 8GB RAM, 4 CPUs"
echo -e "  - Installation time: 10-15 minutes"
echo ""
read -p "$(echo -e ${YELLOW}Continue? \(y/n\): ${NC})" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Install Helm
echo -e "${GREEN}[INFO]${NC} Checking Helm installation..."
if ! command -v helm &> /dev/null; then
    echo -e "${GREEN}[INFO]${NC} Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash > /dev/null 2>&1
    echo -e "${GREEN}[✓]${NC} Helm installed!"
else
    echo -e "${GREEN}[✓]${NC} Helm already installed"
fi

# Create GitLab namespace
echo -e "${GREEN}[INFO]${NC} Creating namespace: ${CYAN}${GITLAB_NAMESPACE}${NC}..."
kubectl create namespace ${GITLAB_NAMESPACE} 2>/dev/null || echo -e "${YELLOW}[INFO]${NC} Namespace already exists"

echo -e "${GREEN}[✓]${NC} Namespace ready!"

# Add GitLab Helm repository
echo -e "${GREEN}[INFO]${NC} Adding GitLab Helm repository..."
helm repo add gitlab https://charts.gitlab.io/ > /dev/null 2>&1
helm repo update > /dev/null 2>&1

echo -e "${GREEN}[✓]${NC} Helm repository added!"

# Install GitLab with corrected values
echo -e "${GREEN}[INFO]${NC} Installing GitLab..."
echo -e "${YELLOW}[INFO]${NC} This will take 10-15 minutes. Please be patient."
echo ""

helm install gitlab gitlab/gitlab \
  --namespace ${GITLAB_NAMESPACE} \
  --set global.hosts.domain=gitlab.local \
  --set global.hosts.externalIP=127.0.0.1 \
  --set global.ingress.configureCertmanager=false \
  --set global.ingress.enabled=false \
  --set nginx-ingress.enabled=false \
  --set gitlab-runner.install=false \
  --set prometheus.install=false \
  --set redis.metrics.enabled=false \
  --set postgresql.metrics.enabled=false \
  --set global.edition=ce \
  --timeout 15m

if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR]${NC} GitLab installation failed!"
    echo -e "${YELLOW}[INFO]${NC} Run cleanup and try again:"
    echo -e "  ${CYAN}./scripts/cleanup.sh${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}[✓]${NC} GitLab installation started!"
echo ""
echo -e "${GREEN}[INFO]${NC} Waiting for GitLab pods to be ready..."
echo -e "${YELLOW}[INFO]${NC} Monitor progress with:"
echo -e "  ${CYAN}kubectl get pods -n gitlab -w${NC}"
echo ""

# Wait for webservice to be ready (with timeout)
echo -e "${GREEN}[INFO]${NC} Waiting for webservice pod (timeout: 15 minutes)..."
kubectl wait --for=condition=ready pod -l app=webservice -n ${GITLAB_NAMESPACE} --timeout=900s 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}[✓]${NC} GitLab is ready!"
else
    echo -e "${YELLOW}[WARN]${NC} GitLab may still be starting."
    echo -e "${YELLOW}[INFO]${NC} Check status: kubectl get pods -n gitlab"
fi

echo ""
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}      GitLab Installation Complete${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""
echo -e "${GREEN}[NEXT]${NC} Run: ${CYAN}./scripts/setup-gitlab.sh${NC}"
echo ""