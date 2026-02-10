variable "enabled" {
  type        = bool
  description = "Set to false to prevent the module from creating any resources"
  default     = true
}

variable "compartment_ocid" {
  type        = string
  description = "OCI compartment OCID"
}

#----------------------------------------------------------------
# VCN Variables
#----------------------------------------------------------------

variable "vcn_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks for the VCN"
  default     = ["10.0.0.0/16"]
}

variable "vcn_dns_label" {
  type        = string
  description = "DNS label for the VCN"
  default     = "default"
}

#----------------------------------------------------------------
# Subnet Variables
#----------------------------------------------------------------

variable "subnet_name" {
  type        = string
  description = "Name of the subnet"
  default     = "public-subnet"
}

variable "subnet_cidr_block" {
  type        = string
  description = "CIDR block for the subnet"
  default     = "10.0.1.0/24"
}

variable "subnet_dns_label" {
  type        = string
  description = "DNS label for the subnet"
  default     = "public"
}

