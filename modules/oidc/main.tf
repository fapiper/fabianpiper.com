locals {
  enabled = data.context_config.main.enabled
}

data "context_config" "main" {}

data "context_label" "main" {
  values = {
    name = "github-actions"
  }
}

data "context_tags" "main" {
  values = {
    name = "github-actions"
  }
}

# Create IAM policy for GitHub Actions user to access OCI Vault
# Note: OCI does not support OIDC federation with GitHub Actions
# Authentication is handled via API keys stored as GitHub Secrets
resource "oci_identity_policy" "github_actions" {
  count          = local.enabled ? 1 : 0
  compartment_id = var.compartment_ocid
  name           = data.context_label.main.rendered
  description    = "Allow GitHub Actions to access OCI Vault secrets"

  statements = [
    "Allow user ${var.user_ocid} to read secret-family in compartment id ${var.compartment_ocid}",
    "Allow user ${var.user_ocid} to use vaults in compartment id ${var.compartment_ocid}",
    "Allow user ${var.user_ocid} to use keys in compartment id ${var.compartment_ocid}",
    "Allow user ${var.user_ocid} to inspect compartments in compartment id ${var.compartment_ocid}"
  ]

  freeform_tags = data.context_tags.main.tags
}

