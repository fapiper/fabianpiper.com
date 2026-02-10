module "networking" {
  source = "../../../modules/networking"

  compartment_ocid  = var.compartment_ocid
  vcn_cidr_blocks   = var.vcn_cidr_blocks
  vcn_dns_label     = var.vcn_dns_label
  subnet_name       = var.subnet_name
  subnet_cidr_block = var.subnet_cidr_block
  subnet_dns_label  = var.subnet_dns_label
}
