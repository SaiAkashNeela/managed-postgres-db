#!/bin/bash
set -e

# Test SSL connection to PostgreSQL

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables
if [ -f "${SCRIPT_DIR}/.env" ]; then
    source "${SCRIPT_DIR}/.env"
fi

POSTGRES_USER="${POSTGRES_USER:-admin}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-changeme123}"
POSTGRES_DB="${POSTGRES_DB:-maindb}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"

echo "Testing SSL connection to PostgreSQL..."
echo ""

# Test 1: Check if SSL is enabled in PostgreSQL
echo "[1] Checking if SSL is enabled..."
SSL_STATUS=$(docker exec managed-postgres-db psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "SHOW ssl;")
echo "SSL Status: ${SSL_STATUS}"

if echo "${SSL_STATUS}" | grep -q "on"; then
    echo "✓ SSL is enabled"
else
    echo "✗ SSL is not enabled"
    exit 1
fi

# Test 2: Check SSL cipher
echo ""
echo "[2] Checking SSL cipher configuration..."
docker exec managed-postgres-db psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "SHOW ssl_ciphers;"

# Test 3: Test connection with sslmode=require (without client certificate)
echo ""
echo "[3] Testing connection with sslmode=require (no client cert)..."

# This simulates an external connection using just the connection string
CONNECTION_STRING="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:${POSTGRES_PORT}/${POSTGRES_DB}?sslmode=require"

if command -v psql &> /dev/null; then
    echo "Using local psql to test connection..."
    if psql "${CONNECTION_STRING}" -c "SELECT version();" &> /dev/null; then
        echo "✓ Connection successful with sslmode=require"
    else
        echo "⚠ Could not connect from host (this is expected if psql is not configured)"
    fi
fi

# Test 4: Check active connections
echo ""
echo "[4] Active SSL connections:"
docker exec managed-postgres-db psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "SELECT datname, usename, client_addr, ssl, cipher FROM pg_stat_ssl JOIN pg_stat_activity ON pg_stat_ssl.pid = pg_stat_activity.pid WHERE ssl = true;"

echo ""
echo "✓ All SSL tests completed"
echo ""
echo "Connection strings for external servers:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Standard (requires SSL):"
echo "  ${CONNECTION_STRING}"
echo ""
echo "Python (psycopg2/sqlalchemy):"
echo "  postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@<YOUR_HOST>:${POSTGRES_PORT}/${POSTGRES_DB}?sslmode=require"
echo ""
echo "Node.js (pg):"
echo "  postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@<YOUR_HOST>:${POSTGRES_PORT}/${POSTGRES_DB}?sslmode=require"
echo ""
echo "Go (lib/pq):"
echo "  host=<YOUR_HOST> port=${POSTGRES_PORT} user=${POSTGRES_USER} password=${POSTGRES_PASSWORD} dbname=${POSTGRES_DB} sslmode=require"
echo ""
