#!/bin/bash
sudo apt update -y
sudo apt upgrade -y
sudo apt install tmux curl golang-cfssl -y

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

curl -L https://dl.k8s.io/v1.25.4/kubernetes-server-linux-amd64.tar.gz -o kubernetes-server-linux-amd64.tar.gz
tar -zxf kubernetes-server-linux-amd64.tar.gz
for BINARY in kubectl kube-apiserver kube-scheduler kube-controller-manager kubelet kube-proxy;
do
  mv kubernetes/server/bin/${BINARY} .
done
rm kubernetes-server-linux-amd64.tar.gz
rm -rf kubernetes

curl -L https://github.com/etcd-io/etcd/releases/download/v3.5.6/etcd-v3.5.6-linux-amd64.tar.gz | 
  tar --strip-components=1 --wildcards -zx '*/etcd' '*/etcdctl'

mkdir etcd-data
chmod 700 etcd-data

wget https://github.com/containerd/containerd/releases/download/v1.6.10/containerd-1.6.10-linux-amd64.tar.gz
tar --strip-components=1 --wildcards -zx '*/ctr' '*/containerd' '*/containerd-shim-runc-v2' -f containerd-1.6.10-linux-amd64.tar.gz
rm containerd-1.6.10-linux-amd64.tar.gz

curl https://github.com/opencontainers/runc/releases/download/v1.1.4/runc.amd64 -L -o runc
chmod +x runc
sudo mv runc /usr/bin/

mv kubectl /usr/local/bin
