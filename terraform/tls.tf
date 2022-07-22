locals {
  ca_common_name = "ca.${var.role}.${var.region}.${var.environment}.${var.dns["domain_name"]}"
  etcd_name_list = [for num in range(var.cluster_size) : "peer-${num}.${var.role}.${var.region}.${var.environment}.${var.dns["domain_name"]}"]
}

# ---------------------------------------------------------------------------------------------------------------------
#  CREATE A CA CERTIFICATE
# ---------------------------------------------------------------------------------------------------------------------

resource "tls_private_key" "ca" {
  algorithm   = var.private_key_algorithm
  ecdsa_curve = var.private_key_ecdsa_curve
  rsa_bits    = var.private_key_rsa_bits
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem   = tls_private_key.ca.private_key_pem
  is_ca_certificate = true

  validity_period_hours = var.validity_period_hours
  allowed_uses          = var.ca_allowed_uses

  subject {
    common_name  = local.ca_common_name
    organization = var.organization_name
  }

}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE TLS CERTIFICATES SIGNED USING THE CA CERTIFICATE
# ---------------------------------------------------------------------------------------------------------------------

resource "tls_private_key" "etcd" {
  algorithm   = var.private_key_algorithm
  ecdsa_curve = var.private_key_ecdsa_curve
  rsa_bits    = var.private_key_rsa_bits

}

resource "tls_cert_request" "etcd" {
  private_key_pem = tls_private_key.etcd.private_key_pem

  dns_names    = concat(local.etcd_name_list, [aws_route53_record.etcd-lb.name])
  ip_addresses = ["127.0.0.1"]

  subject {
    common_name  = aws_route53_record.etcd-lb.name
    organization = var.organization_name
  }
}

resource "tls_locally_signed_cert" "etcd" {
  cert_request_pem = tls_cert_request.etcd.cert_request_pem

  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = var.validity_period_hours
  allowed_uses          = var.allowed_uses

}


resource "tls_private_key" "pg-patroni" {
  algorithm   = var.private_key_algorithm
  ecdsa_curve = var.private_key_ecdsa_curve
  rsa_bits    = var.private_key_rsa_bits

}

resource "tls_cert_request" "pg-patroni" {
  private_key_pem = tls_private_key.pg-patroni.private_key_pem

  dns_names = ["pg-patroni.${var.region}.${var.environment}.${var.dns["domain_name"]}"]

  subject {
    common_name  = "pg-patroni.${var.region}.${var.environment}.${var.dns["domain_name"]}"
    organization = var.organization_name
  }
}

resource "tls_locally_signed_cert" "pg-patroni" {
  cert_request_pem = tls_cert_request.pg-patroni.cert_request_pem

  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = var.validity_period_hours
  allowed_uses          = var.allowed_uses

}

