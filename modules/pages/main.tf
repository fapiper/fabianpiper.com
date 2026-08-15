locals {
  enabled = var.enabled
}

data "cloudflare_zone" "default" {
  count = local.enabled ? 1 : 0

  filter = {
    name = var.zone_name
  }
}

resource "cloudflare_pages_project" "www" {
  count = local.enabled ? 1 : 0

  account_id        = var.account_id
  name              = var.project_name
  production_branch = var.production_branch
}

resource "cloudflare_pages_domain" "custom" {
  for_each = local.enabled ? toset(var.domains) : toset([])

  account_id   = var.account_id
  project_name = cloudflare_pages_project.www[0].name
  name         = each.value

  depends_on = [cloudflare_pages_project.www]
}

# DNS records are not created automatically by cloudflare_pages_domain.
# Create proxied CNAME records pointing to the Pages subdomain.
# Cloudflare CNAME flattening handles the apex domain transparently.
resource "cloudflare_dns_record" "pages_cname" {
  for_each = local.enabled ? toset(var.domains) : toset([])

  zone_id = data.cloudflare_zone.default[0].id
  # Short name: "www" for www.example.com, zone name for apex
  name    = trimsuffix(each.value, ".${var.zone_name}") == each.value ? each.value : trimsuffix(each.value, ".${var.zone_name}")
  type    = "CNAME"
  content = cloudflare_pages_project.www[0].subdomain
  proxied = true
  ttl     = 1

  depends_on = [cloudflare_pages_project.www]
}
