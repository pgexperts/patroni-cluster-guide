locals {
  peer_name_list = [for num in range(var.cluster_size) : "0 0 2380 peer-${num}.${var.role}.${var.region}.${var.environment}.${var.dns["domain_name"]}"]
}

resource "aws_route53_zone" "default" {
  name = "${var.environment}.${var.dns["domain_name"]}"
  vpc {
    vpc_id = data.aws_vpc.default.id
  }
  tags = {
    role    = "${var.role}",
    project = "patroni",
    owner   = "${var.aws_sshkey_name}",
  }
}

resource "aws_route53_record" "default" {
  zone_id = aws_route53_zone.default.id
  name    = "_etcd-server._tcp.${var.role}.${var.region}.${var.environment}.${var.dns["domain_name"]}"
  type    = "SRV"
  ttl     = "1"
  records = local.peer_name_list
}
