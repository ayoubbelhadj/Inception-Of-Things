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
echo -e "${BLUE}${BOLD}       GitLab Configuration Guide${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""

# Check if GitLab is installed
if ! kubectl get namespace ${GITLAB_NAMESPACE} &> /dev/null; then
    echo -e "${RED}[ERROR] GitLab namespace not found!${NC}"
    echo -e "${YELLOW}[INFO] Run: ./scripts/install-gitlab.sh${NC}"
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
echo ""

# Get root password
echo -e "${GREEN}[INFO] Getting GitLab root password...${NC}"
GITLAB_PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password -n ${GITLAB_NAMESPACE} -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)

if [ -z "$GITLAB_PASSWORD" ]; then
    echo -e "${RED}[ERROR] Could not retrieve GitLab password.${NC}"
    echo -e "${YELLOW}[INFO] Try manually: kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 -d${NC}"
    exit 1
fi

# Get GitLab version
GITLAB_VERSION=$(kubectl get pods -n ${GITLAB_NAMESPACE} -l app=webservice -o jsonpath='{.items[0].spec.containers[0].image}' | cut -d':' -f2)

echo ""
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}        GitLab Access Information${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""
echo -e "${CYAN}${BOLD}GitLab Version:${NC} ${GREEN}${GITLAB_VERSION}${NC}"
echo ""
echo -e "${CYAN}${BOLD}Admin Credentials:${NC}"
echo -e "  Username: ${GREEN}root${NC}"
echo -e "  Password: ${GREEN}${GITLAB_PASSWORD}${NC}"
echo ""
MY_IP=$(hostname -I | awk '{print $1}')
echo -e "${CYAN}${BOLD}Access GitLab UI:${NC}"
echo -e "  ${YELLOW}kubectl port-forward -n gitlab svc/gitlab-webservice-default 8082:8181 --address=0.0.0.0${NC}"
echo -e "  Then visit: ${MAGENTA}http://${MY_IP}:8082${NC}"
echo ""

echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""
echo -e "${GREEN}[✓] GitLab is ready to use!${NC}"
echo -e "${YELLOW}[NOTE] Keep the port-forward running to access GitLab${NC}"
echo ""