# OCI Networking Component
# This component manages VPC, subnets, Internet Gateway, route tables, and security lists

variable "compartment_ocid" {
  description = "OCI Compartment OCID where network resources will be created"
  type        = string
}

variable "vcn_cidr_block" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vcn_dns_label" {
  description = "DNS label for the VCN"
  type        = string
  default     = "k3svcn"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "ssh_source_cidr" {
  description = "CIDR block allowed to SSH into the Ingress node. Defaults to 0.0.0.0/0 (open to world)."
  type        = string
  default     = "0.0.0.0/0"
}

variable "common_tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

variable "ingress_private_ip" {
  description = "Static Private IP for the Ingress/NAT node (used for route table)"
  type        = string
  default     = "10.0.1.10"
}
