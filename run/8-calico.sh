#!/bin/bash
helm repo add projectcalico https://projectcalico.docs.tigera.io/charts

cat > values.yaml <<EOF
installation:
  cni:
    type: Calico
  calicoNetwork:
    bgp: Disabled
    ipPools:
    - cidr: 10.244.0.0/16
      encapsulation: VXLAN
EOF

kubectl create namespace tigera-operator
helm install calico projectcalico/tigera-operator --version v3.25.1 --namespace tigera-operator
