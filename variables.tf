variable "project_id" {
  type = string
  description = "Project you want to create the Gitlab instance in"
  default = null
}

variable gitlab_version {
  default = "latest"
  type = string
  description = "Docker Image Tag for Gitlab Container"
}

variable "region" {
  type = string
  description = "GCP region for resources"
  default = "us-central1"
}

variable "zone" {
  type = string
  description = "GCP zone for resources"
  default = "us-central1-a"
}

variable "machine_type" {
  type = string
  default = "n2-standard-8"
  description = "Type of machine GCP should use for your Gitlab Compute Instance"
}

variable "db_machine_type" {
  type = string
  default = "db-f1-micro"
  description = "Type of machine Cloud SQL should use for your Gitlab database"
}

variable "domain" {
  type = string
  description = "Full host name where Gitlab will be deployed"
  default = "cirri.dev"
}

variable "instance_tags" {
  type = list
  description = "tags to instance with"
  default = ["gitlab-host"]
}

variable "allow_stopping" {
  type = bool
  description = "Allow stopping"
  default = true
}

variable "deletion_protection" {
  type = bool
  description = "Prevent Deletion"
  default = false
}

variable "preemptible" {
  type = bool
  description = "Preemptible Instance?"
  default = false
}

variable "automatic_restart" {
  type = bool
  description = "Automatic Restart?"
  default = true
}

variable "disk_size" {
  type = string
  default = 100
  description = "Size of BootDisk"
}

variable disk_image {
  default = "projects/hf-tf-p-platform-gitlab/global/images/git-datadisk"
}

variable "dns_domain" {
  type = string
  description = "DNS Domain Name"
  default = "cirri.dev"
}

variable "service_ports" {
  description = "Service Ports"
  type = list(object({
    name   = string
    port = number
  }))
  default = [
    {
      name = "http"
      port = 80
    },
    {
      name = "https"
      port = 443
    },
    {
      name = "ssh"
      port = 22
    }
  ]
}

variable instance_count {
  type = number
  default = 1
}

variable compute_image {
  type = string
  default = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20200810"
}

variable service_account {
  type = string
}

variable scopes {
  type = list
  default = [
    "https://www.googleapis.com/auth/sqlservice.admin",
    "https://www.googleapis.com/auth/devstorage.read_write"
  ]
}

variable contact_email {
  default = "grp-git-owners@hawkfish.us"
}

variable smtp_user_name {
  default = "apikey"
}

variable "smtp_password" {
  type = string
  default = "snip"
}

variable dns_project {}

variable dns_zone {}

variable custom_ruby_code {
  default = ""
}

variable data_disk_size_gb {
  default = 100
}
variable data_disk_type {
  default = "pd-ssd"
}

variable hostname {
  default = "git"
  type = string
}

variable enable_dns {
  default = true
  description = "Enable DNS. Default will be set to True once DNS project is setup"
}

variable gcp_secrets_project {
  default = null
  description = "GCP Project for Secrets Manager"
}

variable sendgrid_credentials_secret {
  default = "sendgrid_api_token"
}

variable google_oauth2_app_id {
  default = "google_oauth2_app_id"
}

variable google_oauth2_app_secret {
  default = "google_oauth2_app_secret"
}
