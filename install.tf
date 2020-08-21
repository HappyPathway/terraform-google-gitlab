resource "random_password" "admin_password" {
  length = 16
}

locals {
    host_name = "gitlab-${var.env}.${var.dns_domain}"

    docker_compose = templatefile(
        "${path.module}/templates/docker-compose.yaml.tpl", 
        { 
          host_name = local.host_name,
          contact_email = var.contact_email,
          db_username = google_sql_user.root_user.name,
          db_password = random_password.root_password.result,
          smtp_user_name = var.smtp_user_name,
          smtp_password = var.smtp_password,
          google_oauth2_app_id = var.google_oauth2_app_id,
          google_oauth2_app_secret = var.google_oauth2_app_secret,
          custom_ruby_code = var.custom_ruby_code
        }
    )

    startup = templatefile(
        "${path.module}/templates/startup.sh.tpl",
        {
            password = random_password.admin_password.result
            docker_compose = local.docker_compose
        }
    )
}


