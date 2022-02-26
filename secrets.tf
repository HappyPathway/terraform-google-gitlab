locals {
  gcp_secrets_project = var.gcp_secrets_project == null ? var.project_id : var.gcp_secrets_project 
}

data google_secret_manager_secret_version sendgrid {
  project = local.gcp_secrets_project
  secret = var.sendgrid_credentials_secret
}

data google_secret_manager_secret_version oauth2_app_id {
    project = local.gcp_secrets_project
    secret = var.google_oauth2_app_id
}

data google_secret_manager_secret_version oauth2_app_secret {
    project = local.gcp_secrets_project
    secret = var.google_oauth2_app_secret
}