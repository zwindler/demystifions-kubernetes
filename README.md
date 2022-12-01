# demystifions-kubernetes

## Prerequisites

With his blessing, I was strongly inspired by Jérôme Petazzoni's excellent repo [dessine-moi-un-cluster](https://github.com/jpetazzo/dessine-moi-un-cluster) for this part and updated. Thanks Jérôme :).

I also adapted parts of [Kelsey Hightower's kubernetes the hard way](https://github.com/kelseyhightower/kubernetes-the-hard-way) (the TLS certs).

### api-server & friends

Get kubernetes binaries from the kubernetes release page. We want the "server" bundle for amd64 Linux.

```bash
curl -L https://dl.k8s.io/v1.25.4/kubernetes-server-linux-amd64.tar.gz -o kubernetes-server-linux-amd64.tar.gz
tar -zxf kubernetes-server-linux-amd64.tar.gz
for BINARY in kubectl kube-apiserver kube-scheduler kube-controller-manager kubelet kube-proxy;
do
  mv kubernetes/server/bin/${BINARY} .
done
rm kubernetes-server-linux-amd64.tar.gz
rm -rf kubernetes
```

Note: jpetazzo's repo mention a all-in-one binary call `hyperkube` which doesn't seem to exist anymore

### etcd

See [https://github.com/etcd-io/etcd/releases/tag/v3.5.6](https://github.com/etcd-io/etcd/releases/tag/v3.5.6)

Get binaries from the etcd release page. Pick the tarball for Linux amd64. In that tarball, we just need `etcd` and (just in case) `etcdctl`.

This is a fancy one-liner to download the tarball and extract just what we need:

```bash
curl -L https://github.com/etcd-io/etcd/releases/download/v3.5.6/etcd-v3.5.6-linux-amd64.tar.gz | 
  tar --strip-components=1 --wildcards -zx '*/etcd' '*/etcdctl'
```

Test it

```bash
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

```bash
mkdir etcd-data
chmod 700 etcd-data
```

### containerd

Note: Jérôme was using Docker but since Kubernetes 1.24, dockershim, the component responsible for bridging the gap between docker daemon and kubernetes is no longer supported. I (like many other) switched to `containerd` but there are alternatives.

```bash
wget https://github.com/containerd/containerd/releases/download/v1.6.10/containerd-1.6.10-linux-amd64.tar.gz
tar --strip-components=1 --wildcards -zx '*/ctr' '*/containerd' '*/containerd-shim-runc-v2' -f containerd-1.6.10-linux-amd64.tar.gz
rm containerd-1.6.10-linux-amd64.tar.gz
```

### runc

To work, `containerd` is a high level container runtime which relies on `runc` (low level)

Download it 

```bash
curl https://github.com/opencontainers/runc/releases/download/v1.1.4/runc.amd64 -L -o runc
chmod +x runc
mv runc /usr/bin/

```

### Misc

We need `cfssl` tool to generate certificates. Install it (see [github.com/cloudflare/cfssl](https://github.com/cloudflare/cfssl#installation)).

To install cilium (CNI plugin), the easiest way is to use `helm` (see [helm.sh/docs](https://helm.sh/docs/intro/install/)).

Optionally, to ease this tutorial, you should also have a mean to easily switch between terminals. `tmux` or `screen` are your friends. Here is a [tmux cheat sheet](https://tmuxcheatsheet.com/) should you need it ;-).

Optionally as well, `curl` is a nice addition to play with API server.

### Certificates

Even though this tutorial could be run without having any TLS encryption between components (like Jérôme did), for fun (and profit) I'd rather use encryption everywhere. See [github.com/kelseyhightower/kubernetes-the-hard-way](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md)

Generate the CA

```bash
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
```

Generate admin certs

```bash
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
```

Create those 2 variables

```
#replace with you local ip address
LOCALIP=YOUR.LOCAL.IP.ADDRESS

KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local
```

Generate all other certs

```bash
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
  -hostname=${LOCALIP},127.0.0.1,10.0.0.1,${KUBERNETES_HOSTNAMES} \
  -profile=kubernetes \
  ${CERT}-csr.json | cfssljson -bare ${CERT}
done

{
INSTANCE=instance-2022-12-01-11-57-36
cat > kubelet-csr.json <<EOF
{
  "CN": "system:node:${INSTANCE}",
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
  -hostname=${LOCALIP},127.0.0.1,10.0.0.1,${INSTANCE} \
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
```

Get back in main dir

```bash
cd ..
```

### Warning

Last but not least, a lot of files will be created in various places. **Running as root for this tutorial will save you from a world of pain**, even though this is really bad practice. Just don't do it outside of here (please).

## Kubernetes bootstrap

### Authentication Configs

We will create the admin kube config file in `/etc/kubernetes/admin.conf`

```bash
#launch tmux as root
tmux new -t bash

export KUBECONFIG=admin.conf
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
```

### etcd

We can't start the API server until we have an `etcd` backend to support it's persistance. So let's start with `etcd` command

```bash
#create a new tmux session for etcd
'[ctrl]-b' and then ': new -s etcd'

./etcd --data-dir etcd-data  --client-cert-auth --trusted-ca-file=certs/ca.pem --cert-file=certs/kubernetes.pem --key-file=certs/kubernetes-key.pem --advertise-client-urls https://127.0.0.1:2379 --listen-client-urls https://127.0.0.1:2379
  
[...]
{"level":"info","ts":"2022-11-29T17:34:54.601+0100","caller":"embed/serve.go:198","msg":"serving client traffic securely","address":"127.0.0.1:2379"}
```

### kube-apiserver

Now we can start the `kube-apiserver`

```bash
#create a new tmux session for apiserver
'[ctrl]-b' and then ': new -s apiserver'

./kube-apiserver --allow-privileged --authorization-mode=Node,RBAC --client-ca-file=certs/ca.pem\
  --etcd-servers=https://127.0.0.1:2379 --etcd-cafile=certs/ca.pem --etcd-certfile=certs/kubernetes.pem --etcd-keyfile=certs/kubernetes-key.pem \
  --service-account-key-file=certs/service-account.pem --service-account-signing-key-file=certs/service-account-key.pem --service-account-issuer=https://kubernetes.default.svc.cluster.local \
  --tls-cert-file=certs/kubernetes.pem --tls-private-key-file=certs/kubernetes-key.pem
```

Note: you can then switch between sessions with '[ctrl]-b' and then '(' or ')'

Get back to "bash" tmux session and check that API server responds

```bash
'[ctrl]-b' and then ': attach -t bash'

kubectl version --short
```

You should get a similar output

```
Client Version: v1.25.4
Kustomize Version: v4.5.7
Server Version: v1.25.4
```

Check what APIs are available

```
kubectl api-resources | head
NAME                              SHORTNAMES   APIVERSION                             NAMESPACED   KIND
bindings                                       v1                                     true         Binding
componentstatuses                 cs           v1                                     false        ComponentStatus
configmaps                        cm           v1                                     true         ConfigMap
endpoints                         ep           v1                                     true         Endpoints
events                            ev           v1                                     true         Event
limitranges                       limits       v1                                     true         LimitRange
namespaces                        ns           v1                                     false        Namespace
nodes                             no           v1                                     false        Node
persistentvolumeclaims            pvc          v1                                     true         PersistentVolumeClaim
```

We can try to deploy a *Deployment* and see that the *Deployment* is created but not the Pods.

```
kubectl create deployment web --image=nginx
deployment.apps/web created

kubectl get deploy
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
web    0/1     0            0           3m38s

kubectl get pods
No resources found in default namespace.
```

### kube-controller-manager

This is because most of Kubernetes magic is done by the kubernetes **Controller manager** (and the controllers it controls). Typically here, creating a *Deployment* will trigger the creation of a *Replicaset*, which in turn will create our *Pods*.

We can start the controller manager to fix this.

```bash
#create a new tmux session for the controller manager
'[ctrl]-b' and then ': new -s controller'

./kube-controller-manager --kubeconfig kube-controller-manager.conf \
--cluster-signing-cert-file=certs/ca.pem --cluster-signing-key-file=certs/ca-key.pem \
--service-account-private-key-file=certs/service-account-key.pem --use-service-account-credentials \
--root-ca-file=certs/ca.pem
[...]
I1130 14:36:38.454244    1772 garbagecollector.go:163] Garbage collector: all resource monitors have synced. Proceeding to collect garbage
```

The *ReplicaSet* and then the *Pod* are created... but the Pod is stuck in `Pending` indefinitely!

That's because there are many things missing before the Pod can start. 

To start it, we still need:
- a scheduler to decide where to start the **Pod** (here we will have only one **Node** so this should be easy)
- a container runtime to run the containers in the pods
- a CNI plugin to give an IP to the Pod
- a kubelet to let kubernetes know *where* it can run the Pod (on a **Node**)

### kube-scheduler

Let's now start the `kube-scheduler`

```bash
#create a new tmux session for scheduler
'[ctrl]-b' and then ': new -s scheduler'
./kube-scheduler --kubeconfig kube-scheduler.conf

[...]
I1201 12:54:40.814609    2450 secure_serving.go:210] Serving securely on [::]:10259
I1201 12:54:40.814805    2450 tlsconfig.go:240] "Starting DynamicServingCertificateController"
I1201 12:54:40.914977    2450 leaderelection.go:248] attempting to acquire leader lease kube-system/kube-scheduler...
I1201 12:54:40.923268    2450 leaderelection.go:258] successfully acquired lease kube-system/kube-scheduler
```

### container runtime

Let's start the container runtime `containerd` on our machine

```bash
#create a new tmux session for containerd
'[ctrl]-b' and then ': new -s containerd'
./containerd
[...]
INFO[2022-12-01T11:03:37.616892592Z] serving...                                    address=/run/containerd/containerd.sock
INFO[2022-12-01T11:03:37.617062671Z] containerd successfully booted in 0.038455s  
[...]
```

### kubelet

Let's start the `kubelet` component. It will register our current machine as a node, which will allow future *Pod* scheduling later. It will also talk with containerd to launch/monitor/kill the containers of our *Pods*.

```bash
#create a new tmux session for kubelet
'[ctrl]-b' and then ': new -s kubelet'
./kubelet --fail-swap-on=false --kubeconfig kubelet.conf --register-node=true --container-runtime=remote --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock
```

### kube-proxy

Let's now start the `kube-proxy`

```bash
#create a new tmux session for proxy
'[ctrl]-b' and then ': new -s proxy'
./kube-proxy --kubeconfig kube-proxy.conf
```

### CNI plugin

Deploy Calico

```bash
helm repo add projectcalico https://projectcalico.docs.tigera.io/charts

kubectl create namespace tigera-operator
helm install calico projectcalico/tigera-operator --version v3.24.5 --namespace tigera-operator
```

## The end

Now, you should have a working "one node kubernetes cluster"

### Cleanup

You should clear the `/var/lib/kubelet` directory and remove the `/usr/bin/runc` binary
