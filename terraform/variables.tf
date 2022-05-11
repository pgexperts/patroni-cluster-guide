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
