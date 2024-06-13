#!/bin/bash

# change arch if necessary
if [ -z "$1" ]; then ARCH=amd64; else ARCH=$1; fi
# in case I forget (which always happens)
if [ `uname -i` == 'aarch64' ]; then
  ARCH="arm64"
fi

git fetch origin
git reset --hard origin/main

sudo apt update -y
sudo apt upgrade -y
sudo apt install tmux curl golang-cfssl linux-image-generic-hwe-22.04 -y

#K8S_VERSION=1.30.2
K8S_VERSION=1.31.0-alpha.0
ETCD_VERSION=3.5.14
CONTAINERD_VERSION=1.7.18
#RUNC_VERSION=1.1.12
RUNC_VERSION=1.2.0-rc.1
CILIUM_CLI_VERSION=0.16.10
CNI_PLUGINS_VERSION=1.5.0

mkdir -p bin/

# YOLO
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

curl -L https://dl.k8s.io/v$K8S_VERSION/kubernetes-server-linux-$ARCH.tar.gz -o kubernetes-server-linux-$ARCH.tar.gz
tar -zxf kubernetes-server-linux-${ARCH}.tar.gz
for BINARY in kubectl kube-apiserver kube-scheduler kube-controller-manager kubelet kube-proxy;
do
  mv kubernetes/server/bin/${BINARY} .
done
rm kubernetes-server-linux-${ARCH}.tar.gz
rm -rf kubernetes

sudo mv kubectl /usr/local/bin
# add kubectl autocomplete
echo 'source <(kubectl completion bash)' >>~/.bashrc

mv kube* bin/

curl -L https://github.com/etcd-io/etcd/releases/download/v${ETCD_VERSION}/etcd-v${ETCD_VERSION}-linux-${ARCH}.tar.gz | 
  tar --strip-components=1 --wildcards -zx '*/etcd'
mv etcd bin/

mkdir etcd-data
chmod 700 etcd-data

wget https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz
tar --strip-components=1 --wildcards -zx '*/ctr' '*/containerd' '*/containerd-shim-runc-v2' -f containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz
rm containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz
mv containerd* ctr bin/

curl https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.${ARCH} -L -o runc
chmod +x runc
sudo mv runc /usr/bin/

wget https://github.com/cilium/cilium-cli/releases/download/v${CILIUM_CLI_VERSION}/cilium-linux-${ARCH}.tar.gz
tar xzf cilium-linux-${ARCH}.tar.gz
rm cilium-linux-${ARCH}.tar.gz
mv cilium bin/

# Optional: prerequisites for flannel use
sudo mkdir -p /opt/cni/bin
curl -O -L https://github.com/containernetworking/plugins/releases/download/v${CNI_PLUGINS_VERSION}/cni-plugins-linux-${ARCH}-v${CNI_PLUGINS_VERSION}.tgz
sudo tar -C /opt/cni/bin -xzf cni-plugins-linux-${ARCH}-v${CNI_PLUGINS_VERSION}.tgz
rm cni-plugins-linux-${ARCH}-v${CNI_PLUGINS_VERSION}.tgz
sudo chown root: /opt/cni/bin

# disable swap
sudo swapoff -a

# remove firewall on ubuntu in Oracle cloud 
which netfilter-persistent
if [ $? -eq 0 ]; then
  sudo iptables -F
  sudo netfilter-persistent save
fi

# prepare ingress host value
sed -i "s/host: dk.zwindler.fr/host: dk${ARCH}.zwindler.fr/" ingress.yaml

# this will save me from forgetting generating certs
run/0-gen-certs.sh
