# Managed PostgreSQL Database with SSL

A production-ready PostgreSQL database setup with SSL/TLS encryption that doesn't require clients to carry certificate files. Perfect for secure database connections using just a connection string!

## 🔐 Key Features

- **SSL/TLS Encryption**: All connections are encrypted by default
- **Let's Encrypt Support**: Production-ready certificates that work with any domain
- **No Client Certificates Required**: Connect with just a connection string - no need to distribute certificate files
- **Server-Side Certificate Management**: Certificates are managed on the server side
- **Docker-Based**: Easy deployment and management with Docker Compose
- **Coolify Compatible**: Ready-to-deploy on Coolify platform
- **Dynamic Domain Configuration**: Uses environment variables for flexible deployment
- **pgAdmin Included**: Web-based database management interface
- **Automatic Initialization**: Database, users, and tables created automatically
- **Automatic Certificate Renewal**: Built-in Let's Encrypt renewal support
- **Backup Scripts**: Easy database backup and restore

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- macOS, Linux, or WSL2 on Windows
- (Optional) A domain name for Let's Encrypt certificates

### Setup Options

#### Option 1: Local Development (Self-Signed Certificates)

```bash
# 1. Copy environment file
cp .env.example .env

# 2. Edit .env and set:
#    DOMAIN=localhost
#    USE_LETSENCRYPT=false

# 3. Run setup
chmod +x setup.sh
./setup.sh
```

#### Option 2: Production with Let's Encrypt

```bash
# 1. Copy environment file
cp .env.example .env

# 2. Edit .env and set:
#    DOMAIN=your-domain.com
#    LETSENCRYPT_EMAIL=admin@yourdomain.com
#    USE_LETSENCRYPT=true

# 3. Ensure your domain points to your server

# 4. Run setup
chmod +x setup.sh
./setup.sh
```

#### Option 3: Deploy on Coolify

1. Push code to Git repository
2. Create new app in Coolify Dashboard
3. Set environment variables in Coolify
4. Deploy!

### What the Setup Does

