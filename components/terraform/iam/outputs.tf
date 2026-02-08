output "dynamic_group_id" {
  description = "OCID of the dynamic group"
  value       = oci_identity_dynamic_group.default.id
}

output "dynamic_group_name" {
  description = "Name of the dynamic group"
  value       = oci_identity_dynamic_group.default.name
}

output "policy_id" {
  description = "OCID of the policy"
  value       = oci_identity_policy.default.id
}
