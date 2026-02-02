# K3s Cluster Module Variables

variable "compartment_ocid" {
  description = "OCI Compartment OCID"
  type        = string
}

variable "name" {
  description = "Base name for K3s cluster resources"
  type        = string
}

variable "availability_domain" {
  description = "Availability domain for instances"
  type        = string
}

variable "vcn_id" {
  description = "VCN OCID"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet OCID"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for instances"
  type        = string
}

variable "instance_shape" {
  description = "OCI instance shape"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "instance_os" {
  description = "Operating system for instances"
  type        = string
  default     = "Canonical Ubuntu"
}

variable "instance_os_version" {
  description = "OS version for instances"
  type        = string
  default     = "24.04"
}

variable "server_ocpus" {
  description = "OCPUs for server instance"
  type        = number
  default     = 2
}

variable "server_memory_in_gbs" {
  description = "Memory in GBs for server instance"
  type        = number
  default     = 12
}

variable "k3s_token" {
  description = "K3s cluster token"
  type        = string
  sensitive   = true
}

variable "enabled" {
  description = "Enable or disable this component"
  type        = bool
  default     = true
}
