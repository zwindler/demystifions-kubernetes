#!/bin/bash
PATH=$PATH:${pwd}

sudo kube-proxy --kubeconfig kube-proxy.conf

kubectl expose deployment web --port=80

kubectl get svc
