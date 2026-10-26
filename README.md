# Banking Lakehouse Platform

A simulated banking data platform: CDC from 3 source systems (core banking, CRM, LOS) → Kafka → Bronze/Silver/Gold lakehouse on Apache Iceberg, plus a near-real-time fraud detection branch, Customer 360 and money reconciliation. Uses fake data and runs with Docker Compose.

## Status

Only the repo skeleton and the Docker Compose `core` profile exist so far: Postgres, Kafka, Debezium (Kafka Connect), MinIO. The remaining directories are empty and will be filled in phase by phase.

| Phase | Scope | Status |
|---|---|---|
| 1 | Postgres, Kafka, Debezium, MinIO, generator | Core compose only |
| 2 | Spark: Kafka → Bronze → Silver | Not started |
| 3 | Trino + dbt: Gold, SCD2 | Not started |
| 4 | Airflow: reconciliation, maintenance, Great Expectations | Not started |
| 5 | Flink SQL fraud + Slack | Not started |
| 6-7 | Dashboard, lineage, documentation | Not started |

## Running core

```bash
cp .env.example .env
make up          # or: docker compose --env-file .env -f docker/docker-compose.yml --profile core up -d
make ps          # show status
make down        # stop
make clean       # stop and delete volumes (data is lost)
```

| Service | Host port | Notes |
|---|---|---|
| Postgres | 5432 | `wal_level=logical` so Debezium can read the WAL |
| Kafka | 29092 | Inside the Docker network use `kafka:9092` |
| Kafka Connect (Debezium) | 8083 | REST API for registering connectors |
| MinIO API / Console | 9000 / 9001 | Will store Iceberg data later |

## Directory layout

```text
banking_lakehouse/
├── README.md · Makefile · .env.example · .gitignore · pyproject.toml
├── docker/
├── infra/
├── generator/
├── streaming/
├── fraud/
├── dbt/
├── quality/
├── airflow/
├── dashboard/
├── docs/
├── scripts/
└── .github/workflows/
```

### Root files

| File | Purpose |
|---|---|
| `Makefile` | Shortcuts `up/down/ps/logs/clean` for the `core` profile |
| `.env.example` | Environment variable template (user, password, ports, PII hash pepper). Copy to `.env`; `.env` is not committed |
| `.gitignore` | Excludes `.env`, Python caches, IDE files |
| `pyproject.toml` | Python metadata; dependencies will be added once there is code |

### Directories

| Directory | Purpose | Phase |
|---|---|---|
| `docker/` | `docker-compose.yml` (split into profiles, currently only `core`) and per-service configs/Dockerfiles | 1 |
| `docker/debezium/` | Debezium connector config for Postgres (`postgres-connector.json`) | 1 |
| `docker/spark/` | Spark image and configuration | 2 |
| `docker/trino/` | Trino configuration; `catalog/` holds the Iceberg catalog | 3 |
| `docker/airflow/` | Airflow image and configuration | 4 |
| `infra/postgres/init/` | SQL run automatically on first Postgres initialization: 3 source schemas, CDC publication | 1 |
| `infra/minio/` | Script to create the initial buckets | 1 |
| `infra/kafka/` | Topic creation script | 1 |
| `generator/` | Fake data generation: master customer list, core banking, CRM, LOS, deliberate errors/fraud; commands `seed`, `stream`, `inject` | 1 |
| `streaming/` | Spark Structured Streaming jobs: Kafka → Bronze (PII hashing) and Bronze → Silver (`MERGE INTO`), with SQL DDL and tests | 2 |
| `dbt/` | dbt-trino models building Gold: `dim_customer` (SCD2), `identity_map`, `customer_360`, risk marts | 3 |
| `airflow/` | DAGs (dbt, hourly reconciliation, Iceberg maintenance, end-of-day report, health check), plugins and shared SQL | 4 |
| `quality/` | Great Expectations: data quality checks on Silver | 4 |
| `fraud/` | Flink SQL: fraud rules and the `fraud_alerts` sink | 5 |
| `dashboard/` | Streamlit and Grafana | 6 |
| `scripts/` | Utility scripts: bootstrap, Debezium registration, running streaming jobs | 1+ |


## Data flow (summary)

```text
generator → Postgres (core_banking, crm, los)
          → Debezium → Kafka ─┬→ Flink (fraud) → Slack / fraud_alerts
                              └→ Spark: Bronze → Silver (Iceberg trên MinIO)
                                          → dbt + Trino → Gold → Grafana / Streamlit
Airflow orchestrates: Great Expectations, dbt, reconciliation, Iceberg maintenance, health checks
```
