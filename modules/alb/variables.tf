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

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet"
}

variable "ca_certificate" {
  type        = string
  description = "CA certificate"
}

variable "private_key_path" {
  type        = string
  description = "Private key"
}

variable "public_certificate" {
  type        = string
  description = "Public certificate"
}
