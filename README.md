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

### containerd

Note: Jérôme was using Docker but since Kubernetes 1.24, dockershim, the component responsible for bridging the gap between docker daemon and kubernetes is no longer supported. I (like many other) switched to `containerd` but there are alternatives.

```
wget https://github.com/containerd/containerd/releases/download/v1.6.10/containerd-1.6.10-linux-amd64.tar.gz
tar --strip-components=1 --wildcards -zx '*/ctr' '*/containerd' -f containerd-1.6.10-linux-amd64.tar.gz
rm containerd-1.6.10-linux-amd64.tar.gz
```

### Certificates

Even though this tutorial could be run without having any TLS encryption between components (like Jérôme did), for fun (and profit) I'd rather use encryption everywhere.

## Kubernetes boot