resource "google_sql_database_instance" "gitlab" {
  name             = "gitlab-${var.env}"
  database_version = "POSTGRES_12"
  region           = var.region
  project          = var.project_id

  settings {
    tier              = var.db_machine_type
    disk_size         = 100
    disk_autoresize   = true
    availability_type = "REGIONAL"

    backup_configuration {
      enabled    = true
      start_time = "00:00"
    }

    maintenance_window {
      day          = 7 # Sunday
      hour         = 5
      update_track = "stable"
    }

    ip_configuration {
      ipv4_enabled = true
    }

    location_preference {
      zone = coalesce(var.zone, "${var.region}-a")
    }
  }
}

resource "google_sql_database" "gitlab" {
  name       = "gitlab"
  project    = var.project_id
  instance   = google_sql_database_instance.gitlab.name
  charset    = "UTF8"
  collation  = "en_US.UTF8"
  depends_on = [google_sql_database_instance.gitlab]
}

resource "random_password" "root_password" {
  length = 16
  keepers = {
    name = google_sql_database_instance.gitlab.name
  }
  depends_on  = [google_sql_database_instance.gitlab]
}

resource "google_sql_user" "root_user" {
  depends_on = [google_sql_database_instance.gitlab]

  project  = var.project_id
  instance = google_sql_database_instance.gitlab.name
  name     = "postgres"
  password = random_password.root_password.result
}