# Cluster Component - Outputs

output "ingress_instance_id" {
  description = "OCID of the ingress instance"
  value       = var.enabled ? oci_core_instance.ingress[0].id : null
}

output "ingress_public_ip" {
  description = "Public IP of the ingress instance"
  value       = var.enabled ? oci_core_instance.ingress[0].public_ip : null
}

output "ingress_private_ip" {
  description = "Private IP of the ingress instance"
  value       = var.enabled ? oci_core_instance.ingress[0].private_ip : null
}

output "server_instance_id" {
  description = "OCID of the server instance"
  value       = var.enabled ? oci_core_instance.server[0].id : null
}

output "server_private_ip" {
  description = "Private IP of the server instance"
  value       = var.enabled ? oci_core_instance.server[0].private_ip : null
}

output "worker_instance_id" {
  description = "OCID of the worker instance"
  value       = var.enabled && var.enable_worker ? oci_core_instance.worker[0].id : null
}

output "worker_private_ip" {
  description = "Private IP of the worker instance"
  value       = var.enabled && var.enable_worker ? oci_core_instance.worker[0].private_ip : null
}

output "private_subnet_id" {
  description = "OCID of the private subnet"
  value       = var.enabled ? oci_core_subnet.private_subnet[0].id : null
}

output "kubeconfig_command" {
  description = "Command to retrieve kubeconfig"
  value       = var.enabled ? "ssh -i ~/.ssh/id_rsa ubuntu@${oci_core_instance.ingress[0].public_ip} 'ssh ubuntu@${var.server_private_ip} sudo cat /etc/rancher/k3s/k3s.yaml'" : null
}
