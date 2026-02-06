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

variable "instance" {
  type = object({
    name        = string
    shape       = string
    public_key  = string
    k3s_version = string
  })
}

variable "secret" {
  type = object({
    name  = string
    value = string
  })
}

variable "k3s_token" {
  type = string
}
