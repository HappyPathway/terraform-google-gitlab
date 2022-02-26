# server tls certificate
resource "tls_private_key" "server" {
  algorithm   = "RSA"
  ecdsa_curve = "2048"
}

resource "tls_self_signed_cert" "server" {
  key_algorithm   = tls_private_key.server.algorithm
  private_key_pem = tls_private_key.server.private_key_pem

  subject {
    common_name         = local.host_name
    organization        = var.dns_domain
    organizational_unit = "${var.dns_domain} DevOps"
  }

  validity_period_hours = 17520
  early_renewal_hours   = 8760

  allowed_uses = ["server_auth"]

  dns_names = ["localhost"]
}
