#!/bin/bash
set -e

# Script to generate pg_hba.conf dynamically based on ALLOWED_HOSTS configuration
# This allows flexible access control through environment variables

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/config"
PG_HBA_FILE="${CONFIG_DIR}/pg_hba.conf"

# Load environment variables
if [ -f "${SCRIPT_DIR}/.env" ]; then
    source "${SCRIPT_DIR}/.env"
fi

ALLOWED_HOSTS="${ALLOWED_HOSTS:-*}"

echo "Generating pg_hba.conf with access control..."
echo "Allowed hosts: ${ALLOWED_HOSTS}"

# Create config directory if it doesn't exist
mkdir -p "${CONFIG_DIR}"

# Start building pg_hba.conf
cat > "${PG_HBA_FILE}" << 'EOF'
# PostgreSQL Host-Based Authentication Configuration
# Auto-generated based on ALLOWED_HOSTS environment variable
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     trust

# IPv4 local connections (always allowed)
host    all             all             127.0.0.1/32            scram-sha-256

# IPv6 local connections (always allowed)
host    all             all             ::1/128                 scram-sha-256

# Docker network connections (always allowed with SSL)
hostssl all             all             172.16.0.0/12           scram-sha-256
hostssl all             all             192.168.0.0/16          scram-sha-256

EOF

# Parse ALLOWED_HOSTS and generate rules
if [ "$ALLOWED_HOSTS" = "*" ]; then
    # Allow all connections with SSL
    cat >> "${PG_HBA_FILE}" << 'EOF'
# Allow all SSL connections from anywhere (wildcard)
hostssl all             all             0.0.0.0/0               scram-sha-256
hostssl all             all             ::/0                    scram-sha-256

EOF
else
    # Parse comma-separated values
    echo "# Custom allowed hosts/networks" >> "${PG_HBA_FILE}"
    
    IFS=',' read -ra HOSTS <<< "$ALLOWED_HOSTS"
    for host in "${HOSTS[@]}"; do
        # Trim whitespace
        host=$(echo "$host" | xargs)
        
        # Strip http:// or https:// if accidentally included
        host=$(echo "$host" | sed -e 's|^https\?://||' -e 's|/$||')
        
        # Skip if empty after cleaning
        [ -z "$host" ] && continue
        
        # Check if it's a CIDR notation
        if [[ "$host" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$ ]]; then
            # IPv4 address or CIDR range
            if [[ ! "$host" =~ / ]]; then
                host="${host}/32"  # Add /32 if no CIDR specified
            fi
            echo "hostssl all             all             ${host}                scram-sha-256" >> "${PG_HBA_FILE}"
        
        elif [[ "$host" =~ ^[0-9a-fA-F:]+(/[0-9]+)?$ ]]; then
            # IPv6 address or CIDR range
            if [[ ! "$host" =~ / ]]; then
                host="${host}/128"  # Add /128 if no CIDR specified
            fi
            echo "hostssl all             all             ${host}                scram-sha-256" >> "${PG_HBA_FILE}"
        
        elif [[ "$host" =~ ^\*\..*$ ]]; then
            # Wildcard DNS (e.g., *.example.com)
            # PostgreSQL doesn't support DNS wildcards in pg_hba.conf directly
            # We'll document this as requiring the full domain
            echo "# WARNING: DNS wildcard '$host' not directly supported by PostgreSQL" >> "${PG_HBA_FILE}"
            echo "# Please specify exact DNS names or IP ranges instead" >> "${PG_HBA_FILE}"
        
        elif [[ "$host" =~ ^[a-zA-Z0-9\.\-]+$ ]]; then
            # DNS hostname (PostgreSQL resolves at startup)
            echo "hostssl all             all             ${host}                 scram-sha-256" >> "${PG_HBA_FILE}"
        
        else
            echo "# WARNING: Invalid host pattern '$host' - skipping" >> "${PG_HBA_FILE}"
        fi
    done
    
    echo "" >> "${PG_HBA_FILE}"
fi

# Reject non-SSL connections from remote hosts (security)
cat >> "${PG_HBA_FILE}" << 'EOF'
# Reject non-SSL connections from remote hosts
hostnossl all           all             0.0.0.0/0               reject
hostnossl all           all             ::/0                    reject
EOF

echo "✓ pg_hba.conf generated successfully"
echo "  Location: ${PG_HBA_FILE}"
echo ""
echo "Access rules configured for:"

if [ "$ALLOWED_HOSTS" = "*" ]; then
    echo "  - All IP addresses (wildcard)"
else
    IFS=',' read -ra HOSTS <<< "$ALLOWED_HOSTS"
    for host in "${HOSTS[@]}"; do
        host=$(echo "$host" | xargs)
        # Clean up for display
        host=$(echo "$host" | sed -e 's|^https\?://||' -e 's|/$||')
        [ -z "$host" ] && continue
        echo "  - ${host}"
    done
fi

echo ""
echo "Note: http:// and https:// prefixes are automatically removed"
echo "PostgreSQL uses its own protocol on port 5432, not HTTP/HTTPS"

echo ""
echo "To apply changes, restart PostgreSQL:"
echo "  docker-compose restart postgres"
