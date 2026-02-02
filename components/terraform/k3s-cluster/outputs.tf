output "ingress_public_ip" {
  description = "Public IP of the ingress/NAT instance"
  value       = oci_core_instance.ingress.public_ip
}

output "ingress_instance_id" {
  description = "OCID of the ingress instance"
  value       = oci_core_instance.ingress.id
}

output "ingress_private_ip" {
  description = "Private IP of the ingress instance"
  value       = oci_core_instance.ingress.private_ip
}

output "server_private_ip" {
  description = "Private IP of the K3s server instance"
  value       = oci_core_instance.server.private_ip
}

output "worker_private_ip" {
  description = "Private IP of the K3s worker instance"
  value       = var.enable_worker ? oci_core_instance.worker[0].private_ip : null
}

output "private_subnet_id" {
  description = "OCID of the private subnet"
  value       = oci_core_subnet.private_subnet.id
}

output "kubeconfig_command" {
  description = "Command to retrieve kubeconfig"
  value       = "ssh ubuntu@${oci_core_instance.ingress.public_ip} 'ssh ubuntu@${var.server_private_ip} sudo cat /etc/rancher/k3s/k3s.yaml'"
}
