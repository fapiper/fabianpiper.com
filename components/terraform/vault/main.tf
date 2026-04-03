module "vault" {
  source = "../../../modules/vault"

  compartment_ocid       = var.compartment_ocid
  name                   = var.name
  git_username           = var.git_username
  git_pat                = var.git_pat
  mixpanel_token         = var.mixpanel_token
  site_url               = var.site_url
  cloudflare_api_token   = var.cloudflare_api_token
  grafana_admin_password = var.grafana_admin_password
}
