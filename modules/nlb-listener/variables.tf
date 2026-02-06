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
