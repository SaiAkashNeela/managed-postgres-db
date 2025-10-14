# Understanding ALLOWED_HOSTS and URL/Domain Configuration

## 🤔 Common Confusion: URLs vs Hostnames

### What ALLOWED_HOSTS Is NOT For
❌ `https://app.example.com` - PostgreSQL doesn't use HTTP/HTTPS  
❌ `http://192.168.1.100` - PostgreSQL doesn't use HTTP  
❌ Web URLs or API endpoints

### What ALLOWED_HOSTS IS For
✅ `app.example.com` - Hostname (DNS name)  
✅ `192.168.1.100` - IP address  
✅ `10.0.0.0/16` - CIDR network range  
✅ `2001:db8::1` - IPv6 address

## 🔌 How It Actually Works

### Scenario 1: Your App Uses HTTPS, Database Connection is Separate

```
┌─────────────────────┐
│  User's Browser     │
│  https://myapp.com  │
└──────────┬──────────┘
           │ HTTPS (443)
           ▼
┌─────────────────────┐      PostgreSQL Protocol
│  Your Application   │      with SSL (5432)
│  Server             │◄────────────────────────┐
│  IP: 192.168.1.100  │                         │
└─────────────────────┘                         │
                                                 │
                                    ┌────────────┴──────────┐
                                    │  PostgreSQL Server    │
                                    │  ALLOWED_HOSTS:       │
                                    │  192.168.1.100        │
                                    └───────────────────────┘
```

**ALLOWED_HOSTS checks the application server's IP**, not the user's browser URL!

### Scenario 2: Multiple Apps Connecting

```
https://app1.example.com  ──┐
(IP: 192.168.1.100)        │
                            │    PostgreSQL
https://app2.example.com  ──┤    Connection
(IP: 192.168.1.101)        │    (Port 5432)
                            │    with SSL
https://api.example.com   ──┤
(IP: 192.168.1.102)        │
                            ▼
                    ┌──────────────────┐
                    │  PostgreSQL DB   │
                    │  ALLOWED_HOSTS:  │
                    │  192.168.1.0/24  │
                    └──────────────────┘
```

## 📋 Configuration Examples

### If You Know Server Hostnames

Your apps run at these URLs:
- `https://app1.mycompany.com`
- `https://app2.mycompany.com`
- `https://api.mycompany.com`

**ALLOWED_HOSTS Configuration:**
```bash
# Use the HOSTNAMES (without http/https)
ALLOWED_HOSTS=app1.mycompany.com,app2.mycompany.com,api.mycompany.com
```

### If You Know Server IPs

Your apps run at:
- `https://app.example.com` → Server IP: `192.168.1.100`
- `https://api.example.com` → Server IP: `192.168.1.101`

**ALLOWED_HOSTS Configuration:**
```bash
# Use the actual server IPs
ALLOWED_HOSTS=192.168.1.100,192.168.1.101
```

### If All Apps in Same Network

Your apps are in network `10.0.0.0/16`:

**ALLOWED_HOSTS Configuration:**
```bash
# Use CIDR range
ALLOWED_HOSTS=10.0.0.0/16
```

## 🌐 Cloud Platform Examples

### Heroku Apps
Your apps:
- `https://myapp.herokuapp.com`
- `https://myapi.herokuapp.com`

Heroku uses dynamic IPs, so use the hostnames:
```bash
ALLOWED_HOSTS=myapp.herokuapp.com,myapi.herokuapp.com
```

### Vercel/Netlify (Serverless)
These platforms use many rotating IPs. Options:
```bash
# Option 1: Allow all (if database is behind firewall)
ALLOWED_HOSTS=*

# Option 2: Use VPC/Private network
ALLOWED_HOSTS=10.0.0.0/8
```

### AWS EC2
Your apps on EC2 instances:
```bash
# Use private IPs
ALLOWED_HOSTS=10.0.1.50,10.0.1.51,10.0.1.52

# Or private subnet
ALLOWED_HOSTS=10.0.1.0/24

# Or use Elastic IPs
ALLOWED_HOSTS=54.123.45.67,54.123.45.68
```

