# `airflow/`

## Purpose
Apache Airflow orchestration layer — five chained DAGs that automate the full pipeline from API ingestion through BigQuery loading and dbt transformation.

## Contents

| File / Folder | Purpose |
|---|---|
| `Dockerfile` | Custom Airflow image extending `apache/airflow:2.10.2` with additional providers and dependencies |
| `docker-compose.yaml` | Local Airflow environment (LocalExecutor + PostgreSQL metadata DB) |
| `requirements.txt` | Additional Python packages installed in the Airflow image |
| `dags/` | Five Airflow DAG files (see below) |
| `scripts/json_to_ndjson.py` | Converts GeoJSON feature collections to newline-delimited GeoJSON for BigQuery ingestion |

## DAG Reference

| File | DAG ID | Trigger | Purpose |
|---|---|---|---|
| `dag_01_traffic_data_to_gcs.py` | `chi_traffic_01_fetch_traffic_data_to_gcs` | Manual / scheduled | Fetch crash, vehicle, people CSV from Chicago SODA API → Parquet → GCS |
| `dag_02_geo_data_to_gcs.py` | `chi_traffic_02_fetch_geo_data_to_gcs` | Manual / scheduled | Fetch neighbourhood + ward GeoJSON from Chicago SODA API → GCS |
| `dag_03_traffic_gcs_to_bigquery.py` | `chi_traffic_03_load_traffic_gcs_to_bigquery` | Auto-triggered by DAG 01 | Load traffic Parquet from GCS → BigQuery; add `partition_date` column |
| `dag_04_geo_gcs_to_bigquery.py` | `chi_traffic_04_load_geo_gcs_to_bigquery` | Auto-triggered by DAG 02 | Download GeoJSON → convert to NDJSON → GCS → BigQuery |
| `dag_05_dbt_transformations.py` | `chi_traffic_05_run_dbt_transformations` | Auto-triggered by DAG 03 | Spin up dbt Docker container and run `dbt build` |

## DAG Chaining
DAGs are chained using `TriggerDagRunOperator`:
```
DAG 01 → triggers → DAG 03 → triggers → DAG 05
DAG 02 → triggers → DAG 04
```

## How to Run Locally
1. Update `docker-compose.yaml` — replace the volume mount path for GCP keys with your local path
2. Set environment variables (see root README Setup section)
3. `docker compose up -d`
4. Access UI at `http://localhost:8080`
5. Trigger DAG 01 and DAG 02 manually — the rest chain automatically

## Notes
- All DAGs use `schedule_interval=None` — they are triggered manually or by upstream DAGs, not on a fixed cron schedule in this local setup
- The GCS bucket name (`chi-traffic-de-bucket`) is a constant in each DAG — update it to match your own bucket name if different
- `dag_05_dbt_transformations.py` uses `DockerOperator` which requires the `socat` proxy container to be running (see `docker/socat.Dockerfile`) to bridge the Docker socket
