# K3s Cluster Component
# Manages compute instances for K3s server, worker, and ingress nodes

variable "compartment_ocid" {
  description = "OCI Compartment OCID"
  type        = string
}

variable "availability_domain" {
  description = "Availability domain for instances (0-indexed)"
  type        = number
  default     = 0
}

variable "vcn_id" {
  description = "VCN OCID from networking component"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet OCID from networking component"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet OCID (created by this component)"
  type        = string
  default     = ""
}

variable "vcn_cidr_block" {
  description = "VCN CIDR block from networking component"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_security_list_id" {
  description = "Security list ID for private subnet"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH Public Key to use for instances"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ingress_private_ip" {
  description = "Static Private IP for the Ingress/NAT node"
  type        = string
  default     = "10.0.1.10"
}

variable "server_private_ip" {
  description = "Static Private IP for the K3s server node"
  type        = string
  default     = "10.0.2.10"
}

variable "k3s_token" {
  description = "Shared secret for K3s cluster authentication"
  type        = string
  sensitive   = true
}

variable "git_repo_url" {
  description = "Git repository URL for ArgoCD"
  type        = string
}

variable "git_pat" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "git_username" {
  description = "GitHub Username"
  type        = string
  default     = "git"
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token with Zone.DNS permissions"
  type        = string
  sensitive   = true
}

variable "common_tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

# Compute shape configuration for FREE TIER
variable "ingress_shape_config" {
  description = "Shape configuration for ingress node"
  type = object({
    ocpus         = number
    memory_in_gbs = number
  })
  default = {
    ocpus         = 1
    memory_in_gbs = 6
  }
}

variable "server_shape_config" {
  description = "Shape configuration for server node"
  type = object({
    ocpus         = number
    memory_in_gbs = number
  })
  default = {
    ocpus         = 2
    memory_in_gbs = 12
  }
}

variable "worker_shape_config" {
  description = "Shape configuration for worker node"
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
  description = "Whether to provision a worker node"
  type        = bool
  default     = true
}
