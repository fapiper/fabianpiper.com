variable "tenancy_ocid" {
  type        = string
  description = "The OCID of the OCI tenancy"
}

variable "user_ocid" {
  type        = string
  description = "The OCID of the OCI user that will be used by GitHub Actions"
}

variable "private_key_path" {
  type        = string
  description = "Path to the OCI private key file"
}

variable "fingerprint" {
  type        = string
  description = "Fingerprint of the OCI API key"
}

variable "region" {
  type        = string
  description = "OCI region"
}

variable "compartment_ocid" {
  type        = string
  description = "The OCID of the compartment where resources will be created"
}

variable "enabled" {
  type        = bool
  default     = true
  description = "Whether to create resources"
}

variable "tenant" {
  type        = string
  description = "Tenant/organization name"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., fra, lon)"
}

variable "stage" {
  type        = string
  description = "Stage name (e.g., prod, dev)"
}

variable "name" {
  type        = string
  description = "Component name"
  default     = "oidc"
}

