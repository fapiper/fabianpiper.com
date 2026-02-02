output "vcn_id" {
  description = "OCID of the VCN"
  value       = oci_core_vcn.k3s_vcn.id
}

output "vcn_cidr_block" {
  description = "CIDR block of the VCN"
  value       = oci_core_vcn.k3s_vcn.cidr_block
}

output "public_subnet_id" {
  description = "OCID of the public subnet"
  value       = oci_core_subnet.public_subnet.id
}

output "public_subnet_cidr" {
  description = "CIDR block of the public subnet"
  value       = oci_core_subnet.public_subnet.cidr_block
}

output "internet_gateway_id" {
  description = "OCID of the Internet Gateway"
  value       = oci_core_internet_gateway.igw.id
}

output "private_security_list_id" {
  description = "OCID of the private security list"
  value       = oci_core_security_list.private_sl.id
}
