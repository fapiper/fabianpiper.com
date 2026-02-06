output "id" {
  value       = join("", oci_network_load_balancer_network_load_balancer.default[*].id)
  description = "The ID of the load balancer"
}

output "ip_addresses" {
  value = [
    for ip_address in flatten(oci_network_load_balancer_network_load_balancer.default[*].ip_addresses) :
    {
      ip_address = ip_address.ip_address
      public     = ip_address.is_public
    }
  ]
  description = "The IP addresses of the load balancer"
}
