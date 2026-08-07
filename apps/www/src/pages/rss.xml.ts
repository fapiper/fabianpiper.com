import { SITE } from "@/consts"
import { getProjects } from "@/lib/content"
import rss from "@astrojs/rss"
import type { APIContext } from "astro"

export async function GET(context: APIContext) {
  const projects = await getProjects()
  return rss({
    title: SITE.title,
    description: SITE.description,
    site: context.site!,
    items: projects.map((project) => ({
      title: project.data.name,
      description: project.data.description,
      pubDate: project.data.date,
      link: `/projects/${project.id}`,
    })),
  })
}
