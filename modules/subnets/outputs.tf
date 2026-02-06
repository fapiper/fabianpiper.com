output "id" {
  value       = join("", oci_core_subnet.default[*].id)
  description = "The ID of the subnet"
}

output "domain_name" {
  value       = join("", oci_core_subnet.default[*].subnet_domain_name)
  description = "The subnet's domain name, which consists of the subnet's DNS label, the VCN's DNS label, and the oraclevcn.com domain"
}
