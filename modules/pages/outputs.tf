output "project_subdomain" {
  description = "Cloudflare Pages auto-assigned subdomain (<name>.pages.dev)"
  value       = local.enabled ? cloudflare_pages_project.www[0].subdomain : null
}

output "project_domains" {
  description = "Custom domains attached to the Pages project"
  value       = { for k, v in cloudflare_pages_domain.custom : k => v.domain }
}
