#!/bin/bash
sudo ./kubelet --fail-swap-on=false --kubeconfig kubelet.conf \
--register-node=true --container-runtime=remote \
--container-runtime-endpoint=unix:///var/run/containerd/containerd.sock
