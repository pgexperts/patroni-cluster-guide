provider "aws" {
  region = "us-west-2"
}

variable "instance_type" {
  default = "t3.small"
}

variable "region" {
  default = "us-west-2"
}

variable "azs" {
  default = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "environment" {
  default = "staging"
}

variable "role" {
  default = "etcd3-test"
}

variable "etcd_mount_point" {
  default = "/var/lib/etcd"
}

# Flatcar Container Linux stable 3139.2.0 (HVM)
variable "ami" {
  default = "ami-04a03ab92f0f9fb0c"
}

variable "dns" {
  type = map(any)

  default = {
    domain_name = "pgx.internal"
  }
}

variable "cluster_size" {
  default = 5
}

variable "ebs_volume_size" {
  default = 20
}

variable "ntp_host" {
  default = "0.north-america.pool.ntp.org"
}

variable "vpc_id" {
  default = "vpc-00753c68"
}

variable "aws_sshkey_name" {
  default = "jeff"
}

variable "organization_name" {
  description = "The name of the organization to associate with the certificates (e.g. Acme Co)."
  type        = string
  default     = "PGX"
}

variable "validity_period_hours" {
  description = "The number of hours after initial issuing that the certificate will become invalid."
  type        = number
  default     = 43830
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL TLS PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "ca_allowed_uses" {
  description = "List of keywords from RFC5280 describing a use that is permitted for the CA certificate. For more info and the list of keywords, see https://www.terraform.io/docs/providers/tls/r/self_signed_cert.html#allowed_uses."
  type        = list(string)

  default = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
  ]
}

variable "allowed_uses" {
  description = "List of keywords from RFC5280 describing a use that is permitted for the issued certificate. For more info and the list of keywords, see https://www.terraform.io/docs/providers/tls/r/self_signed_cert.html#allowed_uses."
  type        = list(string)

  default = [
    "key_encipherment",
    "digital_signature",
  ]
}

variable "permissions" {
  description = "The Unix file permission to assign to the cert files (e.g. 0600)."
  type        = string
  default     = "0600"
}

variable "private_key_algorithm" {
  description = "The name of the algorithm to use for private keys. Must be one of: RSA or ECDSA."
  type        = string
  default     = "RSA"
}

variable "private_key_ecdsa_curve" {
  description = "The name of the elliptic curve to use. Should only be used if var.private_key_algorithm is ECDSA. Must be one of P224, P256, P384 or P521."
  type        = string
  default     = "P256"
}

variable "private_key_rsa_bits" {
  description = "The size of the generated RSA key in bits. Should only be used if var.private_key_algorithm is RSA."
  type        = string
  default     = "2048"
}

variable "etcd_cert_owner" {
  description = "The owner of the certificate files on the etcd hosts."
  type        = string
  default     = "etcd:etcd"
}

variable "ssl_cert_dir" {
  description = "The directory that Flatcar linux users for SSL certificates"
  type        = string
  default     = "/etc/ssl/certs"
}

variable "etcd_ca_cert_path" {
  description = "The location to place the CA cert on the etcd hosts."
  type        = string
  default     = "/etc/ssl/certs/etcd-ca-cert.pem"
}

variable "etcd_key_path" {
  description = "The location to place the CA cert on the etcd hosts."
  type        = string
  default     = "/etc/ssl/certs/etcd-key.pem"
}

variable "etcd_cert_path" {
  description = "The location to place the CA cert on the etcd hosts."
  type        = string
  default     = "/etc/ssl/certs/etcd-cert.pem"
}

variable "patroni_cert_owner" {
  description = "The owner of the certificate files on the patroni hosts."
  type        = string
  default     = "postgres:postgres"
}

variable "patroni_ca_cert_path" {
  description = "The location to place the CA cert on the patroni hosts."
  type        = string
  default     = "/etc/patroni/ca-cert.pem"
}

variable "patroni_key_path" {
  description = "The location to place the CA cert on the patroni hosts."
  type        = string
  default     = "/etc/patroni/key.pem"
}

variable "patroni_cert_path" {
  description = "The location to place the CA cert on the patroni hosts."
  type        = string
  default     = "/etc/patroni/cert.pem"
}

