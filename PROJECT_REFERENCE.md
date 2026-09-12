# Project Reference — Chicago Traffic Crash Analytics Pipeline

> Quick-reference sheet for resume bullet points, interview prep, and recruiter conversations.

**GitHub:** [github.com/morid648/chicago-traffic-crash-pipeline](https://github.com/morid648/chicago-traffic-crash-pipeline)
**Live Dashboard:** [Tableau Public](https://public.tableau.com/shared/5BNTZ4Q3G?:display_count=n&:origin=viz_share_link)

---

## One-Line Summary

Built an end-to-end data engineering pipeline processing 4.6M+ rows of Chicago traffic crash and geospatial data — orchestrated with Apache Airflow (five chained DAGs), landed in GCS as Parquet, modelled in BigQuery using a three-layer dbt star schema (Staging → Refined → Mart), with infrastructure provisioned via Terraform and insights delivered through a Tableau dashboard.

---

## Resume Bullet Points

Pick 3–4 based on the role.

- Engineered a **weekly batch pipeline** on GCP ingesting 4.6M+ rows of Chicago traffic crash data from the SODA API, processing it through **Apache Airflow** (5 chained DAGs), **Google Cloud Storage**, and **BigQuery** using a functional snapshot approach with `partition_date` time-partitioning
- Designed a **three-layer dbt transformation model** (Staging → Refined → Mart) in BigQuery implementing a star schema — `fact_crash`, `fact_people`, `fact_vehicle`, `dim_datetime`, `dim_location` — with data validation tests including a custom `unique_id_partition` test for partition-aware uniqueness
- Implemented **Functional Data Engineering** principles: full data snapshot per pipeline run stored in GCS as Parquet; BigQuery retains all historical partitions; dbt always selects the latest partition for downstream models — enabling auditability, backfills, and rollback
- Built a **geospatial data pipeline** ingesting Chicago neighbourhood and ward GeoJSON boundaries, converting to newline-delimited GeoJSON using a custom Python utility, loading to BigQuery with GEOGRAPHY columns, and joining to crash location data in dbt for spatial analytics
- Provisioned all **GCP infrastructure with Terraform**: GCS bucket, BigQuery dataset, Cloud Composer environment, Airflow service account, and Tableau service account with scoped BigQuery read permissions
- Containerised **dbt execution with Docker** — `DockerOperator` in DAG 05 spins up a dbt container via a socat proxy, enabling Docker-from-Docker within the Airflow container network
- Delivered a **Tableau dashboard** connected to BigQuery mart tables via service account, visualising crash trends, severity distribution, contributing causes, and geographic density by neighbourhood and ward

---

## Technology Stack

| Category | Technologies |
|---|---|
| Orchestration | Apache Airflow 2.10 |
| Language | Python |
| Data Source | Chicago Data Portal SODA API |
| Cloud Storage | Google Cloud Storage (Parquet, GeoJSONL) |
| Data Warehouse | BigQuery |
| Transformation | dbt-bigquery |
| Data Modeling | Star Schema, Incremental Models |
| Infrastructure | Terraform, GCP |
| Containerisation | Docker, DockerOperator |
| Visualisation | Tableau |
| Geospatial | GeoJSON, NDJSON, BigQuery GEOGRAPHY |

---

## Architecture at a Glance

```
Chicago Data Portal SODA API
        │ requests (Python)
        ▼
    ┌──────────────────────────────────┐
    │ DAG 01: Traffic → GCS (Parquet)  │
    │ DAG 02: Geo → GCS (GeoJSON)      │
    └───────────┬──────────────────────┘
                │ TriggerDagRunOperator
                ▼
    ┌──────────────────────────────────┐
    │ DAG 03: GCS → BigQuery (traffic) │
    │ DAG 04: GCS → BigQuery (geo)     │
    └───────────┬──────────────────────┘
                │ TriggerDagRunOperator
                ▼
    ┌──────────────────────────────────┐
    │ DAG 05: dbt (Docker container)   │
    │  Staging → Refined → Mart        │
    └───────────┬──────────────────────┘
                │
                ▼
        Tableau Dashboard
```

---

## Key Design Decisions — Interview Talking Points

### Why Functional Data Engineering / snapshots instead of upserts?
Every pipeline run stores a complete snapshot of the source data in GCS and appends it to BigQuery with a `partition_date` column. This means: if the source data is corrected, the old version is still in BigQuery (auditability). If a dbt run fails, you can re-run it against the already-landed snapshot without re-calling the API. If you need to backfill 3 months of history, all the snapshots are already there. Upserts would destroy that history.

### Why dbt's incremental model for Refined instead of a full refresh?
The Refined layer uses incremental materialisation selecting only the latest `partition_date` — so each dbt run only processes the newest snapshot, not all 4.6M rows from every previous run. This keeps transformation time proportional to new data volume, not total historical volume.

### Why run dbt inside a Docker container via DockerOperator?
It isolates dbt's Python environment completely from Airflow's — no dependency conflicts. The dbt project, dbt profiles, and GCP credentials are each mounted as separate Docker volumes, so the container is stateless and the same image can be used in both local dev and Cloud Composer without modification.

### Why a custom `unique_id_partition` test instead of dbt's standard `unique`?
The snapshot approach means `crash_record_id = "ABC123"` legitimately appears in multiple partitions (Monday's snapshot, Tuesday's snapshot, etc.). dbt's standard `unique` test would flag this as a failure even though the data is correct. The custom test enforces uniqueness only **within** a given `partition_date`, which is the right invariant for this schema.

### Why Terraform for infrastructure instead of manual GCP console setup?
Reproducibility. The entire environment — bucket, dataset, Composer, service accounts, IAM roles — can be torn down and rebuilt with `terraform apply`. This also means the infrastructure is version-controlled alongside the pipeline code, so changes to permissions or resource config are tracked in git.

---

## DAG Reference

| File | DAG ID | What it does |
|---|---|---|
| `dag_01_traffic_data_to_gcs.py` | `chi_traffic_01_fetch_traffic_data_to_gcs` | Fetch crash/vehicle/people CSV from SODA API → Parquet → GCS |
| `dag_02_geo_data_to_gcs.py` | `chi_traffic_02_fetch_geo_data_to_gcs` | Fetch neighbourhood/ward GeoJSON → GCS |
| `dag_03_traffic_gcs_to_bigquery.py` | `chi_traffic_03_load_traffic_gcs_to_bigquery` | Load Parquet → BigQuery; add + populate partition_date |
| `dag_04_geo_gcs_to_bigquery.py` | `chi_traffic_04_load_geo_gcs_to_bigquery` | GeoJSON → NDJSON → GCS → BigQuery GEOGRAPHY |
| `dag_05_dbt_transformations.py` | `chi_traffic_05_run_dbt_transformations` | Run dbt build via Docker container |

## dbt Model Reference

| Layer | Model | Materialization | Key transformation |
|---|---|---|---|
| Staging | `staging_crash` | View | Type-cast, rename fields |
| Staging | `staging_people` | View | Type-cast, rename fields |
| Staging | `staging_vehicle` | View | Type-cast, rename fields |
| Staging | `staging_neighborhood` | View | Flatten GeoJSON properties |
| Staging | `staging_ward` | View | Flatten GeoJSON properties |
| Refined | `refined_fact_crash` | Incremental | Boolean conversion, null handling, latest partition |
| Refined | `refined_fact_people` | Incremental | Boolean conversion, null handling |
| Refined | `refined_fact_vehicle` | Incremental | Type cleanup |
| Refined | `refined_dim_datetime` | Incremental | Extract year, month, day, hour, day_of_week |
| Refined | `refined_dim_location` | Incremental | Location fields from crash |
| Refined | `refined_dim_location_enriched` | Incremental | Spatial join with neighbourhood + ward |
| Refined | `refined_neighborhood` | Incremental | Cleaned geo boundaries |
| Refined | `refined_ward` | Incremental | Cleaned geo boundaries |
| Mart | `fact_crash` | View | Final crash fact |
| Mart | `fact_people` | View | Final people fact |
| Mart | `fact_vehicle` | View | Final vehicle fact |
| Mart | `dim_datetime` | View | Date/time dimension |
| Mart | `dim_location` | View | Location dimension with geo enrichment |

---

## Suggested Interview Answers

**"Walk me through this project."**
> "It's a weekly batch pipeline for Chicago's traffic crash data. Airflow orchestrates five chained DAGs — the first two fetch crash records and geospatial boundary data from Chicago's SODA API, convert them to Parquet or NDJSON, and land them in Google Cloud Storage. The next two DAGs load that data into BigQuery, adding a partition date column to every row so we preserve a full snapshot of each run. Then a fifth DAG triggers dbt, which runs inside a Docker container and transforms the raw data through three layers — Staging views, Refined incremental models that clean and type-cast the data, and Mart views that expose a star schema to Tableau."

**"What is Functional Data Engineering and why did you use it here?"**
> "It's a philosophy where you treat every pipeline run as producing a complete, immutable snapshot of the source data — like a function that takes today's API response and produces today's dataset. So every run appends a new partition to BigQuery rather than overwriting. The payoff is: old partitions are always there for auditability, dbt always has a clean re-runnable snapshot to work with, and backfills are just selecting an earlier partition. The cost is storage — you're keeping every historical state. For a public dataset like Chicago crash records that's trivial."

**"How does dbt handle the snapshot data in BigQuery?"**
> "The Refined layer uses incremental materialisation where the model filters to only the latest partition_date. So each dbt run processes only the newest snapshot — the query reads maybe 300K rows for today's run, not 4.6M total rows for all history. The Mart layer is views on top of Refined, so they always show the most current data automatically."

**"What was the geospatial challenge and how did you solve it?"**
> "The Chicago API returns neighbourhood and ward boundaries as GeoJSON feature collections, but BigQuery's native format for loading JSON with geography is newline-delimited GeoJSON — one JSON object per line. I wrote a Python utility that reads the feature collection, iterates over features, serialises each geometry as a string, and writes one line per feature. That file gets uploaded to GCS and loaded to BigQuery with GEOGRAPHY schema. In dbt, I then do a spatial join between crash coordinates and the ward/neighbourhood polygons using BigQuery's `ST_WITHIN` function."

---

## Known Limitations

- No incremental API ingestion — the pipeline fetches all records up to the configured row limit on every run (functional approach by design, but expensive for very large tables)
- No data quality monitoring beyond dbt tests — no alerting if source data volume drops significantly
- Cloud Composer is expensive for a weekly pipeline — more cost-efficient alternatives: Cloud Run + Cloud Scheduler, or managed Airflow on a smaller instance
