resource "aws_security_group" "default" {
  name        = "${var.role}.${var.region}.${var.environment}.${var.dns["domain_name"]}"
  description = "ASG-${var.role}"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name        = "${var.role}.${var.region}.${var.environment}.${var.dns["domain_name"]}"
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

resource "aws_security_group" "patroni" {
  name        = "pg-patroni-${var.role}.${var.region}.${var.environment}.${var.dns["domain_name"]}"
  description = "PostgreSQL and Patroni from VPC"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name        = "pg-patroni-${var.role}",
    service     = "postgresql",
    owner       = "${var.aws_sshkey_name}",
    role        = "${var.role}"
    environment = "${var.environment}"
  }

  # postgresql from this SG and from the VPC subnets for the NLB
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["${data.aws_vpc.default.cidr_block}"]
  }

  # patroni API from this SG and from the VPC subnets for the NLB
  ingress {
    from_port   = 8008
    to_port     = 8008
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["${data.aws_vpc.default.cidr_block}"]
  }

  # SSH from the world - WARNING: VERY BAD for non test infrastructure!!
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
