#!/bin/bash
set -e

# Script to update access control rules without restarting PostgreSQL
# Reloads configuration after updating pg_hba.conf

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}Updating PostgreSQL access control rules...${NC}"
echo ""

# Regenerate pg_hba.conf
chmod +x "${SCRIPT_DIR}/generate-pg-hba.sh"
"${SCRIPT_DIR}/generate-pg-hba.sh"

# Check if PostgreSQL is running
if ! docker ps | grep -q "managed-postgres-db"; then
    echo -e "${YELLOW}⚠ PostgreSQL is not running${NC}"
    echo "  Start it with: ./start.sh"
    exit 0
fi

# Reload PostgreSQL configuration
echo ""
echo -e "${BLUE}Reloading PostgreSQL configuration...${NC}"

# Load environment variables
if [ -f "${SCRIPT_DIR}/.env" ]; then
    source "${SCRIPT_DIR}/.env"
fi

POSTGRES_USER="${POSTGRES_USER:-admin}"
POSTGRES_DB="${POSTGRES_DB:-maindb}"

# Reload configuration (doesn't require restart)
docker exec managed-postgres-db psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "SELECT pg_reload_conf();" > /dev/null 2>&1

echo -e "${GREEN}✓ Configuration reloaded${NC}"
echo ""
echo -e "${BLUE}Current access rules:${NC}"
cat "${SCRIPT_DIR}/config/pg_hba.conf" | grep -E "^(host|hostssl|hostnossl)" | grep -v "^#"
echo ""
echo -e "${GREEN}✓ Access control updated successfully${NC}"
