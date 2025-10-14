# Access Control Examples

This document provides real-world examples of configuring the `ALLOWED_HOSTS` environment variable for different scenarios.

## 🌐 Common Scenarios

### Scenario 1: Open to All (Development/Testing)

**Use Case**: Development environment, testing, or when behind a secure firewall

```bash
ALLOWED_HOSTS=*
```

**Security Level**: ⚠️ Low (SSL still required)  
**When to Use**: Development, internal networks only  
**Generated Rules**:
```
hostssl all all 0.0.0.0/0 scram-sha-256
hostssl all all ::/0 scram-sha-256
```

---

### Scenario 2: Single Application Server

**Use Case**: One application server connecting to database

```bash
ALLOWED_HOSTS=192.168.1.100
```

**Security Level**: 🔒 High  
**When to Use**: Dedicated application server setup  
**Generated Rules**:
```
hostssl all all 192.168.1.100/32 scram-sha-256
```

---

### Scenario 3: Multiple Application Servers

**Use Case**: Multiple app servers in different locations

```bash
ALLOWED_HOSTS=192.168.1.100,192.168.1.101,192.168.1.102
```

**Security Level**: 🔒 High  
**When to Use**: Multi-server application deployment  
**Generated Rules**:
```
hostssl all all 192.168.1.100/32 scram-sha-256
hostssl all all 192.168.1.101/32 scram-sha-256
hostssl all all 192.168.1.102/32 scram-sha-256
```

---

### Scenario 4: Private Subnet/CIDR Range

**Use Case**: All servers in a private network segment

```bash
ALLOWED_HOSTS=192.168.1.0/24
```

**Security Level**: 🔒 Medium-High  
**When to Use**: Private subnet with multiple servers  
**Generated Rules**:
```
hostssl all all 192.168.1.0/24 scram-sha-256
```

**Common CIDR Ranges**:
- `/32` - Single IP (255.255.255.255)
- `/24` - 256 IPs (255.255.255.0)
- `/16` - 65,536 IPs (255.255.0.0)
- `/8` - 16,777,216 IPs (255.0.0.0)

---

### Scenario 5: Multiple Subnets

**Use Case**: Servers across multiple network segments

```bash
ALLOWED_HOSTS=192.168.1.0/24,10.0.0.0/16,172.16.0.0/12
```

**Security Level**: 🔒 Medium  
**When to Use**: Multi-datacenter, multi-cloud deployments  
**Generated Rules**:
```
hostssl all all 192.168.1.0/24 scram-sha-256
hostssl all all 10.0.0.0/16 scram-sha-256
hostssl all all 172.16.0.0/12 scram-sha-256
```

---

### Scenario 6: DNS Hostnames

**Use Case**: Connecting via domain names instead of IPs

```bash
ALLOWED_HOSTS=app1.example.com,app2.example.com,backend.myapp.com
```

**Security Level**: 🔒 High  
**When to Use**: Dynamic IPs, cloud environments with DNS  
**Generated Rules**:
```
hostssl all all app1.example.com scram-sha-256
hostssl all all app2.example.com scram-sha-256
hostssl all all backend.myapp.com scram-sha-256
```

**Important Notes**:
- DNS resolution happens at PostgreSQL startup/reload
- Changes to DNS require PostgreSQL reload: `./update-access-control.sh`
- Ensure reverse DNS is properly configured

---

### Scenario 7: Mixed (IP + CIDR + DNS)

**Use Case**: Complex infrastructure with different connection types

```bash
ALLOWED_HOSTS=192.168.1.100,10.0.0.0/16,app.example.com,203.0.113.42
```

**Security Level**: 🔒 Medium-High  
**When to Use**: Hybrid cloud, mixed infrastructure  
**Generated Rules**:
```
hostssl all all 192.168.1.100/32 scram-sha-256
hostssl all all 10.0.0.0/16 scram-sha-256
hostssl all all app.example.com scram-sha-256
hostssl all all 203.0.113.42/32 scram-sha-256
```

---

### Scenario 8: Cloud Provider Networks

**Use Case**: AWS, Azure, GCP private networks

#### AWS VPC
```bash
ALLOWED_HOSTS=10.0.0.0/16
```

#### Azure VNet
```bash
ALLOWED_HOSTS=10.1.0.0/16
```

#### GCP VPC
```bash
ALLOWED_HOSTS=10.128.0.0/20
```

#### Multi-Cloud
```bash
ALLOWED_HOSTS=10.0.0.0/16,10.1.0.0/16,10.128.0.0/20
```

