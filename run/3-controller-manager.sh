#!/bin/bash
CERTS_OPTS="--cluster-signing-cert-file=certs/ca.pem \
            --cluster-signing-key-file=certs/ca-key.pem \
            --service-account-private-key-file=certs/admin-key.pem \
            --root-ca-file=certs/ca.pem"

bin/kube-controller-manager ${CERTS_OPTS} \
--kubeconfig admin.conf \
--use-service-account-credentials \
--allocate-node-cidrs=true
