#!/bin/bash

/usr/bin/docker run -v ${ssl_cert_dir}:${ssl_cert_dir} amazon/aws-cli s3 cp ${ca_cert_pem} ${etcd_ca_cert_path}
/usr/bin/docker run -v ${ssl_cert_dir}:${ssl_cert_dir} amazon/aws-cli s3 cp ${key_pem} ${etcd_key_path}
/usr/bin/docker run -v ${ssl_cert_dir}:${ssl_cert_dir} amazon/aws-cli s3 cp ${cert_pem} ${etcd_cert_path}
chmod 600 ${etcd_ca_cert_path} ${etcd_key_path} ${etcd_cert_path}
chown ${etcd_cert_owner} ${etcd_ca_cert_path} ${etcd_key_path} ${etcd_cert_path}
