# patroni-cluster-guide

```
curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
sudo apt update
sudo apt install postgresql-14 patroni
```

```
sudo apt install etcd
```

```
sudo apt install haproxy
```

```
ETCD_LISTEN_PEER_URLS="http://172.31.62.121:2380,http://127.0.0.1:7001"
ETCD_LISTEN_CLIENT_URLS="http://127.0.0.1:2379, http://172.31.62.121:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://172.31.62.121:2380"
ETCD_INITIAL_CLUSTER="etcd0=http://172.31.62.121:2380,"
ETCD_ADVERTISE_CLIENT_URLS="http://172.31.62.121:2379"
ETCD_INITIAL_CLUSTER_TOKEN="cluster1"
ETCD_INITIAL_CLUSTER_STATE="new"
```

sudo vim /etc/patroni/dcs.yml
```
etcd:
  host: 172.31.62.121:2379
```

# On replica and primary
```
sudo pg_dropcluster 14 main
sudo pg_createconfig_patroni 14 main
sudo systemctl start patroni@14-main
```


References:

https://snapshooter.com/learn/postgresql/postgresql-cluster-patroni

http://metadata.ftp-master.debian.org/changelogs/main/p/patroni/stable_README.Debian
