#!/bin/bash
CERTS_OPTS="--client-ca-file=certs/ca.pem \
            --tls-cert-file=certs/admin.pem \
            --tls-private-key-file=certs/admin-key.pem \
            --service-account-key-file=certs/admin.pem \
            --service-account-signing-key-file=certs/admin-key.pem \
            --service-account-issuer=https://kubernetes.default.svc.cluster.local"


ETCD_OPTS="--etcd-cafile=certs/ca.pem \
           --etcd-certfile=certs/admin.pem \
           --etcd-keyfile=certs/admin-key.pem \
           --etcd-servers=https://127.0.0.1:2379"

bin/kube-apiserver ${CERTS_OPTS} ${ETCD_OPTS} \
            --allow-privileged \
	        --authorization-mode=Node,RBAC


# Try this
# kubectl version --short

# kubectl api-resources | head

# kubectl create deployment web --image=nginx
