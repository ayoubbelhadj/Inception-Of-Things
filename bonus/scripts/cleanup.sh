#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

GITLAB_NAMESPACE="gitlab"

echo -e "${CYAN}Cleaning up GitLab...${NC}"
echo ""

# Stop port-forwards
pkill -f "port-forward.*gitlab" 2>/dev/null

# Uninstall GitLab
echo -e "${GREEN}[INFO]${NC} Uninstalling GitLab..."
helm uninstall gitlab -n ${GITLAB_NAMESPACE} 2>/dev/null || true

# Delete namespace
echo -e "${GREEN}[INFO]${NC} Deleting namespace..."
kubectl delete namespace ${GITLAB_NAMESPACE} 2>/dev/null || true

echo ""
echo -e "${GREEN}✓ GitLab cleanup complete!${NC}"
echo ""