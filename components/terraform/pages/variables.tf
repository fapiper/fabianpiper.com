variable "enabled" {
  type    = bool
  default = true
}

variable "tenant" {
  type    = string
  default = null
}

variable "environment" {
  type    = string
  default = null
}

variable "stage" {
  type    = string
  default = null
}

variable "name" {
  type    = string
  default = null
}

variable "region" {
  type    = string
  default = null
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token — must include Account:Cloudflare Pages:Edit and Zone:DNS:Edit permissions"
  sensitive   = true
}

variable "cloudflare_account_id" {
  type        = string
  description = "Cloudflare account ID"
  sensitive   = true
}

variable "zone_name" {
  type        = string
  description = "Cloudflare DNS zone name (e.g. fabianpiper.com)"
}

variable "project_name" {
  type        = string
  description = "Cloudflare Pages project name"
  default     = "www"
}

variable "production_branch" {
  type        = string
  description = "Git branch that maps to the production Pages deployment"
  default     = "main"
}

variable "domains" {
  type        = list(string)
  description = "Custom domains to attach to the Pages project"
  default     = []
}
