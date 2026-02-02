resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  create_namespace = true
}

resource "kubernetes_secret" "repo_creds" {
  metadata {
    name      = "repo-creds"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }
  string_data = {
    url      = var.git_repo_url
    username = var.git_username
    password = var.git_pat
  }
}

resource "kubernetes_manifest" "root_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "root-app"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.git_repo_url
        targetRevision = "HEAD"
        path           = "gitops/clusters/prod" # Your new structure
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      syncPolicy = {
        automated = { prune = true, selfHeal = true }
      }
    }
  }
  depends_on = [helm_release.argocd]
}