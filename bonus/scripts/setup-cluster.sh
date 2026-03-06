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
CLUSTER_NAME="iot-cluster"

echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}    Bonus: Setup K3d Cluster${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""

# Check required tools
echo -e "${GREEN}[INFO]${NC} Checking required tools..."
MISSING_TOOLS=0

for tool in docker kubectl k3d; do
    if ! command -v $tool &> /dev/null; then
        echo -e "${RED}[ERROR]${NC} ${tool} not found!"
        MISSING_TOOLS=1
    fi
done

if [ $MISSING_TOOLS -eq 1 ]; then
    echo -e "${YELLOW}[INFO]${NC} Install missing tools first"
    exit 1
fi

echo -e "${GREEN}[✓]${NC} All required tools found!"
echo ""

# Delete existing cluster if exists
if k3d cluster list | grep -q ${CLUSTER_NAME}; then
    echo -e "${YELLOW}[INFO]${NC} Deleting existing cluster '${CLUSTER_NAME}'..."
    k3d cluster delete ${CLUSTER_NAME}
fi

# Create K3d cluster
echo -e "${GREEN}[INFO]${NC} Creating K3d cluster: ${CYAN}${CLUSTER_NAME}${NC}..."
k3d cluster create ${CLUSTER_NAME} \
    --port "8080:80@loadbalancer" \
    --port "8443:443@loadbalancer" \
    --agents 1

echo -e "${GREEN}[✓]${NC} K3d cluster created!"

# Wait for cluster to be ready
echo -e "${GREEN}[INFO]${NC} Waiting for cluster nodes to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=120s

echo -e "${GREEN}[✓]${NC} Cluster is ready!"

echo ""
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}      Cluster Setup Complete!${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""
echo -e "${GREEN}[NEXT]${NC} Run: ${CYAN}./install-gitlab.sh${NC}"
echo ""
