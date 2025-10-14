#!/bin/bash
set -e

# Script to renew Let's Encrypt certificates
# Add this to crontab for automatic renewal: 0 0 * * * /path/to/renew-certs.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERTS_DIR="${SCRIPT_DIR}/certs"
LETSENCRYPT_DIR="${SCRIPT_DIR}/letsencrypt"

# Load environment variables
if [ -f "${SCRIPT_DIR}/.env" ]; then
    source "${SCRIPT_DIR}/.env"
fi

DOMAIN="${DOMAIN:-localhost}"
LETSENCRYPT_STAGING="${LETSENCRYPT_STAGING:-false}"

# Logging
LOG_FILE="${SCRIPT_DIR}/letsencrypt-renewal.log"
echo "[$(date)] Starting certificate renewal check..." >> "$LOG_FILE"

# Staging flag
STAGING_FLAG=""
if [ "$LETSENCRYPT_STAGING" = "true" ]; then
    STAGING_FLAG="--staging"
fi

# Renew certificate
sudo certbot renew \
    ${STAGING_FLAG} \
    --config-dir "${LETSENCRYPT_DIR}" \
    --work-dir "${LETSENCRYPT_DIR}/work" \
    --logs-dir "${LETSENCRYPT_DIR}/logs" >> "$LOG_FILE" 2>&1

# Check if renewal was successful
if [ $? -eq 0 ]; then
    echo "[$(date)] Certificate renewal successful" >> "$LOG_FILE"
    
    # Copy renewed certificates to PostgreSQL certs directory
    CERT_PATH="${LETSENCRYPT_DIR}/live/${DOMAIN}"
    
    if [ -f "${CERT_PATH}/fullchain.pem" ]; then
        sudo cp "${CERT_PATH}/fullchain.pem" "${CERTS_DIR}/server.crt"
        sudo cp "${CERT_PATH}/privkey.pem" "${CERTS_DIR}/server.key"
        sudo cp "${CERT_PATH}/chain.pem" "${CERTS_DIR}/root.crt" 2>/dev/null || \
            sudo cp "${CERT_PATH}/fullchain.pem" "${CERTS_DIR}/root.crt"
        
        # Set proper permissions
        sudo chown $(whoami):$(whoami) "${CERTS_DIR}"/*
        chmod 600 "${CERTS_DIR}/server.key"
        chmod 644 "${CERTS_DIR}/server.crt"
        chmod 644 "${CERTS_DIR}/root.crt"
        
        echo "[$(date)] Certificates updated in ${CERTS_DIR}" >> "$LOG_FILE"
        
        # Restart PostgreSQL to load new certificates
        cd "${SCRIPT_DIR}"
        if docker-compose ps | grep -q "managed-postgres-db"; then
            echo "[$(date)] Restarting PostgreSQL..." >> "$LOG_FILE"
            docker-compose restart postgres
            echo "[$(date)] PostgreSQL restarted with new certificates" >> "$LOG_FILE"
        fi
    fi
else
    echo "[$(date)] Certificate renewal failed" >> "$LOG_FILE"
    exit 1
fi

echo "[$(date)] Certificate renewal completed" >> "$LOG_FILE"
