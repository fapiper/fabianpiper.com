output "zone_id" {
  description = "Cloudflare zone ID (resolved from zone_name)"
  value       = local.enabled ? data.cloudflare_zone.default[0].id : null
}

output "record_ids" {
  description = "Map of DNS record names to their Cloudflare record IDs"
  value       = { for k, v in cloudflare_dns_record.a : k => v.id }
}

output "record_hostnames" {
  description = "Map of DNS record names to their fully qualified hostnames"
  value       = { for k, v in cloudflare_dns_record.a : k => v.name }
}
