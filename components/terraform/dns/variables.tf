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
  description = "Cloudflare API token for DNS management"
  sensitive   = true
}

variable "zone_id" {
  type        = string
  description = "Cloudflare zone ID (from the Cloudflare dashboard)"
}

variable "records" {
  description = "List of DNS A records to create pointing to the ingress IP"
  type = list(object({
    name    = string
    proxied = optional(bool, false)
    ttl     = optional(number, 60)
  }))
  default = []
}
