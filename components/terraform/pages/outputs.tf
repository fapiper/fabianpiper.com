output "project_subdomain" {
  description = "Cloudflare Pages auto-assigned subdomain (<name>.pages.dev)"
  value       = module.pages.project_subdomain
}

output "project_domains" {
  description = "Custom domains attached to the Pages project"
  value       = module.pages.project_domains
}
