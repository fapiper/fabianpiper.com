variable "enabled" {
  description = "Enable or disable this module"
  type        = bool
  default     = true
}

variable "zone_name" {
  description = "Cloudflare DNS zone name (e.g. fabianpiper.com) — zone ID is resolved automatically"
  type        = string
}

variable "ingress_ip" {
  description = "Public IP of the ingress instance to point DNS records at"
  type        = string
  default     = ""
}

variable "records" {
  description = "List of DNS A records to create pointing to the ingress IP"
  type = list(object({
    name    = string
    proxied = optional(bool, false)
    ttl     = optional(number, 300)
  }))
  default = []
}
