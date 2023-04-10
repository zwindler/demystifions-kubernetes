#!/bin/bash
kubectl create ns kube-flannel
kubectl label --overwrite ns kube-flannel pod-security.kubernetes.io/enforce=privileged
helm install flannel \
        --namespace kube-flannel \
        https://github.com/flannel-io/flannel/releases/latest/download/flannel.tgz
