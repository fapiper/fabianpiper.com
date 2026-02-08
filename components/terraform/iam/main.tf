module "iam" {
  source = "../../../modules/iam"

  enabled          = var.enabled
  name             = var.name
  tenancy_ocid     = var.tenancy_ocid
  compartment_ocid = var.compartment_ocid
}
