module "networking" {
  source = "../../../modules/networking"

  compartment_ocid       = var.compartment_ocid
  name                   = var.name
  vcn_cidr_block         = var.vcn_cidr_block
  vcn_dns_label          = var.vcn_dns_label
  public_subnet_cidr     = var.public_subnet_cidr
  public_subnet_dns_label = var.public_subnet_dns_label
  ssh_source_cidr        = var.ssh_source_cidr
  enabled                = var.enabled
}
