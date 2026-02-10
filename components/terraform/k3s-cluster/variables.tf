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
  type    = bool
  default = true
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

# Networking variables
# Note: vcn_id and public_subnet_id are now fetched via terraform_remote_state
# from the networking component - see remote-state.tf

variable "vcn_cidr_block" {
  description = "VCN CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}


variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}


variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
}

# Instance configuration
variable "instance_shape" {
  description = "OCI instance shape"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "instance_os" {
  description = "Operating system for instances"
  type        = string
  default     = "Canonical Ubuntu"
}

variable "instance_os_version" {
  description = "OS version for instances"
  type        = string
  default     = "24.04"
}

# Ingress instance
variable "ingress_display_name" {
  description = "Display name for ingress instance"
  type        = string
  default     = "k3s-ingress"
}

variable "ingress_hostname_label" {
  description = "Hostname label for ingress instance"
  type        = string
  default     = "ingress"
}

variable "ingress_private_ip" {
  description = "Static private IP for ingress instance"
  type        = string
  default     = "10.0.1.10"
}

variable "ingress_shape_config" {
  description = "Shape configuration for ingress instance"
  type = object({
    ocpus         = number
    memory_in_gbs = number
  })
  default = {
    ocpus         = 1
    memory_in_gbs = 6
  }
}

# Server instance
variable "server_display_name" {
  description = "Display name for server instance"
  type        = string
  default     = "k3s-server"
}

variable "server_hostname_label" {
  description = "Hostname label for server instance"
  type        = string
  default     = "server"
}

variable "server_private_ip" {
  description = "Static private IP for server instance"
  type        = string
  default     = "10.0.2.10"
}

variable "server_shape_config" {
  description = "Shape configuration for server instance"
  type = object({
    ocpus         = number
    memory_in_gbs = number
  })
  default = {
    ocpus         = 2
    memory_in_gbs = 12
  }
}

# Worker instance
variable "worker_display_name" {
  description = "Display name for worker instance"
  type        = string
  default     = "k3s-worker"
}

variable "worker_hostname_label" {
  description = "Hostname label for worker instance"
  type        = string
  default     = "worker-1"
}

variable "worker_shape_config" {
  description = "Shape configuration for worker instance"
  type = object({
    ocpus         = number
    memory_in_gbs = number
  })
  default = {
    ocpus         = 1
    memory_in_gbs = 6
  }
}

variable "enable_worker" {
  description = "Enable worker instance"
  type        = bool
  default     = true
}

# K3s configuration
variable "k3s_version" {
  description = "K3s version to install"
  type        = string
  default     = "v1.28.5+k3s1"
}

variable "k3s_token" {
  description = "K3s cluster token"
  type        = string
  sensitive   = true
}

variable "initialization_method" {
  description = "Method for cluster initialization"
  type        = string
  default     = "cloud-init"
}

# Git configuration for registry
variable "git_pat" {
  description = "GitHub Personal Access Token for container registry"
  type        = string
  sensitive   = true
}

variable "git_username" {
  description = "GitHub username for container registry"
  type        = string
  default     = "git"
}

variable "git_repo_url" {
  description = "Git repository URL for ArgoCD bootstrap"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
