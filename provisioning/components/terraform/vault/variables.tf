variable "compartment_ocid" {
  type = string
}

variable "vault_name" {
  type = string
}

variable "vault_type" {
  type    = string
  default = "DEFAULT"
}

variable "master_key_name" {
  type = string
}

variable "master_key_algorithm" {
  type = string
}

variable "master_key_length" {
  type = number
}

variable "master_key_protection_mode" {
  type = string
}

variable "secrets" {
  type = list(object({
    name        = string
    description = optional(string)
  }))
}

variable "secret_values" {
  type      = map(string)
  default   = {}
  sensitive = true
}

variable "enabled" {
  type    = bool
  default = true
}