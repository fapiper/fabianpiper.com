output "vcn_id" {
  description = "OCID of the VCN"
  value       = module.networking.vcn_id
}

output "vcn_cidr_block" {
  description = "CIDR block of the VCN"
  value       = module.networking.vcn_cidr_block
}

output "public_subnet_id" {
  description = "OCID of the public subnet"
  value       = module.networking.public_subnet_id
}

output "public_subnet_cidr" {
  description = "CIDR block of the public subnet"
  value       = module.networking.public_subnet_cidr
}

output "internet_gateway_id" {
  description = "OCID of the Internet Gateway"
  value       = module.networking.internet_gateway_id
}

output "public_route_table_id" {
  description = "OCID of the public route table"
  value       = module.networking.public_route_table_id
}
