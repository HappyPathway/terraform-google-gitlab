

resource google_compute_instance service_instances {
  name  = "gitlab${format("%02d", count.index + 1)}-${var.env}"
  count = var.instance_count
  zone  = var.zone

  
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
    network = google_compute_network.gitlab.self_link

    access_config {
      // Ephemeral IP
    }
  }

  service_account {
    email  = var.service_account
    scopes = var.scopes
  }

  metadata = {
    fqdn               = "gitlab${format("%02d", count.index + 1)}.${var.dns_domain}"
    serial-port-enable = "true"
    startup_script = local.startup
  }
}

resource google_compute_instance_group service_group {
  name        = "gitlab-${var.env}"
  description = "Service instance group for gitlab-${var.env}"
  zone        = var.zone

  instances = google_compute_instance.service_instances.*.self_link

  dynamic named_port {
    for_each = var.service_ports
    content {
      name = named_port.value.name
      port = named_port.value.port
    }
  }
}
