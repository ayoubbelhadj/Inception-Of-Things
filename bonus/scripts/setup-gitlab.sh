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
    echo -e "${RED}[ERROR]${NC} GitLab namespace not found!"
    echo -e "${YELLOW}[INFO]${NC} Run: ./scripts/install-gitlab.sh"
    exit 1
fi

# Check if webservice is ready
echo -e "${GREEN}[INFO]${NC} Checking GitLab status..."
WEBSERVICE_READY=$(kubectl get pods -n ${GITLAB_NAMESPACE} -l app=webservice -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)

if [ "$WEBSERVICE_READY" != "True" ]; then
    echo -e "${YELLOW}[WARN]${NC} GitLab webservice is not ready yet."
    echo -e "${YELLOW}[INFO]${NC} Current status:"
    kubectl get pods -n ${GITLAB_NAMESPACE} -l app=webservice
    echo ""
    echo -e "${YELLOW}[INFO]${NC} Wait for webservice to show 2/2 Running, then run this script again."
    exit 1
fi

echo -e "${GREEN}[✓]${NC} GitLab is ready!"
echo ""

# Get root password
echo -e "${GREEN}[INFO]${NC} Getting GitLab root password..."
GITLAB_PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password -n ${GITLAB_NAMESPACE} -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)

if [ -z "$GITLAB_PASSWORD" ]; then
    echo -e "${RED}[ERROR]${NC} Could not retrieve GitLab password."
    echo -e "${YELLOW}[INFO]${NC} Try manually: kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 -d"
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
echo -e "${CYAN}${BOLD}Access GitLab UI:${NC}"
echo -e "  ${YELLOW}kubectl port-forward -n gitlab svc/gitlab-webservice-default 8082:8181${NC}"
echo -e "  Then visit: ${MAGENTA}http://localhost:8082${NC}"
echo ""

echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}    Step-by-Step Setup Instructions${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""

echo -e "${CYAN}${BOLD}Step 1: Access GitLab UI${NC}"
echo -e "  Open a new terminal and run:"
echo -e "    ${YELLOW}kubectl port-forward -n gitlab svc/gitlab-webservice-default 8082:8181${NC}"
echo ""
echo -e "  Keep this terminal open and visit in browser:"
echo -e "    ${MAGENTA}http://localhost:8082${NC}"
echo ""

echo -e "${CYAN}${BOLD}Step 2: Login to GitLab${NC}"
echo -e "  Username: ${GREEN}root${NC}"
echo -e "  Password: ${GREEN}${GITLAB_PASSWORD}${NC}"
echo ""

echo -e "${CYAN}${BOLD}Step 3: Create a New Project${NC}"
echo -e "  1. Click '${GREEN}New Project${NC}' or '${GREEN}Create a project${NC}'"
echo -e "  2. Choose '${GREEN}Create blank project${NC}'"
echo -e "  3. Project name: ${GREEN}iot-app${NC}"
echo -e "  4. Visibility Level: ${GREEN}Public${NC}"
echo -e "  5. ${YELLOW}Uncheck${NC} '${GREEN}Initialize repository with a README${NC}'"
echo -e "  6. Click '${GREEN}Create project${NC}'"
echo ""

echo -e "${CYAN}${BOLD}Step 4: Get GitLab Repository URL${NC}"
echo -e "  After creating the project, you'll see:"
echo -e "    ${GREEN}http://localhost:8082/root/iot-app.git${NC}"
echo ""

echo -e "${CYAN}${BOLD}Step 5: Push Your Code to GitLab${NC}"
echo -e "  ${YELLOW}cd ../../p3/github-repo${NC}"
echo -e "  ${YELLOW}git remote add gitlab http://localhost:8082/root/iot-app.git${NC}"
echo -e "  ${YELLOW}git push gitlab main${NC}"
echo ""
echo -e "  When prompted:"
echo -e "    Username: ${GREEN}root${NC}"
echo -e "    Password: ${GREEN}${GITLAB_PASSWORD}${NC}"
echo ""

echo -e "${CYAN}${BOLD}Step 6: Update Argo CD Application${NC}"
echo -e "  The application.yaml should use the internal GitLab URL:"
echo -e "    ${GREEN}http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/iot-app.git${NC}"
echo ""
echo -e "  Deploy the application:"
echo -e "    ${YELLOW}kubectl apply -f ../confs/application.yaml${NC}"
echo ""

echo -e "${CYAN}${BOLD}Step 7: Verify Deployment${NC}"
echo -e "  ${YELLOW}kubectl get application -n argocd${NC}"
echo -e "  ${YELLOW}kubectl get pods -n dev${NC}"
echo ""

echo -e "${CYAN}${BOLD}Step 8: Test Version Change (v1 → v2)${NC}"
echo -e "  In GitLab UI:"
echo -e "    1. Navigate to ${GREEN}Repository → Files${NC}"
echo -e "    2. Open ${GREEN}dev/deployment.yaml${NC}"
echo -e "    3. Click '${GREEN}Edit${NC}'"
echo -e "    4. Change: ${YELLOW}wil42/playground:v1${NC} → ${GREEN}wil42/playground:v2${NC}"
echo -e "    5. Add commit message: ${GREEN}Update to v2${NC}"
echo -e "    6. Click '${GREEN}Commit changes${NC}'"
echo ""
echo -e "  Watch Argo CD sync:"
echo -e "    ${YELLOW}kubectl get application -n argocd -w${NC}"
echo ""

echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}         Quick Reference Commands${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""
echo -e "${CYAN}Access GitLab:${NC}"
echo -e "  ${YELLOW}kubectl port-forward -n gitlab svc/gitlab-webservice-default 8082:8181${NC}"
echo ""
echo -e "${CYAN}Check GitLab Pods:${NC}"
echo -e "  ${YELLOW}kubectl get pods -n gitlab${NC}"
echo ""
echo -e "${CYAN}Check Argo CD:${NC}"
echo -e "  ${YELLOW}kubectl get application -n argocd${NC}"
echo ""
echo -e "${CYAN}Check Application:${NC}"
echo -e "  ${YELLOW}kubectl get pods -n dev${NC}"
echo ""
echo -e "${CYAN}View GitLab Logs:${NC}"
echo -e "  ${YELLOW}kubectl logs -n gitlab -l app=webservice --tail=50${NC}"
echo ""
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""
echo -e "${GREEN}[✓]${NC} GitLab is ready to use!"
echo -e "${YELLOW}[NOTE]${NC} Keep the port-forward running to access GitLab"
echo ""