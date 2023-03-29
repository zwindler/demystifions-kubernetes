#!/bin/bash
kubectl create ns kube-flannel
kubectl label --overwrite ns kube-flannel pod-security.kubernetes.io/enforce=privileged
helm install flannel \
        --set podCidr="10.244.0.0/16" \
        --namespace kube-flannel \
        https://github.com/flannel-io/flannel/releases/latest/download/flannel.tgz
