#!/bin/bashPATH=$PATH:$(pwd)

PATH=$PATH:${pwd}
helm repo add projectcalico https://projectcalico.docs.tigera.io/charts

kubectl create namespace tigera-operator
helm install calico projectcalico/tigera-operator --version v3.24.5 --namespace tigera-operator
