module "oidc" {
  source = "../../../modules/oidc"

  tenancy_ocid     = var.tenancy_ocid
  compartment_ocid = var.compartment_ocid
  user_ocid        = var.user_ocid
}

