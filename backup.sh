#!/bin/bash
set -e

# Backup PostgreSQL database

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Load environment variables
if [ -f "${SCRIPT_DIR}/.env" ]; then
    source "${SCRIPT_DIR}/.env"
fi

POSTGRES_USER="${POSTGRES_USER:-admin}"
POSTGRES_DB="${POSTGRES_DB:-maindb}"

mkdir -p "${BACKUP_DIR}"

BACKUP_FILE="${BACKUP_DIR}/backup_${POSTGRES_DB}_${TIMESTAMP}.sql"

echo "Creating backup of database: ${POSTGRES_DB}"
echo "Backup file: ${BACKUP_FILE}"

docker exec managed-postgres-db pg_dump -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" > "${BACKUP_FILE}"

# Compress the backup
gzip "${BACKUP_FILE}"

echo "✓ Backup completed: ${BACKUP_FILE}.gz"
echo ""
echo "To restore, run:"
echo "  gunzip -c ${BACKUP_FILE}.gz | docker exec -i managed-postgres-db psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}"
