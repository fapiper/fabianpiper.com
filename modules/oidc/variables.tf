variable "tenancy_ocid" {
  type        = string
  description = "The OCID of the OCI tenancy"
}

variable "name" {
  type        = string
  description = "Name for the OIDC resources"
  default     = "github-actions"
}

variable "git_email" {
  type        = string
  description = "Email address for the GitHub Actions service account"
}

