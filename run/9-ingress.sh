#!/bin/bash
helm repo add traefik https://traefik.github.io/charts
helm install traefik traefik/traefik \
              --set ports.web.nodePort=30080 \
              --set ports.websecure.nodePort=30443
























if [ `uname -i` == 'x86_64' ]; then
  ARCH=amd64
else
  ARCH=arm64
fi

### Ingress
cat > ingress.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: dk
  namespace: default
spec:
  rules:
    - host: dk${ARCH}.zwindler.fr
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name:  web
                port:
                  number: 3000
EOF
kubectl apply -f ingress.yaml
