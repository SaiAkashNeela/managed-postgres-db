#!/bin/bash
set -e

# Start the PostgreSQL database

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting managed PostgreSQL database..."

cd "${SCRIPT_DIR}"
docker-compose up -d

echo "✓ PostgreSQL started"
echo ""
echo "Check status with: docker-compose ps"
echo "View logs with: docker-compose logs -f postgres"
