output "load_balancer_ip" {
  description = "Public IP address of the network load balancer"
  value       = oci_network_load_balancer_network_load_balancer.k3s_nlb.ip_addresses[0].ip_address
}

output "load_balancer_id" {
  description = "OCID of the network load balancer"
  value       = oci_network_load_balancer_network_load_balancer.k3s_nlb.id
}
