variable "project_id" {
  type = string
  description = "Project you want to create the Gitlab instance in"
}

variable "region" {
  type = string
  description = "GCP region for resources"
  default = "us-central1"
}

variable "zone" {
  type = string
  description = "GCP zone for resources"
  default = null
}

variable "db_machine_type" {
  type = string
  default = "db-n1-standard-4"
  description = "Type of machine Cloud SQL should use for your Gitlab database"
}

variable "domain" {
  type = string
  description = "Full host name where Gitlab will be deployed"
}