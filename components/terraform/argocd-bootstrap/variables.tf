variable "kubeconfig_content" {
  description = "Content of the kubeconfig file"
  type        = string
  sensitive   = true
  default     = ""  # Empty by default - provided after K3s cluster is deployed
}

variable "git_repo_url" {
  description = "Git repository URL for Argo CD applications"
  type        = string
}

variable "git_revision" {
  description = "Git revision to use (branch, tag, or commit)"
  type        = string
  default     = "HEAD"
}

variable "argocd_namespace" {
  description = "Namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "enabled" {
  description = "Enable or disable this component"
  type        = bool
  default     = true
}
