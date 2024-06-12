# demystifions-kubernetes

## License

All the scripts, images, markdown text and presentation in this repository are licenced under license CC BY-SA 4.0 (Creative Commons Attribution-ShareAlike 4.0 International)

This license requires that reusers give credit to the creator. It allows reusers to distribute, remix, adapt, and build upon the material in any medium or format, even for commercial purposes. If others remix, adapt, or build upon the material, they must license the modified material under identical terms.

    BY: Credit must be given to you, the creator.
    SA: Adaptations must be shared under the same terms. 

## Prerequisites

I'm going to launch this on a clean VM running Ubuntu 22.04. Hostname for this VM should be **kubernetes** (due to ✨*certificates stuff*✨ I don't want to bother you with).

### api-server & friends

Get kubernetes binaries from the kubernetes release page. We want the "server" bundle for amd64 Linux.

```bash
K8S_VERSION=1.29.0-alpha.3
curl -L https://dl.k8s.io/v${K8S_VERSION}/kubernetes-server-linux-amd64.tar.gz -o kubernetes-server-linux-amd64.tar.gz
tar -zxf kubernetes-server-linux-amd64.tar.gz
for BINARY in kubectl kube-apiserver kube-scheduler kube-controller-manager kubelet kube-proxy;
do
  mv kubernetes/server/bin/${BINARY} .
done
rm kubernetes-server-linux-amd64.tar.gz
rm -rf kubernetes
```

Note: jpetazzo's repo mentions a all-in-one binary call `hyperkube` which doesn't seem to exist anymore.

### etcd

