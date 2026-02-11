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

# NOTE: OCI does not support OpenID Connect (OIDC) federation like AWS/Azure/GCP
# This module creates a service account approach instead for GitHub Actions
# GitHub Actions will use encrypted SOPS secrets containing minimal OCI credentials

# Create a dedicated IAM user for GitHub Actions
resource "oci_identity_user" "github_actions" {
  count          = local.enabled ? 1 : 0
  compartment_id = var.tenancy_ocid
  name           = data.context_label.main.rendered
  description    = "Service account for GitHub Actions CI/CD"
  freeform_tags  = data.context_tags.main.tags
}

# Create a group for GitHub Actions users
resource "oci_identity_group" "github_actions" {
  count          = local.enabled ? 1 : 0
  compartment_id = var.tenancy_ocid
  name           = "${data.context_label.main.rendered}-group"
  description    = "Group for GitHub Actions service accounts"
  freeform_tags  = data.context_tags.main.tags
}

# Add the user to the group
resource "oci_identity_user_group_membership" "github_actions" {
  count    = local.enabled ? 1 : 0
  user_id  = oci_identity_user.github_actions[0].id
  group_id = oci_identity_group.github_actions[0].id
}

# Policy for GitHub Actions to push to GHCR and read from Vault (minimal permissions)
resource "oci_identity_policy" "github_actions" {
  count          = local.enabled ? 1 : 0
  compartment_id = var.tenancy_ocid
  name           = data.context_label.main.rendered
  description    = "Allow GitHub Actions to read Vault secrets for GHCR authentication"

  statements = [
    # Read-only access to Vault secrets (for GHCR PAT)
    "Allow group ${oci_identity_group.github_actions[0].name} to read secret-family in tenancy",
    "Allow group ${oci_identity_group.github_actions[0].name} to read vaults in tenancy",
    "Allow group ${oci_identity_group.github_actions[0].name} to inspect keys in tenancy",
    # Inspect permissions for basic operations
    "Allow group ${oci_identity_group.github_actions[0].name} to inspect compartments in tenancy"
  ]

  freeform_tags = data.context_tags.main.tags
}

