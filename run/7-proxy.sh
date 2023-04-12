#!/bin/bash
sudo bin/kube-proxy --kubeconfig admin.conf

# kubectl apply -f service.yaml

# try this
# kubectl expose deployment web --port=80
# kubectl get svc
