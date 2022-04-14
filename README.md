# patroni-cluster-guide

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
REGISTRY=gcr.io/etcd-development/etcd
ETCD_VERSION=latest
TOKEN=patroni-etcd-cluster
CLUSTER_STATE=new
NAME_1=etcd-node-1
NAME_2=etcd-node-2
NAME_3=etcd-node-3
HOST_1=172.31.8.252
HOST_2=172.31.2.27
HOST_3=172.31.5.240
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
  --initial-cluster-state ${CLUSTER_STATE} --initial-cluster-token ${TOKEN}

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
  --initial-cluster-state ${CLUSTER_STATE} --initial-cluster-token ${TOKEN}

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
sudo vim /etc/patroni/dcs.yml
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
sudo systemctl start patroni@14-main
```

```
sudo patronictl -c /etc/patroni/14-main.yml list
```

# References:

https://snapshooter.com/learn/postgresql/postgresql-cluster-patroni

http://metadata.ftp-master.debian.org/changelogs/main/p/patroni/stable_README.Debian

## Couple good examples of running etcd:
https://github.com/monzo/etcd3-terraform
https://monzo.com/blog/2017/11/29/very-robust-etcd

https://github.com/crewjam/etcd-aws
https://crewjam.com/etcd-aws/

