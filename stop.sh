#!/bin/bash
set -e

# Stop the PostgreSQL database

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Stopping managed PostgreSQL database..."

cd "${SCRIPT_DIR}"
docker-compose down

echo "✓ PostgreSQL stopped"