See [https://github.com/etcd-io/etcd/releases/tag/v3.5.10](https://github.com/etcd-io/etcd/releases/tag/v3.5.10)

Get binaries from the etcd release page. Pick the tarball for Linux amd64. In that tarball, we just need `etcd` and (just in case) `etcdctl`.

This is a fancy one-liner to download the tarball and extract just what we need:

```bash
ETCD_VERSION=3.5.10
curl -L https://github.com/etcd-io/etcd/releases/download/v${ETCD_VERSION}/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz | 
  tar --strip-components=1 --wildcards -zx '*/etcd' '*/etcdctl'
```

Test it

```bash
$ etcd --version
etcd Version: 3.5.10
Git SHA: cecbe35ce
Go Version: go1.16.15
Go OS/Arch: linux/amd64

$ etcdctl version
etcdctl version: 3.5.10
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
wget https://github.com/containerd/containerd/releases/download/v1.7.9/containerd-1.7.9-linux-amd64.tar.gz
tar --strip-components=1 --wildcards -zx '*/ctr' '*/containerd' '*/containerd-shim-runc-v2' -f containerd-1.7.9-linux-amd64.tar.gz
rm containerd-1.7.9-linux-amd64.tar.gz
```

### runc

`containerd` is a high level container runtime which relies on `runc` (low level. Download it:

```bash
curl https://github.com/opencontainers/runc/releases/download/v1.1.4/runc.amd64 -L -o runc
chmod +x runc
sudo mv runc /usr/bin/
```

### Misc

We need `cfssl` tool to generate certificates. Install it (see [github.com/cloudflare/cfssl](https://github.com/cloudflare/cfssl#installation)).

To install calico (the CNI plugin in this tutorial), the easiest way is to use `helm` (see [helm.sh/docs](https://helm.sh/docs/intro/install/)).

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

Generate the admin certs (will be used for everything, bad practice).

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

Get back in main dir

```bash
cd ..
```

### Warnings

We are going to use admin cert for ALL components of Kubernetes. Please don't do this, this is really bad practice. All components should have separate certificates (some even need more than one). See [PKI certificates and requirements](https://kubernetes.io/docs/setup/best-practices/certificates/) in the official documentation for more information on this topic.

Also, a lot of files will be created in various places, and sometime they need priviledges to do so. For convenience, some binaries will be launched as **root** (`containerd`, `kubelet`, `kube-proxy`) using `sudo`.

## Kubernetes bootstrap

### Authentication Configs

We will create a kubeconfig files using the certs we generated. We'll use them later:

```bash
#launch tmux
tmux new -t bash

export KUBECONFIG=admin.conf
kubectl config set-cluster demystifions-kubernetes \
  --certificate-authority=certs/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443

kubectl config set-credentials admin \
  --embed-certs=true \
  --client-certificate=certs/admin.pem \
  --client-key=certs/admin-key.pem

kubectl config set-context admin \
  --cluster=demystifions-kubernetes \
  --user=admin

kubectl config use-context admin
```

### etcd

We can't start the API server until we have an `etcd` backend to support it's persistance. So let's start with `etcd` command:

```bash
#create a new tmux session for etcd
'[ctrl]-b' and then ': new -s etcd'

./etcd --advertise-client-urls https://127.0.0.1:2379 \
--client-cert-auth \
--data-dir etcd-data \
--cert-file=certs/admin.pem \
--key-file=certs/admin-key.pem \
--listen-client-urls https://127.0.0.1:2379 \
--trusted-ca-file=certs/ca.pem
[...]
{"level":"info","ts":"2022-11-29T17:34:54.601+0100","caller":"embed/serve.go:198","msg":"serving client traffic securely","address":"127.0.0.1:2379"}
```

### kube-apiserver

Now we can start the `kube-apiserver`:

```bash
#create a new tmux session for apiserver
'[ctrl]-b' and then ': new -s apiserver'

./kube-apiserver --allow-privileged \
--authorization-mode=Node,RBAC \
--client-ca-file=certs/ca.pem \
--etcd-cafile=certs/ca.pem \
--etcd-certfile=certs/admin.pem \
--etcd-keyfile=certs/admin-key.pem \
--etcd-servers=https://127.0.0.1:2379 \
--service-account-key-file=certs/admin.pem \
--service-account-signing-key-file=certs/admin-key.pem \
--service-account-issuer=https://kubernetes.default.svc.cluster.local \
--tls-cert-file=certs/admin.pem \
--tls-private-key-file=certs/admin-key.pem
```

Note: you can then switch between sessions with '[ctrl]-b' and then '(' or ')'

Get back to "bash" tmux session and check that API server responds

```bash
'[ctrl]-b' and then ': attach -t bash'

kubectl version --short
```

You should get a similar output

```
Client Version: v1.29.0-alpha.3
Kustomize Version: v4.5.7
Server Version: v1.29.0-alpha.3
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

We can try to deploy a *Deployment* and see that the *Deployment* is created but not the *Pods*.

```
cat > deploy.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: web
  name: web
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - image: zwindler/vhelloworld
        name: web
EOF
kubectl apply -f deploy.yaml

#or
#kubectl create deployment web --image=zwindler/vhelloworld
```

You should get the following message:
```bash
deployment.apps/web created
```

But... nothing happens

```bash
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

./kube-controller-manager \
--kubeconfig admin.conf \
--cluster-signing-cert-file=certs/ca.pem \
--cluster-signing-key-file=certs/ca-key.pem \
--service-account-private-key-file=certs/admin-key.pem \
--use-service-account-credentials \
--root-ca-file=certs/ca.pem
[...]
I1130 14:36:38.454244    1772 garbagecollector.go:163] Garbage collector: all resource monitors have synced. Proceeding to collect garbage
```

The *ReplicaSet* and then the *Pod* are created... but the *Pod* is stuck in `Pending` indefinitely!

That's because there are many things missing before the Pod can start. 

To start it, we still need a scheduler to decide where to start the **Pod**

### kube-scheduler

Let's now start the `kube-scheduler`:

```bash
#create a new tmux session for scheduler
'[ctrl]-b' and then ': new -s scheduler'
./kube-scheduler --kubeconfig admin.conf

[...]
I1201 12:54:40.814609    2450 secure_serving.go:210] Serving securely on [::]:10259
I1201 12:54:40.814805    2450 tlsconfig.go:240] "Starting DynamicServingCertificateController"
I1201 12:54:40.914977    2450 leaderelection.go:248] attempting to acquire leader lease kube-system/kube-scheduler...
I1201 12:54:40.923268    2450 leaderelection.go:258] successfully acquired lease kube-system/kube-scheduler
```

But we still don't have our *Pod*... Sad panda.

In fact, that's because we still need a bunch of things...
- a container runtime to run the containers in the pods
- a `kubelet` daemon to let kubernetes interact with the container runtime
### container runtime

Let's start the container runtime `containerd` on our machine:

```bash
#create a new tmux session for containerd
'[ctrl]-b' and then ': new -s containerd'
sudo ./containerd
[...]
INFO[2022-12-01T11:03:37.616892592Z] serving...                                    address=/run/containerd/containerd.sock
INFO[2022-12-01T11:03:37.617062671Z] containerd successfully booted in 0.038455s  
[...]
```

### kubelet

Let's start the `kubelet` component. It will register our current machine as a *Node*, which will allow future *Pod* scheduled by scheduler.

At last!

The role of the kubelet is also to talk with containerd to launch/monitor/kill the containers of our *Pods*.

```bash
#create a new tmux session for kubelet
'[ctrl]-b' and then ': new -s kubelet'
sudo ./kubelet \
--container-runtime=remote \
--container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \
--fail-swap-on=false \
--kubeconfig admin.conf \
--register-node=true
```

We are going to get error messages telling us that we have no CNI plugin

```bash
E1211 21:13:22.555830   27332 kubelet.go:2373] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
E1211 21:13:27.556616   27332 kubelet.go:2373] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
E1211 21:13:32.558180   27332 kubelet.go:2373] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
```

### CNI plugin

To deal with networking inside Kubernetes, we need a few last things. A `kube-proxy` (which in some cases can be removed) and a CNI plugin. 

For CNI plugin, I chose Calico but there are many more options out there. Here I just deploy the chart and let Calico do the magic.

```bash
helm repo add projectcalico https://projectcalico.docs.tigera.io/charts

