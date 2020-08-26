data "google_netblock_ip_ranges" "health_checker_netblock_ranges" {
  range_type = "health-checkers"
}

data "google_netblock_ip_ranges" "iap_forwarder_netblock_ranges" {
  range_type = "health-checkers"
}


### General Networking and Firewalls ###
resource "google_compute_network" "gitlab" {
  name                    = "net-git-${var.env}"
  project                 = var.project_id
  auto_create_subnetworks = true
}


resource "google_compute_subnetwork" "gitlab-default" {
  provider = google-beta
  name          = "${var.hostname}-${var.env}-default"
  ip_cidr_range = "10.1.2.0/24"
  region        = var.region
  network       = google_compute_network.gitlab.id
}

resource "google_compute_subnetwork" "gitlab-proxy" {
  provider = google-beta
  name          = "${var.hostname}-${var.env}"
  ip_cidr_range = "10.127.0.0/26"
  region        = var.region
  network       = google_compute_network.gitlab.id
  purpose       = "INTERNAL_HTTPS_LOAD_BALANCER"
  role          = "ACTIVE"
}

// Forwarding rule for Internal Load Balancing
resource "google_compute_global_forwarding_rule" "default" {
  provider = google-beta
  depends_on = [google_compute_subnetwork.gitlab-proxy]
  name   = "git-${var.env}"
  # region = var.region

  ip_protocol           = "TCP"
  # load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.gitlab.id
  # network               = google_compute_network.gitlab.id
  # subnetwork            = google_compute_subnetwork.gitlab-default.id
  # network_tier          = "PREMIUM"
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
resource "google_compute_health_check" "gitlab" {
  # region = "us-central1"
  name   = "http-health-check-${var.env}"
  https_health_check {
    port = 8443
    request_path = "/-/readiness"
  }
}

resource "google_compute_backend_service" "gitlab" {
  #region      = var.region
  name        = "backend-${var.hostname}-${var.env}"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = google_compute_instance_group.service_group.self_link
    balancing_mode = "UTILIZATION"
  }

  health_checks = [google_compute_health_check.gitlab.id]
}

resource "google_compute_url_map" "gitlab" {
  # region      = var.region
  name        = "${var.hostname}-map-${var.env}"

  default_service = google_compute_backend_service.gitlab.id

  host_rule {
    hosts        = [var.domain]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.gitlab.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.gitlab.id
    }
  }
}

resource "google_compute_managed_ssl_certificate" "gitlab" {
  provider = google-beta

  name = "${var.hostname}-${var.env}"

  managed {
    domains = ["${var.hostname}-${var.env}.${var.dns_domain}."]
  }
}


resource "google_compute_target_https_proxy" "gitlab" {
  # region           = var.region
  name             = var.hostname
  url_map          = google_compute_url_map.gitlab.id
  ssl_certificates = [google_compute_managed_ssl_certificate.gitlab.id]
  depends_on = [
    google_compute_managed_ssl_certificate.gitlab
  ]
}


resource google_dns_record_set dns {
  count = var.enable_dns ? var.instance_count : 0
  name    = "${var.hostname}-${var.env}.${var.dns_domain}"
  project = var.dns_project

  type = "A"
  ttl  = 300

  managed_zone = var.dns_zone

  rrdatas = [ google_compute_global_forwarding_rule.default.ip_address ]
}