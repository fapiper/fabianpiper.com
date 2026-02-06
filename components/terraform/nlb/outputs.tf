output "id" {
  value       = module.nlb.id
  description = "The ID of the load balancer"
}

output "ip_addresses" {
  value       = module.nlb.ip_addresses
  description = "The IP addresses of the load balancer"
}
