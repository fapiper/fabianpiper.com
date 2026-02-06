output "access_key_id" {
  value       = join("", oci_identity_customer_secret_key.default[*].id)
  description = "The access key ID"
}

output "secret_access_key" {
  value       = join("", oci_identity_customer_secret_key.default[*].key)
  description = "The secret access key"
  sensitive   = true
}