The setup script will automatically:
- Create/copy `.env` file if needed
- Generate or obtain SSL certificates (Let's Encrypt or self-signed)
- Create necessary directories
- Start PostgreSQL with SSL enabled
- Initialize the database with sample schema
- Run health checks

That's it! Your database is ready to use with SSL encryption.

## 📝 Configuration

### Environment Variables

Copy `.env.example` to `.env` and customize:

```bash
# PostgreSQL Configuration
POSTGRES_USER=admin
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=maindb
POSTGRES_PORT=5432

# pgAdmin Configuration
PGADMIN_EMAIL=admin@example.com
PGADMIN_PASSWORD=admin_password
PGADMIN_PORT=5050

# SSL/Domain Configuration
DOMAIN=your-domain.com              # Your actual domain or localhost
LETSENCRYPT_EMAIL=admin@yourdomain.com
USE_LETSENCRYPT=true                # true for Let's Encrypt, false for self-signed
LETSENCRYPT_STAGING=false           # true for testing (avoids rate limits)
```

**Important Configuration Notes:**

- **For Production with Domain**: Set `DOMAIN=your-domain.com` and `USE_LETSENCRYPT=true`
- **For Local Development**: Set `DOMAIN=localhost` and `USE_LETSENCRYPT=false`
- **For Coolify**: Domain will be automatically set by Coolify

## 🔌 Connecting to the Database

### Connection String (Recommended)

This is all you need! No certificate files required:

```
postgresql://admin:changeme123@localhost:5432/maindb?sslmode=require
```

For remote/production servers, replace `localhost` with your server's IP or domain:

```
postgresql://admin:password@your-server.com:5432/maindb?sslmode=require
```

### Language-Specific Examples

#### Python (psycopg2)
```python
import psycopg2

conn = psycopg2.connect(
    "postgresql://admin:password@localhost:5432/maindb?sslmode=require"
)
```

#### Python (SQLAlchemy)
```python
from sqlalchemy import create_engine

engine = create_engine(
    "postgresql://admin:password@localhost:5432/maindb?sslmode=require"
)
```

#### Node.js (pg)
```javascript
const { Client } = require('pg');

const client = new Client({
  connectionString: 'postgresql://admin:password@localhost:5432/maindb?sslmode=require'
});

await client.connect();
```

#### Go (lib/pq)
```go
import (
    "database/sql"
    _ "github.com/lib/pq"
)

db, err := sql.Open("postgres", 
    "host=localhost port=5432 user=admin password=password dbname=maindb sslmode=require")
```

#### Java (JDBC)
```java
String url = "jdbc:postgresql://localhost:5432/maindb?ssl=true&sslmode=require";
Connection conn = DriverManager.getConnection(url, "admin", "password");
```

#### Ruby (pg gem)
```ruby
require 'pg'

conn = PG.connect(
  host: 'localhost',
  port: 5432,
  dbname: 'maindb',
  user: 'admin',
  password: 'password',
  sslmode: 'require'
)
```

#### .NET (Npgsql)
```csharp
var connString = "Host=localhost;Port=5432;Database=maindb;Username=admin;Password=password;SSL Mode=Require;Trust Server Certificate=true";
using var conn = new NpgsqlConnection(connString);
```

## 🛠️ Management Scripts

### Start Database
```bash
./start.sh
```

### Stop Database
```bash
./stop.sh
```

### Connect via psql
```bash
./connect.sh
```

### Backup Database
```bash
./backup.sh
```
Backups are saved to `./backups/` directory.

### Test SSL Connection
```bash
./test-ssl.sh
```

### View Logs
```bash
docker-compose logs -f postgres
```

## 🔧 Advanced Configuration

### SSL Modes Explained

- `disable`: No SSL (not recommended)
- `allow`: Try SSL, fall back to non-SSL
- `prefer`: Try SSL first, fall back to non-SSL
- **`require`**: SSL required, server cert not verified (recommended for this setup)
- `verify-ca`: SSL required, verify server certificate
- `verify-full`: SSL required, verify server certificate and hostname

This setup uses **server-side SSL with `require` mode**, which:
- ✅ Encrypts all traffic
- ✅ Doesn't require client certificates
- ✅ Works with just a connection string
- ✅ Simple to use from any programming language

### Using with Production (Let's Encrypt)

For production with a real domain, use Let's Encrypt certificates:

1. **Configure your domain** in `.env`:
   ```bash
   DOMAIN=db.yourdomain.com
   LETSENCRYPT_EMAIL=admin@yourdomain.com
   USE_LETSENCRYPT=true
   LETSENCRYPT_STAGING=false  # false for production, true for testing
   ```

2. **Ensure DNS is configured**: Your domain must point to your server's IP

3. **Run certificate setup**:
   ```bash
   chmod +x setup-certs.sh
   ./setup-certs.sh
   ```

4. **Start the database**:
   ```bash
   ./start.sh
   ```

5. **Set up automatic renewal** (certificates expire every 90 days):
   ```bash
   chmod +x renew-certs.sh
   sudo crontab -e
   # Add this line:
   0 0 * * * /path/to/managed-postgres-db/renew-certs.sh
   ```

### Manual Certificate Installation

If you already have certificates from another CA:

1. Place certificates in the `certs/` directory:
   - `server.crt` - Server certificate
   - `server.key` - Private key
   - `root.crt` - CA chain
2. Update permissions:
   ```bash
   chmod 600 certs/server.key
   chmod 644 certs/server.crt certs/root.crt
   ```
3. Restart the database:
   ```bash
   ./stop.sh && ./start.sh
   ```

### Accessing from External Servers

1. **Expose PostgreSQL port**: Update `docker-compose.yml` to bind to `0.0.0.0`:
   ```yaml
   ports:
     - "0.0.0.0:5432:5432"
   ```

2. **Configure firewall**: Open port 5432

3. **Use connection string** with your server's IP/domain:
   ```
   postgresql://admin:password@YOUR_SERVER_IP:5432/maindb?sslmode=require
   ```

## 📊 pgAdmin Access

Access the web interface at: `http://localhost:5050`

**Login credentials** (from `.env`):
- Email: `admin@example.com`
- Password: `admin123`

**Add server in pgAdmin:**
- Host: `postgres` (Docker network name)
- Port: `5432`
- Database: `maindb`
- Username: `admin`
- Password: (from your `.env` file)
- SSL Mode: `Require`

## 🗄️ Database Schema

The setup includes sample tables:

### users
- `id` (UUID, primary key)
- `username` (varchar, unique)
- `email` (varchar, unique)
- `created_at` (timestamp)
- `updated_at` (timestamp)

### sessions
- `id` (UUID, primary key)
- `user_id` (UUID, foreign key)
- `token` (varchar)
- `expires_at` (timestamp)
- `created_at` (timestamp)

## 🔒 Security Features

- ✅ SSL/TLS encryption for all connections
- ✅ Password authentication with scram-sha-256
- ✅ Non-SSL connections rejected for remote access
- ✅ Connection logging enabled
- ✅ Modern cipher suites only
- ✅ TLS 1.2+ required

## 📦 Backup and Restore

### Create Backup
```bash
./backup.sh
```

### Restore from Backup
```bash
gunzip -c backups/backup_maindb_20231015_143022.sql.gz | \
  docker exec -i managed-postgres-db psql -U admin -d maindb
```

## 🐛 Troubleshooting

### Check if SSL is enabled
```bash
docker exec managed-postgres-db psql -U admin -d maindb -c "SHOW ssl;"
```

### Check SSL connections
```bash
docker exec managed-postgres-db psql -U admin -d maindb -c \
  "SELECT datname, usename, client_addr, ssl FROM pg_stat_ssl JOIN pg_stat_activity ON pg_stat_ssl.pid = pg_stat_activity.pid;"
```

### View PostgreSQL logs
```bash
docker-compose logs -f postgres
```

### Connection refused?
- Check if container is running: `docker ps`
- Check if port is available: `lsof -i :5432`
- Check firewall settings

### Self-signed certificate warnings?
This is normal with self-signed certificates. Use `sslmode=require` (not `verify-ca` or `verify-full`) to avoid these warnings while still maintaining encrypted connections.

## � Deploying with Coolify

Coolify is a self-hosted platform for deploying applications. This setup is fully compatible!

### Quick Deploy on Coolify

1. **Push your code to a Git repository** (GitHub, GitLab, etc.)

2. **In Coolify Dashboard**:
   - Create a new application
   - Select "Docker Compose" as deployment type
   - Connect your Git repository
   - Set the branch (usually `main` or `master`)

3. **Set Environment Variables in Coolify**:
   ```bash
   POSTGRES_USER=admin
   POSTGRES_PASSWORD=your_secure_password
   POSTGRES_DB=maindb
   POSTGRES_PORT=5432
   DOMAIN=your-coolify-domain.com
   LETSENCRYPT_EMAIL=admin@yourdomain.com
   USE_LETSENCRYPT=true
   ```

4. **Configure Port Mapping**:
   - Expose port 5432 for PostgreSQL
   - Optionally expose port 5050 for pgAdmin

5. **Deploy**: Coolify will automatically:
   - Pull your code
   - Set up SSL certificates
   - Start PostgreSQL with encryption
   - Configure health checks

6. **Access Your Database**:
   ```
   postgresql://admin:password@your-coolify-domain.com:5432/maindb?sslmode=require
   ```

### Coolify-Specific Commands

```bash
# Deploy/redeploy
./coolify-deploy.sh

# View logs
docker-compose logs -f postgres
```

## �📁 Project Structure

```
managed-postgres-db/
├── docker-compose.yml      # Docker Compose configuration
├── coolify.yaml           # Coolify configuration
├── .env.example           # Environment variables template
├── .env                   # Your environment variables (gitignored)
├── setup.sh              # Initial setup script
├── setup-certs.sh        # Universal certificate setup (Let's Encrypt or self-signed)
├── letsencrypt-setup.sh  # Let's Encrypt certificate setup
├── renew-certs.sh        # Certificate renewal script
├── generate-certs.sh     # Self-signed certificate generation
├── coolify-deploy.sh     # Coolify deployment script
├── start.sh              # Start database
├── stop.sh               # Stop database
├── connect.sh            # Connect via psql
├── backup.sh             # Backup database
├── test-ssl.sh           # Test SSL connection
├── config/
│   ├── postgresql.conf   # PostgreSQL configuration
│   └── pg_hba.conf      # Host-based authentication
├── init/
│   ├── 01-init.sql      # Database initialization
│   └── 02-configure-ssl.sql
├── examples/
│   ├── python_example.py # Python connection example
│   ├── nodejs_example.js # Node.js connection example
│   └── requirements.txt  # Python dependencies
├── certs/                # SSL certificates (gitignored)
├── letsencrypt/          # Let's Encrypt certificates (gitignored)
└── backups/              # Database backups (gitignored)
```

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

MIT License - feel free to use this in your projects!

## 🎯 Use Cases

Perfect for:
- Development environments
- Staging servers
- Internal applications
- Microservices
- API backends
- Any application requiring secure PostgreSQL connections

## 🔗 Useful Links

- [PostgreSQL SSL Documentation](https://www.postgresql.org/docs/current/ssl-tcp.html)
- [psycopg2 Connection Strings](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING)
- [Docker PostgreSQL Image](https://hub.docker.com/_/postgres)

---

**Made with ❤️ for secure database connections**
