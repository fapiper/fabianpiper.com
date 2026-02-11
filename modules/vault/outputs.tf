output "name" {
  value       = join("", oci_kms_vault.default[*].display_name)
  description = "The name of the vault"
}

output "id" {
  value       = join("", oci_kms_vault.default[*].id)
  description = "The ID of the vault"
}

output "encryption_key_id" {
  value       = join("", oci_kms_key.default[*].id)
  description = "The ID of the encryption key"
}

output "git_username_secret_id" {
  value       = join("", oci_vault_secret.git_username[*].id)
  description = "The OCID of the git username secret"
}

output "git_pat_secret_id" {
  value       = join("", oci_vault_secret.git_pat[*].id)
  description = "The OCID of the GitHub PAT secret"
}

output "mixpanel_token_secret_id" {
  value       = join("", oci_vault_secret.mixpanel_token[*].id)
  description = "The OCID of the Mixpanel token secret"
}
