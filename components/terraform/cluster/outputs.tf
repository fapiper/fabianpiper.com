output "ingress_public_ip" {
  description = "Public IP of the ingress instance"
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

output "kubeconfig_command" {
  description = "Command to retrieve kubeconfig"
  value       = module.cluster.kubeconfig_command
}
