output "dynamic_group_id" {
  description = "OCID of the dynamic group"
  value       = module.iam.dynamic_group_id
}

output "dynamic_group_name" {
  description = "Name of the dynamic group"
  value       = module.iam.dynamic_group_name
}

output "policy_id" {
  description = "OCID of the policy"
  value       = module.iam.policy_id
}