kubectl create namespace tigera-operator
helm install calico projectcalico/tigera-operator --version v3.24.5 --namespace tigera-operator
```

### kube-proxy

Let's start the `kube-proxy`:

```bash
#create a new tmux session for proxy
'[ctrl]-b' and then ': new -s proxy'
sudo ./kube-proxy --kubeconfig admin.conf
```

Then, we are going to create a ClusterIP service to obtain a stable IP address (and load balancer) for our deployment.

```bash
cat > service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: web
  name: web
spec:
  ports:
  - port: 3000
    protocol: TCP
    targetPort: 80
  selector:
    app: web
EOF
kubectl apply -f service.yaml

kubectl get svc
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.0.0.1     <none>        443/TCP   38m
web          ClusterIP   10.0.0.34    <none>        3000/TCP  67s

```

### IngressController

Finally, to allow us to connect to our Pod using a nice URL in our brower, I'll add an optional *IngressController*. Let's deploy Traefik as our ingressController

```bash
helm repo add traefik https://traefik.github.io/charts
"traefik" has been added to your repositories

helm install traefik traefik/traefik
[...]
Traefik Proxy v2.9.5 has been deployed successfully

kubectl get svc
NAME         TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)                      AGE
kubernetes   ClusterIP      10.0.0.1     <none>        443/TCP                      58m
traefik      LoadBalancer   10.0.0.86    <pending>     80:31889/TCP,443:31297/TCP   70s
web          ClusterIP      10.0.0.34    <none>        3000/TCP                     21m
```

Notice the Ports on the traefik line: **80:31889/TCP,443:31297/TCP** in my example.

Provided that DNS can resolve domain.tld to the IP of our Node, we can now access Traefik from the Internet by using http://domain.tld:31889 (and https://domain.tld:31297).

But how can we connect to our website?

By creating an Ingress that redirects traffic coming to dk.domain.tld to our docker image

```yaml
cat > ingress.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: dk
  namespace: default
spec:
  rules:
    - host: dk.domain.tld
      http:
        paths:
          - path: /
            pathType: Exact
            backend:
              service:
                name:  web
                port:
                  number: 3000
