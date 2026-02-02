variable "compartment_ocid" {
  description = "OCI Compartment OCID"
  type        = string
}

variable "tenancy_ocid" {
  description = "OCI Tenancy OCID"
  type        = string
}

variable "name" {
  description = "Base name for IAM resources"
  type        = string
}

variable "enabled" {
  description = "Enable or disable this component"
  type        = bool
  default     = true
}
