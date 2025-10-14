#!/bin/bash
set -e

# Universal certificate setup script
# Handles both Let's Encrypt and self-signed certificates based on .env configuration

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERTS_DIR="${SCRIPT_DIR}/certs"

# Load environment variables
if [ ! -f "${SCRIPT_DIR}/.env" ]; then
    echo -e "${RED}✗ .env file not found${NC}"
    echo -e "${YELLOW}  Copy .env.example to .env and configure it${NC}"
    exit 1
fi

source "${SCRIPT_DIR}/.env"

# Configuration
DOMAIN="${DOMAIN:-localhost}"
USE_LETSENCRYPT="${USE_LETSENCRYPT:-false}"

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   SSL Certificate Setup                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Check if certificates already exist
if [ -f "${CERTS_DIR}/server.crt" ] && [ -f "${CERTS_DIR}/server.key" ]; then
    echo -e "${YELLOW}⚠ Certificates already exist${NC}"
    
    # Show certificate details
    echo ""
    echo -e "${BLUE}Current certificate:${NC}"
    openssl x509 -in "${CERTS_DIR}/server.crt" -noout -subject -issuer -dates
    echo ""
    
    read -p "Do you want to regenerate certificates? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Using existing certificates${NC}"
        exit 0
    fi
    
    echo -e "${YELLOW}Removing old certificates...${NC}"
    rm -f "${CERTS_DIR}"/*
fi

echo -e "${BLUE}Domain: ${GREEN}${DOMAIN}${NC}"
echo -e "${BLUE}Certificate type: ${GREEN}${USE_LETSENCRYPT}${NC}"
echo ""

# Decide which certificate method to use
if [ "$USE_LETSENCRYPT" = "true" ]; then
    if [ "$DOMAIN" = "localhost" ] || [ "$DOMAIN" = "127.0.0.1" ]; then
        echo -e "${RED}✗ Cannot use Let's Encrypt for localhost${NC}"
        echo -e "${YELLOW}  Falling back to self-signed certificates${NC}"
        echo ""
        chmod +x "${SCRIPT_DIR}/generate-certs.sh"
        "${SCRIPT_DIR}/generate-certs.sh"
    else
        echo -e "${GREEN}Using Let's Encrypt certificates${NC}"
        chmod +x "${SCRIPT_DIR}/letsencrypt-setup.sh"
        "${SCRIPT_DIR}/letsencrypt-setup.sh"
    fi
else
    echo -e "${GREEN}Using self-signed certificates${NC}"
    chmod +x "${SCRIPT_DIR}/generate-certs.sh"
    "${SCRIPT_DIR}/generate-certs.sh"
fi

echo ""
echo -e "${GREEN}✓ Certificate setup completed${NC}"
