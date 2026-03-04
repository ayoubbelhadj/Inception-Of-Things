#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] Please run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}    Part 3: Install Required Tools${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""

# Install Docker
echo -e "${GREEN}[INFO] Checking Docker installation...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${GREEN}[INFO] Installing Docker...${NC}"
    apt-get update
    apt-get install -y ca-certificates curl gnupg
    
    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Set up repository
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    
    # Start Docker
    systemctl start docker
    systemctl enable docker
    
    echo -e "${GREEN}[✓] Docker installed!${NC}"
else
    echo -e "${GREEN}[✓] Docker already installed${NC}"
fi

# Verify Docker is running
if ! docker ps &> /dev/null; then
    echo -e "${GREEN}[INFO] Starting Docker...${NC}"
    systemctl start docker
    sleep 3
fi

echo -e "${GREEN}[✓] Docker is ready!${NC}"

# Install kubectl
echo -e "${GREEN}[INFO] Checking kubectl installation...${NC}"
if ! command -v kubectl &> /dev/null; then
    echo -e "${GREEN}[INFO] Installing kubectl...${NC}"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" 2>/dev/null
    chmod +x kubectl
    mv kubectl /usr/local/bin/
    echo -e "${GREEN}[✓] kubectl installed!${NC}"
else
    echo -e "${GREEN}[✓] kubectl already installed${NC}"
fi

# Install K3d
echo -e "${GREEN}[INFO] Checking K3d installation...${NC}"
if ! command -v k3d &> /dev/null; then
    echo -e "${GREEN}[INFO] Installing K3d...${NC}"
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    echo -e "${GREEN}[✓] K3d installed!${NC}"
else
    echo -e "${GREEN}[✓] K3d already installed${NC}"
fi

# Show installed versions
echo ""
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}         Installed Tool Versions${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${CYAN}Docker:${NC}  $(docker --version)"
echo -e "${CYAN}kubectl:${NC} $(kubectl version --client --short 2>/dev/null | grep Client || kubectl version --client 2>/dev/null | head -1)"
echo -e "${CYAN}K3d:${NC}     $(k3d version | head -1)"
echo ""
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo -e "${BLUE}${BOLD}      Tool Installation Complete!${NC}"
echo -e "${BLUE}${BOLD}=========================================${NC}"
echo ""
echo -e "${GREEN}[✓] All tools installed successfully!${NC}"
echo -e "${YELLOW}[NEXT]${NC} Run: ${CYAN}sudo ./scripts/setup-cluster.sh${NC}"
echo ""