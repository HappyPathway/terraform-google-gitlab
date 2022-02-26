#3.36.0
locals {
  gcp_project = var.project_id
}

data "google_project" "project" {
  project_id = local.gcp_project 
}

resource google_compute_instance service_instances {
  name  = "${var.hostname}${format("%02d", count.index + 1)}"
  project = local.gcp_project
  count = var.instance_count
  zone  = var.zone

  depends_on = [
    google_sql_database_instance.gitlab,
    google_sql_database.gitlab
  ]

  machine_type              = var.machine_type
  tags                      = var.instance_tags
  allow_stopping_for_update = var.allow_stopping
  deletion_protection       = var.deletion_protection

  scheduling {
    preemptible         = var.preemptible
    on_host_maintenance = "MIGRATE"
    automatic_restart   = var.automatic_restart
  }

  # Required for service_instances_data_disk to work w/o oscillating
  lifecycle {
    ignore_changes = [
      attached_disk,
      network_interface[0].alias_ip_range,
      network_interface[0].network_ip,
      metadata
    ]
  }

  boot_disk {
    auto_delete = true

    initialize_params {
      size  = var.disk_size
      type  = "pd-ssd"
      image = var.compute_image
    }
  }

  network_interface {
    network = google_compute_network.gitlab.id
    subnetwork = google_compute_subnetwork.gitlab-default.id
    /*
    access_config {
      nat_ip = google_compute_address.address.address
    }
    */
  }

  service_account {
    email  = var.service_account
    scopes = var.scopes
  }

  metadata_startup_script = local.startup
  metadata = {
    fqdn               = "${var.hostname}.${var.dns_domain}"
    serial-port-enable = "true"
  }
}

resource "google_compute_resource_policy" "git-backup" {
  project = local.gcp_project
  name  = "data-disk-git-${var.hostname}"
  provider = google-beta
  region = var.region
  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time = "04:00"
      }
    }
    retention_policy {
      max_retention_days = 14
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
  }
} 

# Attach Disk to Service Instances if needed 
resource google_compute_disk service_instances_data_disk {
  name  = "${var.hostname}${format("%02d", count.index + 1)}-data-disk"
  count = var.instance_count
  project = local.gcp_project
  resource_policies = ["${google_compute_resource_policy.git-backup.self_link}"]
  provider = google-beta

  size  = var.data_disk_size_gb
  image = var.disk_image
  type  = var.data_disk_type
  zone  = var.zone

  # Data disk image changes should only apply to *new* data disks
  lifecycle {
    ignore_changes = [image]
  }
}

resource google_compute_attached_disk service_instances_data_disk {
  project = local.gcp_project
  device_name = "gce-data-disk"
  count = var.instance_count

  disk     = google_compute_disk.service_instances_data_disk[count.index].self_link
  instance = google_compute_instance.service_instances[count.index].self_link
  mode     = "READ_WRITE"
}

resource google_compute_instance_group service_group {
  project = local.gcp_project
  name        = var.hostname
  description = "Service instance group for ${var.hostname}"
  zone        = var.zone
  depends_on = [
   google_compute_instance.service_instances 
  ]
  instances = google_compute_instance.service_instances.*.self_link

  dynamic named_port {
    for_each = var.service_ports
    content {
      name = named_port.value.name
      port = named_port.value.port
    }
  }
}

