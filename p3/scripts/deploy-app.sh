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

# Check application status
echo -e "${GREEN}[INFO] Checking application status...${NC}"
sleep 3

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

# Wait for pod to be ready
echo ""
echo -e "${GREEN}[INFO] Waiting for app pod to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=wil-playground -n ${DEV_NAMESPACE} --timeout=120s 2>/dev/null

# Get external IP
EXTERNAL_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || curl -s ipecho.net/plain || echo "localhost")

echo ""
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}        Deployment Complete!${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""

echo -e "${CYAN}${BOLD}Access Your Application:${NC}"
echo -e "  ${MAGENTA}${BOLD}http://${EXTERNAL_IP}:8080${NC}"
echo ""
echo -e "${GREEN}${BOLD}Test:${NC}"
echo -e "  ${YELLOW}curl http://${EXTERNAL_IP}:8080${NC}"
echo -e "  ${CYAN}# Expected: {\"status\":\"ok\", \"message\": \"v1\"}${NC}"
echo ""