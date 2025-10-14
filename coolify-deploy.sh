#!/bin/bash
set -e

# Coolify deployment script
# This script is compatible with Coolify's deployment process

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Coolify PostgreSQL Deployment               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Load environment variables
if [ ! -f "${SCRIPT_DIR}/.env" ]; then
    echo -e "${YELLOW}⚠ .env file not found, using defaults${NC}"
else
    source "${SCRIPT_DIR}/.env"
fi

# Setup certificates
echo -e "${BLUE}Setting up SSL certificates...${NC}"
if [ ! -f "${SCRIPT_DIR}/certs/server.crt" ]; then
    chmod +x "${SCRIPT_DIR}/setup-certs.sh"
    "${SCRIPT_DIR}/setup-certs.sh"
fi

# Pull latest images
echo -e "${BLUE}Pulling Docker images...${NC}"
docker-compose pull

# Start services
echo -e "${BLUE}Starting services...${NC}"
docker-compose up -d

# Wait for health check
echo -e "${BLUE}Waiting for PostgreSQL to be healthy...${NC}"
for i in {1..30}; do
    if docker-compose ps | grep -q "healthy"; then
        echo -e "${GREEN}✓ PostgreSQL is healthy${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

echo ""
echo -e "${GREEN}✓ Deployment completed${NC}"

# Show connection info
source "${SCRIPT_DIR}/.env"
DOMAIN="${DOMAIN:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_DB="${POSTGRES_DB:-maindb}"
POSTGRES_USER="${POSTGRES_USER:-admin}"

echo ""
echo -e "${BLUE}Connection String:${NC}"
echo -e "${GREEN}postgresql://${POSTGRES_USER}:****@${DOMAIN}:${POSTGRES_PORT}/${POSTGRES_DB}?sslmode=require${NC}"
echo ""
