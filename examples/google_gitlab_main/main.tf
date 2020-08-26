data "google_project" "sandbox_project" {
  project_id = var.project_id
}
data "google_compute_default_service_account" "default" {
}

module "gitlab" {
  source           = "../../"
  project_id       = var.project_id
  env = "sandbox-${var.random}"
  instance_count = 1
  service_account = data.google_compute_default_service_account.default.email
  scopes = ["cloud-platform"]
  contact_email = "dave-cft@hawkfish.us"
  smtp_user_name = var.smtp_user_name
  smtp_password = var.smtp_password
  compute_image = var.compute_image
  dns_project = var.project_id
  dns_zone = "hfenv.dev"
  data_disk_image = "projects/hf-tf-d-tech-dave-sandbox/global/images/gitlab-datadisk"
  data_disk_size_gb = 500
  ssl_certificate = "projects/hf-tf-d-tech-dave-sandbox/global/sslCertificates/dave-sandbox-test"
}
          