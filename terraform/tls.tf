resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "registration" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = "jeff.frost@pgexperts.com"
}

resource "acme_certificate" "certificate" {
  account_key_pem           = acme_registration.registration.account_key_pem
  common_name               = aws_route53_zone.default.name
  subject_alternative_names = ["*.${var.role}.${var.region}.${var.environment}.${var.dns["domain_name"]}"]

  dns_challenge {
    provider = "route53"

    config = {
      AWS_HOSTED_ZONE_ID = aws_route53_zone.default.zone_id
    }
  }

  depends_on = [acme_registration.registration]
}

resource "aws_s3_object" "certificate_artifacts_s3_objects" {
  for_each = toset(["certificate_pem", "issuer_pem", "private_key_pem"])

  bucket  = aws_s3_bucket.files.id
  key     = "tls-certs/${each.key}"
  content = lookup(acme_certificate.certificate, "${each.key}")
}
