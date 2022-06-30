The etcd part of this terraform is based heavily on https://github.com/monzo/etcd3-terraform and this blog
post: [Very Robust etcd](https://monzo.com/blog/2017/11/29/very-robust-etcd/)

Notable changes include:
* Using a NLB instead of a classic ELB
* Launching in an existing VPC instead of defining a new one
* Not using a default security group
* Removed deprecated template module in favor of templatefile function

In addition to etcd, this module also:
* Launches the Patroni/PostgreSQL instances
* Configures them via user-data
* Adds them to LB Target Groups such that the NLB listeners on port 5432 and
    5433 forward to the primary and replica respectively

The TLS part of this terraform is based heavily on https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/private-tls-cert
