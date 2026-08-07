import { glob } from "astro/loaders"
import { defineCollection, reference } from "astro:content"
import { z } from "astro/zod"

const authors = defineCollection({
  loader: glob({
    pattern: "**/[^_]*.md",
    base: "./src/content/authors",
  }),
  schema: z.object({
    name: z.string(),
    pronouns: z.string().optional(),
    avatar: z.url().or(z.string().startsWith("/")),
    bio: z.string().optional(),
    mail: z.email().optional(),
    socials: z.record(z.string(), z.url()).optional(),
  }),
})

const blog = defineCollection({
  loader: glob({
    pattern: "**/[^_]*.md",
    base: "./src/content/blog",
  }),
  schema: ({ image }) =>
    z.object({
      title: z.string(),
      description: z.string(),
      date: z.coerce.date(),
      order: z.number().optional(),
      tags: z.array(z.string()).optional(),
      authors: z.array(reference("authors")),
      image: image().optional(),
      draft: z.boolean().optional(),
    }),
})

const projects = defineCollection({
  loader: glob({ pattern: "**/[^_]*.md", base: "./src/content/projects" }),
  schema: ({ image }) =>
    z.object({
      name: z.string(),
      description: z.string(),
      tags: z.array(z.string()).optional(),
      image: image().optional(),
      date: z.coerce.date().optional(),
      links: z
        .array(
          z.object({
            label: z.string(),
            href: z.string().url(),
          }),
        )
        .optional(),
      featured: z.boolean().optional(),
      order: z.number().optional(),
    }),
})

const publications = defineCollection({
  loader: glob({
    pattern: "**/[^_]*.md",
    base: "./src/content/publications",
  }),
  schema: ({ image }) =>
    z.object({
      title: z.string(),
      authors: z.array(z.string()),
      published: z.boolean(),
      publishedIn: z
        .object({
          name: z.string(),
          url: z.string().url(),
        })
        .optional(),
      pdfUrl: z.string().url().optional(),
      htmlUrl: z.string().url().optional(),
      doi: z.string().optional(),
      paperType: z.enum(["Full paper", "Short paper"]),
      tags: z.array(z.string()).optional(),
      date: z.coerce.date().optional(),
      image: image().optional(),
      featured: z.boolean().optional(),
      order: z.number().optional(),
    }),
})

export const collections = { blog, authors, projects, publications }
