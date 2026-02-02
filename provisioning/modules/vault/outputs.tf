output "vault_id" {
  value = try(oci_kms_vault.default[0].id, null)
}

output "management_endpoint" {
  value = try(oci_kms_vault.default[0].management_endpoint, null)
}

output "crypto_endpoint" {
  value = try(oci_kms_vault.default[0].crypto_endpoint, null)
}

output "key_id" {
  value = try(oci_kms_key.default[0].id, null)
}

output "secret_ids" {
  description = "Map of secret names to their OCI OCIDs"
  value       = { for k, v in oci_vault_secret.this : k => v.id }
}