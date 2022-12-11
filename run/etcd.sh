#!/bin/bash
./etcd --advertise-client-urls https://127.0.0.1:2379 \
--client-cert-auth \
--data-dir etcd-data \
--cert-file=certs/kubernetes.pem \
--key-file=certs/kubernetes-key.pem \
--listen-client-urls https://127.0.0.1:2379 \
--trusted-ca-file=certs/ca.pem \
