variable "compartment_ocid" {
  type        = string
  description = "OCI Compartment OCID"
}

variable "vault_name" {
  type        = string
  description = "Display name for the Vault"
}

variable "vault_type" {
  type        = string
  default     = "DEFAULT"
}

variable "master_key_name" {
  type        = string
}

variable "master_key_algorithm" {
  type    = string
  default = "AES"
}

variable "master_key_length" {
  type    = number
  default = 32
}

variable "master_key_protection_mode" {
  type    = string
  default = "SOFTWARE"
}

variable "secrets_config" {
  type = list(object({
    name        = string
    description = optional(string)
  }))
  default     = []
  description = "List of secret names to initialize in the vault"
}

variable "secret_values" {
  type        = map(string)
  default     = {}
  description = "Map of secret names to their actual sensitive values"
  sensitive   = true
}

variable "enabled" {
  type    = bool
  default = true
}