resource "aws_iam_role" "etcd" {
  name = "${var.role}.${var.region}.${var.environment}.${var.dns["domain_name"]}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "etcd" {
  name       = "${var.role}.${var.region}.${var.environment}.${var.dns["domain_name"]}"
  role       = "${var.role}.${var.region}.${var.environment}.${var.dns["domain_name"]}"
  depends_on = [aws_iam_role.etcd]
}

resource "aws_iam_role_policy" "etcd" {
  name       = "${var.role}.${var.region}.${var.environment}.${var.dns["domain_name"]}"
  role       = aws_iam_role.etcd.name
  depends_on = [aws_iam_role.etcd]

  lifecycle {
    create_before_destroy = true
  }

  policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeAddresses",
        "ec2:DescribeInstances",
        "ec2:DescribeVolumes",
        "ec2:DescribeVolumeStatus",
        "ec2:AttachVolume",
        "ec2:DetachVolume"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
