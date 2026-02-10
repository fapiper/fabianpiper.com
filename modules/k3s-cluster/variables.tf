variable "compartment_ocid" {
  description = "OCI Compartment OCID"
  type        = string
}

variable "availability_domain" {
  description = "Availability domain index (0-based)"
  type        = number
  default     = 0
}

variable "vcn_id" {
  description = "VCN OCID from networking component"
  type        = string
}

variable "vcn_cidr_block" {
  description = "VCN CIDR block"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet OCID from networking component"
  type        = string
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
  description = "Method for cluster initialization: cloud-init, ansible, or script"
  type        = string
  default     = "cloud-init"
  validation {
    condition     = contains(["cloud-init", "ansible", "script"], var.initialization_method)
    error_message = "initialization_method must be one of: cloud-init, ansible, script"
  }
}

variable "git_pat" {
  description = "GitHub Personal Access Token for container registry authentication"
  type        = string
  sensitive   = true
}

variable "git_username" {
  description = "GitHub username"
  type        = string
  default     = ""
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

variable "enabled" {
  description = "Enable or disable this component"
  type        = bool
  default     = true
}
