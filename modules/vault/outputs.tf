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
