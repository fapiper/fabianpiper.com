variable "compartment_ocid" {
  type        = string
  description = "Compartment OCID"
  default     = null
}

variable "name" {
  type        = string
  description = "The name used as a part of resources display name"
  default     = null
}

variable "git_username" {
  type        = string
  description = "Git username for GitHub authentication"
  sensitive   = true
}

variable "git_pat" {
  type        = string
  description = "GitHub Personal Access Token"
  sensitive   = true
}

variable "mixpanel_token" {
  type        = string
  description = "Mixpanel token"
  sensitive   = true
}

variable "site_url" {
  type        = string
  description = "Site URL"
  sensitive   = true
}