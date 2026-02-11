module "vault" {
  source = "../../../modules/vault"

  compartment_ocid = var.compartment_ocid
  name             = var.name
  git_username     = var.git_username
  git_pat          = var.git_pat
  mixpanel_token   = var.mixpanel_token
}
