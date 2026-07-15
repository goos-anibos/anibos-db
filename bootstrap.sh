#!/bin/sh
DB_USER=${DB_USER:-anibos}
DB_PASS=${DB_PASS:-anibospass}
ANIBOS_DATABASE_NAME=${ANIBOS_DATABASE_NAME:-anibos}

# Use the correct PostgreSQL data directory
PGDATA=${PGDATA:-/var/lib/postgresql/data}

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

# Set proper permissions
chown postgres:postgres "$PGDATA/pg_hba.conf"
chmod 600 "$PGDATA/pg_hba.conf"

# postgresql.conf - use the correct path
if [ -f /postgresql.conf ]; then
    cp /postgresql.conf "$PGDATA/postgresql.conf"
    chown postgres:postgres "$PGDATA/postgresql.conf"
    chmod 600 "$PGDATA/postgresql.conf"
fi

# Reload PostgreSQL to apply configuration changes
pg_ctl reload -D "$PGDATA" || true

# Setup user and database
psql -U postgres <<-EOSQL
    CREATE ROLE $DB_USER WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN NOREPLICATION PASSWORD '$DB_PASS' VALID UNTIL 'infinity';
    CREATE DATABASE $ANIBOS_DATABASE_NAME OWNER $DB_USER;
EOSQL

# Create nomad configuration
cat > /migrations/nomad.ini <<EOL
[nomad]
engine = sqla
url = postgresql://postgres@/${ANIBOS_DATABASE_NAME}

[anibos]
user = ${DB_USER}
database = ${ANIBOS_DATABASE_NAME}
EOL

# Fix Python import issue before running migrations
# Option 1: Monkey patch collections.Callable
python3 -c "
import collections
from collections.abc import Callable
collections.Callable = Callable
print('Fixed collections.Callable import')
" || true

# Run migrations
echo "Running migrations..."
/opt/venv/bin/nomad init || {
    echo "Nomad init failed, attempting to fix Python environment..."
    # Try to fix opster issue
    pip install --upgrade opster || true
    # Retry
    /opt/venv/bin/nomad init
}
/opt/venv/bin/nomad apply -a || {
    echo "Nomad apply failed"
    exit 1
}

echo "Bootstrap completed successfully!"
