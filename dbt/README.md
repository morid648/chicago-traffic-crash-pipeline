# `dbt/`

## Purpose
dbt transformation project that models raw BigQuery data through three layers — Staging → Refined → Mart — producing a star schema for Tableau consumption.

## Project: `chi_traffic_crash`

### Layer Overview

```
raw_data (BigQuery)
      ↓
Staging (views)
      ↓
Refined (incremental — latest partition only)
      ↓
Mart (views — star schema)
      ↓
Tableau
```

### Models

#### Staging (`models/staging/`) — Views on raw BigQuery tables
| Model | Source table | Purpose |
|---|---|---|
| `staging_crash` | `raw_data.crash` | Type-cast and rename crash fields |
| `staging_people` | `raw_data.people` | Type-cast and rename people fields |
| `staging_vehicle` | `raw_data.vehicle` | Type-cast and rename vehicle fields |
| `staging_neighborhood` | `raw_data.neighborhood` | Flatten neighborhood GeoJSON properties |
| `staging_ward` | `raw_data.ward` | Flatten ward GeoJSON properties |

#### Refined (`models/refined/`) — Incremental models, latest partition only
| Model | Purpose |
|---|---|
| `refined_fact_crash` | Cleaned crash records with boolean conversions and null handling |
| `refined_fact_people` | Cleaned people records |
| `refined_fact_vehicle` | Cleaned vehicle records |
| `refined_dim_datetime` | Date/time attributes extracted from crash timestamp |
| `refined_dim_location` | Location fields from crash data |
| `refined_dim_location_enriched` | Location joined with neighborhood and ward geospatial data |
| `refined_neighborhood` | Cleaned neighborhood boundaries |
| `refined_ward` | Cleaned ward boundaries |

#### Mart (`models/mart/`) — Views (star schema)
| Model | Grain | Purpose |
|---|---|---|
| `fact_crash` | One row per crash (`crash_record_id`) | Core crash metrics |
| `fact_people` | One row per person (`person_id`) | People involved in crashes |
| `fact_vehicle` | One row per vehicle (`crash_unit_id`) | Vehicles involved in crashes |
| `dim_datetime` | One row per crash timestamp | Date/time dimension |
| `dim_location` | One row per crash location | Location dimension with geo enrichment |

### Macros (`macros/`)
| Macro | Purpose |
|---|---|
| `convert_to_boolean` | Converts `Y`/`N` string values to SQL boolean |
| `string_empty_to_null` | Converts empty string `''` to `NULL` |

### Tests
- **Source tests** (`models/sources.yaml`): `not_null`, `unique`, `unique_id_partition`, referential integrity between crash/people/vehicle
- **Custom test** (`tests/generic/unique_id_partition.sql`): Validates uniqueness within a partition date — used because the functional snapshot approach means the same ID can appear in multiple partitions (different run dates), so standard `unique` would fail

### How to Run

```bash
cd dbt/chi_traffic_crash
dbt run           # Run all models
dbt test          # Run all tests
dbt build         # Run + test in one command
dbt run --select staging    # Run only staging layer
dbt run --select mart       # Run only mart layer
```

Requires a `profiles.yml` configured with your BigQuery project credentials.
