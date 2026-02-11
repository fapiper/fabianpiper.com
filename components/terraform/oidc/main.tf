module "oidc" {
  source = "../../../modules/oidc"

  tenancy_ocid     = var.tenancy_ocid
}