output "vcn_id" {
  description = "VCN OCID"
  value       = try(oci_core_vcn.default[0].id, null)
}

output "vcn_cidr_blocks" {
  description = "VCN CIDR blocks"
  value       = try(oci_core_vcn.default[0].cidr_blocks, [])
}

output "subnet_id" {
  description = "Subnet OCID"
  value       = try(oci_core_subnet.default[0].id, null)
}

output "subnet_domain_name" {
  description = "Subnet domain name"
  value       = try(oci_core_subnet.default[0].subnet_domain_name, null)
}

output "internet_gateway_id" {
  description = "Internet Gateway OCID"
  value       = try(oci_core_internet_gateway.default[0].id, null)
}

