output "name" {
  value       = join("", oci_vault_secret.default[*].secret_name)
  description = "The name of the vault"
}
