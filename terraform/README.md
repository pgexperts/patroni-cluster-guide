This is based heavily on https://github.com/monzo/etcd3-terraform and this blog
post: [Very Robust etcd](https://monzo.com/blog/2017/11/29/very-robust-etcd/)

Notable changes include:
* Using a NLB instead of a classic ELB
* Launching in an existing VPC instead of defining a new one
* Not using a default security group
* Launching the patroni/postgresql instances
