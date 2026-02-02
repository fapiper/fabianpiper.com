# OCI Networking Module
# Creates VCN, subnets, Internet Gateway, route tables, and security lists

variable "compartment_ocid" {
  description = "OCI Compartment OCID"
  type        = string
}

variable "name" {
  description = "Base name for networking resources"
  type        = string
}

variable "vcn_cidr_block" {
  description = "CIDR block for the VCN"
  type        = string
}

variable "vcn_dns_label" {
  description = "DNS label for the VCN"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
}

variable "public_subnet_dns_label" {
  description = "DNS label for public subnet"
  type        = string
  default     = "public"
}

variable "ssh_source_cidr" {
  description = "CIDR block allowed to SSH into instances"
  type        = string
  default     = "0.0.0.0/0"
}

variable "enabled" {
  description = "Enable or disable this component"
  type        = bool
  default     = true
}
