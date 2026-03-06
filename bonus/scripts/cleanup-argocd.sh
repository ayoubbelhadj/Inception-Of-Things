#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

ARGOCD_NAMESPACE="argocd"
DEV_NAMESPACE="dev"

echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}    Bonus: Cleanup Argo CD${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""

# Remove application
echo -e "${GREEN}[INFO] Removing Argo CD application...${NC}"
kubectl delete -f ../confs/application.yaml 2>/dev/null || true

# Delete dev namespace
echo -e "${GREEN}[INFO] Deleting namespace: ${CYAN}${DEV_NAMESPACE}${NC}..."
kubectl delete namespace ${DEV_NAMESPACE} 2>/dev/null || true

# Delete argocd namespace
echo -e "${GREEN}[INFO] Deleting namespace: ${CYAN}${ARGOCD_NAMESPACE}${NC}..."
kubectl delete namespace ${ARGOCD_NAMESPACE} 2>/dev/null || true

echo ""
echo -e "${GREEN}[✓] Argo CD cleanup complete!${NC}"
echo ""
