terraform {
  required_version = ">= 1.5"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_content != "" ? "/tmp/kubeconfig" : null
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_content != "" ? "/tmp/kubeconfig" : null
}

resource "local_file" "kubeconfig" {
  count = var.enabled ? 1 : 0

  content  = var.kubeconfig_content
  filename = "/tmp/kubeconfig"
}

resource "helm_release" "argocd" {
  count = var.enabled ? 1 : 0

  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = var.argocd_namespace
  create_namespace = true
  version          = "5.51.6"

  values = [
    yamlencode({
      server = {
        extraArgs = [
          "--insecure"
        ]
      }
    })
  ]

  depends_on = [local_file.kubeconfig]
}

resource "kubernetes_manifest" "infrastructure_app" {
  count = var.enabled ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "infrastructure"
      namespace = var.argocd_namespace
      finalizers = [
        "resources-finalizer.argocd.argoproj.io"
      ]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.git_repo_url
        path           = "argocd/infrastructure"
        targetRevision = var.git_revision
        directory = {
          recurse = true
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.argocd_namespace
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }

  depends_on = [helm_release.argocd]
}

resource "kubernetes_manifest" "apps_app" {
  count = var.enabled ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "apps"
      namespace = var.argocd_namespace
      finalizers = [
        "resources-finalizer.argocd.argoproj.io"
      ]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.git_repo_url
        path           = "argocd/apps"
        targetRevision = var.git_revision
        directory = {
          recurse = true
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.argocd_namespace
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }

  depends_on = [helm_release.argocd]
}
