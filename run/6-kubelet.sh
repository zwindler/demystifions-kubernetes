#!/bin/bash

CONTAINERD_OPTS="--container-runtime=remote \
                 --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock"

sudo ./kubelet \
--kubeconfig admin.conf \
--register-node=true

# If your server has swap (but we should have disabled it)
#--fail-swap-on=false
