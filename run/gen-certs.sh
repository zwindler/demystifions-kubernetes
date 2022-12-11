#!/bin/bash
mkdir certs && cd certs

{
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF
cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "FR",
      "L": "Pessac",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Nouvelle Aquitaine"
    }
  ]
}
EOF
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
}

{
cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "FR",
      "L": "Pessac",
      "O": "system:masters",
      "OU": "Démystifions Kubernetes",
      "ST": "Nouvelle Aquitaine"
    }
  ]
}
EOF
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin
}

for CERT in kubernetes kube-controller-manager kube-scheduler service-account; do
cat > ${CERT}-csr.json <<EOF
{
  "CN": "system:${CERT}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "FR",
      "L": "Pessac",
      "O": "system:${CERT}",
      "OU": "Démystifions Kubernetes",
      "ST": "Nouvelle Aquitaine"
    }
  ]
}
EOF
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=127.0.0.1,10.0.0.1,kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local \
  -profile=kubernetes \
  ${CERT}-csr.json | cfssljson -bare ${CERT}
done

{
cat > kubelet-csr.json <<EOF
{
  "CN": "system:node:kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "FR",
      "L": "Pessac",
      "O": "system:nodes",
      "OU": "Démystifions Kubernetes",
      "ST": "Nouvelle Aquitaine"
    }
  ]
}
EOF
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=127.0.0.1,10.0.0.1,${INSTANCE} \
  -profile=kubernetes \
  kubelet-csr.json | cfssljson -bare kubelet
}

{
cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "FR",
      "L": "Pessac",
      "O": "system:node-proxier",
      "OU": "Démystifions Kubernetes",
      "ST": "Nouvelle Aquitaine"
    }
  ]
}
EOF
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy
}

cd ..

export PATH=$PATH:${pwd}

for COMPONENT in admin kube-controller-manager kube-scheduler kubelet kube-proxy; do
export KUBECONFIG=${COMPONENT}.conf
kubectl config set-cluster demystifions-kubernetes \
  --certificate-authority=certs/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443

kubectl config set-credentials ${COMPONENT} \
  --embed-certs=true \
  --client-certificate=certs/${COMPONENT}.pem \
  --client-key=certs/${COMPONENT}-key.pem

kubectl config set-context ${COMPONENT} \
  --cluster=demystifions-kubernetes \
  --user=${COMPONENT}

kubectl config use-context ${COMPONENT}
done

mkdir ~/.kube && cp admin.conf ~/.kube/config
