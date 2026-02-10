variable "tenancy_ocid" {
  type        = string
  description = "OCI tenancy OCID"
}

variable "user_ocid" {
  type        = string
  description = "OCI user OCID"
}

variable "private_key_path" {
  type        = string
  description = "Path to OCI API private key"
}

variable "fingerprint" {
  type        = string
  description = "OCI API key fingerprint"
}

variable "region" {
  type        = string
  description = "OCI region"
}

variable "compartment_ocid" {
  type        = string
  description = "OCI compartment OCID"
}

variable "enabled" {
  type        = bool
  description = "Enable/disable this component"
  default     = true
}

variable "tenant" {
  type        = string
  description = "Tenant name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "stage" {
  type        = string
  description = "Stage name"
}

variable "name" {
  type        = string
  description = "Resource name"
}

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

