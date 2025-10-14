#!/bin/bash
set -e

# Quick test to verify Let's Encrypt certificate expiration and renewal setup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment
if [ -f "${SCRIPT_DIR}/.env" ]; then
    source "${SCRIPT_DIR}/.env"
fi

DOMAIN="${DOMAIN:-localhost}"
CERTS_DIR="${SCRIPT_DIR}/certs"

echo "Checking certificate expiration..."
echo ""

if [ ! -f "${CERTS_DIR}/server.crt" ]; then
    echo "✗ No certificate found at ${CERTS_DIR}/server.crt"
    exit 1
fi

# Check expiration
EXPIRY_DATE=$(openssl x509 -in "${CERTS_DIR}/server.crt" -noout -enddate | cut -d= -f2)
EXPIRY_EPOCH=$(date -j -f "%b %d %T %Y %Z" "$EXPIRY_DATE" "+%s" 2>/dev/null || date -d "$EXPIRY_DATE" "+%s")
CURRENT_EPOCH=$(date "+%s")
DAYS_LEFT=$(( ($EXPIRY_EPOCH - $CURRENT_EPOCH) / 86400 ))

echo "Certificate for: ${DOMAIN}"
echo "Expires: ${EXPIRY_DATE}"
echo "Days remaining: ${DAYS_LEFT}"
echo ""

if [ $DAYS_LEFT -lt 30 ]; then
    echo "⚠ WARNING: Certificate expires in less than 30 days!"
    echo "  Run: ./renew-certs.sh"
elif [ $DAYS_LEFT -lt 60 ]; then
    echo "⚠ Certificate will expire soon"
    echo "  Consider running: ./renew-certs.sh"
else
    echo "✓ Certificate is valid"
fi

# Check if renewal is set up in crontab
echo ""
echo "Checking automatic renewal setup..."
if crontab -l 2>/dev/null | grep -q "renew-certs.sh"; then
    echo "✓ Automatic renewal is configured in crontab"
else
    echo "✗ Automatic renewal is NOT configured"
    echo ""
    echo "To set up automatic renewal:"
    echo "  sudo crontab -e"
    echo "  Add: 0 0 * * * ${SCRIPT_DIR}/renew-certs.sh"
fi
