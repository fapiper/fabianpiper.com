output "id" {
  value       = module.alb.id
  description = "The ID of the ALB"
}

output "ip_addresses" {
  value       = module.alb.ip_addresses
  description = "The IP addresses of the ALB"
}

output "certificate_name" {
  value       = module.alb.certificate_name
  description = "The name of the certificate"
}
