#!/bin/bash

/usr/bin/docker run -v ${etcd_mount_point}:${etcd_mount_point} amazon/aws-cli s3 cp ${ca_cert_pem} ${etcd_mount_point}/ca_cert.pem
/usr/bin/docker run -v ${etcd_mount_point}:${etcd_mount_point} amazon/aws-cli s3 cp ${key_pem} ${etcd_mount_point}/key.pem
/usr/bin/docker run -v ${etcd_mount_point}:${etcd_mount_point} amazon/aws-cli s3 cp ${cert_pem} ${etcd_mount_point}/cert.pem
chmod 600 ${etcd_mount_point}/*.pem
chown ${etcd_cert_owner} ${etcd_mount_point}/*.pem
