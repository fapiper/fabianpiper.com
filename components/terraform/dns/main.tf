module "dns" {
  source = "../../../modules/dns"

  private            = var.dns.private
  compartment_ocid   = var.compartment_ocid
  name               = var.name
  ip_addresses       = local.ip_addresses
  domain_name        = var.dns.domain_name
  vcn_id             = module.vcn_reference.outputs.vcn_id
  subnet_domain_name = module.vcn_reference.outputs.subnet_domain_name
}
