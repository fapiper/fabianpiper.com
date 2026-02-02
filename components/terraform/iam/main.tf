resource "oci_identity_dynamic_group" "default" {
  // TODO compare
  compartment_id = var.compartment_ocid
  name           = "nodes"
  description    = "Dynamic group for all nodes to access OCI Vault"
  matching_rule  = "ALL {instance.compartment.id = '${var.compartment_ocid}'}"
}

resource "oci_identity_policy" "default" {
  // TODO compare
  compartment_id = var.compartment_ocid
  name           = "secrets-read-policy"
  description    = "Allow nodes to read secrets from Vault"
  statements = [
    "allow dynamic-group ${oci_identity_dynamic_group.default.name} to read secret-family in compartment id ${var.compartment_ocid}",
    "allow dynamic-group ${oci_identity_dynamic_group.default.name} to use vaults in compartment id ${var.compartment_ocid}",
  ]
}