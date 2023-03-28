#!/bin/bash
helm repo add projectcalico https://projectcalico.docs.tigera.io/charts
kubectl create namespace tigera-operator

cat > values.yaml <<EOF
installation:
  cni:
    type: Calico
  calicoNetwork:
    ipPools:
    - cidr: 10.244.0.0/16
EOF

helm install calico projectcalico/tigera-operator --version v3.24.5 --namespace tigera-operator
