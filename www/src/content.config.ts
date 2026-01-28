import { glob } from 'astro/loaders'
import { defineCollection, z } from 'astro:content'

const blog = defineCollection({
  loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/blog' }),
  schema: ({ image }) =>
    z.object({
      title: z.string(),
      description: z.string(),
      date: z.coerce.date(),
      order: z.number().optional(),
      image: image().optional(),
      tags: z.array(z.string()).optional(),
      authors: z.array(z.string()).optional(),
      draft: z.boolean().optional(),
    }),
})

const authors = defineCollection({
  loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/authors' }),
  schema: z.object({
    name: z.string(),
    pronouns: z.string().optional(),
    avatar: z.string().url().or(z.string().startsWith('/')),
    bio: z.string().optional(),
    mail: z.string().email().optional(),
    website: z.string().url().optional(),
    twitter: z.string().url().optional(),
    github: z.string().url().optional(),
    linkedin: z.string().url().optional(),
    discord: z.string().url().optional(),
  }),
})

const projects = defineCollection({
  loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/projects' }),
  schema: ({ image }) =>
    z.object({
      name: z.string(),
      description: z.string(),
      tags: z.array(z.string()).optional(),
      image: image().optional(),
      links: z
        .array(
          z.object({
            label: z.string(),
            href: z.string().url(),
          }),
        )
        .optional(),
      featured: z.boolean().optional(),
    }),
})

const publications = defineCollection({
  loader: glob({
    pattern: '**/*.{md,mdx}',
    base: './src/content/publications',
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
      paperType: z.enum(['Full paper', 'Short paper']),
      date: z.coerce.date().optional(),
      image: image().optional(),
      featured: z.boolean().optional(),
    }),
})

export const collections = { blog, authors, projects, publications }
