# patroni-cluster-guide

# Create hosts
* Create 3x Ubuntu 20.04 instances for the etcd cluster preferably on 3 separate Availability Zones
* Create 3x Ubuntu 20.04 instances for the postgres/patroni cluster perferably on 3 separate Availability Zones
* On the postgres/patroni instances, you need a security group that allows the load balancer to connect to port 5432 (postgresql) and port 8008 (patroni api)
![security-group-rules](/images/security-group-rules.png)

### On etcd hosts
```
sudo apt update
sudo apt install docker.io
sudo vim /etc/group
# add ubuntu to the docker group and logout/back in
docker:x:120:ubuntu
```

```
# For each machine
# enter the private IP address below in the HOST_* variables
REGISTRY=gcr.io/etcd-development/etcd
ETCD_VERSION=latest
TOKEN=patroni-etcd-cluster
CLUSTER_STATE=new
NAME_1=etcd-node-1
NAME_2=etcd-node-2
NAME_3=etcd-node-3
HOST_1=172.31.24.96
HOST_2=172.31.31.41
HOST_3=172.31.19.0
CLUSTER=${NAME_1}=http://${HOST_1}:2380,${NAME_2}=http://${HOST_2}:2380,${NAME_3}=http://${HOST_3}:2380
DATA_DIR=/var/lib/etcd

# For node 1
THIS_NAME=${NAME_1}
THIS_IP=${HOST_1}
docker run \
  -p 2379:2379 \
  -p 2380:2380 \
  --volume=${DATA_DIR}:/etcd-data \
  --name etcd ${REGISTRY}:${ETCD_VERSION} \
  /usr/local/bin/etcd \
  --data-dir=/etcd-data --name ${THIS_NAME} \
  --initial-advertise-peer-urls http://${THIS_IP}:2380 --listen-peer-urls http://0.0.0.0:2380 \
  --advertise-client-urls http://${THIS_IP}:2379 --listen-client-urls http://0.0.0.0:2379 \
  --initial-cluster ${CLUSTER} \
  --initial-cluster-state ${CLUSTER_STATE} --initial-cluster-token ${TOKEN} &

# For node 2
THIS_NAME=${NAME_2}
THIS_IP=${HOST_2}
docker run \
  -p 2379:2379 \
  -p 2380:2380 \
  --volume=${DATA_DIR}:/etcd-data \
  --name etcd ${REGISTRY}:${ETCD_VERSION} \
  /usr/local/bin/etcd \
  --data-dir=/etcd-data --name ${THIS_NAME} \
  --initial-advertise-peer-urls http://${THIS_IP}:2380 --listen-peer-urls http://0.0.0.0:2380 \
  --advertise-client-urls http://${THIS_IP}:2379 --listen-client-urls http://0.0.0.0:2379 \
  --initial-cluster ${CLUSTER} \
  --initial-cluster-state ${CLUSTER_STATE} --initial-cluster-token ${TOKEN} &

# For node 3
THIS_NAME=${NAME_3}
THIS_IP=${HOST_3}
docker run \
  -p 2379:2379 \
  -p 2380:2380 \
  --volume=${DATA_DIR}:/etcd-data \
  --name etcd ${REGISTRY}:${ETCD_VERSION} \
  /usr/local/bin/etcd \
  --data-dir=/etcd-data --name ${THIS_NAME} \
  --initial-advertise-peer-urls http://${THIS_IP}:2380 --listen-peer-urls http://0.0.0.0:2380 \
  --advertise-client-urls http://${THIS_IP}:2379 --listen-client-urls http://0.0.0.0:2379 \
  --initial-cluster ${CLUSTER} \
  --initial-cluster-state ${CLUSTER_STATE} --initial-cluster-token ${TOKEN} &
```

Now you should have a running etcd cluster. Verify by issuing the `member list` command:

```
docker exec etcd /bin/sh -c "export ETCDCTL_API=3 && /usr/local/bin/etcdctl member list"
```

You should receive some output that looks like this:
```
22a32856510ab4ab, started, etcd-node-1, http://172.31.8.252:2380, http://172.31.8.252:2379
535b53b1c7f00ff3, started, etcd-node-2, http://172.31.2.27:2380, http://172.31.2.27:2379
915ba6d1a88f616b, started, etcd-node-3, http://172.31.5.240:2380, http://172.31.5.240:2379
```

## Install postgresql and patroni
```
curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
sudo apt update
sudo apt install postgresql-14 patroni
```

Now use the cluster info you found above to populate the dcs.yml file:
`sudo vim /etc/patroni/dcs.yml`
```
etcd:
  hosts: 172.31.8.252:2379,172.31.2.27:2379,172.31.5.240:2379
```

## drop the default cluster and recreate with the pg_createconfig_patroni command
```
#NETWORK=$(ip r|grep '/.*link'|awk '{print $1}')
# Becaure we're using an NLB we need to all the subnets in the VPC
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

## Create a target group in the AWS Console for the primary (writer) endpoint
* Click Target Groups on the left in the AWS EC2 Console
* Client Create target group
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

