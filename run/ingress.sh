helm repo add traefik https://traefik.github.io/charts
"traefik" has been added to your repositories

helm install traefik traefik/traefik

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
