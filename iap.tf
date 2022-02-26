data google_client_openid_userinfo provisioner {}

resource "random_string" "random" {
  length = 4
  special = false
}

resource "google_iap_brand" "project_brand" {
  project = local.gcp_project
  support_email     = data.google_client_openid_userinfo.provisioner.email
  application_title = "${var.hostname}-${random_string.random.result}"
  # project           = data.google_project.project.id
}

resource "google_iap_client" "project_client" {
  display_name = "IAP Client"
  brand        = google_iap_brand.project_brand.name
}
