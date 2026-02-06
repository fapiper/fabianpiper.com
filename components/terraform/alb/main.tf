module "alb" {
  source = "../../../modules/alb"

  compartment_ocid   = var.compartment_ocid
  name               = var.alb.name
  subnet_id          = module.vcn_reference.outputs.subnet_id
  ca_certificate     = var.alb.ca_certificate
  private_key_path   = var.dns_primary_private_key_path
  public_certificate = var.alb.public_certificate
}
