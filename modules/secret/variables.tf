variable "compartment_ocid" {
  type        = string
  description = "Compartment OCID"
  default     = null
}

variable "name" {
  type        = string
  description = "The name used as a part of resources display name"
  default     = null
}

variable "value" {
  type        = string
  description = "The secret value"
  default     = null
}

variable "vault_id" {
  type        = string
  description = "The ID of the vault"
  default     = null
}

variable "encryption_key_id" {
  type        = string
  description = "The ID of the key"
  default     = null
}
