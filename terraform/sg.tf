resource "aws_security_group" "default" {
  name        = "${var.role}.${var.region}.i.${var.environment}.${var.dns["domain_name"]}"
  description = "ASG-${var.role}"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name        = "${var.role}.${var.region}.i.${var.environment}.${var.dns["domain_name"]}"
    role        = "${var.role}"
    environment = "${var.environment}"
  }

  # etcd peer + client traffic within the etcd nodes themselves
  ingress {
    from_port = 2379
    to_port   = 2380
    protocol  = "tcp"
    self      = true
  }

  # etcd client traffic from the VPC
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.default.cidr_block}"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
