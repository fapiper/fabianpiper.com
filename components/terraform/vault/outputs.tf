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

output "git_username_secret_id" {
  value       = module.vault.git_username_secret_id
  description = "The OCID of the git username secret"
}

output "git_pat_secret_id" {
  value       = module.vault.git_pat_secret_id
  description = "The OCID of the GitHub PAT secret"
}

output "mixpanel_token_secret_id" {
  value       = module.vault.mixpanel_token_secret_id
  description = "The OCID of the Mixpanel token secret"
}
