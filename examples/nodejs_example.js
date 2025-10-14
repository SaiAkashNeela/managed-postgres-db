// Example Node.js script to connect to the managed PostgreSQL database
// Uses pg library with SSL connection

const { Client } = require('pg');

// Get connection string from environment or use defaults
function getConnectionString() {
    const host = process.env.POSTGRES_HOST || 'localhost';
    const port = process.env.POSTGRES_PORT || '5432';
    const user = process.env.POSTGRES_USER || 'admin';
    const password = process.env.POSTGRES_PASSWORD || 'changeme123';
    const database = process.env.POSTGRES_DB || 'maindb';
    
    return `postgresql://${user}:${password}@${host}:${port}/${database}?sslmode=require`;
}

async function testConnection() {
    const connectionString = getConnectionString();
    
    console.log('🔌 Testing PostgreSQL Connection with SSL');
    console.log('='.repeat(50));
    
    const client = new Client({
        connectionString,
        ssl: {
            rejectUnauthorized: false // Required for self-signed certificates
        }
    });
    
    try {
        // Connect to database
        await client.connect();
        console.log('✓ Connected to PostgreSQL');
        
        // Test 1: Check PostgreSQL version
        const versionResult = await client.query('SELECT version();');
        console.log(`  Version: ${versionResult.rows[0].version.substring(0, 50)}...`);
        
        // Test 2: Check SSL status
        const sslResult = await client.query('SHOW ssl;');
        console.log(`✓ SSL Status: ${sslResult.rows[0].ssl}`);
        
        // Test 3: Check current connection SSL info
        const sslInfoQuery = `
            SELECT 
                inet_client_addr() as client_addr,
                inet_server_addr() as server_addr,
                ssl,
                version
            FROM pg_stat_ssl 
            JOIN pg_stat_activity ON pg_stat_ssl.pid = pg_stat_activity.pid
            WHERE pg_stat_activity.pid = pg_backend_pid();
        `;
        const sslInfo = await client.query(sslInfoQuery);
        if (sslInfo.rows.length > 0 && sslInfo.rows[0].ssl) {
            console.log('✓ Connection is encrypted');
            console.log(`  Client: ${sslInfo.rows[0].client_addr}`);
            console.log(`  Server: ${sslInfo.rows[0].server_addr}`);
            console.log(`  TLS Version: ${sslInfo.rows[0].version}`);
        } else {
            console.log('⚠ Connection is not encrypted');
        }
        
        // Test 4: Query sample data
        const countResult = await client.query('SELECT COUNT(*) as count FROM users;');
        console.log('✓ Sample query successful');
        console.log(`  Users in database: ${countResult.rows[0].count}`);
        
        // Test 5: List all tables
        const tablesQuery = `
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public';
        `;
        const tables = await client.query(tablesQuery);
        console.log('✓ Tables in database:');
        tables.rows.forEach(table => {
            console.log(`  - ${table.table_name}`);
        });
        
        console.log('='.repeat(50));
        console.log('✓ All tests passed!');
        console.log('');
        console.log('Connection string format:');
        console.log(connectionString.replace(process.env.POSTGRES_PASSWORD || 'changeme123', '****'));
        
        return true;
        
    } catch (error) {
        console.error('✗ Database error:', error.message);
        return false;
    } finally {
        await client.end();
    }
}

async function createSampleData() {
    const connectionString = getConnectionString();
    const client = new Client({
        connectionString,
        ssl: {
            rejectUnauthorized: false
        }
    });
    
    try {
        await client.connect();
        
        // Insert sample users
        const insertQuery = `
            INSERT INTO users (username, email) 
            VALUES 
                ('john_doe', 'john@example.com'),
                ('jane_smith', 'jane@example.com')
            ON CONFLICT (username) DO NOTHING
            RETURNING id, username;
        `;
        
        const result = await client.query(insertQuery);
        
        if (result.rows.length > 0) {
            console.log(`✓ Inserted ${result.rows.length} sample users`);
            result.rows.forEach(user => {
                console.log(`  - ${user.username} (ID: ${user.id})`);
            });
        } else {
            console.log('ℹ Sample users already exist');
        }
        
    } catch (error) {
        console.error('✗ Error creating sample data:', error.message);
    } finally {
        await client.end();
    }
}

// Main execution
async function main() {
    console.log('');
    const success = await testConnection();
    
    if (success) {
        console.log('');
        await createSampleData();
        console.log('');
        console.log('✓ Example script completed successfully!');
    } else {
        console.log('');
        console.log('✗ Connection test failed');
        process.exit(1);
    }
}

// Run if executed directly
if (require.main === module) {
    main().catch(error => {
        console.error('Fatal error:', error);
        process.exit(1);
    });
}

module.exports = { testConnection, createSampleData };
