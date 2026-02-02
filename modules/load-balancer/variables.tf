# Load Balancer Component Variables

variable "compartment_ocid" {
  description = "OCI Compartment OCID"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet OCID for load balancer"
  type        = string
}

variable "ingress_instance_id" {
  description = "OCID of the ingress instance (backend)"
  type        = string
}

variable "ingress_private_ip" {
  description = "Private IP of the ingress instance"
  type        = string
}

variable "nlb_display_name" {
  description = "Display name for Network Load Balancer"
  type        = string
  default     = "k3s-nlb"
}

variable "is_private" {
  description = "Whether the NLB is private"
  type        = bool
  default     = false
}

variable "is_preserve_source_destination" {
  description = "Whether to preserve source/destination"
  type        = bool
  default     = false
}

variable "backend_set_name" {
  description = "Name of the backend set"
  type        = string
  default     = "k3s-backends"
}

variable "backend_policy" {
  description = "Load balancing policy"
  type        = string
  default     = "FIVE_TUPLE"
}

variable "health_check_protocol" {
  description = "Health check protocol"
  type        = string
  default     = "TCP"
}

variable "health_check_port" {
  description = "Health check port"
  type        = number
  default     = 6443
}

variable "health_check_interval_ms" {
  description = "Health check interval in milliseconds"
  type        = number
  default     = 10000
}

variable "health_check_timeout_ms" {
  description = "Health check timeout in milliseconds"
  type        = number
  default     = 3000
}

variable "health_check_retries" {
  description = "Number of health check retries"
  type        = number
  default     = 3
}

variable "https_listener_name" {
  description = "Name for HTTPS listener"
  type        = string
  default     = "k3s-https-listener"
}

variable "https_listener_port" {
  description = "HTTPS listener port"
  type        = number
  default     = 443
}

variable "https_listener_protocol" {
  description = "HTTPS listener protocol"
  type        = string
  default     = "TCP"
}

variable "http_listener_name" {
  description = "Name for HTTP listener"
  type        = string
  default     = "k3s-http-listener"
}

variable "http_listener_port" {
  description = "HTTP listener port"
  type        = number
  default     = 80
}

variable "http_listener_protocol" {
  description = "HTTP listener protocol"
  type        = string
  default     = "TCP"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enabled" {
  description = "Enable or disable this component"
  type        = bool
  default     = true
}
