output "argocd_server_url" {
  description = "Argo CD server URL"
  value       = var.enabled ? "http://${helm_release.argocd[0].name}-server.${var.argocd_namespace}.svc.cluster.local" : null
}
