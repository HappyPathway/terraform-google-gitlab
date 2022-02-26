data "google_netblock_ip_ranges" "health_checker_netblock_ranges" {
  range_type = "health-checkers"
}

data "google_netblock_ip_ranges" "iap_forwarder_netblock_ranges" {
  range_type = "iap-forwarders"
}


### General Networking and Firewalls ###
resource "google_compute_network" "gitlab" {
  name                    = "net-git-${var.hostname}"
  project                 = var.project_id
  auto_create_subnetworks = false
}


resource "google_compute_subnetwork" "gitlab-default" {
  provider = google-beta
  name          = "${var.hostname}-default"
  project                 = var.project_id
  ip_cidr_range = "10.1.2.0/24"
  region        = var.region
  network       = google_compute_network.gitlab.id
}

// Forwarding rule for Internal Load Balancing
resource "google_compute_global_forwarding_rule" "default" {
  provider = google-beta
  project                 = var.project_id
  name   = var.hostname
  ip_protocol           = "TCP"
  port_range            = "443"
  target                = google_compute_target_https_proxy.gitlab.id
}

resource "google_compute_router" "router" {
  name    = var.hostname
  project                 = var.project_id
  region  = google_compute_subnetwork.gitlab-default.region
  network = google_compute_network.gitlab.id
}

resource "google_compute_router_nat" "nat" {
  project                 = var.project_id
  name                               = var.hostname
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}


resource "google_compute_firewall" "allow_glb_healthcheckers" {
  project = var.project_id
  name    = "allow-glb-${var.hostname}"
  network = google_compute_network.gitlab.name

  allow {
    protocol = "icmp"
  }
  
  allow {
    protocol = "tcp"
    ports = [443]
  }

  source_ranges = data.google_netblock_ip_ranges.health_checker_netblock_ranges.cidr_blocks_ipv4
  target_tags = ["gitlab-host"]
}

resource "google_compute_firewall" "allow_tcp_iap_ssh" {
  project = var.project_id
  name    = "allow-iap-forwarded-ssh-${var.hostname}"
  description = "Allows IAP TCP forwarding to connect to ssh for git clones and ssh-alt for administration"
  network = google_compute_network.gitlab.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports = [22, 2222]
  }

  source_ranges = concat(["130.211.0.0/22", "35.191.0.0/16"], data.google_netblock_ip_ranges.iap_forwarder_netblock_ranges.cidr_blocks_ipv4)
  target_tags = ["gitlab-host"]
}

resource "google_compute_firewall" "allow_ingress_from_iap" {
  project = var.project_id
  name    = "allow-ingress-from-iap-${var.hostname}"
  description = "Allows IAP TCP forwarding to connect to ssh for git clones and ssh-alt for administration"
  network = google_compute_network.gitlab.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports = [22, 3389, 80, 443]
  }

  source_ranges = concat(["35.235.240.0/20"], data.google_netblock_ip_ranges.iap_forwarder_netblock_ranges.cidr_blocks_ipv4)
  target_tags = ["gitlab-host"]
}


### Load Balancer Setup ###
resource "google_compute_health_check" "gitlab" {
  project = var.project_id
  # region = "us-central1"
  name   = "http-health-check-${var.hostname}"
  https_health_check {
    port = 443
    request_path = "/-/readiness"
  }
}

resource "google_compute_backend_service" "gitlab" {
  project = var.project_id
  #region      = var.region
  name        = "backend-${var.hostname}"
  protocol    = "HTTPS"
  timeout_sec = 10
  port_name = "https"
  
  backend {
    group = google_compute_instance_group.service_group.self_link
    balancing_mode = "UTILIZATION"
  }

  iap {
    oauth2_client_id = google_iap_client.project_client.client_id
    oauth2_client_secret = google_iap_client.project_client.secret
  }

  health_checks = [google_compute_health_check.gitlab.id]
}

resource "google_compute_url_map" "gitlab" {
  # region      = var.region
  name        = "${var.hostname}-map"
  project    = var.project_id
  default_service = google_compute_backend_service.gitlab.id
}

resource "google_compute_managed_ssl_certificate" "gitlab" {
  provider = google-beta
  project    = var.project_id

  name = var.hostname

  managed {
    domains = ["${var.hostname}.${var.dns_domain}."]
  }
}


resource "google_compute_target_https_proxy" "gitlab" {
  # region           = var.region
  project    = var.project_id
  name             = var.hostname
  url_map          = google_compute_url_map.gitlab.id
  ssl_certificates = [google_compute_managed_ssl_certificate.gitlab.id]
  depends_on = [
    google_compute_managed_ssl_certificate.gitlab
  ]
}

data "google_dns_managed_zone" "dns_zone" {
  name = var.dns_zone
  project = var.dns_project
}

resource google_dns_record_set dns {
  count = var.enable_dns ? var.instance_count : 0
  name    = "${var.hostname}.${var.dns_domain}."
  project = var.dns_project

  type = "A"
  ttl  = 300

  managed_zone = data.google_dns_managed_zone.dns_zone.name

  rrdatas = [ google_compute_global_forwarding_rule.default.ip_address ]
}
