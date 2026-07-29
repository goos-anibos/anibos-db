# AniBOS Database

AniBOS database Docker image based on PostgreSQL with TimescaleDB and PostGIS extensions.

**Repository:** https://github.com/goos-anibos/anibos-db

---

## Overview

The **AniBOS Database** repository provides a Docker image containing PostgreSQL and AniBOS database migration scripts.

The database contains two primary schemas:

| Schema | Description |
|---------|-------------|
| **anibos** | AniBOS project and deployment metadata |
| **satnrt** | Backend schema for the Near Real-Time (NRT) satellite telemetry pipeline |

For the database schema documentation, see:

https://docs.google.com/spreadsheets/d/1R0mZ0ZgvyGcx-KwTJxLp9p8_XqcsWyUV/edit?gid=1952008307#gid=1952008307

---

# Features

- PostgreSQL 14
- TimescaleDB extension
- PostGIS extension
- Automatic database migrations
- Nomad migration tool installed in a Python virtual environment
- Docker Compose support

> **Note**
>
> The official `timescale/timescaledb-postgis` Docker image is no longer maintained. This project uses an alternative maintained image.

---

# Prerequisites

- Docker 20.10+
- Docker Compose 2+
- Git
- Port **5432** available (or modify the port mapping)

---

# Project Structure

```text
anibos-db/
├── migrations/
│   ├── 0000-roles/
│   │   └── up.j2
│   ├── 0011-create-anibos-schema/
│   │   └── up.j2
│   └── 0012-create-satnrt-schema/
│       └── up.j2
├── bootstrap.sh
├── Dockerfile
├── docker-compose.yml
├── pg_hba.conf
├── postgresql.conf
├── requirements.txt
└── README.md
```

---

# Quick Start

## 1. Clone the repository

```bash
git clone git@github.com:goos-anibos/anibos-db.git
cd anibos-db
```

---

## 2. Build the Docker image

```bash
docker compose build --no-cache
```

Example output:

```text
✔ Image anibos-db-database        Built
✔ Network anibos-db_default       Created
✔ Container anibos-db-database-1  Created
```

---

## 3. Start the database

```bash
docker compose up -d
```

---

## 4. Connect to the database

Use any PostgreSQL client such as DBeaver.

| Setting | Value |
|----------|-------|
| Host | localhost |
| Port | 5432 |
| Database | anibos |
| Username | anibos |
| Password | anibospass |

Expected schemas:

- `anibos`
- `satnrt`

---

## 5. View logs

```bash
docker compose logs -f database
```

---

# Other Docker Commands 

| Command | Description                   |
|---------|-------------------------------|
| `docker compose down -v` | Remove containers and volumes |
| `docker compose exec database bash` | Open shell                    |
| `docker compose exec database psql -U anibos -d anibos` | Open PostgreSQL shell         |

---

# Cleaning Local Data

### Windows

```powershell
Remove-Item -Recurse -Force .\data\db
```

### Linux / macOS

```bash
rm -rf ./data/db
```

---

# Database Migrations

Migrations are executed automatically every time the Docker container starts via `bootstrap.sh`.

```bash
docker compose up -d
```

---

## Manual Migration Methods


### Apply all Migrations – Using Nomad

Install dependencies:

```bash
pip install -r requirements.txt
```

Initialize:

```bash
nomad init
```

Apply migrations:

```bash
nomad apply -a
```

### Apply Specific Migration(s) – Using Nomad

Apply a specific migration:

```bash
nomad apply 0011-create-anibos-schema
```

Rollback:

```bash
nomad rollback -a
```

Rollback to a version:

```bash
nomad rollback 0010
```

---

# Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_USER` | anibos | Database username |
| `DB_PASS` | anibospass | Database password |
| `ANIBOS_DATABASE_NAME` | anibos | Database name |
| `PGHOST` | localhost | PostgreSQL host |
| `PGPORT` | 5432 | PostgreSQL port |
| `DATABASE_URL` | Generated automatically | Connection string |

Example:

```bash
DB_USER=myuser \
DB_PASS=mypass \
ANIBOS_DATABASE_NAME=mydb \
PGHOST=192.168.1.100 \
psql \
-U myuser \
-d mydb \
-h 192.168.1.100 \
-f migrations/0011-create-anibos-schema/up.j2
```

---

# Verifying Migrations

List all tables:

```bash
docker compose exec database \
psql \
-U anibos \
-d anibos \
-c "\dt anibos.*"
```

List schemas:

```bash
docker compose exec database \
psql \
-U anibos \
-d anibos \
-c "\dn"
```

Migration status:

```bash
docker compose exec database \
/opt/venv/bin/nomad status
```

---

# Automatic Migration Order

During startup, `bootstrap.sh` performs the following:

1. Create database roles
2. Enable PostgreSQL extensions
3. Create the `anibos` schema
4. Create the `satnrt` schema

The `anibos` schema includes:

- countries
- institution_codes
- contacts
- projects
- campaigns
- animals
- deployments

---

# Troubleshooting

## Role already exists

```
role "anibos" already exists
```

This is expected if migrations have already been executed.

---

## Must be superuser

```
must be superuser to alter superuser roles
```

Run the migration as:

```bash
psql -U postgres -d anibos
```

---

## Foreign key errors

```
column "campaign" referenced in foreign key constraint does not exist
```

Update to the latest migration files.

---

## Connection refused

Verify:

```bash
docker compose ps
```

Check:

- Host
- Port
- Credentials

---

## TimescaleDB version warning

Example:

```
Extension version 2.13.0 installed, latest is 2.29.0
```

This warning is non-fatal.

---

# Reset Everything

```bash
docker compose down -v

rm -rf ./data/db

docker compose build --no-cache

docker compose up -d
```

---

# Contributing

1. Fork the repository
2. Create a feature branch

```bash
git checkout -b feature/my-feature
```

3. Commit changes

```bash
git commit -m "Add new feature"
```

4. Push

```bash
git push origin feature/my-feature
```

5. Open a Pull Request

---

# License

Specify the project license here.

---

# Useful Links

- Repository: https://github.com/goos-anibos/anibos-db
- Issues: https://github.com/goos-anibos/anibos-db/issues
- Database Schema: https://docs.google.com/spreadsheets/d/1R0mZ0ZgvyGcx-KwTJxLp9p8_XqcsWyUV/edit?gid=1952008307#gid=1952008307
