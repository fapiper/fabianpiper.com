# OCI KMS Vault
resource "oci_kms_vault" "default" {
  count          = var.enabled ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = var.vault_name
  vault_type     = var.vault_type
}

# Master Encryption Key
resource "oci_kms_key" "default" {
  count               = var.enabled ? 1 : 0
  compartment_id      = var.compartment_ocid
  display_name        = var.master_key_name
  management_endpoint = oci_kms_vault.default[0].management_endpoint
  protection_mode     = var.master_key_protection_mode

  key_shape {
    algorithm = var.master_key_algorithm
    length    = var.master_key_length
  }
}

# Dynamic Secret Provisioning
resource "oci_vault_secret" "this" {
  for_each = var.enabled ? { for s in var.secrets_config : s.name => s } : {}

  compartment_id = var.compartment_ocid
  vault_id       = oci_kms_vault.default[0].id
  key_id         = oci_kms_key.default[0].id
  secret_name    = each.key # 'each.key' is the string name (e.g. "github-pat")
  description    = lookup(each.value, "description", "Managed by Atmos/Terraform")

  secret_content {
    content_type = "BASE64"

    # We use a placeholder or the actual value from Atmos vars
    content = base64encode(
      lookup(var.secret_values, each.key, "placeholder-update-me")
    )
  }

  lifecycle {
    # This prevents Terraform from overwriting the secret value if we
    # update it manually in the OCI Console or via another method
    ignore_changes = [secret_content]
  }
}