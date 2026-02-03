locals {
  enabled = var.enabled
  name    = var.name
}

# Dynamic Group for K3s Nodes
resource "oci_identity_dynamic_group" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = var.tenancy_ocid
  name           = "${local.name}-k3s-nodes"
  description    = "Dynamic group for K3s nodes to access OCI Vault"
  matching_rule  = "ALL {instance.compartment.id = '${var.compartment_ocid}'}"
}

# Policy for Vault Access
resource "oci_identity_policy" "default" {
  count = local.enabled ? 1 : 0

  compartment_id = var.compartment_ocid
  name           = "${local.name}-k3s-secrets-policy"
  description    = "Policy for K3s nodes to access OCI Vault secrets"

  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.default[0].name} to read secret-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.default[0].name} to use vaults in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.default[0].name} to use keys in compartment id ${var.compartment_ocid}"
  ]

  depends_on = [oci_identity_dynamic_group.default]
}
