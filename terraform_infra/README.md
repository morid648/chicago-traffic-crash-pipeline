# `terraform_infra/`

## Purpose
Terraform configuration that provisions all required GCP infrastructure for the pipeline. Run once before the pipeline is executed for the first time.

## What Gets Provisioned

| Resource | Details |
|---|---|
| GCS Bucket | Data lake storage for Parquet and GeoJSONL files |
| BigQuery Dataset | `chi_traffic_dataset` — holds all raw and transformed tables |
| Cloud Composer Environment | Managed Apache Airflow on GCP (Composer 2.9.7, Airflow 2.9.3) |
| Composer Service Account | IAM service account with `composer.worker` role |
| Tableau Service Account | Read-only BigQuery access for Tableau dashboard connection |
| Tableau SA Key | JSON key written to `tableau/secrets/` for Tableau→BigQuery auth |

## Files

| File | Purpose |
|---|---|
| `main.tf` | Resource definitions for all GCP infrastructure |
| `variables.tf` | All configurable values — **update these before applying** |
| `.terraform.lock.hcl` | Provider version lock file |

## Before Applying

Open `variables.tf` and replace all placeholder values:

```hcl
variable "credentials" {
  default = "/path/to/your/gcp/credentials.json"   # ← your service account key path
}

variable "project_name" {
  default = "<your-gcp-project-id>"                 # ← your GCP project ID
}

variable "project_number" {
  default = "<your-gcp-project-number>"             # ← your GCP project number
}
```

## How to Apply

```bash
cd terraform_infra
terraform init
terraform plan    # Review what will be created
terraform apply   # Provision resources
```

## Notes
- Running `terraform destroy` will delete the GCS bucket and its contents (force_destroy = true)
- Cloud Composer environment provisioning can take 20–30 minutes
- The Tableau service account key is written to `tableau/secrets/tableau-sa-key.json` — this path is `.gitignore`d and must never be committed
