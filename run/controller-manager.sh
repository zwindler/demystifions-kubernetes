#!/bin/bash
PATH=$PATH:${pwd}
kube-controller-manager --kubeconfig kube-controller-manager.conf \
--cluster-signing-cert-file=certs/ca.pem --cluster-signing-key-file=certs/ca-key.pem \
--service-account-private-key-file=certs/service-account-key.pem --use-service-account-credentials \
--root-ca-file=certs/ca.pem