EOF
kubectl apply -f ingress.yaml
```

[http://dk.domain.tld:31889/](http://dk.domain.tld:31889/) should now be available!! Congrats!

## Playing with our cluster

Let's then have a look to the iptables generated by `kube-proxy`

```bash
sudo iptables -t nat -L KUBE-SERVICES |grep -v calico
Chain KUBE-SERVICES (2 references)
target     prot opt source               destination         
KUBE-SVC-NPX46M4PTMTKRN6Y  tcp  --  anywhere             10.0.0.1             /* default/kubernetes:https cluster IP */ tcp dpt:https
KUBE-SVC-LOLE4ISW44XBNF3G  tcp  --  anywhere             10.0.0.34            /* default/web cluster IP */ tcp dpt:http
KUBE-NODEPORTS  all  --  anywhere             anywhere             /* kubernetes service nodeports; NOTE: this must be the last rule in this chain */ ADDRTYPE match dst-type LOCAL
```

Here we can see that everything trying to go to 10.0.0.34 (the IP of our Kubernetes **Service** for nginx) is forwarded to **KUBE-SVC-LOLE4ISW44XBNF3G** rule

```bash
sudo iptables -t nat -L KUBE-SVC-LOLE4ISW44XBNF3G
Chain KUBE-SVC-LOLE4ISW44XBNF3G (1 references)
target     prot opt source               destination         
KUBE-SEP-3RY52QTAPPWAROT7  all  --  anywhere             anywhere             /* default/web -> 192.168.238.4:80 */
```

Digging a little bit further, we can see that for now, all the traffic is directed to the rule called **KUBE-SEP-3RY52QTAPPWAROT7**. **SEP** stands for "Service EndPoint"

```bash
sudo iptables -t nat -L KUBE-SEP-3RY52QTAPPWAROT7
Chain KUBE-SEP-3RY52QTAPPWAROT7 (1 references)
target     prot opt source               destination         
KUBE-MARK-MASQ  all  --  192.168.238.4        anywhere             /* default/web */
DNAT       tcp  --  anywhere             anywhere             /* default/web */ tcp to:192.168.238.4:80
```

Let's scale our deployment to see what happens

```bash
kubectl scale deploy web --replicas=4
deployment.apps/web scaled

kubectl get pods -o wide
NAME                   READY   STATUS    RESTARTS   AGE   IP              NODE                           NOMINATED NODE   READINESS GATES
web-8667899c97-8dsp7   1/1     Running   0          10s   192.168.238.6   instance-2022-12-01-15-47-29   <none>           <none>
web-8667899c97-jvwbl   1/1     Running   0          10s   192.168.238.5   instance-2022-12-01-15-47-29   <none>           <none>
web-8667899c97-s4sjg   1/1     Running   0          10s   192.168.238.7   instance-2022-12-01-15-47-29   <none>           <none>
web-8667899c97-vvqb7   1/1     Running   0          43m   192.168.238.4   instance-2022-12-01-15-47-29   <none>           <none>
```

iptables rules are updated accordingly, with random propability to be selected

```bash
sudo iptables -t nat -L KUBE-SVC-LOLE4ISW44XBNF3G
Chain KUBE-SVC-LOLE4ISW44XBNF3G (1 references)
target     prot opt source               destination         
KUBE-SEP-3RY52QTAPPWAROT7  all  --  anywhere             anywhere             /* default/web -> 192.168.238.4:80 */ statistic mode random probability 0.25000000000
KUBE-SEP-XDYZG4GSYEXZWWXS  all  --  anywhere             anywhere             /* default/web -> 192.168.238.5:80 */ statistic mode random probability 0.33333333349
KUBE-SEP-U3XU475URPOLV25V  all  --  anywhere             anywhere             /* default/web -> 192.168.238.6:80 */ statistic mode random probability 0.50000000000
KUBE-SEP-XLJ4FHFV6DVOXHKZ  all  --  anywhere             anywhere             /* default/web -> 192.168.238.7:80 */
```

## The end

Now, you should have a working "one node kubernetes cluster"

### Cleanup

You should clear the `/var/lib/kubelet` directory and remove the `/usr/bin/runc` and `/usr/local/bin/kubectl` binaries

If you want to run the lab again, also clear etcd-data directory or even the whole demystifions-kubernetes folder and `git clone` it again

## Similar resources 

* Jérôme Petazzoni's [dessine-moi-un-cluster](https://github.com/jpetazzo/dessine-moi-un-cluster)
* Kelsey Hightower's [kubernetes the hard way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
