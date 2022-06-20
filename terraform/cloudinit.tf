locals {
  my_cloud_init_config = [
    for n in range(var.cluster_size) : templatefile("${path.module}/cloudinit/userdata-template.json", {
          environment = "${var.environment}"
          role        = "${var.role}"
          region      = "${var.region}"

          etcd_member_unit = <<-EO1
              ${templatefile("${path.module}/cloudinit/etcd_member_unit", {
                    peer_name             = "peer-${n}"
                    discovery_domain_name = "${var.role}.${var.region}.${var.environment}.${var.dns["domain_name"]}"
                    cluster_name          = "${var.role}"
                  }
                )
              }
            EO1

          etcd_bootstrap_unit = <<-EO2
              ${templatefile("${path.module}/cloudinit/etcd_bootstrap_unit", {
                    region                     = "${var.region}"
                    peer_name                  = "peer-${n}"
                    discovery_domain_name      = "${var.role}.${var.region}.${var.environment}.${var.dns["domain_name"]}"
                    etcd3_bootstrap_binary_url = "https://${aws_s3_bucket.files.bucket_domain_name}/etcd3-bootstrap-linux-amd64"
                  }
                )
              }
            EO2

        ntpdate_unit = <<-EO3
              ${templatefile("${path.module}/cloudinit/ntpdate_unit", {
                    ntp_host = "${var.ntp_host}"
                  }
                )
              }
            EO3

        ntpdate_timer_unit = templatefile("${path.module}/cloudinit/ntpdate_timer_unit", { a = 1 })
      }
    )
  ]
}
