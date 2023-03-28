#!/bin/bash
CERTS_OPTS=--cert-file=certs/admin.pem \
           --key-file=certs/admin-key.pem \
           --trusted-ca-file=certs/ca.pem

./etcd --advertise-client-urls https://127.0.0.1:2379 \
--listen-client-urls https://127.0.0.1:2379 \
--client-cert-auth \
--data-dir etcd-data \
$CERTS_OPTS
