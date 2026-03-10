#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

GITLAB_NAMESPACE="gitlab"

echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}       GitLab Configuration${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""

# Check if GitLab is installed
if ! kubectl get namespace ${GITLAB_NAMESPACE} &> /dev/null; then
    echo -e "${RED}[ERROR] GitLab namespace not found!${NC}"
    echo -e "${YELLOW}[INFO] Run: ./install-gitlab.sh${NC}"
    exit 1
fi

# Check if webservice is ready
echo -e "${GREEN}[INFO] Checking GitLab status...${NC}"
WEBSERVICE_READY=$(kubectl get pods -n ${GITLAB_NAMESPACE} -l app=webservice -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)

if [ "$WEBSERVICE_READY" != "True" ]; then
    echo -e "${YELLOW}[WARN] GitLab webservice is not ready yet.${NC}"
    echo -e "${YELLOW}[INFO] Current status:${NC}"
    kubectl get pods -n ${GITLAB_NAMESPACE} -l app=webservice
    echo ""
    echo -e "${YELLOW}[INFO] Wait for webservice to show 2/2 Running, then run this script again.${NC}"
    exit 1
fi

echo -e "${GREEN}[✓] GitLab is ready!${NC}"

# Apply NodePort service
echo -e "${GREEN}[INFO] Creating NodePort service for GitLab...${NC}"
kubectl apply -f ../confs/gitlab-nodeport.yaml

echo -e "${GREEN}[✓] NodePort service created!${NC}"

# Get root password
echo -e "${GREEN}[INFO] Getting GitLab root password...${NC}"
GITLAB_PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password -n ${GITLAB_NAMESPACE} -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)

if [ -z "$GITLAB_PASSWORD" ]; then
    echo -e "${RED}[ERROR] Could not retrieve GitLab password.${NC}"
    exit 1
fi

# Get external IP
EXTERNAL_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || echo "localhost")

echo ""
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}        GitLab Access Information${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""
echo -e "${CYAN}${BOLD}Admin Credentials:${NC}"
echo -e "  Username: ${GREEN}root${NC}"
echo -e "  Password: ${GREEN}${GITLAB_PASSWORD}${NC}"
echo ""
echo -e "${CYAN}${BOLD}Access GitLab UI:${NC}"
echo -e "  ${MAGENTA}${BOLD}http://${EXTERNAL_IP}:30081${NC}"
echo ""
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""

# Save credentials
cat > ../gitlab-credentials.txt << EOF
GitLab Access Information
=========================

URL: http://${EXTERNAL_IP}:30081
Username: root
Password: ${GITLAB_PASSWORD}

Repository URL: http://${EXTERNAL_IP}:30081/root/iot-abelhadj.git
EOF

echo -e "${CYAN}[INFO] Credentials saved to: ../gitlab-credentials.txt${NC}"
echo ""