#!/bin/bash
set -e

# Script to view current connections and test access rules

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables
if [ -f "${SCRIPT_DIR}/.env" ]; then
    source "${SCRIPT_DIR}/.env"
fi

POSTGRES_USER="${POSTGRES_USER:-admin}"
POSTGRES_DB="${POSTGRES_DB:-maindb}"

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   PostgreSQL Connection Status                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Check if PostgreSQL is running
if ! docker ps | grep -q "managed-postgres-db"; then
    echo -e "${YELLOW}⚠ PostgreSQL is not running${NC}"
    echo "  Start it with: ./start.sh"
    exit 1
fi

echo -e "${GREEN}[1] Current Access Rules (pg_hba.conf)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "${SCRIPT_DIR}/config/pg_hba.conf" | grep -E "^(host|hostssl|hostnossl)" | grep -v "^#" || echo "No rules found"
echo ""

echo -e "${GREEN}[2] Active Connections${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker exec managed-postgres-db psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "
SELECT 
    pid,
    usename as user,
    datname as database,
    client_addr as client_ip,
    client_hostname as hostname,
    CASE 
        WHEN ssl THEN 'SSL (' || version || ')' 
        ELSE 'NO SSL' 
    END as encryption,
    state,
    backend_start::timestamp(0) as connected_since
FROM pg_stat_ssl 
JOIN pg_stat_activity ON pg_stat_ssl.pid = pg_stat_activity.pid
WHERE datname IS NOT NULL
ORDER BY backend_start DESC;
" 2>/dev/null || echo "Unable to retrieve connection information"

echo ""
echo -e "${GREEN}[3] Connection Summary${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker exec managed-postgres-db psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "
SELECT 
    COUNT(*) as total_connections,
    COUNT(*) FILTER (WHERE ssl = true) as ssl_connections,
    COUNT(*) FILTER (WHERE ssl = false) as non_ssl_connections,
    COUNT(DISTINCT client_addr) as unique_clients
FROM pg_stat_ssl 
JOIN pg_stat_activity ON pg_stat_ssl.pid = pg_stat_activity.pid
WHERE datname IS NOT NULL;
" 2>/dev/null || echo "Unable to retrieve summary"

echo ""
echo -e "${GREEN}[4] Allowed Hosts Configuration${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ALLOWED_HOSTS="${ALLOWED_HOSTS:-*}"
echo "ALLOWED_HOSTS: ${ALLOWED_HOSTS}"

if [ "$ALLOWED_HOSTS" = "*" ]; then
    echo "Status: Allowing connections from ALL IP addresses"
else
    echo "Status: Restricted to specific hosts/networks"
    IFS=',' read -ra HOSTS <<< "$ALLOWED_HOSTS"
    for host in "${HOSTS[@]}"; do
        host=$(echo "$host" | xargs)
        echo "  - ${host}"
    done
fi

echo ""
echo -e "${BLUE}To update access control:${NC}"
echo "  1. Edit .env and modify ALLOWED_HOSTS"
echo "  2. Run: ./update-access-control.sh"
