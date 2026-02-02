module "iam" {
  source = "../../../modules/iam"

  compartment_ocid = var.compartment_ocid
  tenancy_ocid     = var.tenancy_ocid
  name             = var.name
  enabled          = var.enabled
}
