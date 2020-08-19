resource "random_password" "db_password" {
  length = 16
  special = true
  override_special = "_%@"
}

data "local_file" "install" {
    filename = "${path.module}/install.sh"
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
          google_oauth2_app_id = var.google_oauth2_app_id 
        }
    )

    startup = templatefile(
        "${path.module}/templates/startup.sh.tpl",
        {
            install = data.local_file.install.content
            docker_compose = local.docker_compose
        }
    )
}


