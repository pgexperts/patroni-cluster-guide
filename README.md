# patroni-cluster-guide

## Install terraform via asdf
```
brew install asdf
asdf plugin add terraform
asdf install terraform 1.2.3
```

You'll also need to add something like this to your `~/.aws/config`:

```
[default]
region = us-west-2
credential_process = sh -c "op item get --format json 'PGX AWS Key' | jq '.fields | map({(.label):.}) | add | {Version:1, AccessKeyId:.aws_access_key_id.value, SecretAccessKey:.aws_secret_access_key.value}'"
```
If you prefer to use a specific named AWS profile, assign that to the `AWS_PROFILE` environment variable:

```export AWS_PROFILE=pgx```

## Apply terraform
* `terraform apply` the terraform module in the `terraform` directory
```
cd terraform
terraform init
terraform apply -var aws_sshkey_name="jeff"
```

(Where "jeff" above is replaced by your SSH key name as listed in ec2's Key
Pairs.)

You should eventually see some output that looks similar to this:
```
Apply complete! Resources: 59 added, 0 changed, 0 destroyed.
```
The terraform most notably launches a highly available etcd cluster as well as
3x Patroni/PostgreSQL instances (named pg-patroni-[123]).
After installing PostgreSQL and Patroni packages, it drops the default
PostgreSQL cluster. It then configures Patroni to talk to the etcd cluster above by editing
`/etc/patroni/dcs.yml`. and then running 
`sudo pg_createconfig_patroni --network=${NETWORK} 14 main`
It then seds that config to allow md5 connections from the VPC's CIDR address
and starts the Patroni cluster.
Finally, it creates load balancers and target groups to access the postgresql
primary and replicas on ports 5432 and 5433 respectively.

The etcd instances only allow SSH from IP addresses inside the VPC.

## Check the status on your etcd cluster with `etcdctl`:
**NOTE:** the etcd instances use flatcar linux and the ssh username is `core`.
On one of the peer-*.etcd3-test instances:
```
docker exec etcd-member /bin/sh -c "export ETCDCTL_API=3 && /usr/local/bin/etcdctl member list"
```

## Check the status on your patroni cluster with `patronictl`:
On one of the patroni-pg-* instances:
```
sudo patronictl -c /etc/patroni/14-main.yml list
```

You should get output that looks like:
```
+ Cluster: 14-main (7096589276548035899) ----+---------+----+-----------+
| Member           | Host          | Role    | State   | TL | Lag in MB |
+------------------+---------------+---------+---------+----+-----------+
| ip-172-31-1-9    | 172.31.1.9    | Leader  | running |  1 |           |
| ip-172-31-11-144 | 172.31.11.144 | Replica | running |  1 |         0 |
| ip-172-31-14-50  | 172.31.14.50  | Replica | running |  1 |         0 |
+------------------+---------------+---------+---------+----+-----------+
```

If you get warnings that look like this:
```
2022-06-23 15:44:35,571 - WARNING - failed to resolve host etcd3-test-lb.us-west-2.staging.pgx.internal: [Errno -2] Name or service not known
2022-06-23 15:44:35,571 - WARNING - Retrying (Retry(total=1, connect=None, read=None, redirect=0, status=None)) after connection broken by 'NewConnectionError('<urllib3.connection.HTTPConnection object at 0x7f2eed4b2e60>: Failed to establish a new connection: getaddrinfo returns an empty list')': /version
```
Just hit ctrl-c and try again in a few minutes. It takes a little while for the
route53 records to propagate and start resolving on the newly created
instances.

## Check the postgresql connectivity through the load balancer
Port 5432 will be the primary and 5433 will be the replicas.
**NOTE:** You'll need to set a password for the postgres user on the primary first.
```
psql -h postgresql-lb.us-west-2.staging.pgx.internal -p 5432 -U postgres postgres
psql -h postgresql-lb.us-west-2.staging.pgx.internal -p 5433 -U postgres postgres
```


## Here's how you would configure the load balancers by hand in the console


## Create a target group in the AWS Console for the primary (writer) endpoint
* Click Target Groups on the left in the AWS EC2 Console
* Click Create target group
* Choose Instances
* Give the group a name like "patroni-postgres-primary"
* For protocol and port, choose TCP and 5432
* For VPC, choose the VPC that we used above
* For health check protocol, choose HTTP
* For health check path, enter `/primary`
* Click on Advanced Healthcheck Settings
* Choose override for the Port and enter 8008
* Change the interval to 10s
* Add appropriate tags, for example:
  * project:patroni
  * service:postgresql
  * owner:jeff
