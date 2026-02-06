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

variable "alb_listener" {
  type = object({
    name              = string
    port              = number
    health_check_port = number
    use_ssl           = bool
  })
}
