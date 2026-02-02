module "vault" {
  source = "../../../modules/vault"

  enabled                    = var.enabled
  compartment_ocid           = var.compartment_ocid
  vault_name                 = var.vault_name
  vault_type                 = var.vault_type
  master_key_name            = var.master_key_name
  master_key_algorithm       = var.master_key_algorithm
  master_key_length          = var.master_key_length
  master_key_protection_mode = var.master_key_protection_mode

  # The list of names from the catalog
  secrets_config             = var.secrets

  # The actual sensitive values from our SOPS-encrypted stacks
  secret_values              = var.secret_values
}