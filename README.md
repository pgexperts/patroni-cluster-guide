# patroni-cluster-guide

```
curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
sudo apt update
sudo apt install postgresql-14 patroni
```

### On etcd hosts
```
sudo apt update
sudo apt install docker.io
sudo vim /etc/group
# add ubuntu to the docker group and logout/back in
docker:x:120:ubuntu
```

```
REGISTRY=quay.io/coreos/etcd
# available from v3.2.5
REGISTRY=gcr.io/etcd-development/etcd

# For each machine
ETCD_VERSION=latest
TOKEN=my-etcd-token
CLUSTER_STATE=new
NAME_1=etcd-node-0
NAME_2=etcd-node-1
NAME_3=etcd-node-2
HOST_1=172.31.5.117
HOST_2=172.31.13.92
HOST_3=172.31.2.178
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
  --initial-cluster-state ${CLUSTER_STATE} --initial-cluster-token ${TOKEN}

ubuntu@ip-172-31-5-117:~$ docker exec etcd /bin/sh -c "export ETCDCTL_API=3 && /usr/local/bin/etcdctl member list"
c43bb5f4dd2a997f, started, etcd-node-1, http://172.31.13.92:2380, http://172.31.13.92:2379
c5ba5b66773ed76b, started, etcd-node-0, http://172.31.5.117:2380, http://172.31.5.117:2379
efe7fd3df3589921, started, etcd-node-2, http://172.31.2.178:2380, http://172.31.2.178:2379
```

```
sudo systemctl restart etcd
```

sudo vim /etc/patroni/dcs.yml
```
etcd:
  host: 172.31.61.34:2379
```

# On replica and primary
```
sudo pg_dropcluster 14 main
sudo pg_createconfig_patroni 14 main
sudo systemctl start patroni@14-main
```

```
sudo patronictl -c /etc/patroni/14-main.yml list
```

```
sudo apt install haproxy
```

# References:

https://snapshooter.com/learn/postgresql/postgresql-cluster-patroni

http://metadata.ftp-master.debian.org/changelogs/main/p/patroni/stable_README.Debian

## Couple good examples of running etcd:
https://github.com/monzo/etcd3-terraform
https://monzo.com/blog/2017/11/29/very-robust-etcd

https://github.com/crewjam/etcd-aws
https://crewjam.com/etcd-aws/
