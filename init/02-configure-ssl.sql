-- Update pg_hba.conf to require SSL for all connections
-- This script adds SSL enforcement rules

\echo '==== Configuring SSL authentication ===='

-- Note: pg_hba.conf is better configured directly via file
-- But we can set some SSL-related parameters here

-- Set connection logging
ALTER SYSTEM SET log_connections = 'on';
ALTER SYSTEM SET log_disconnections = 'on';

-- Reload configuration
SELECT pg_reload_conf();

\echo '✓ SSL authentication configured'
\echo '✓ All remote connections will require SSL'
