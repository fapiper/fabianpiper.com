# OCI Networking Module - Outputs

output "vcn_id" {
  description = "OCID of the VCN"
  value       = try(oci_core_vcn.default[0].id, null)
}

output "vcn_cidr_block" {
  description = "CIDR block of the VCN"
  value       = try(oci_core_vcn.default[0].cidr_block, null)
}

output "public_subnet_id" {
  description = "OCID of the public subnet"
  value       = try(oci_core_subnet.public[0].id, null)
}

output "public_subnet_cidr" {
  description = "CIDR block of the public subnet"
  value       = try(oci_core_subnet.public[0].cidr_block, null)
}

output "internet_gateway_id" {
  description = "OCID of the Internet Gateway"
  value       = try(oci_core_internet_gateway.default[0].id, null)
}

output "public_route_table_id" {
  description = "OCID of the public route table"
  value       = try(oci_core_route_table.public[0].id, null)
}
