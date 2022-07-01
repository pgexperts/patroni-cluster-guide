locals {
  my_cloud_init_config = [
    for n in range(var.cluster_size) : templatefile("${path.module}/cloudinit/userdata-template.json.tfpl", {
          environment = "${var.environment}"
          role        = "${var.role}"
          region      = "${var.region}"
          bucket_url  = "s3://${aws_s3_bucket.files.bucket}"

          etcd_member_unit = <<-EO1
              ${templatefile("${path.module}/cloudinit/etcd_member_unit.tfpl", {
                    peer_name             = "peer-${n}"
                    discovery_domain_name = "${var.role}.${var.region}.${var.environment}.${var.dns["domain_name"]}"
                    cluster_name          = "${var.role}"
                  }
                )
              }
            EO1

          etcd_bootstrap_unit = <<-EO2
              ${templatefile("${path.module}/cloudinit/etcd_bootstrap_unit.tfpl", {
                    region                     = "${var.region}"
                    peer_name                  = "peer-${n}"
                    discovery_domain_name      = "${var.role}.${var.region}.${var.environment}.${var.dns["domain_name"]}"
                    etcd_mount_point           = var.etcd_mount_point
                    etcd3_bootstrap_binary_url = "https://${aws_s3_bucket.files.bucket_domain_name}/etcd3-bootstrap-linux-amd64"
                  }
                )
              }
            EO2

          certificate_bootstrap_unit = <<-EO3
              ${templatefile("${path.module}/cloudinit/certificate_bootstrap_unit.tfpl", {
                    etcd_mount_point           = var.etcd_mount_point
                    certificate_bootstrap_url  = "s3://${aws_s3_bucket.files.bucket}/${aws_s3_object.certificate-bootstrap.id}"
                  }
                )
              }
            EO3

          ntpdate_unit = <<-EO4
              ${templatefile("${path.module}/cloudinit/ntpdate_unit.tfpl", {
                    ntp_host = "${var.ntp_host}"
                  }
                )
              }
            EO4

          ntpdate_timer_unit = templatefile("${path.module}/cloudinit/ntpdate_timer_unit.tfpl", { a = 1 })

      }
    )
  ]
}
