#!/bin/bash
set -e

# Setup script for managed PostgreSQL with SSL
# This script initializes the database environment

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Managed PostgreSQL Database Setup           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}✗ Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker is installed${NC}"

# Check if .env file exists
if [ ! -f "${SCRIPT_DIR}/.env" ]; then
    echo -e "${YELLOW}⚠ .env file not found. Creating from .env.example...${NC}"
    if [ -f "${SCRIPT_DIR}/.env.example" ]; then
        cp "${SCRIPT_DIR}/.env.example" "${SCRIPT_DIR}/.env"
        echo -e "${GREEN}✓ .env file created${NC}"
        echo -e "${YELLOW}⚠ Please edit .env file to set your passwords and configuration${NC}"
        echo -e "${YELLOW}  Then run this script again.${NC}"
        exit 0
    else
        echo -e "${RED}✗ .env.example not found${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ .env file found${NC}"

# Generate SSL certificates if they don't exist
if [ ! -f "${SCRIPT_DIR}/certs/server.crt" ]; then
    echo -e "${YELLOW}⚠ SSL certificates not found. Setting up...${NC}"
    chmod +x "${SCRIPT_DIR}/setup-certs.sh"
    "${SCRIPT_DIR}/setup-certs.sh"
else
    echo -e "${GREEN}✓ SSL certificates found${NC}"
fi

# Create necessary directories
echo -e "${BLUE}Creating directories...${NC}"
mkdir -p "${SCRIPT_DIR}/config"
mkdir -p "${SCRIPT_DIR}/init"
mkdir -p "${SCRIPT_DIR}/backups"

echo -e "${GREEN}✓ Directories created${NC}"

# Stop existing containers if running
if docker ps -a | grep -q "managed-postgres-db"; then
    echo -e "${YELLOW}⚠ Existing container found. Stopping...${NC}"
    cd "${SCRIPT_DIR}"
    docker-compose down
fi

# Start the database
echo -e "${BLUE}Starting PostgreSQL with SSL...${NC}"
cd "${SCRIPT_DIR}"
docker-compose up -d

# Wait for PostgreSQL to be ready
echo -e "${BLUE}Waiting for PostgreSQL to be ready...${NC}"
sleep 5

# Check if container is running
if docker ps | grep -q "managed-postgres-db"; then
    echo -e "${GREEN}✓ PostgreSQL is running${NC}"
else
    echo -e "${RED}✗ Failed to start PostgreSQL${NC}"
    echo -e "${YELLOW}Check logs with: docker-compose logs postgres${NC}"
    exit 1
fi

# Test SSL connection
echo -e "${BLUE}Testing SSL connection...${NC}"
source "${SCRIPT_DIR}/.env"

if docker exec managed-postgres-db psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "SHOW ssl;" | grep -q "on"; then
    echo -e "${GREEN}✓ SSL is enabled${NC}"
else
    echo -e "${RED}✗ SSL is not enabled${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Setup completed successfully!          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Database Information:${NC}"
echo -e "  Host: ${GREEN}localhost${NC}"
echo -e "  Port: ${GREEN}${POSTGRES_PORT:-5432}${NC}"
echo -e "  Database: ${GREEN}${POSTGRES_DB}${NC}"
echo -e "  User: ${GREEN}${POSTGRES_USER}${NC}"
echo -e "  SSL: ${GREEN}Enabled (required)${NC}"
echo ""
echo -e "${BLUE}Connection String:${NC}"
echo -e "${GREEN}postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:${POSTGRES_PORT:-5432}/${POSTGRES_DB}?sslmode=require${NC}"
echo ""
echo -e "${BLUE}pgAdmin:${NC}"
echo -e "  URL: ${GREEN}http://localhost:${PGADMIN_PORT:-5050}${NC}"
echo -e "  Email: ${GREEN}${PGADMIN_EMAIL}${NC}"
echo -e "  Password: ${GREEN}${PGADMIN_PASSWORD}${NC}"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo -e "  Start:   ${BLUE}./start.sh${NC}"
echo -e "  Stop:    ${BLUE}./stop.sh${NC}"
echo -e "  Logs:    ${BLUE}docker-compose logs -f postgres${NC}"
echo -e "  Connect: ${BLUE}./connect.sh${NC}"
echo -e "  Backup:  ${BLUE}./backup.sh${NC}"
echo ""
