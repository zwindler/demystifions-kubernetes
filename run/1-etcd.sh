#!/bin/bash
CERTS_OPTS="--client-cert-auth \
           --cert-file=certs/admin.pem \
           --key-file=certs/admin-key.pem \
           --trusted-ca-file=certs/ca.pem"

# By default, etcd will server HTTP, not HTTPS
FORCE_HTTPS_OPTS="--advertise-client-urls https://127.0.0.1:2379 \
                  --listen-client-urls https://127.0.0.1:2379"

bin/etcd --data-dir etcd-data $CERTS_OPTS $FORCE_HTTPS_OPTS
