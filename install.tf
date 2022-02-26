resource "random_password" "admin_password" {
  length = 16
  special = false
  upper = false
  number = false
}

data "google_client_openid_userinfo" "me" {
}

locals {
    host_name = "${var.hostname}.${var.dns_domain}"

    docker_compose = templatefile(
        "${path.module}/templates/docker-compose.yaml", 
        { 
          host_name = local.host_name,
          contact_email = var.contact_email,
          gitlab_version = var.gitlab_version,
          db_username = google_sql_user.root_user.name,
          db_password = random_password.root_password.result,
          db_project = data.google_project.project.name,
          db_region = var.region
          db_instance = google_sql_database_instance.gitlab.name
          smtp_user_name = var.smtp_user_name,
          smtp_password = data.google_secret_manager_secret_version.sendgrid.secret_data,
          google_oauth2_app_id = data.google_secret_manager_secret_version.oauth2_app_id.secret_data,
          google_oauth2_app_secret = data.google_secret_manager_secret_version.oauth2_app_secret.secret_data,
          custom_ruby_code = var.custom_ruby_code

        }
    )

    sendgrid_test = templatefile(
        "${path.module}/templates/sendgrid.sh.tpl",
        {
          smtp_password = data.google_secret_manager_secret_version.sendgrid.secret_data,
          email = data.google_client_openid_userinfo.me.email
        }
    )

    startup = templatefile(
        "${path.module}/templates/startup.sh.tpl",
        {
            password = random_password.admin_password.result,
            docker_compose = local.docker_compose,
            sendgrid_test = local.sendgrid_test,
            hostname = local.host_name,
            ssl_key = tls_private_key.server.private_key_pem,
            ssl_cert = tls_self_signed_cert.server.cert_pem
        }
    )
}


