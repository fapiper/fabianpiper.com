output "user_id" {
  value       = join("", oci_identity_user.github_actions[*].id)
  description = "The OCID of the GitHub Actions IAM user"
}

output "user_name" {
  value       = join("", oci_identity_user.github_actions[*].name)
  description = "The name of the GitHub Actions IAM user"
}

output "group_id" {
  value       = join("", oci_identity_group.github_actions[*].id)
  description = "The OCID of the GitHub Actions IAM group"
}

output "policy_id" {
  value       = join("", oci_identity_policy.github_actions[*].id)
  description = "The OCID of the IAM policy for GitHub Actions"
}

output "policy_name" {
  value       = join("", oci_identity_policy.github_actions[*].name)
  description = "The name of the IAM policy for GitHub Actions"
}

