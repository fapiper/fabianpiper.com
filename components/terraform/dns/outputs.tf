output "zone_id" {
  description = "Cloudflare zone ID"
  value       = module.dns.zone_id
}

output "record_ids" {
  description = "Map of DNS record names to their Cloudflare record IDs"
  value       = module.dns.record_ids
}

output "record_hostnames" {
  description = "Map of DNS record names to their fully qualified hostnames"
  value       = module.dns.record_hostnames
}

