#!/bin/bash
sudo ./kube-proxy --kubeconfig admin.conf

# try this
# kubectl expose deployment web --port=80
# kubectl get svc
