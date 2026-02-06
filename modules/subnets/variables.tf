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

variable "vcn_id" {
  type        = string
  description = "The ID of the VCN"
  default     = null
}

variable "igw_id" {
  type        = string
  description = "The ID of the internet gateway"
  default     = null
}

variable "default_security_list_id" {
  type        = string
  description = "The ID of the default security list"
  default     = null
}

variable "ipv4_cidr_block" {
  type        = string
  description = "CIDR block for the subnet"
  default     = null
}

variable "dns_label" {
  type = string
  # Source: https://docs.oracle.com/en-us/iaas/Content/Network/Concepts/dns.htm#About
  description = <<-EOT
    DNS label for the subnet, used to form FQDN.
    Example of FQDN consisting of:
    - VNIC's hostname `instance1`
    - subnet's DNS label `subnet-1`
    - VCN's DNS label `vcn-2`
    would be `instance1.subnet-1.vcn-2.oraclevcn.com`
    EOT
  default     = null
}

variable "ssh_enabled" {
  type        = bool
  description = <<-EOT
    If 'true', SSH will be enabled in this subnet by adding corresponding security lists.
    If 'false', SSH will be disabled.
  EOT
  default     = false
}

variable "https_enabled" {
  type        = bool
  description = <<-EOT
    If 'true', HTTPS will be enabled in this subnet by adding corresponding security lists.
    If 'false', HTTPS will be disabled.
  EOT
  default     = false
}

variable "container_cluster_enabled" {
  type        = bool
  description = <<-EOT
    If 'true', container cluster will be enabled in this subnet by adding corresponding security lists.
    If 'false', container cluster will be disabled.
  EOT
  default     = false
}

variable "create_route_table" {
  type        = bool
  description = <<-EOT
    If `true', route table will be created and routes will be added to destinations this module knows about.
    If `false`, do not manage route table, allowing it to be managed by another component.
  EOT
  default     = true
}

variable "route_table_enabled" {
  type        = bool
  description = <<-EOT
    If `true', route table will be created and routes will be added to destinations this module knows about.
    If `false`, do not manage route table, allowing it to be managed by another component.
  EOT
  default     = true
}
