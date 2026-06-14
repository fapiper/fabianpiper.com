# Cluster Component - Outputs

output "ingress_instance_id" {
  description = "OCID of the ingress instance"
  value       = var.enabled ? oci_core_instance.ingress[0].id : null
}

output "ingress_public_ip" {
  description = "Reserved public IP of the ingress instance"
  value       = var.enabled ? oci_core_public_ip.ingress_reserved[0].ip_address : null
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

locals {
  ssh_private_key_path = trimsuffix(var.ssh_public_key_path, ".pub")
  ingress_ip           = var.enabled ? oci_core_public_ip.ingress_reserved[0].ip_address : null
  unsafe_opts          = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
  ssh_jump             = var.enabled ? "ssh -i ${local.ssh_private_key_path} ubuntu@${local.ingress_ip}" : null
  ssh_jump_unsafe      = var.enabled ? "ssh -i ${local.ssh_private_key_path} ${local.unsafe_opts} ubuntu@${local.ingress_ip}" : null
}

output "ssh_private_key_path" {
  description = "Derived SSH private key path (ssh_public_key_path without .pub)"
  value       = local.ssh_private_key_path
}

output "ssh_jump_command" {
  description = "SSH to the jump host (ingress node)"
  value       = var.enabled ? local.ssh_jump : null
}

output "ssh_jump_command_unsafe" {
  description = "SSH to the jump host — skips host-key check (use after rebuilds)"
  value       = var.enabled ? local.ssh_jump_unsafe : null
}

output "ssh_controlplane_command" {
  description = "SSH to the K3s control-plane node via jump host"
  value       = var.enabled ? "ssh -i ${local.ssh_private_key_path} -J ubuntu@${local.ingress_ip} ubuntu@${var.server_private_ip}" : null
}

output "ssh_controlplane_command_unsafe" {
  description = "SSH to the K3s control-plane node via jump host — skips host-key checks on both hops (use after rebuilds)"
  value       = var.enabled ? "ssh -i ${local.ssh_private_key_path} ${local.unsafe_opts} -J ubuntu@${local.ingress_ip} ubuntu@${var.server_private_ip}" : null
}

output "kubeconfig_command" {
  description = "Fetch k3s kubeconfig from control-plane — pipe to kubeconfig-prod.yaml, then sed 127.0.0.1 → 10.0.2.10"
  value       = var.enabled ? "${local.ssh_jump} 'ssh ubuntu@${var.server_private_ip} sudo cat /etc/rancher/k3s/k3s.yaml'" : null
}

output "kubeconfig_command_unsafe" {
  description = "Fetch k3s kubeconfig — skips host-key checks on both hops (use after rebuilds)"
  value       = var.enabled ? "${local.ssh_jump_unsafe} 'ssh ${local.unsafe_opts} ubuntu@${var.server_private_ip} sudo cat /etc/rancher/k3s/k3s.yaml'" : null
}
