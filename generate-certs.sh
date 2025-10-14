#!/bin/bash
set -e

# Script to generate SSL certificates for PostgreSQL
# This creates self-signed certificates for development/testing
# For production, use certificates from a trusted CA like Let's Encrypt

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERTS_DIR="${SCRIPT_DIR}/certs"

# Load environment variables if .env exists
if [ -f "${SCRIPT_DIR}/.env" ]; then
    source "${SCRIPT_DIR}/.env"
fi

# SSL Configuration with defaults from .env
COUNTRY="${SSL_COUNTRY:-US}"
STATE="${SSL_STATE:-California}"
CITY="${SSL_CITY:-San Francisco}"
ORG="${SSL_ORG:-YourCompany}"
UNIT="${SSL_UNIT:-IT}"
COMMON_NAME="${DOMAIN:-localhost}"

# Certificate validity (days)
VALIDITY_DAYS=3650

echo -e "${GREEN}=== PostgreSQL SSL Certificate Generator ===${NC}"
echo ""

# Create certs directory if it doesn't exist
mkdir -p "${CERTS_DIR}"

# Check if certificates already exist
if [ -f "${CERTS_DIR}/server.crt" ] && [ -f "${CERTS_DIR}/server.key" ]; then
    echo -e "${YELLOW}Certificates already exist in ${CERTS_DIR}${NC}"
    read -p "Do you want to regenerate them? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Using existing certificates.${NC}"
        exit 0
    fi
    echo -e "${YELLOW}Regenerating certificates...${NC}"
    rm -f "${CERTS_DIR}"/*
fi

echo -e "${GREEN}Generating self-signed SSL certificates...${NC}"
echo "Country: ${COUNTRY}"
echo "State: ${STATE}"
echo "City: ${CITY}"
echo "Organization: ${ORG}"
echo "Unit: ${UNIT}"
echo "Common Name: ${COMMON_NAME}"
echo ""

# Generate private key
echo -e "${GREEN}[1/3] Generating private key...${NC}"
openssl genrsa -out "${CERTS_DIR}/server.key" 2048
chmod 600 "${CERTS_DIR}/server.key"

# Generate certificate signing request (CSR)
echo -e "${GREEN}[2/3] Generating certificate signing request...${NC}"
openssl req -new -key "${CERTS_DIR}/server.key" \
    -out "${CERTS_DIR}/server.csr" \
    -subj "/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=${UNIT}/CN=${COMMON_NAME}"

# Generate self-signed certificate
echo -e "${GREEN}[3/3] Generating self-signed certificate (valid for ${VALIDITY_DAYS} days)...${NC}"
openssl x509 -req -days ${VALIDITY_DAYS} \
    -in "${CERTS_DIR}/server.csr" \
    -signkey "${CERTS_DIR}/server.key" \
    -out "${CERTS_DIR}/server.crt"

# Set proper permissions
chmod 600 "${CERTS_DIR}/server.key"
chmod 644 "${CERTS_DIR}/server.crt"

# Create root certificate (copy of server cert for this self-signed setup)
cp "${CERTS_DIR}/server.crt" "${CERTS_DIR}/root.crt"
chmod 644 "${CERTS_DIR}/root.crt"

# Display certificate information
echo ""
echo -e "${GREEN}=== Certificate Information ===${NC}"
openssl x509 -in "${CERTS_DIR}/server.crt" -noout -text | grep -A 2 "Validity"
openssl x509 -in "${CERTS_DIR}/server.crt" -noout -subject

echo ""
echo -e "${GREEN}✓ SSL certificates generated successfully!${NC}"
echo ""
echo "Certificate files created in ${CERTS_DIR}:"
ls -lh "${CERTS_DIR}"
echo ""
echo -e "${YELLOW}Note: These are self-signed certificates suitable for development.${NC}"
echo -e "${YELLOW}For production, use certificates from a trusted CA.${NC}"
echo ""
echo -e "${GREEN}You can now start the PostgreSQL server with SSL enabled.${NC}"
