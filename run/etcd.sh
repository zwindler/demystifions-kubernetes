#!/bin/bash
PATH=$PATH:${pwd}
etcd --data-dir etcd-data  --client-cert-auth --trusted-ca-file=certs/ca.pem \
--cert-file=certs/kubernetes.pem --key-file=certs/kubernetes-key.pem \
--advertise-client-urls https://127.0.0.1:2379 --listen-client-urls https://127.0.0.1:2379
