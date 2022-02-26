data "google_project" "sandbox_project" {
  project_id = var.project_id
}

data "google_compute_default_service_account" "default" {
}

resource "random_string" "random" {
  length = 8
  special = false
  upper = false
  number = false
}


module "gitlab" {
  source           = "../../"
  project_id       = var.project_id
  instance_count = 1
  service_account = data.google_compute_default_service_account.default.email
  scopes = ["cloud-platform"]
  contact_email = "dave-cft@hawkfish.us"
  compute_image = var.compute_image
  dns_project = "hf-tf-p-platform-global-dns"
  dns_zone = "cirri"
  data_disk_size_gb = 500
}
          