### DigitalOcean Droplets
```bash
# Use droplet IPs
ALLOWED_HOSTS=157.230.50.100,157.230.50.101

# Or private network
ALLOWED_HOSTS=10.116.0.0/20
```

### Kubernetes
```bash
# Pod network CIDR
ALLOWED_HOSTS=10.244.0.0/16

# Or service IPs
ALLOWED_HOSTS=10.96.0.0/12
```

## 🔧 Finding Your Server's IP/Hostname

### From Your Application Server

```bash
# Get public IP
curl ifconfig.me

# Get hostname
hostname -f

# Get all IPs
ip addr show

# Get private IP (AWS EC2)
curl http://169.254.169.254/latest/meta-data/local-ipv4
```

### From Your Cloud Provider

**AWS:**
- Go to EC2 Dashboard → Instances
- Note the "Private IPv4" or "Public IPv4"

**DigitalOcean:**
- Go to Droplets
- Note the "Private IP" under networking

**GCP:**
- Go to Compute Engine → VM Instances
- Note the "Internal IP"

**Azure:**
- Go to Virtual Machines
- Note the "Private IP address"

## 🚨 Important Notes

1. **PostgreSQL doesn't care about HTTP/HTTPS** - it uses its own protocol
2. **ALLOWED_HOSTS checks the SOURCE IP** of the connection
3. **Your app's URL is irrelevant** - only the server's IP matters
4. **SSL/TLS in PostgreSQL** is separate from HTTPS
5. **Both can be encrypted:**
   - User → App: HTTPS (port 443)
   - App → Database: PostgreSQL with SSL (port 5432)

## 📝 Step-by-Step Setup

### Step 1: Find Your Application Server's IP/Hostname

```bash
# SSH into your app server
ssh user@your-app-server

# Check IP
curl ifconfig.me
# Output: 192.168.1.100

# Or hostname
hostname -f
# Output: app1.example.com
```

### Step 2: Configure ALLOWED_HOSTS

Edit `.env`:
```bash
# Using IP
ALLOWED_HOSTS=192.168.1.100

# Or using hostname
ALLOWED_HOSTS=app1.example.com

# Or multiple
ALLOWED_HOSTS=192.168.1.100,app1.example.com,app2.example.com
```

### Step 3: Apply Configuration

```bash
./update-access-control.sh
```

### Step 4: Test Connection

From your application server:
```bash
psql "postgresql://admin:password@db.example.com:5432/maindb?sslmode=require"
```

## 🔍 Debugging Connection Issues

### Connection Refused

```bash
# Check what IP you're connecting FROM
curl ifconfig.me

# Check if that IP is in ALLOWED_HOSTS
./show-connections.sh

# Update if needed
# Edit .env: ALLOWED_HOSTS=your.ip.here
./update-access-control.sh
```

### "No pg_hba.conf entry for host"

This means your IP is not in `ALLOWED_HOSTS`:

```bash
# From your app server, find your IP
curl ifconfig.me

# Add it to .env
echo "ALLOWED_HOSTS=192.168.1.100" >> .env

# Apply
./update-access-control.sh
```

## 💡 Best Practices

### Development
```bash
# Allow all (safe if not exposed to internet)
ALLOWED_HOSTS=*
```

### Staging
```bash
# Specific IPs or hostnames
ALLOWED_HOSTS=staging-app.example.com,192.168.1.100
```

### Production
```bash
# Restrictive - only known servers
ALLOWED_HOSTS=prod-app1.example.com,prod-app2.example.com,10.0.0.0/24
```

## 📚 Summary

| What You Have | What to Put in ALLOWED_HOSTS |
|---------------|------------------------------|
| `https://myapp.com` at IP `1.2.3.4` | `1.2.3.4` |
| App at hostname `app.example.com` | `app.example.com` |
| Multiple apps in `10.0.0.0/16` | `10.0.0.0/16` |
| Apps with dynamic IPs | `*` (with firewall) |
| Kubernetes pods | Pod network CIDR |

**Remember:** PostgreSQL connections use TCP on port 5432, not HTTP/HTTPS!

---

For more examples, see [ACCESS_CONTROL_EXAMPLES.md](ACCESS_CONTROL_EXAMPLES.md)
