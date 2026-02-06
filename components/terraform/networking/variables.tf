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

variable "vcn" {
  type = object({
    name                           = string
    ipv4_cidr_blocks               = list(string)
    dns_label                      = string
    default_security_list_deny_all = bool
    default_route_table_no_routes  = bool
    internet_gateway_enabled       = bool
  })
}

variable "subnets" {
  type = object({
    name                      = string
    ipv4_cidr_block           = string
    dns_label                 = string
    ssh_enabled               = bool
    https_enabled             = bool
    container_cluster_enabled = bool
    create_route_table        = bool
    route_table_enabled       = bool
  })
}
