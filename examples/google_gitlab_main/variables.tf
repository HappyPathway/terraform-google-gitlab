variable project_id {
    default = "hf-tf-d-tech-dave-git-sandbox"
}

variable "domain" {
  type = string
  description = "Full host name where Gitlab will be deployed"
  default = "hawkfish.us"
}

variable compute_image {
  type = string
  default = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20200810"
}

variable dns_project {
  default = "hf-tf-p-platform-global-dns"
}
