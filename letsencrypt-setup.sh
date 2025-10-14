#!/bin/bash
set -e

# Script to obtain Let's Encrypt SSL certificates using Certbot
# This script supports standalone mode for initial setup

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERTS_DIR="${SCRIPT_DIR}/certs"
LETSENCRYPT_DIR="${SCRIPT_DIR}/letsencrypt"

# Load environment variables
if [ -f "${SCRIPT_DIR}/.env" ]; then
    source "${SCRIPT_DIR}/.env"
fi

# Configuration from environment variables
DOMAIN="${DOMAIN:-localhost}"
LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-admin@${DOMAIN}}"
LETSENCRYPT_STAGING="${LETSENCRYPT_STAGING:-false}"
USE_LETSENCRYPT="${USE_LETSENCRYPT:-false}"

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Let's Encrypt Certificate Manager           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Validate domain
if [ "$DOMAIN" = "localhost" ] || [ "$DOMAIN" = "127.0.0.1" ]; then
    echo -e "${RED}✗ Let's Encrypt cannot issue certificates for localhost${NC}"
    echo -e "${YELLOW}  Please set a valid domain in .env file${NC}"
    echo -e "${YELLOW}  Or use self-signed certificates with ./generate-certs.sh${NC}"
    exit 1
fi

# Check if certbot is installed
if ! command -v certbot &> /dev/null; then
    echo -e "${YELLOW}⚠ Certbot is not installed${NC}"
    echo ""
    echo "Install certbot:"
    echo "  macOS:   brew install certbot"
    echo "  Ubuntu:  sudo apt install certbot"
    echo "  CentOS:  sudo yum install certbot"
    echo ""
    read -p "Would you like to install certbot now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install certbot
        elif command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y certbot
        elif command -v yum &> /dev/null; then
            sudo yum install -y certbot
        else
            echo -e "${RED}✗ Unable to install certbot automatically${NC}"
            exit 1
        fi
    else
        exit 1
    fi
fi

echo -e "${GREEN}✓ Certbot is installed${NC}"

# Create directories
mkdir -p "${CERTS_DIR}"
mkdir -p "${LETSENCRYPT_DIR}"

# Staging or production
STAGING_FLAG=""
if [ "$LETSENCRYPT_STAGING" = "true" ]; then
    STAGING_FLAG="--staging"
    echo -e "${YELLOW}⚠ Using Let's Encrypt STAGING environment${NC}"
    echo -e "${YELLOW}  Set LETSENCRYPT_STAGING=false for production certificates${NC}"
fi

echo ""
echo -e "${BLUE}Certificate Configuration:${NC}"
echo -e "  Domain: ${GREEN}${DOMAIN}${NC}"
echo -e "  Email:  ${GREEN}${LETSENCRYPT_EMAIL}${NC}"
echo -e "  Mode:   ${GREEN}${LETSENCRYPT_STAGING:-production}${NC}"
echo ""

# Check if PostgreSQL is running on port 80/443
if lsof -Pi :80 -sTCP:LISTEN -t &> /dev/null || lsof -Pi :443 -sTCP:LISTEN -t &> /dev/null; then
    echo -e "${YELLOW}⚠ Port 80 or 443 is in use${NC}"
    echo -e "${YELLOW}  Certbot needs port 80 for HTTP-01 challenge${NC}"
    echo ""
    read -p "Stop services on port 80/443? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Using DNS challenge or manual mode instead${NC}"
    fi
fi

# Obtain certificate
echo -e "${BLUE}Obtaining Let's Encrypt certificate...${NC}"
echo ""

# Method 1: Standalone (requires port 80)
echo -e "${GREEN}Attempting standalone mode...${NC}"
sudo certbot certonly \
    --standalone \
    --non-interactive \
    --agree-tos \
    --email "${LETSENCRYPT_EMAIL}" \
    --domains "${DOMAIN}" \
    ${STAGING_FLAG} \
    --config-dir "${LETSENCRYPT_DIR}" \
    --work-dir "${LETSENCRYPT_DIR}/work" \
    --logs-dir "${LETSENCRYPT_DIR}/logs" || {
    
    echo -e "${YELLOW}⚠ Standalone mode failed${NC}"
    echo ""
    echo "Alternative methods:"
    echo "1. Use DNS challenge:"
    echo "   sudo certbot certonly --manual --preferred-challenges dns -d ${DOMAIN}"
    echo ""
    echo "2. Use webroot (if you have a web server):"
    echo "   sudo certbot certonly --webroot -w /var/www/html -d ${DOMAIN}"
    echo ""
    echo "3. Use your cloud provider's DNS plugin"
    exit 1
}

# Check if certificate was obtained
CERT_PATH="${LETSENCRYPT_DIR}/live/${DOMAIN}"
if [ ! -f "${CERT_PATH}/fullchain.pem" ] || [ ! -f "${CERT_PATH}/privkey.pem" ]; then
    echo -e "${RED}✗ Failed to obtain certificates${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Let's Encrypt certificate obtained${NC}"

# Copy certificates to PostgreSQL certs directory
echo -e "${BLUE}Setting up certificates for PostgreSQL...${NC}"

# Create symbolic links or copies
sudo cp "${CERT_PATH}/fullchain.pem" "${CERTS_DIR}/server.crt"
sudo cp "${CERT_PATH}/privkey.pem" "${CERTS_DIR}/server.key"
sudo cp "${CERT_PATH}/chain.pem" "${CERTS_DIR}/root.crt" 2>/dev/null || \
    sudo cp "${CERT_PATH}/fullchain.pem" "${CERTS_DIR}/root.crt"

# Set proper permissions for PostgreSQL
sudo chown $(whoami):$(whoami) "${CERTS_DIR}"/*
chmod 600 "${CERTS_DIR}/server.key"
chmod 644 "${CERTS_DIR}/server.crt"
chmod 644 "${CERTS_DIR}/root.crt"

echo -e "${GREEN}✓ Certificates configured for PostgreSQL${NC}"

# Display certificate information
echo ""
echo -e "${GREEN}=== Certificate Information ===${NC}"
openssl x509 -in "${CERTS_DIR}/server.crt" -noout -text | grep -A 2 "Validity"
openssl x509 -in "${CERTS_DIR}/server.crt" -noout -subject
openssl x509 -in "${CERTS_DIR}/server.crt" -noout -issuer

echo ""
echo -e "${GREEN}✓ Let's Encrypt certificates ready!${NC}"
echo ""
echo -e "${BLUE}Certificate locations:${NC}"
echo -e "  Server Cert: ${CERTS_DIR}/server.crt"
echo -e "  Private Key: ${CERTS_DIR}/server.key"
echo -e "  CA Chain:    ${CERTS_DIR}/root.crt"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo -e "  - Certificates expire in 90 days"
echo -e "  - Set up automatic renewal with: sudo crontab -e"
echo -e "  - Add: 0 0 * * * ${SCRIPT_DIR}/renew-certs.sh"
echo ""
echo -e "${GREEN}You can now start PostgreSQL with:${NC} ./start.sh"
