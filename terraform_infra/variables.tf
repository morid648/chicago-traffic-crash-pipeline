
variable "credentials" {
  description = "GCP credentials"
  default     = "/path/to/your/gcp/credentials.json"
}

variable "project_name" {
  description = "Project name"
  default     = "<your-gcp-project-id>"
}

variable "project_number" {
  description = "Project number"
  default     = <your-gcp-project-number>
}
variable "gcs_bucket_location" {
  description = "Project location"
  default     = "US"
}

variable "bq_dataset_name" {
  description = "BigQuery datset name for chicago traffic crash data"
  default     = "chi_traffic_dataset"
}

variable "gcs_bucket_name" {
  description = "GCS bucket name for chicago traffic data"
  default     = "chi-traffic-de-bucket"
}

variable "tableau_bq_roles" {
    description = "List of roles to assign to tableau service account"
    type = list(string)
    default = [
        "roles/bigquery.dataViewer",
        "roles/bigquery.metadataViewer",
        "roles/bigquery.jobUser" ]
}
