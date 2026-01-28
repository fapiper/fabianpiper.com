apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - crd.yaml

helmCharts:
  - name: external-dns
    repo: https://kubernetes-sigs.github.io/external-dns/
    version: 1.13.0
    releaseName: external-dns
    namespace: external-dns
    valuesInline:
      logLevel: debug
      provider: cloudflare
      env:
        - name: CF_API_TOKEN
          valueFrom:
            secretKeyRef:
              name: cloudflare-api-token-secret
              key: api-token
      domainFilters:
        - fabianpiper.com
      extraArgs:
        - --zone-id-filter=537a18e193fc9874b0f3c3ddcd12912f
      sources:
        - crd
      rbac:
        create: true
        extraRules:
          - apiGroups: ["gateway.networking.k8s.io"]
            resources: ["gateways","httproutes","grpcroutes","tlsroutes","tcproutes","udproutes","gatewayclasses"]
            verbs: ["get","watch","list"]
          - apiGroups: ["externaldns.k8s.io"]
            resources: ["dnsendpoints"]
            verbs: ["get","watch","list"]
          - apiGroups: ["externaldns.k8s.io"]
            resources: ["dnsendpoints/status"]
            verbs: ["update"]