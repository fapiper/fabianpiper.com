apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: www-route
  namespace: default
  annotations:
    external-dns.alpha.kubernetes.io/target: "${ingress_public_ip}"
spec:
  parentRefs:
  - name: public-gateway
    namespace: envoy-gateway-system
    sectionName: https-www
  hostnames:
  - "${domain_name}"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: www
      port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: www-redirect
  namespace: default
spec:
  parentRefs:
  - name: public-gateway
    namespace: envoy-gateway-system
    sectionName: http
  hostnames:
  - "${domain_name}"
  rules:
  - filters:
    - type: RequestRedirect
      requestRedirect:
        scheme: https
        statusCode: 301
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: www-tls
  namespace: default
spec:
  secretName: www-tls
  issuerRef:
    name: cloudflare-issuer
    kind: ClusterIssuer
  commonName: "${domain_name}"
  dnsNames:
  - "${domain_name}"
