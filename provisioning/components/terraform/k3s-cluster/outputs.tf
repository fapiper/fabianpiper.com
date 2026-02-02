output "server_public_ip" {
  description = "Public IP of the K3s server"
  value       = module.k3s_cluster.server_public_ip
}

output "server_private_ip" {
  description = "Private IP of the K3s server"
  value       = module.k3s_cluster.server_private_ip
}

output "kubeconfig" {
  description = "Kubeconfig for accessing the K3s cluster"
  value       = module.k3s_cluster.kubeconfig
  sensitive   = true
}
