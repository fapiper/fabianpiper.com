module "vault" {
  source = "../../../modules/vault"

  compartment_ocid = var.compartment_ocid
  name             = var.name
}
