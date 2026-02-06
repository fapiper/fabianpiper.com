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

variable "ipv4_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks for the VCN"
  default     = null
}

variable "dns_label" {
  type = string
  # Source: https://docs.oracle.com/en-us/iaas/Content/Network/Concepts/dns.htm#About
  description = <<-EOT
    DNS label for the VCN, used to form FQDN.
    Example of FQDN consisting of:
    - VNIC's hostname `instance1`
    - subnet's DNS label `subnet-1`
    - VCN's DNS label `vcn-2`
    would be `instance1.subnet-1.vcn-2.oraclevcn.com`
    EOT
  default     = null
}

variable "default_security_list_deny_all" {
  type        = bool
  description = <<-EOT
    If `true`, manage the default security list and remove all rules, disabling all ingress and egress.
    If `false`, do not manage the default security list, allowing it to be managed by another component.
    EOT
  default     = true
}

variable "default_route_table_no_routes" {
  type        = bool
  default     = false
  description = <<-EOT
    If `true`, manage the default route table and remove all routes, disabling all ingress and egress.
    If `false`, do not manage the default route table, allowing it to be managed by another component.
    EOT
}

variable "internet_gateway_enabled" {
  type        = bool
  description = "Set `true` to create an internet gateway for the VCN"
  default     = true
}
