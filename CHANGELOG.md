# Changelog

## [1.0.0] - 2026-09-13

### Added
- Five chained Airflow DAGs: API ingestion → GCS → BigQuery → dbt transformations
- Functional Data Engineering pattern: full snapshot per run with `partition_date` column
- dbt three-layer model: Staging (5 views) → Refined (8 incremental models) → Mart (5 star-schema views)
- Custom dbt test `unique_id_partition` for partition-aware uniqueness validation
- GeoJSON → NDJSON conversion utility (`airflow/scripts/json_to_ndjson.py`) for BigQuery GEOGRAPHY ingestion
- Terraform IaC provisioning GCS, BigQuery, Cloud Composer, and service accounts
- Dockerised dbt execution via Airflow `DockerOperator` + `socat` proxy
- Tableau workbook connected to BigQuery mart layer
- READMEs for all folders

### Security
- Replaced hardcoded local credential paths in `docker-compose.yaml` with placeholders
- Replaced real GCP project ID, project number, and credential file paths in `variables.tf` with placeholders
- Replaced real GCP service account key filename reference in `docker-compose.yaml`
- Renamed `dag_id` and `trigger_dag_id` strings from numbered convention to professional descriptive names
- Replaced `owner` field in DAG default_args from contributor handle to `morid648`
