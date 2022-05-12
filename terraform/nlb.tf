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
  }
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 10
    protocol            = "HTTP"
    path                = "/health"
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
