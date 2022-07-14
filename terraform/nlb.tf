resource "aws_lb" "internal" {
  name               = "${var.role}-internal-${var.environment}"
  subnets            = data.aws_subnets.default.ids
  load_balancer_type = "network"
  internal           = true
  idle_timeout       = 3600

  tags = {
    Name        = "${var.role}.${var.region}.${var.environment}.${var.dns["domain_name"]}"
    environment = var.environment
    role        = var.role
    owner       = "${var.aws_sshkey_name}"
  }
}

resource "aws_lb_target_group" "default" {
  name     = "${var.role}-internal-${var.environment}"
  port     = 2379
  protocol = "TCP"
  vpc_id   = var.vpc_id
  tags = {
    Name        = "${var.role}.${var.region}.${var.environment}.${var.dns["domain_name"]}"
    environment = var.environment
    role        = var.role
    owner       = "${var.aws_sshkey_name}"
  }
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 10
    protocol            = "TCP"
    port                = 2379
  }
}

resource "aws_lb_listener" "internal" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 2379
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.default.arn
    type             = "forward"
  }
}

resource "aws_route53_record" "internal" {
  zone_id = aws_route53_zone.default.id
  name    = "${var.role}-lb.${var.region}.${var.environment}.${var.dns["domain_name"]}"
  type    = "A"

  alias {
    name                   = aws_lb.internal.dns_name
    zone_id                = aws_lb.internal.zone_id
    evaluate_target_health = false
  }
}

resource "aws_lb" "postgresql" {
  name               = "postgresql-internal-${var.environment}"
  subnets            = data.aws_subnets.default.ids
  load_balancer_type = "network"
  internal           = true
  idle_timeout       = 3600

  tags = {
    Name        = "postgres-${var.region}.${var.environment}.${var.dns["domain_name"]}"
    environment = var.environment
    role        = var.role
    owner       = "${var.aws_sshkey_name}"
  }
}

resource "aws_lb_target_group" "postgresql-primary" {
  name     = "pg-primary-tg-${var.environment}"
  port     = 5432
  protocol = "TCP"
  vpc_id   = var.vpc_id
  tags = {
    Name        = "postgresql-primary-${var.region}.${var.environment}.${var.dns["domain_name"]}"
    environment = var.environment
    role        = "postgresql-primary"
    owner       = "${var.aws_sshkey_name}"
  }
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 10
    protocol            = "HTTP"
    path                = "/primary"
    port                = 8008
  }
}

resource "aws_lb_listener" "postgresql-primary" {
  load_balancer_arn = aws_lb.postgresql.arn
  port              = 5432
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.postgresql-primary.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "postgresql-primary" {
  count            = length(aws_instance.pg-patroni)
  target_group_arn = aws_lb_target_group.postgresql-primary.arn
  target_id        = aws_instance.pg-patroni[count.index].id
}

resource "aws_route53_record" "postgresql-primary" {
  zone_id = aws_route53_zone.default.id
  name    = "postgresql-lb.${var.region}.${var.environment}.${var.dns["domain_name"]}"
  type    = "A"

  alias {
    name                   = aws_lb.postgresql.dns_name
    zone_id                = aws_lb.postgresql.zone_id
    evaluate_target_health = false
  }
}

resource "aws_lb_target_group" "postgresql-replica" {
  name     = "pg-replica-tg-${var.environment}"
  port     = 5432
  protocol = "TCP"
  vpc_id   = var.vpc_id
  tags = {
    Name        = "postgresql-replica-${var.region}.${var.environment}.${var.dns["domain_name"]}"
    environment = var.environment
    role        = "postgresql-replica"
    owner       = "${var.aws_sshkey_name}"
  }
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 10
    protocol            = "HTTP"
    path                = "/replica"
    port                = 8008
  }
}

resource "aws_lb_listener" "postgresql-replica" {
  load_balancer_arn = aws_lb.postgresql.arn
  port              = 5433
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.postgresql-replica.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "postgresql-replica" {
  count            = length(aws_instance.pg-patroni)
  target_group_arn = aws_lb_target_group.postgresql-replica.arn
  target_id        = aws_instance.pg-patroni[count.index].id
}
