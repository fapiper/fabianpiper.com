module "oidc" {
  source = "../../../modules/oidc"

  tenancy_ocid = var.tenancy_ocid
  name         = var.name
  git_email    = var.git_email
}