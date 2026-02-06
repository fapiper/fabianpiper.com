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

variable "shape" {
  type        = string
  description = "The shape of the instance"
}

variable "public_key" {
  type        = string
  description = "The SSH authorized public key"
}

variable "load_balancers" {
  type = map(object({
    id               = string
    backend_set_name = string
    backend_port     = number
  }))
}

variable "vault_name" {
  type        = string
  description = "The name of the vault containing the secret with cluster state value"
}

variable "secret_name" {
  type        = string
  description = "The name of the secret containg the cluster state value"
}

variable "k3s_version" {
  type        = string
  description = "K3s version to use"
}

variable "k3s_token" {
  type        = string
  description = "K3s token"
}

variable "internal_lb_domain_name" {
  type        = string
  description = "The domain name of the internal load balancer"
}
