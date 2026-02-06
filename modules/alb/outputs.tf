output "id" {
  value       = join("", oci_load_balancer_load_balancer.default[*].id)
  description = "The ID of the ALB"
}

output "ip_addresses" {
  value = [
    for ip_address_details in flatten(oci_load_balancer_load_balancer.default[*].ip_address_details) :
    {
      ip_address = ip_address_details.ip_address
      public     = ip_address_details.is_public
    }
  ]
  description = "The IP addresses of the ALB"
}

output "certificate_name" {
  value       = join("", oci_load_balancer_certificate.default[*].certificate_name)
  description = "The name of the certificate"
}
