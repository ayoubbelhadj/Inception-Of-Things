#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

GITLAB_NAMESPACE="gitlab"

echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}       GitLab Configuration Guide${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""

# Check if GitLab is installed
if ! kubectl get namespace ${GITLAB_NAMESPACE} &> /dev/null; then
    echo -e "${YELLOW}[WARN]${NC} GitLab namespace not found!"
    echo -e "${YELLOW}[INFO]${NC} Run: sudo ./scripts/install-gitlab.sh"
    exit 1
fi

# Get root password
echo -e "${GREEN}[INFO]${NC} Getting GitLab root password..."
GITLAB_PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password -n ${GITLAB_NAMESPACE} -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)

if [ -z "$GITLAB_PASSWORD" ]; then
    echo -e "${YELLOW}[WARN]${NC} Password not found. GitLab may still be starting."
    echo -e "${YELLOW}[INFO]${NC} Check pods: kubectl get pods -n gitlab"
    exit 1
fi

echo ""
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}        GitLab Access Info${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""
echo -e "${CYAN}${BOLD}GitLab Credentials:${NC}"
echo -e "  Username: ${GREEN}root${NC}"
echo -e "  Password: ${GREEN}${GITLAB_PASSWORD}${NC}"
echo ""
echo -e "${CYAN}${BOLD}Step 1: Access GitLab UI${NC}"
echo -e "  ${YELLOW}kubectl port-forward -n gitlab svc/gitlab-webservice-default 8082:8181${NC}"
echo -e "  Visit: ${MAGENTA}http://localhost:8082${NC}"
echo ""
echo -e "${CYAN}${BOLD}Step 2: Create Project in GitLab${NC}"
echo -e "  1. Login with root + password above"
echo -e "  2. Click '${GREEN}New Project${NC}' → '${GREEN}Create blank project${NC}'"
echo -e "  3. Project name: ${GREEN}iot-app${NC}"
echo -e "  4. Visibility: ${GREEN}Public${NC}"
echo -e "  5. Uncheck '${GREEN}Initialize repository with a README${NC}'"
echo -e "  6. Click '${GREEN}Create project${NC}'"
echo ""
echo -e "${CYAN}${BOLD}Step 3: Push Your Code to GitLab${NC}"
echo -e "  ${YELLOW}cd ../p3/github-repo${NC}"
echo -e "  ${YELLOW}git remote add gitlab http://localhost:8082/root/iot-app.git${NC}"
echo -e "  ${YELLOW}git push gitlab main${NC}"
echo ""
echo -e "  Note: You'll be asked for username/password:"
echo -e "  - Username: ${GREEN}root${NC}"
echo -e "  - Password: ${GREEN}${GITLAB_PASSWORD}${NC}"
echo ""
echo -e "${CYAN}${BOLD}Step 4: Update Argo CD Application${NC}"
echo -e "  ${YELLOW}kubectl apply -f confs/application.yaml${NC}"
echo ""
echo -e "${CYAN}${BOLD}Step 5: Verify Deployment${NC}"
echo -e "  ${YELLOW}kubectl get application -n argocd${NC}"
echo -e "  ${YELLOW}kubectl get pods -n dev${NC}"
echo ""
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""