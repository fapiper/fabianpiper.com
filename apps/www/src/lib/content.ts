import { SITE } from "@/consts"
import { getCollection, type CollectionEntry } from "astro:content"
import { isSubpost } from "@/lib/utils"

export const pageTitle = (title: string) => `${title} | ${SITE.title}`

export async function getPosts(): Promise<CollectionEntry<"blog">[]> {
  const posts = await getCollection("blog", ({ data }) => !data.draft)
  return posts
    .filter((post) => !isSubpost(post.id))
    .sort((a, b) => b.data.date.getTime() - a.data.date.getTime())
}

export async function getSubposts(): Promise<
  Map<string, CollectionEntry<"blog">[]>
> {
  const posts = await getCollection(
    "blog",
    ({ id, data }) => !data.draft && id.split("/").length === 2,
  )
  posts.sort(
    (a, b) =>
      (a.data.order ?? Infinity) - (b.data.order ?? Infinity) ||
      a.data.date.getTime() - b.data.date.getTime(),
  )
  return Map.groupBy(posts, (post) => post.id.split("/")[0])
}

export async function getTags(): Promise<
  Map<string, CollectionEntry<"blog">[]>
> {
  const posts = await getPosts()
  const series = await getSubposts()
  const tags = new Map<string, CollectionEntry<"blog">[]>()
  for (const post of posts) {
    const chain = [post, ...(series.get(post.id) ?? [])]
    for (const tag of new Set(
      chain.flatMap((entry) => entry.data.tags ?? []),
    )) {
      const tagged = tags.get(tag)
      if (tagged) tagged.push(post)
      else tags.set(tag, [post])
    }
  }
  return new Map(
    [...tags].sort(
      ([a, postsA], [b, postsB]) =>
        postsB.length - postsA.length || a.localeCompare(b),
    ),
  )
}

export async function getFeaturedProjects(): Promise<
  CollectionEntry<"projects">[]
> {
  const projects = await getProjects()
  return projects.filter((project) => project.data.featured)
}

export async function getPublications(): Promise<
  CollectionEntry<"publications">[]
> {
  const publications = await getCollection("publications")
  const sorted = publications.sort((a, b) => {
    const dateA = a.data.date?.getTime() || 0
    const dateB = b.data.date?.getTime() || 0
    return dateB - dateA
  })

  const withOrder = sorted
    .filter((p) => p.data.order !== undefined)
    .sort((a, b) => a.data.order! - b.data.order!)

  const withoutOrder = sorted.filter((p) => p.data.order === undefined)

  withOrder.forEach((pub) => {
    withoutOrder.splice(pub.data.order!, 0, pub)
  })

  return withoutOrder
}

export async function getProjects(): Promise<CollectionEntry<"projects">[]> {
  const projects = await getCollection("projects")

  const sorted = projects.sort((a, b) => {
    const dateA = a.data.date?.getTime() || 0
    const dateB = b.data.date?.getTime() || 0
    return dateB - dateA
  })

  const withOrder = sorted
    .filter((p) => p.data.order !== undefined)
    .sort((a, b) => a.data.order! - b.data.order!)

  const withoutOrder = sorted.filter((p) => p.data.order === undefined)

  withOrder.forEach((project) => {
    withoutOrder.splice(project.data.order!, 0, project)
  })

  return withoutOrder
}
