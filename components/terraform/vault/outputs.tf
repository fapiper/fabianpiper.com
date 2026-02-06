output "name" {
  value       = module.vault.name
  description = "The name of the vault"
}

output "id" {
  value       = module.vault.id
  description = "The ID of the vault"
}

output "encryption_key_id" {
  value       = module.vault.encryption_key_id
  description = "The ID of the encryption key"
}
