# OCI IAM Module - Outputs

output "dynamic_group_id" {
  description = "OCID of the dynamic group"
  value       = try(oci_identity_dynamic_group.default[0].id, null)
}

output "dynamic_group_name" {
  description = "Name of the dynamic group"
  value       = try(oci_identity_dynamic_group.default[0].name, null)
}

output "policy_id" {
  description = "OCID of the policy"
  value       = try(oci_identity_policy.default[0].id, null)
}
