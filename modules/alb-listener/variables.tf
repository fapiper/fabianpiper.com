variable "name" {
  type        = string
  description = "The name used as a part of resources display name"
  default     = null
}

variable "load_balancer_id" {
  type        = string
  description = "The ID of the load balancer"
}

variable "listener_port" {
  type        = number
  description = "The port for the listener"
}

variable "health_check_port" {
  type        = number
  description = "The port to send the health check request to"
}

variable "use_ssl" {
  type        = bool
  description = <<-EOT
    If 'true', certificate will be attached to the listener.
    If 'false', SSL won't be used for the listener.
    EOT
  default     = false
}

variable "certificate_name" {
  type        = string
  description = "The name of the certificate"
}
