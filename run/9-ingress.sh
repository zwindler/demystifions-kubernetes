#!/bin/bash
helm repo add traefik https://traefik.github.io/charts
helm install traefik traefik/traefik \
              --set ports.web.nodePort=30080 \
              --set ports.websecure.nodePort=30443

kubectl apply -f ingress.yaml
