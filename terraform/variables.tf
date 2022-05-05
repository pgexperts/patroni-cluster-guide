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

variable "ami" {
  default = "ami-a0ff1ed9ami-000077a6d32e18f38"
}

variable "dns" {
  type = map(any)

  default = {
    domain_name = "pgx-internal.local"
  }
}

variable "cluster_size" {
  default = 5
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
