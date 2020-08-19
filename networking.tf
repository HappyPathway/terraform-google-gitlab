data "google_netblock_ip_ranges" "health_checker_netblock_ranges" {
  range_type = "health-checkers"
}

data "google_netblock_ip_ranges" "iap_forwarder_netblock_ranges" {
  range_type = "health-checkers"
}


### General Networking and Firewalls ###
resource "google_compute_network" "gitlab" {
  name                    = "net-gitlab-${var.env}"
  project                 = var.project_id
  auto_create_subnetworks = true
}


resource "google_compute_firewall" "allow_glb_healthcheckers" {
  project = var.project_id
  name    = "allow-glb-${var.env}"
  network = google_compute_network.gitlab.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports = [8443]
  }
  source_ranges = data.google_netblock_ip_ranges.health_checker_netblock_ranges.cidr_blocks_ipv4
}

resource "google_compute_firewall" "allow_tcp_iap_ssh" {
  project = var.project_id
  name    = "allow-iap-forwarded-ssh-${var.env}"
  description = "Allows IAP TCP forwarding to connect to ssh for git clones and ssh-alt for administration"
  network = google_compute_network.gitlab.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports = [22, 2222]
  }

  source_ranges = data.google_netblock_ip_ranges.iap_forwarder_netblock_ranges.cidr_blocks_ipv4
  target_tags = ["gitlab-host"]
}


### Load Balancer Setup ###
resource "google_compute_region_health_check" "gitlab" {
  region = "us-central1"
  name   = "http-health-check-${var.env}"
  https_health_check {
    port = 8443
    request_path = "/-/readiness"
  }
}

resource "google_compute_region_backend_service" "gitlab" {
  region      = var.region
  name        = "backend-gitlab-${var.env}"
  protocol    = "HTTPS"
  timeout_sec = 10
  
  backend {
    group = google_compute_instance_group.service_group.self_link
    balancing_mode = "UTILIZATION"
  }

  health_checks = [google_compute_region_health_check.gitlab.id]
}

resource "google_compute_region_url_map" "gitlab" {
  region      = var.region
  name        = "gitlab-map-${var.env}"

  default_service = google_compute_region_backend_service.gitlab.id

  host_rule {
    hosts        = [var.domain]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_region_backend_service.gitlab.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_region_backend_service.gitlab.id
    }
  }
}

resource "google_compute_managed_ssl_certificate" "gitlab" {
  provider = google-beta

  name = "gitlab-${var.env}"

  managed {
    domains = ["${var.domain}."]
  }
}

resource "google_compute_region_target_https_proxy" "gitlab" {
  region           = var.region
  name             = "gitlab-${var.env}"
  url_map          = google_compute_region_url_map.gitlab.id
  ssl_certificates = [google_compute_managed_ssl_certificate.gitlab.id]
  depends_on = [
    google_compute_managed_ssl_certificate.gitlab
  ]
}