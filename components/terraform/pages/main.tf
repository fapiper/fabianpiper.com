module "pages" {
  source = "../../../modules/pages"

  enabled           = var.enabled
  account_id        = var.cloudflare_account_id
  zone_name         = var.zone_name
  project_name      = var.project_name
  production_branch = var.production_branch
  domains           = var.domains
}
