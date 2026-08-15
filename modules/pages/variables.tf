variable "enabled" {
  description = "Enable or disable this module"
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
  sensitive   = true
}

variable "zone_name" {
  description = "Cloudflare DNS zone name (e.g. fabianpiper.com) — used to resolve zone ID"
  type        = string
}

variable "project_name" {
  description = "Cloudflare Pages project name"
  type        = string
  default     = "www"
}

variable "production_branch" {
  description = "Git branch that maps to the production Pages deployment"
  type        = string
  default     = "main"
}

variable "domains" {
  description = "Custom domains to attach to the Pages project; Cloudflare creates the DNS records automatically"
  type        = list(string)
  default     = []
}
