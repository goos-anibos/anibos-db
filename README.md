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

## ER Diagram (Mermaid)

```mermaid
erDiagram
    countries ||--o{ institution_codes : "has"
    countries ||--o{ contacts : "has"
    institution_codes ||--o{ contacts : "employs / belongs to"
    institution_codes ||--o{ projects : "publishes as"
    contacts ||--o{ projects : "publishes as"
    projects ||--o{ contacts_projects : "has contributors"
    contacts ||--o{ contacts_projects : "contributes to"
    projects ||--o{ campaigns : "contains"
    campaigns ||--o{ deployments : "includes"
    animals ||--o{ deployments : "tagged in"

    countries {
        char2 country_id PK
        varchar100 country_name
        char3 iso3_code
        char3 iso_numeric
    }

    institution_codes {
        varchar200 institutioncode PK
        text institutionname
        text website
        text org_id
        char2 country_id FK
        text state
        text sector
        timestamptz date_created
        timestamptz date_updated
    }

    contacts {
        text contact_pk PK
        text first_name
        text last_name
        text email UK
        varchar200 institution_code FK
        bpchar2 country_id FK
        text personal_url
        bool is_active
        timestamptz date_created
        timestamptz date_updated
    }

    projects {
        text program
        text project_id PK
        text title
        text license
        bool gts_ingest
        text project_name
        text uuid
        text info_url
        text summary
        text citation
        text keywords
        text keywords_vocabulary
        text history
        text publisher_type
        text publisher_institutioncode_pk FK
        text publisher_contact_pk FK
        timestamptz date_created
        timestamptz date_issued
        timestamptz date_modified
        bool is_active
    }

    contacts_projects {
        text project_id PK FK
        text contact_pk PK FK
        text role
        text role_type
        text role_vocabulary
        date start_date
        date end_date
        bool is_creator
        bool is_active
        timestamptz date_created
        timestamptz date_updated
    }

    animals {
        text animal_id PK
        varchar scientific_name
        varchar common_name
        varchar aphia_id
        timestamptz date_created
        timestamptz date_updated
        text comment
    }

    campaigns {
        text project_id PK FK
        text campaign PK
        text naming_authority
        text argos_program_number
        text instrument_manufacturer
        text conventions
        text sea_name
        text standard_name_vocab
        text instrument
        text cdm_data_type
        text feature_type
        text data_mode
        text processing_level
        text source
        text qc_manual
        timestamptz date_issued
        timestamptz date_created
        timestamptz date_updated
    }

    deployments {
        text program
        text project_id FK
        text campaign_id FK
        text deployment_id PK
        text animal_id FK
        text wigos_station_identifier
        text wmo_platform_code
        numeric deployment_lat
        numeric deployment_lon
        timestamptz deployment_start
        timestamptz deployment_end
        text manufacturer_id
        text instrument
        text instrument_model
        text instrument_ptt_id
        text instrument_sensor_type
        text instrument_serial_number
        text platform
        text platform_id
        text platform_name
        text platform_type
        text platform_vocabulary
        timestamptz time_coverage_start
        timestamptz time_coverage_end
        numeric geospatial_lat_min
        numeric geospatial_lat_max
        text geospatial_lat_units
        numeric geospatial_lon_min
        numeric geospatial_lon_max
        text geospatial_lon_units
        numeric geospatial_vertical_min
        numeric geospatial_vertical_max
        text geospatial_vertical_units
        text geospatial_vertical_positive
        geometry geospatial_bounds
        text geospatial_bounds_crs
        text geospatial_bounds_vertical_crs
        timestamptz date_created
        timestamptz date_updated
    }

    %% Relationships
    countries ||--o{ institution_codes : "has"
    countries ||--o{ contacts : "has"
    institution_codes ||--o{ contacts : "employs / belongs to"
    institution_codes ||--o{ projects : "publishes as"
    contacts ||--o{ projects : "publishes as"
    projects ||--o{ contacts_projects : "has contributors"
    contacts ||--o{ contacts_projects : "contributes to"
    projects ||--o{ campaigns : "contains"
    campaigns ||--o{ deployments : "includes"
    animals ||--o{ deployments : "tagged in"
