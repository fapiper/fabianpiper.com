variable "tenancy_ocid" {
  type = string
}

variable "user_ocid" {
  type = string
}

variable "private_key_path" {
  type = string
}

variable "fingerprint" {
  type = string
}

variable "region" {
  type = string
}

variable "compartment_ocid" {
  type = string
}

variable "enabled" {
  type = bool
}

variable "tenant" {
  type = string
}

variable "environment" {
  type = string
}

variable "stage" {
  type = string
}

variable "name" {
  type = string
}

variable "git_username" {
  type        = string
  description = "Git username for GitHub authentication"
  sensitive   = true
}

variable "git_pat" {
  type        = string
  description = "GitHub Personal Access Token"
  sensitive   = true
}
