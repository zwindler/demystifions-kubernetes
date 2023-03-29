#!/bin/bash

sudo pkill containerd
sudo pkill etcd

rm -rf etcd-data
sudo rm -rf /var/lib/kubelet/
sudo rm /usr/bin/runc
sudo rm /usr/local/bin/kubectl
