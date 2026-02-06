module "vcn" {
  source = "../../../modules/vcn"

  compartment_ocid               = var.compartment_ocid
  name                           = var.vcn.name
  ipv4_cidr_blocks               = var.vcn.ipv4_cidr_blocks
  dns_label                      = var.vcn.dns_label
  default_security_list_deny_all = var.vcn.default_security_list_deny_all
  default_route_table_no_routes  = var.vcn.default_route_table_no_routes
  internet_gateway_enabled       = var.vcn.internet_gateway_enabled
}

module "subnets" {
  source = "../../../modules/subnets"

  compartment_ocid          = var.compartment_ocid
  name                      = var.subnets.name
  vcn_id                    = module.vcn.id
  igw_id                    = module.vcn.igw_id
  default_security_list_id  = module.vcn.default_security_list_id
  ipv4_cidr_block           = var.subnets.ipv4_cidr_block
  dns_label                 = var.subnets.dns_label
  ssh_enabled               = var.subnets.ssh_enabled
  https_enabled             = var.subnets.https_enabled
  container_cluster_enabled = var.subnets.container_cluster_enabled
  create_route_table        = var.subnets.create_route_table
  route_table_enabled       = var.subnets.route_table_enabled
}
