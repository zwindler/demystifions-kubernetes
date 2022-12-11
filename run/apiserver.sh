#!/bin/bash
PATH=$PATH:$(pwd)

kube-apiserver --allow-privileged --authorization-mode=Node,RBAC \
--client-ca-file=certs/ca.pem --etcd-servers=https://127.0.0.1:2379 \
--etcd-cafile=certs/ca.pem --etcd-certfile=certs/kubernetes.pem --etcd-keyfile=certs/kubernetes-key.pem \
--service-account-key-file=certs/kubernetes.pem \
--service-account-signing-key-file=certs/kubernetes-key.pem \
--service-account-issuer=https://kubernetes.default.svc.cluster.local \
--tls-cert-file=certs/kubernetes.pem --tls-private-key-file=certs/kubernetes-key.pem

kubectl version --short

kubectl api-resources | head

kubectl create deployment web --image=nginx
