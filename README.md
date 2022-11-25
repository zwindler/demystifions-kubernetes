# demystifions-kubernetes

## Prerequisites

With his blessing, I copy-pasted Jérôme Petazzoni's excellent repo [dessine-moi-un-cluster](https://github.com/jpetazzo/dessine-moi-un-cluster) for this part and updated. Thanks Jérôme :).

### api-server & friends

Get kubernetes binaries from the kubernetes release page. We want the "server" bundle for amd64 Linux.

```
curl -L https://dl.k8s.io/v1.25.4/kubernetes-server-linux-amd64.tar.gz -o kubernetes-server-linux-amd64.tar.gz
tar -zxf kubernetes-server-linux-amd64.tar.gz
for BINARY in kubectl kube-apiserver kube-scheduler kube-controller-manager kubelet kube-proxy;
do
  mv kubernetes/server/bin/${BINARY} .
done
rm kubernetes-server-linux-amd64.tar.gz
rm -rf kubernetes
```

Note: jpetazzo's repo mention a all-in-one binary call hyperkube which doesn't seem to exist anymore

### etcd

See [https://github.com/etcd-io/etcd/releases/tag/v3.5.6](https://github.com/etcd-io/etcd/releases/tag/v3.5.6)

Get binaries from the etcd release page. Pick the tarball for Linux amd64. In that tarball, we just need `etcd` and (just in case) `etcdctl`.

This is a fancy one-liner to download the tarball and extract just what we need:

```
curl -L https://github.com/etcd-io/etcd/releases/download/v3.5.6/etcd-v3.5.6-linux-amd64.tar.gz | 
  tar --strip-components=1 --wildcards -zx '*/etcd' '*/etcdctl'
```

Test it

```
$ etcd --version
etcd Version: 3.5.6
Git SHA: cecbe35ce
Go Version: go1.16.15
Go OS/Arch: linux/amd64

$ etcdctl version
etcdctl version: 3.5.6
API version: 3.5
```

Create a directory to host etcd database files

```
mkdir etcd-data
chmod 700 etcd-data
```

### containerd

Note: Jérôme was using Docker but since Kubernetes 1.24, dockershim, the component responsible for bridging the gap between docker daemon and kubernetes is no longer supported. I (like many other) switched to `containerd` but there are alternatives.

```
wget https://github.com/containerd/containerd/releases/download/v1.6.10/containerd-1.6.10-linux-amd64.tar.gz
tar --strip-components=1 --wildcards -zx '*/ctr' '*/containerd' -f containerd-1.6.10-linux-amd64.tar.gz
rm containerd-1.6.10-linux-amd64.tar.gz
```

### Misc

We need `cfssl` tool to generate certificates. Install it.


Optionnaly, to ease this tutorial, you should also have a mean to easily switch between terminals. `tmux` or `screen` are your friends. Here is a [tmux cheat sheet](https://tmuxcheatsheet.com/) ;-)

Optionnaly as well, `curl` is a nice addition to play with API server.

### Certificates

Even though this tutorial could be run without having any TLS encryption between components (like Jérôme did), for fun (and profit) I'd rather use encryption everywhere.

Create a dir for all certs and then generate a CA

```
mkdir certs && cd certs

TODO see https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md

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
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Oregon"
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
      "C": "US",
      "L": "Portland",
      "O": "system:masters",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
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

{

cat > kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-controller-manager",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

}

{

cat > kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-scheduler",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler

}

cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${LOCALIP},127.0.0.1 \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

}
```

Get back in main dir

```
cd ..
```

### Warning

Last but not least, a lot of files will be created in various places. **Running as root for this tutorial will save you from a world of pain**, even though this is really bad practice. Just don't do it outside of here (please).

## Kubernetes bootstrap

### Authentication Configs

We will create the admin kube config file in /etc/kubernetes/admin.conf

```
#launch tmux as root
tmux new -t terminal

export KUBECONFIG=/etc/kubernetes/admin.conf
export PATH=$PATH:${pwd}

mkdir /etc/kubernetes
kubectl config set-cluster demystifions-kubernetes \
  --certificate-authority=certs/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443

kubectl config set-credentials admin \
  --embed-certs=true \
  --client-certificate=certs/admin.pem \
  --client-key=certs/admin-key.pem

kubectl config set-context demystifions-kubernetes \
  --cluster=demystifions-kubernetes \
  --user=admin

kubectl config use-context demystifions-kubernetes
```

### etcd

We can't start the API server until we have an etcd backend to support it's persistance. So let's start with `etcd` command

```
#create a new tmux session for etcd
'[ctrl]-b' and then ': new -s etcd'

./etcd --data-dir etcd-data  --client-cert-auth --trusted-ca-file=certs/ca.pem --cert-file=certs/kubernetes.pem --key-file=certs/kubernetes-key.pem --advertise-client-urls https://127.0.0.1:2379 --listen-client-urls https://127.0.0.1:2379
  
[...]
{"level":"info","ts":"2022-11-24T20:30:46.132+0100","caller":"embed/serve.go:100","msg":"ready to serve client requests"}
{"level":"info","ts":"2022-11-24T20:30:46.133+0100","caller":"etcdmain/main.go:44","msg":"notifying init daemon"}
{"level":"info","ts":"2022-11-24T20:30:46.133+0100","caller":"etcdmain/main.go:50","msg":"successfully notified init daemon"}
{"level":"info","ts":"2022-11-24T20:30:46.135+0100","caller":"embed/serve.go:146","msg":"serving client traffic insecurely; this is strongly discouraged!","address":"127.0.0.1:2379"}
```

### kube-apiserver

Now we can start the apiserver

```
#create a new tmux session for apiserver
'[ctrl]-b' and then ': new -s apiserver'
./kube-apiserver --authorization-mode=Node,RBAC --client-ca-file=certs/ca.pem\
  --etcd-servers=https://127.0.0.1:2379 --etcd-cafile=certs/ca.pem --etcd-certfile=certs/kubernetes.pem --etcd-keyfile=certs/kubernetes-key.pem \
  --service-account-key-file=certs/service-account.pem --service-account-signing-key-file=certs/service-account-key.pem --service-account-issuer=https://kubernetes.default.svc.cluster.local \
  --tls-cert-file=certs/kubernetes.pem --tls-private-key-file=certs/kubernetes-key.pem
```

Note: you can then switch between sessions with '[ctrl]-b' and then '(' or ')'

Get back to "terminal" tmux session and check that API server responds

```bash
'[ctrl-b]-b' and then ': attach -t terminal'

kubectl version --short
```

You should get a similar output

```
Client Version: v1.25.4
Kustomize Version: v4.5.7
Server Version: v1.25.4
```

We can try to deploy a Deployment and see that the Deployment is created but not the Pods.

```
kubectl create deployment web --image=nginx
deployment.apps/web created

kubectl get deploy
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
web    0/1     0            0           3m38s

kubectl get pods
No resources found in default namespace.
```

This is because most of Kubernetes magic is done by the kubernetes **Controller manager** (and the controllers it controls). Typically here, creating a Deployment will trigger the creation of a Replicaset, which in turn will create our Pods.

### kube-controller-manager

We can then start the controller manager

### kube-scheduler

We can then start the scheduler