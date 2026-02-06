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

variable "dns" {
  type = object({
    private     = bool
    domain_name = string
  })
  default = {
    private     = true
    domain_name = null
  }
}

variable "lb" {
  type = set(string)
}
