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
APP_NAME="playground-app"
ARGOCD_NAMESPACE="argocd"
DEV_NAMESPACE="dev"
APP_FILE="../confs/application.yaml"

echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}    Deploy Application via Argo CD${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""

# Deploy application
echo -e "${GREEN}[INFO] Deploying application:${NC} ${CYAN}${APP_NAME}${NC}..."
kubectl apply -f ${APP_FILE}

echo -e "${GREEN}[✓] Application manifest applied!${NC}"

# Wait for application to be created
echo -e "${GREEN}[INFO] Waiting for application to be recognized...${NC}"
sleep 5

# Check application status
echo -e "${GREEN}[INFO] Checking application status...${NC}"
kubectl get application ${APP_NAME} -n ${ARGOCD_NAMESPACE} &> /dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[✓] Application registered in Argo CD!${NC}"
else
    echo -e "${RED}[ERROR] Application not found in Argo CD!${NC}"
    exit 1
fi

# Wait for sync
echo -e "${GREEN}[INFO] Waiting for Argo CD to sync ...${NC}"
COUNTER=0
while [ $COUNTER -lt 60 ]; do
    SYNC_STATUS=$(kubectl get application ${APP_NAME} -n ${ARGOCD_NAMESPACE} -o jsonpath='{.status.sync.status}' 2>/dev/null)
    HEALTH_STATUS=$(kubectl get application ${APP_NAME} -n ${ARGOCD_NAMESPACE} -o jsonpath='{.status.health.status}' 2>/dev/null)
    
    if [ "$SYNC_STATUS" == "Synced" ] && [ "$HEALTH_STATUS" == "Healthy" ]; then
        echo -e "${GREEN}[✓] Application synced and healthy!${NC}"
        break
    fi

    sleep 5
    COUNTER=$((COUNTER+1))
done

if [ $COUNTER -eq 60 ]; then
    echo -e "${YELLOW}[WARN] Sync timeout, but application may still be deploying...${NC}"
fi

echo ""
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}        Deployment Complete!${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""
echo -e "${GREEN}${BOLD}Next steps:${NC}"
echo -e "  1. Test the app:"
echo -e "     ${YELLOW}sudo kubectl port-forward -n dev svc/playground-service 8888:8888${NC}"
echo -e "     ${YELLOW}curl http://localhost:8888${NC}"
echo ""
echo -e "  2. View in Argo CD UI:"
echo -e "     ${YELLOW}sudo kubectl port-forward svc/argocd-server -n argocd 8081:443${NC}"
echo -e "     Visit: ${MAGENTA}https://localhost:8081${NC}"
echo ""
echo -e "  3. Change version:"
echo -e "     ${YELLOW}Edit github-repo/dev/deployment.yaml${NC}"
echo -e "     ${YELLOW}Change: wil42/playground:v1 → wil42/playground:v2${NC}"
echo -e "     ${YELLOW}git commit & push${NC}"
echo ""