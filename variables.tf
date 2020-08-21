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
  default = "us-central1-a"
}

variable "machine_type" {
  type = string
  default = "n1-standard-4"
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
  default = "hawkfish.us"
}

variable "instance_tags" {
  type = list
  description = "tags to instance with"
  default = []
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

variable "dns_domain" {
  type = string
  description = "DNS Domain Name"
  default = "hawkfish.us"
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

variable "env" {
  type = string
  description = "Name of Gitlab Environment"
}

variable instance_count {
  type = number
  default = 1
}

variable compute_image {
  type = string
}

variable service_account {
  type = string
}

variable scopes {
  type = list
}

variable "google_oauth2_app_id" {
  type = string
  default = "413349817129-gs8jrc3b2cf4jo5v8bbthsdnjbmg4542.apps.googleusercontent.com"
}

variable "google_oauth2_app_secret" {
  type = string
  default = "snip"
}

variable contact_email {}

variable smtp_user_name {}
variable smtp_password {}
          

variable dns_project {}

variable dns_zone {}

variable custom_ruby_code {
  default = ""
}

variable data_disk_image {}

variable data_disk_size_gb {
  default = 100
}
variable data_disk_type {
  default = "pd-ssd"
}

variable ssl_certificate {
  type = string
  description = "ID of SSL Certificate to use for HTTPS Proxy. Can be in the form of projects/{{project}}/global/sslCertificates/{{name}}"
}