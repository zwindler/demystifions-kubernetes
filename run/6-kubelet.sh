#!/bin/bash
sudo ./kubelet \
--container-runtime=remote \
--container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \
--fail-swap-on=false \
--kubeconfig admin.conf \
--register-node=true
