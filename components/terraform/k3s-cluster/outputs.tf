output "ingress_public_ip" {
  description = "Public IP of the ingress instance"
  value       = module.k3s_cluster.ingress_public_ip
}

output "ingress_private_ip" {
  description = "Private IP of the ingress instance"
  value       = module.k3s_cluster.ingress_private_ip
}

output "server_private_ip" {
  description = "Private IP of the server instance"
  value       = module.k3s_cluster.server_private_ip
}

output "worker_private_ip" {
  description = "Private IP of the worker instance"
  value       = module.k3s_cluster.worker_private_ip
}

output "kubeconfig_command" {
  description = "Command to retrieve kubeconfig"
  value       = module.k3s_cluster.kubeconfig_command
}
