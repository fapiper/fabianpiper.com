import type { APIRoute } from "astro"

export const GET: APIRoute = ({ site, url }) => {
  const base = site ?? new URL(url.origin)
  const sitemap = new URL("sitemap-index.xml", base)
  return new Response(`User-agent: *\nAllow: /\n\nSitemap: ${sitemap.href}\n`)
}
