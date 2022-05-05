provider "aws" {
  region = "us-west-1"
}

variable "instance_type" {
  default = "t3.small"
}

variable "region" {
  default = "us-west-1"
}

variable "azs" {
  default = ["us-west-1a", "us-west-1b", "us-west-1c"]
}

variable "environment" {
  default = "staging"
}

variable "role" {
  default = "etcd3-test"
}

variable "ami" {
  default = "ami-a0ff1ed9"
}

variable "vpc_cidr" {
  default = "10.200.0.0/16"
}

variable "dns" {
  type = map(any)

  default = {
    domain_name = "example.com"
  }
}

variable "cluster_size" {
  default = 5
}

variable "ntp_host" {
  default = "0.north-america.pool.ntp.org"
}
