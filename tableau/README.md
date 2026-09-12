# `tableau/`

## Purpose
Tableau workbook that connects to the BigQuery mart layer and visualises crash trends, severity, and geographic distribution across Chicago.

## Contents

| File | Purpose |
|---|---|
| `workbooks/chi_crash_insights.twb` | Tableau workbook file — connects to BigQuery mart tables |

## Live Dashboard

[View on Tableau Public →](https://public.tableau.com/shared/5BNTZ4Q3G?:display_count=n&:origin=viz_share_link)

## How to Open Locally

1. Open Tableau Desktop
2. Open `workbooks/chi_crash_insights.twb`
3. When prompted for a connection, provide your BigQuery credentials
4. The workbook connects to the `mart` schema tables: `fact_crash`, `fact_people`, `fact_vehicle`, `dim_datetime`, `dim_location`

## Authentication

The Tableau service account is provisioned by Terraform (`terraform_infra/main.tf`) with `bigquery.dataViewer`, `bigquery.metadataViewer`, and `bigquery.jobUser` roles. The key is written to `tableau/secrets/tableau-sa-key.json` — this folder is `.gitignore`d.

## Notes
- The `.twb` file is XML-based and can be opened in a text editor to inspect the calculated fields and data source configuration
- Refreshing the workbook after a new pipeline run will reflect the latest snapshot data from the mart layer
