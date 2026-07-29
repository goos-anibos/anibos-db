#!/bin/sh
DB_USER=${DB_USER:-anibos}
DB_PASS=${DB_PASS:-anibospass}
ANIBOS_DATABASE_NAME=${ANIBOS_DATABASE_NAME:-anibos}

PGDATA=${PGDATA:-/pg/data}

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to start..."
until pg_isready -U postgres; do
    sleep 2
done
echo "PostgreSQL is ready!"

# pg_hba.conf - use the correct path
if [ -f /pg_hba.conf ]; then
    cp /pg_hba.conf "$PGDATA/pg_hba.conf"
    echo "host    all    all    172.0.0.1/8    trust" >> "$PGDATA/pg_hba.conf"
else
    cat > "$PGDATA/pg_hba.conf" <<EOL
local   all    all                            trust
host    all    all            127.0.0.1/32    trust
host    all    all            ::1/128         trust
host    all    all            172.0.0.1/8     trust
EOL
fi

# Set permissions
chown postgres:postgres "$PGDATA/pg_hba.conf"
chmod 600 "$PGDATA/pg_hba.conf"

# postgresql.conf
if [ -f /postgresql.conf ]; then
    cp /postgresql.conf "$PGDATA/postgresql.conf"
    chown postgres:postgres "$PGDATA/postgresql.conf"
    chmod 600 "$PGDATA/postgresql.conf"
fi

# Reload PostgreSQL to apply configuration changes
pg_ctl reload -D "$PGDATA" || true

# Setup user and database
psql -U postgres <<-EOSQL
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$DB_USER') THEN
            CREATE ROLE $DB_USER WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN NOREPLICATION PASSWORD '$DB_PASS' VALID UNTIL 'infinity';
        END IF;
    END
    \$\$;
    SELECT 'CREATE DATABASE $ANIBOS_DATABASE_NAME OWNER $DB_USER'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$ANIBOS_DATABASE_NAME')\gexec
EOSQL

# ==========================================
# ENABLE POSTGIS EXTENSIONS
# ==========================================
echo "Enabling PostGIS extensions..."
psql -U $DB_USER -d $ANIBOS_DATABASE_NAME <<-EOSQL
    -- Create extensions
    CREATE EXTENSION IF NOT EXISTS postgis;
    CREATE EXTENSION IF NOT EXISTS postgis_topology;
    SELECT PostGIS_Version();
EOSQL

# Create nomad configuration
cat > /migrations/nomad.ini <<EOL
[nomad]
engine = sqla
url = postgresql://${DB_USER}:${DB_PASS}@localhost:5432/${ANIBOS_DATABASE_NAME}

[anibos]
host = localhost
user = ${DB_USER}
pass = ${DB_PASS}
port = 5432
database = ${ANIBOS_DATABASE_NAME}
EOL

python3 -c "
import collections
from collections.abc import Callable
collections.Callable = Callable
print('Fixed collections.Callable import')
" || true

# Run migrations
echo "Running migrations..."
cd /migrations

# Check if nomad exists and run migrations
if command -v /opt/venv/bin/nomad >/dev/null 2>&1; then
    /opt/venv/bin/nomad init || {
        echo "Nomad init failed, attempting to fix Python environment..."
        pip install --upgrade opster || true
        /opt/venv/bin/nomad init
    }
    /opt/venv/bin/nomad apply -a || {
        echo "Nomad apply failed, falling back to SQL migrations..."
        # Fallback to SQL
        for migration_dir in /migrations/[0-9]*-*/; do
            if [ -f "${migration_dir}up.j2" ]; then
                echo "Running migration: $(basename $migration_dir)"
                psql -U $DB_USER -d $ANIBOS_DATABASE_NAME -f "${migration_dir}up.j2" || exit 1
            fi
        done
    }
else
    echo "Nomad not found, running SQL migrations directly..."
    for migration_dir in /migrations/[0-9]*-*/; do
        if [ -f "${migration_dir}up.j2" ]; then
            echo "Running migration: $(basename $migration_dir)"
            psql -U $DB_USER -d $ANIBOS_DATABASE_NAME -f "${migration_dir}up.j2" || exit 1
        fi
    done
fi

echo "Bootstrap completed successfully!"