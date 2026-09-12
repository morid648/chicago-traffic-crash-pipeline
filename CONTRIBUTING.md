# Contributing

## How to Contribute

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-change`
3. Make your changes
4. Run dbt tests: `dbt test` (requires BigQuery connection)
5. Commit with a descriptive message
6. Open a pull request

## Project-Specific Guidelines

- New dbt models go in the appropriate layer (`staging/`, `refined/`, `mart/`)
- All new staging and mart models need corresponding entries in `sources.yaml` or `mart.yaml`
- New dbt models that introduce a unique key should include a `unique_id_partition` test
- DAG files follow the naming convention: `dag_NN_description.py`
- DAG IDs follow the convention: `chi_traffic_NN_description`
- Never commit GCP credentials, service account keys, or `.env` files

## Reporting Issues

Open a GitHub issue with:
- Description of the issue
- Which DAG or dbt model is affected
- Relevant Airflow task logs or dbt error output
