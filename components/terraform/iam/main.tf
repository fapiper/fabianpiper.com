resource "oci_identity_dynamic_group" "default" {
  compartment_id = var.compartment_ocid
  name           = "servers"
  description    = "Grouping all servers"
  matching_rule  = "ALL {instance.compartment.id = '${var.compartment_ocid}'}"
}

resource "oci_identity_policy" "default" {
  compartment_id = var.compartment_ocid
  name           = "cluster-state-mgmt"
  description    = "Cluster state management"
  statements = [
    "allow dynamic-group ${oci_identity_dynamic_group.default.name} to inspect vaults in compartment id ${var.compartment_ocid}",
    "allow dynamic-group ${oci_identity_dynamic_group.default.name} to inspect secrets in compartment id ${var.compartment_ocid}",
    "allow dynamic-group ${oci_identity_dynamic_group.default.name} to read secret-bundle in compartment id ${var.compartment_ocid}",
    "allow dynamic-group ${oci_identity_dynamic_group.default.name} to use secret in compartment id ${var.compartment_ocid}",
    "allow dynamic-group ${oci_identity_dynamic_group.default.name} to manage secret-versions in compartment id ${var.compartment_ocid}",
  ]
}
