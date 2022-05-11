# patroni-cluster-guide

## Install terraform via asdf
```
brew install asdf
asdf plugin add terraform
asdf install terraform 1.1.9
```

You'll also need to add something like this to your `~/.aws/config`:

```
[default]
region = us-west-2
credential_process = sh -c "op item get --format json 'PGX AWS Key' | jq '.fields | map({(.label):.}) | add | {Version:1, AccessKeyId:.aws_access_key_id.value, SecretAccessKey:.aws_secret_access_key.value}'"
```
If you prefer to use a specific named AWS profile, assign that to the `AWS_PROFILE` environment variable:

```export AWS_PROFILE=pgx```

## Create etcd cluster
* `terraform apply` the terraform module in the `terraform` directory
```
cd terraform
terraform apply
```

You should eventually see some output that looks similar to this:
```
Apply complete! Resources: 42 added, 0 changed, 0 destroyed.
```

## Create PostgreSQL/Patroni hosts
* Create 3x Ubuntu 20.04 instances for the postgres/patroni cluster preferably on 3 separate Availability Zones
* On the postgres/patroni instances, you need a security group that allows the load balancer to connect to port 5432 (postgresql) and port 8008 (patroni api)
![security-group-rules](/images/security-group-rules.png)


## Install postgresql and patroni
```
curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
sudo apt update
sudo apt install postgresql-14 patroni
```

Populate the dcs.yml file with the following info
(**NOTE**: remove everything else):
`sudo vim /etc/patroni/dcs.yml`
```
etcd3:
  hosts: peer-0.etcd3-test.us-west-2.i.staging.pgx.internal:2379
```

## drop the default cluster and recreate with the pg_createconfig_patroni command
```
#NETWORK=$(ip r|grep '/.*link'|awk '{print $1}')
# Becaure we're using an NLB we need to add all the subnets in the VPC
NETWORK="172.31.0.0/16"
sudo pg_dropcluster --stop 14 main
sudo pg_createconfig_patroni --network=${NETWORK} 14 main
```

Edit the config you just generated and uncomment the line with md5 auth for the 172.31.0.0/16 subnet we used above
`sudo vim /etc/patroni/14-main.yml`

Start the patroni service
```
sudo systemctl start patroni@14-main
```

Check the status on your patroni cluster with `patronictl`:
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

