output "ingress_public_ip" {
  description = "Reserved public IP of the ingress instance"
  value       = module.cluster.ingress_public_ip
}

output "ingress_private_ip" {
  description = "Private IP of the ingress instance"
  value       = module.cluster.ingress_private_ip
}

output "server_private_ip" {
  description = "Private IP of the server instance"
  value       = module.cluster.server_private_ip
}

output "worker_private_ip" {
  description = "Private IP of the worker instance"
  value       = module.cluster.worker_private_ip
}

output "ssh_private_key_path" {
  description = "Derived SSH private key path"
  value       = module.cluster.ssh_private_key_path
}

output "ssh_jump_command" {
  description = "SSH to the jump host (ingress node)"
  value       = module.cluster.ssh_jump_command
}

output "ssh_jump_command_unsafe" {
  description = "SSH to the jump host — skips host-key check (use after rebuilds)"
  value       = module.cluster.ssh_jump_command_unsafe
}

output "ssh_controlplane_command" {
  description = "SSH to the K3s control-plane node via jump host"
  value       = module.cluster.ssh_controlplane_command
}

output "ssh_controlplane_command_unsafe" {
  description = "SSH to the K3s control-plane node via jump host — skips host-key checks on both hops (use after rebuilds)"
  value       = module.cluster.ssh_controlplane_command_unsafe
}

output "kubeconfig_command" {
  description = "Fetch k3s kubeconfig from control-plane"
  value       = module.cluster.kubeconfig_command
}

output "kubeconfig_command_unsafe" {
  description = "Fetch k3s kubeconfig — skips host-key checks on both hops (use after rebuilds)"
  value       = module.cluster.kubeconfig_command_unsafe
}
