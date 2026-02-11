output "policy_id" {
  value       = module.oidc.policy_id
  description = "The OCID of the IAM policy for GitHub Actions"
}

output "policy_name" {
  value       = module.oidc.policy_name
  description = "The name of the IAM policy for GitHub Actions"
}