* Click Next
* Check the boxes next to the postgresql/patroni servers
* Make sure in Ports for selected instances, it is 5432
* Click Include as Pending Below
* Click Create Target Group

![Click create target group](/images/create-target-group.png)
![Choose Instances](/images/choose-instances.png)
![Health Checks](/images/health-checks.png)
![Target Tags](/images/target-tags.png)
![Register Targets 1](/images/register-targets-1.png)
![Register Targets 2](/images/register-targets-2.png)


## Create a target group in the AWS Console for the follower (reader) endpoint
* Click Target Groups on the left in the AWS EC2 Console
* Client Create target group
* Choose Instances
* Give the group a name like "patroni-postgres-follower"
* For protocol and port, choose TCP and 5432
* For VPC, choose the VPC that we used above
* For health check protocol, choose HTTP
* For health check path, enter `/replica
* Click on Advanced Healthcheck Settings
* Choose override for the Port and enter 8008
* Change the interval to 10s
* Add appropriate tags, for example:
  * project:patroni
  * service:postgresql
  * owner:jeff
* Click Next
* Check the boxes next to the postgresql/patroni servers
* Make sure in Ports for selected instances, it is 5432
* Click Include as Pending Below
* Click Create Target Group

![Click target groups](/images/target-groups.png)
![Click create target group](/images/create-target-group.png)
![Choose Instances](/images/choose-instances-follower.png)
![Health Checks](/images/health-checks-follower.png)
![Target Tags](/images/target-tags.png)
![Register Targets 1](/images/register-targets-1.png)
![Register Targets 2](/images/register-targets-2.png)

## Create a network load balancer in the AWS Console
* Click Load Balancers on the left in the AWS EC2 Console
* Click Create Load Balancer
* Click Create under Network Load Balancer
* Give the load balancer a name such as "postgres-patroni"
* Choose Internal as the Schema
* Choose IPv4 as the IP address type
* Choose the VPC that you used above
* Click the box next to all the availability zones
* In the Listeners and Routers section, select `TCP` port `5432` and `patroni-postgres-primary` as the target group
* In the Listeners and Routers section, select `TCP` port `5433` and `patroni-postgres-follower` as the target group
* Add appropriate tags, for example:
  * project:patroni
  * service:postgresql
  * owner:jeff
* Click Create load balancer

![Click load balancers](/images/load-balancers.png)
![Click create load balancer](/images/create-load-balancer.png)
![Click create network load balancer](/images/create-network-load-balancer.png)
![Name the load balancer](/images/load-balancer-basic-config.png)
![Load balancer networking](/images/load-balancer-networking.png)
![Listener primary](/images/listener-primary.png)
![Add listener](/images/add-listener.png)
![Listener follower](/images/listener-follower.png)
![Load balancer tags](/images/load-balancer-tags.png)
![Load balancer summary](/images/load-balancer-summary.png)

After a little while, you should see that the healthy target on the `patroni-postgres-primary` target group should be the same as the current primary from the `sudo patronictl -c /etc/patroni/14-main.yml list` output and the healthy targets in the `patroni-postgres-follower` target group are the replicas from that list.

![Healthy primary](/images/target-health-primary.png)
![Healthy follower](/images/target-health-follower.png)

## Test the connection
**NOTE:** You cannot connect through the load balancer to the same host as you are on. That is, if you are on the primary and connect to port 5432 on the load balancer, your connection will hang. This is because the target group preserves the client IP address, so it seems as though you are trying to make a connection to yourself, though in actuality, the connection is going through the load balancer, so the tcp stack ignores the connection.


# References:

https://snapshooter.com/learn/postgresql/postgresql-cluster-patroni

http://metadata.ftp-master.debian.org/changelogs/main/p/patroni/stable_README.Debian

## Couple good examples of running etcd:
https://github.com/monzo/etcd3-terraform
https://monzo.com/blog/2017/11/29/very-robust-etcd

https://github.com/crewjam/etcd-aws
https://crewjam.com/etcd-aws/

