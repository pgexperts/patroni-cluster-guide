resource "aws_launch_configuration" "default" {
  count                       = var.cluster_size
  name_prefix                 = "peer-${count.index}.${var.role}.${var.region}.${var.environment}.${var.dns["domain_name"]}-"
  image_id                    = var.ami
  instance_type               = var.instance_type
  ebs_optimized               = true
  iam_instance_profile        = aws_iam_instance_profile.default.id
  key_name                    = var.aws_sshkey_name
  enable_monitoring           = false
  associate_public_ip_address = true
  security_groups             = [aws_security_group.default.id]
  user_data                   = element(local.my_cloud_init_config, count.index)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "default" {
  count                     = var.cluster_size
  availability_zones        = ["${element(var.azs, count.index)}"]
  name                      = "peer-${count.index}.${var.role}.${var.region}.${var.environment}.${var.dns["domain_name"]}"
  max_size                  = 1
  min_size                  = 1
  desired_capacity          = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  force_delete              = true
  launch_configuration      = element(aws_launch_configuration.default.*.name, count.index)
  target_group_arns         = [aws_lb_target_group.default.arn]
  wait_for_capacity_timeout = "0"

  tag {
    key                 = "Name"
    value               = "peer-${count.index}.${var.role}.${var.region}.${var.environment}.${var.dns["domain_name"]}"
    propagate_at_launch = true
  }

  tag {
    key                 = "environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "role"
    value               = "peer-${count.index}.${var.role}"
    propagate_at_launch = true
  }

  tag {
    key                 = "r53-domain-name"
    value               = "${var.environment}.${var.dns["domain_name"]}"
    propagate_at_launch = false
  }

  tag {
    key                 = "r53-zone-id"
    value               = aws_route53_zone.default.id
    propagate_at_launch = false
  }

  depends_on = [
    aws_lambda_function.cloudwatch-dns-service
  ]
}

resource "aws_ebs_volume" "ssd" {
  count             = var.cluster_size
  type              = "gp2"
  availability_zone = element(var.azs, count.index)
  size              = var.ebs_volume_size

  tags = {
    Name        = "peer-${count.index}-ssd.${var.role}.${var.region}.${var.environment}.${var.dns["domain_name"]}"
    environment = var.environment
    role        = "peer-${count.index}-ssd.${var.role}"
  }
}
