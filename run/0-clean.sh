#!/bin/bash

sudo pkill containerd
sudo pkill etcd

# remove cluster data
rm -rf certs/
rm -rf etcd-data/
rm -f admin.conf

# remove binaries
sudo rm -f /usr/bin/runc
sudo rm -f /usr/local/bin/kubectl
bin/cilium uninstall

# clean directories containing infos from previous installs
sudo rm -rf /var/lib/kubelet/
sudo rm -rf /opt/cni/bin/
sudo rm -rf /etc/cni/net.d/

# remove kubectl in bashrc
sed -i '/kubectl completion bash/d' ~/.bashrc
