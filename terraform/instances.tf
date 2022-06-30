data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "pg-patroni" {
  count             = 3
  ami               = data.aws_ami.ubuntu.id
  instance_type     = "t3.small"
  availability_zone = element(var.azs, count.index)
  key_name          = var.aws_sshkey_name

  vpc_security_group_ids = [
    aws_security_group.default.id,
    aws_security_group.pg-patroni.id
  ]

  user_data = <<-EOT
      #! /bin/bash
      sudo apt-get --assume-yes install curl ca-certificates gnupg
      curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null
      sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
      sudo apt-get --assume-yes update
      sudo apt-get --assume-yes install postgresql-14 patroni
      sudo pg_dropcluster --stop 14 main
      printf "etcd3:\n  hosts: ${var.role}-lb.${var.region}.${var.environment}.${var.dns["domain_name"]}:2379\n" | sudo tee /etc/patroni/dcs.yml
      sudo pg_createconfig_patroni --network=${data.aws_vpc.default.cidr_block} 14 main
      sed -i 's:#      - host    all             all             ${data.aws_vpc.default.cidr_block}               md5:      - host    all             all             ${data.aws_vpc.default.cidr_block}               md5:' /etc/patroni/14-main.yml
      sudo systemctl start patroni@14-main
    EOT

  tags = {
    Name    = "pg-patroni-${count.index + 1}",
    role    = "${var.role}",
    project = "patroni",
    service = "postgresql",
    owner   = "${var.aws_sshkey_name}",
  }

  depends_on = [
    aws_autoscaling_group.default, aws_lb.internal, aws_route53_record.internal
  ]
}

