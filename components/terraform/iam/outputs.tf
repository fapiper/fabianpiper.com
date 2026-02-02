output "dynamic_group_id" {
  // TODO required?
  description = "OCID of the nodes dynamic group"
  value       = oci_identity_dynamic_group.default.id
}

output "policy_id" {
  // TODO required?
  description = "OCID of the vault access policy"
  value       = oci_identity_policy.default.id
}