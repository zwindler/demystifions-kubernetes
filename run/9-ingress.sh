#!/bin/bash
helm repo add traefik https://traefik.github.io/charts
helm install traefik traefik/traefik \
              --set ports.web.nodePort=30080 \
              --set ports.websecure.nodePort=30443

### Ingress
cat > ingress.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: dk
  namespace: default
spec:
  rules:
    - host: dk.zwindler.fr
      http:
        paths:
          - path: /
            pathType: Exact
            backend:
              service:
                name:  web
                port:
                  number: 80
EOF
kubectl apply -f ingress.yaml
