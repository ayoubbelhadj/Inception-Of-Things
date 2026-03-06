#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

CLUSTER_NAME="iot-cluster"

echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}    Bonus: Cleanup K3d Cluster${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""

if ! k3d cluster list | grep -q ${CLUSTER_NAME}; then
    echo -e "${YELLOW}[INFO]${NC} Cluster '${CLUSTER_NAME}' not found, nothing to do."
    exit 0
fi

echo -e "${GREEN}[INFO]${NC} Deleting cluster: ${CYAN}${CLUSTER_NAME}${NC}..."
k3d cluster delete ${CLUSTER_NAME}

echo ""
echo -e "${GREEN}[✓]${NC} Cluster '${CLUSTER_NAME}' deleted!"
echo ""
