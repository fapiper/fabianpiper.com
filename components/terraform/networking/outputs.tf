output "vcn_id" {
  value       = module.networking.vcn_id
  description = "The ID of the VCN"
}

output "subnet_id" {
  value       = module.networking.subnet_id
  description = "The ID of the subnet"
}

output "subnet_domain_name" {
  value       = module.networking.subnet_domain_name
  description = "The subnet's domain name, which consists of the subnet's DNS label, the VCN's DNS label, and the oraclevcn.com domain"
}
