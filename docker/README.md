# `docker/`

## Purpose
Docker images for the dbt transformation container and the Docker socket proxy, both used by Airflow's `DockerOperator` in DAG 05.

## Contents

| File | Purpose |
|---|---|
| `dbt.Dockerfile` | Builds the dbt image: installs `dbt-bigquery` and mounts the dbt project |
| `socat.Dockerfile` | Builds a lightweight `socat` proxy that exposes the Docker socket over TCP so Airflow's `DockerOperator` can spin up containers from inside its own container |

## How It Works

Airflow's `DockerOperator` needs to communicate with the Docker daemon. In a containerised Airflow environment, the Docker socket isn't directly accessible. The `socat` container bridges this:

```
Airflow container
  → DockerOperator → tcp://docker-proxy:2375
  → socat container → /var/run/docker.sock (host Docker daemon)
  → dbt container (spun up on demand, auto-removed after run)
```

## Build

```bash
# Build dbt image
docker build -f docker/dbt.Dockerfile -t dbt_docker .

# Build socat proxy image
docker build -f docker/socat.Dockerfile -t docker-proxy .
```

Both images are referenced in `airflow/docker-compose.yaml`.
