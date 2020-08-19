variable project_id {
    default = "hf-tf-d-tech-dave-sandbox"
}

variable "domain" {
  type = string
  description = "Full host name where Gitlab will be deployed"
  default = "hawkfish.us"
}

variable "random" {}

variable compute_image {
  type = string
  default = "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-1804-bionic-v20200806"
}

variable smtp_password {}

variable smtp_user_name {}