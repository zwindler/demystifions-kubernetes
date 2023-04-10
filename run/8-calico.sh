#!/bin/bash
helm repo add projectcalico https://projectcalico.docs.tigera.io/charts

kubectl create namespace tigera-operator
helm install calico projectcalico/tigera-operator --version v3.25.1 --namespace tigera-operator