**Security Level**: 🔒 High  
**When to Use**: Cloud-based deployments

---

### Scenario 9: IPv6 Support

**Use Case**: Modern IPv6 infrastructure

```bash
ALLOWED_HOSTS=2001:db8::1,2001:db8::/32
```

**Security Level**: 🔒 High  
**When to Use**: IPv6-enabled networks  
**Generated Rules**:
```
hostssl all all 2001:db8::1/128 scram-sha-256
hostssl all all 2001:db8::/32 scram-sha-256
```

---

### Scenario 10: Kubernetes/Container Orchestration

**Use Case**: Database accessed from Kubernetes pods

#### Kubernetes Pod Network (typical)
```bash
ALLOWED_HOSTS=10.244.0.0/16
```

#### Docker Swarm Overlay Network
```bash
ALLOWED_HOSTS=10.0.9.0/24
```

#### Multiple K8s Clusters
```bash
ALLOWED_HOSTS=10.244.0.0/16,10.245.0.0/16
```

**Security Level**: 🔒 Medium  
**When to Use**: Container orchestration platforms

---

### Scenario 11: Development + Production

**Use Case**: Different configs for different environments

#### Development (.env.dev)
```bash
ALLOWED_HOSTS=*
```

#### Staging (.env.staging)
```bash
ALLOWED_HOSTS=10.0.0.0/16,staging-app.example.com
```

#### Production (.env.prod)
```bash
ALLOWED_HOSTS=app1.example.com,app2.example.com,192.168.1.0/24
```

---

## 🔧 Testing Your Configuration

After setting `ALLOWED_HOSTS`, verify the configuration:

### 1. Check Generated Rules
```bash
cat config/pg_hba.conf
```

### 2. View Active Connections
```bash
./show-connections.sh
```

### 3. Test Connection from Allowed Host
```bash
psql "postgresql://admin:password@your-server:5432/maindb?sslmode=require"
```

### 4. Test Connection from Blocked Host (should fail)
```bash
# This should be rejected if the IP is not in ALLOWED_HOSTS
psql "postgresql://admin:password@your-server:5432/maindb?sslmode=require"
# Expected: FATAL: no pg_hba.conf entry for host
```

---

## 🚨 Security Best Practices

### ✅ DO:
- Use specific IP addresses or CIDR ranges when possible
- Use DNS names for dynamic cloud environments
- Test configuration changes in staging first
- Keep `ALLOWED_HOSTS` as restrictive as possible
- Use `*` only in development or behind a firewall
- Regularly review access logs: `./show-connections.sh`

### ❌ DON'T:
- Use `ALLOWED_HOSTS=*` in production without a firewall
- Expose port 5432 directly to the internet
- Allow entire public IP ranges
- Forget to update rules when infrastructure changes

---

## 📊 Quick Reference Table

| Use Case | Example | Security | Complexity |
|----------|---------|----------|------------|
| Development | `*` | ⚠️ Low | Simple |
| Single Server | `192.168.1.100` | 🔒 High | Simple |
| Small Cluster | `192.168.1.100,192.168.1.101` | 🔒 High | Simple |
| Private Subnet | `192.168.1.0/24` | 🔒 Medium-High | Simple |
| Multi-Subnet | `192.168.1.0/24,10.0.0.0/16` | 🔒 Medium | Medium |
| DNS Names | `app.example.com` | 🔒 High | Medium |
| Mixed | `IP,CIDR,DNS` | 🔒 Medium-High | Complex |
| Cloud VPC | `10.0.0.0/16` | 🔒 High | Simple |
| IPv6 | `2001:db8::/32` | 🔒 High | Medium |
| Kubernetes | `10.244.0.0/16` | 🔒 Medium | Medium |

---

## 🔄 Applying Changes

Whenever you update `ALLOWED_HOSTS`:

```bash
# Edit .env file
nano .env

# Update access control (no restart needed)
./update-access-control.sh

# Verify changes
./show-connections.sh
```

**Changes take effect immediately** without restarting the database! 🎉

---

## 📝 Notes

1. **All connections require SSL** regardless of `ALLOWED_HOSTS`
2. **Localhost (127.0.0.1) is always allowed** for local management
3. **Docker networks are always allowed** for container-to-container communication
4. **DNS wildcards (*.example.com) are not supported** by PostgreSQL - use specific hostnames
5. **IPv4 and IPv6 can be mixed** in the same configuration
6. **Changes reload without downtime** - no database restart required

---

For more information, see the main [README.md](README.md) or run `./show-connections.sh` to view your current configuration.
