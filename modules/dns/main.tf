locals {
  # Skip record creation if cluster hasn't been applied yet (empty ingress_ip)
  enabled     = var.enabled && var.ingress_ip != ""
  records_map = local.enabled ? { for r in var.records : r.name => r } : {}
}

resource "cloudflare_dns_record" "a" {
  for_each = local.records_map

  zone_id = var.zone_id
  name    = each.value.name
  type    = "A"
  content = var.ingress_ip
  proxied = each.value.proxied
  # ttl is required in v5; 1 = automatic (required when proxied=true)
  ttl = each.value.proxied ? 1 : each.value.ttl
}
