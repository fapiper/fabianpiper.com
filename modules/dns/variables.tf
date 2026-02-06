variable "private" {
  type        = bool
  description = <<-EOT
    If 'true', the DNS record will be private.
    If 'false', the DNS record will be public.
    EOT
  default     = true
}

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

variable "ip_addresses" {
  type = list(object({
    ip_address = string
    public     = bool
  }))
  description = "The IP addresses for the DNS record"
  default     = null
}

variable "domain_name" {
  type        = string
  description = "The domain name"
  default     = null
}

# Private vars
variable "vcn_id" {
  type        = string
  description = "The ID of the VCN"
  default     = null
}

variable "subnet_domain_name" {
  type        = string
  description = "The subnet's domain name, which consists of the subnet's DNS label, the VCN's DNS label and the oraclevcn.com domain"
  default     = null
}
