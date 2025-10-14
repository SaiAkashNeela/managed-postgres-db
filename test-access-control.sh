#!/bin/bash
# Quick test script to verify ALLOWED_HOSTS configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment
if [ -f "${SCRIPT_DIR}/.env" ]; then
    source "${SCRIPT_DIR}/.env"
fi

ALLOWED_HOSTS="${ALLOWED_HOSTS:-*}"

echo "╔════════════════════════════════════════════════╗"
echo "║   ALLOWED_HOSTS Configuration Test            ║"
echo "╚════════════════════════════════════════════════╝"
echo ""
echo "Current Configuration:"
echo "  ALLOWED_HOSTS = ${ALLOWED_HOSTS}"
echo ""

# Parse and display
if [ "$ALLOWED_HOSTS" = "*" ]; then
    echo "✓ Wildcard mode: All IPs allowed"
    echo "  Security: ⚠️  Use only in development or behind firewall"
else
    echo "✓ Restricted mode: Specific hosts allowed"
    echo "  Security: 🔒 High"
    echo ""
    echo "Allowed hosts:"
    IFS=',' read -ra HOSTS <<< "$ALLOWED_HOSTS"
    for host in "${HOSTS[@]}"; do
        host=$(echo "$host" | xargs)
        
        if [[ "$host" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$ ]]; then
            echo "  • ${host} (IPv4)"
        elif [[ "$host" =~ ^[0-9a-fA-F:]+(/[0-9]+)?$ ]]; then
            echo "  • ${host} (IPv6)"
        elif [[ "$host" =~ ^[a-zA-Z0-9\.\-]+$ ]]; then
            echo "  • ${host} (DNS)"
        else
            echo "  • ${host} (Unknown format)"
        fi
    done
fi

echo ""
echo "Generated pg_hba.conf entries:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f "${SCRIPT_DIR}/config/pg_hba.conf" ]; then
    grep -E "^hostssl.*scram-sha-256" "${SCRIPT_DIR}/config/pg_hba.conf" | grep -v "^#" | head -10
else
    echo "pg_hba.conf not found. Run: ./generate-pg-hba.sh"
fi

echo ""
echo "To apply changes:"
echo "  1. Edit .env and modify ALLOWED_HOSTS"
echo "  2. Run: ./update-access-control.sh"
echo ""
echo "To view active connections:"
echo "  ./show-connections.sh"
