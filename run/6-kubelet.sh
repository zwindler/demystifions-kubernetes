#!/bin/bash

sudo bin/kubelet --kubeconfig admin.conf \
--container-runtime-endpoint=unix:///var/run/containerd/containerd.sock

# If your server has swap (but we should have disabled it)
#--fail-swap-on=false
