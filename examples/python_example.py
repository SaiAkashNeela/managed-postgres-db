#!/usr/bin/env python3
"""
Example Python script to connect to the managed PostgreSQL database.
Uses psycopg2 with SSL connection.
"""

import os
import sys
from typing import Optional

try:
    import psycopg2
    from psycopg2.extras import RealDictCursor
except ImportError:
    print("Error: psycopg2 not installed")
    print("Install with: pip install psycopg2-binary")
    sys.exit(1)


def get_connection_string() -> str:
    """Get connection string from environment or use defaults."""
    host = os.getenv('POSTGRES_HOST', 'localhost')
    port = os.getenv('POSTGRES_PORT', '5432')
    user = os.getenv('POSTGRES_USER', 'admin')
    password = os.getenv('POSTGRES_PASSWORD', 'changeme123')
    database = os.getenv('POSTGRES_DB', 'maindb')
    
    return f"postgresql://{user}:{password}@{host}:{port}/{database}?sslmode=require"


def test_connection():
    """Test the database connection and SSL status."""
    connection_string = get_connection_string()
    
    print("🔌 Testing PostgreSQL Connection with SSL")
    print("=" * 50)
    
    try:
        # Connect to the database
        conn = psycopg2.connect(connection_string)
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Test 1: Check PostgreSQL version
        cursor.execute("SELECT version();")
        version = cursor.fetchone()
        print(f"✓ Connected to PostgreSQL")
        print(f"  Version: {version['version'][:50]}...")
        
        # Test 2: Check SSL status
        cursor.execute("SHOW ssl;")
        ssl_status = cursor.fetchone()
        print(f"✓ SSL Status: {ssl_status['ssl']}")
        
        # Test 3: Check current connection SSL info
        cursor.execute("""
            SELECT 
                inet_client_addr() as client_addr,
                inet_server_addr() as server_addr,
                ssl,
                version
            FROM pg_stat_ssl 
            JOIN pg_stat_activity ON pg_stat_ssl.pid = pg_stat_activity.pid
            WHERE pg_stat_activity.pid = pg_backend_pid();
        """)
        ssl_info = cursor.fetchone()
        if ssl_info and ssl_info['ssl']:
            print(f"✓ Connection is encrypted")
            print(f"  Client: {ssl_info['client_addr']}")
            print(f"  Server: {ssl_info['server_addr']}")
            print(f"  TLS Version: {ssl_info['version']}")
        else:
            print("⚠ Connection is not encrypted")
        
        # Test 4: Query sample data
        cursor.execute("SELECT COUNT(*) as count FROM users;")
        result = cursor.fetchone()
        print(f"✓ Sample query successful")
        print(f"  Users in database: {result['count']}")
        
        # Test 5: List all tables
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public';
        """)
        tables = cursor.fetchall()
        print(f"✓ Tables in database:")
        for table in tables:
            print(f"  - {table['table_name']}")
        
        cursor.close()
        conn.close()
        
        print("=" * 50)
        print("✓ All tests passed!")
        print("")
        print("Connection string format:")
        print(get_connection_string().replace(os.getenv('POSTGRES_PASSWORD', 'changeme123'), '****'))
        
        return True
        
    except psycopg2.Error as e:
        print(f"✗ Database error: {e}")
        return False
    except Exception as e:
        print(f"✗ Unexpected error: {e}")
        return False


def create_sample_data():
    """Insert some sample data into the database."""
    connection_string = get_connection_string()
    
    try:
        conn = psycopg2.connect(connection_string)
        cursor = conn.cursor()
        
        # Insert sample users
        cursor.execute("""
            INSERT INTO users (username, email) 
            VALUES 
                ('john_doe', 'john@example.com'),
                ('jane_smith', 'jane@example.com')
            ON CONFLICT (username) DO NOTHING
            RETURNING id, username;
        """)
        
        inserted = cursor.fetchall()
        if inserted:
            print(f"✓ Inserted {len(inserted)} sample users")
            for user in inserted:
                print(f"  - {user[1]} (ID: {user[0]})")
        else:
            print("ℹ Sample users already exist")
        
        conn.commit()
        cursor.close()
        conn.close()
        
    except Exception as e:
        print(f"✗ Error creating sample data: {e}")


if __name__ == "__main__":
    print("")
    if test_connection():
        print("")
        create_sample_data()
        print("")
        print("✓ Example script completed successfully!")
    else:
        print("")
        print("✗ Connection test failed")
        sys.exit(1)
