#!/bin/bash
set -e

# Connect to PostgreSQL via psql

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables
if [ -f "${SCRIPT_DIR}/.env" ]; then
    source "${SCRIPT_DIR}/.env"
fi

POSTGRES_USER="${POSTGRES_USER:-admin}"
POSTGRES_DB="${POSTGRES_DB:-maindb}"

echo "Connecting to PostgreSQL as ${POSTGRES_USER}..."
echo "Database: ${POSTGRES_DB}"
echo ""

docker exec -it managed-postgres-db psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}"
