# Load Balancer Component - Outputs

output "nlb_id" {
  description = "OCID of the Network Load Balancer"
  value       = var.enabled ? oci_network_load_balancer_network_load_balancer.k3s_nlb[0].id : null
}

output "nlb_ip_addresses" {
  description = "IP addresses of the Network Load Balancer"
  value       = var.enabled ? oci_network_load_balancer_network_load_balancer.k3s_nlb[0].ip_addresses : null
}

output "nlb_public_ip" {
  description = "Primary public IP of the Network Load Balancer"
  value       = var.enabled ? oci_network_load_balancer_network_load_balancer.k3s_nlb[0].ip_addresses[0].ip_address : null
}
