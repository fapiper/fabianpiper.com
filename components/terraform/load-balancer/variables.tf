# Network Load Balancer Component
# Manages OCI Network Load Balancer for K3s ingress traffic

variable "compartment_ocid" {
  description = "OCI Compartment OCID"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet OCID where NLB will be created"
  type        = string
}

variable "ingress_instance_id" {
  description = "OCID of the ingress instance to use as backend"
  type        = string
}

variable "common_tags" {
  description = "Tags to be applied to all resources"
  type        = map(string)
  default     = {}
}
