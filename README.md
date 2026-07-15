# anibos-db
AniBOS backend DB Docker image

## Overview

The **AniBOS Database** builds a PostgreSQL database Docker container with AniBOS database migration scripts.

Schemas: 
- **anibos**: [AniBOS schema](https://docs.google.com/spreadsheets/d/1R0mZ0ZgvyGcx-KwTJxLp9p8_XqcsWyUV/edit?gid=1952008307#gid=1952008307)
- **satnrt**: the backend for Near Real Time pipeline.

---

## Components:

- **PostgreSQL 14** with **TimescaleDB** (for time-series optimization).
- **PostGIS** (for geospatial queries).
- **Nomad** (the migration tool) pre-installed inside a Python virtual environment.
- `bootstrap.sh` runs the database migrations after Docker container after startup.

---

## Prerequisites

- **Docker** (version 20.10+)
- **Docker Compose** (version 2.0+)
- **Git** (for cloning the repository)
- **Port 5432** (default PostgreSQL) must be free on the host machine, or change the port mapping.

---

## Related files

anibos-db/
├── Dockerfile_SAT       # Builds the TimescaleDB + Python + Nomad environment
├── docker-compose.yml   # Orchestrates the container lifecycle
├── requirements.txt     # Python dependencies (Nomad, SQLAlchemy, etc.)
├── bootstrap.sh         # Initialization script run on first container start
├── migrations/          # Database migration files (SQL)
├── pg_hba.conf          # Client authentication configuration
└── postgresql.conf      # PostgreSQL server configuration

---

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone TBD
   cd anibos-db
   
2. **Build and run the `otnsat` docker image 
   ```bash
    docker compose build --no-cache

 - Expected output
    ✔ Image anibos-db-database       Built                                                                           78.9s
    ✔ Network anibos-db_default      Created                                                                          0.2s
    ✔ Container anibos-db-database-1 Created                                                                         17.4s

   ```bash
       docker compose up
  - Expected output


# AniBOS Database Schema

AniBOS schema implemented the project and deployment metadata defined in https://docs.google.com/spreadsheets/d/1R0mZ0ZgvyGcx-KwTJxLp9p8_XqcsWyUV/edit?gid=1041943450#gid=1041943450
Normalized into project‑program‑deployment hierarchy.

---

## Migration Process


0. Roles
    - Creates roles with correct inheritance

1. Extensions
    - Creates extensions post and dblink

2. Creates `anibos` schema

3. Creates `satnrt` schema
