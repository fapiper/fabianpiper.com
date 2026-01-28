import type { IconMap, SocialLink, Site } from '@/types'

export const SITE: Site = {
  title: 'Fabian Piper',
  description:
    'astro-erudite is a opinionated, unstyled blogging template—built with Astro, Tailwind, and shadcn/ui.',
  href: 'https://glg.fabianpiper.com',
  author: 'fapiper',
  locale: 'en-US',
  featuredProjectCount: 4,
  featuredPublicationCount: 3,
  postsPerPage: 3,
}

export const NAV_LINKS: SocialLink[] = [
  {
    href: '/blog',
    label: 'projects',
  },
  {
    href: '/authors',
    label: 'publications',
  }
]

export const SOCIAL_LINKS: SocialLink[] = [
  {
    href: 'https://github.com/fapiper',
    label: 'GitHub',
  },
  {
    href: 'https://linkedin.com/in/fabian-piper',
    label: 'LinkedIn',
  },
  {
    href: 'mailto:hello@fabianpiper.com',
    label: 'Email',
  },
  {
    href: '/rss.xml',
    label: 'RSS',
  },
]

export const ICON_MAP: IconMap = {
  Website: 'lucide:globe',
  GitHub: 'lucide:github',
  LinkedIn: 'lucide:linkedin',
  Email: 'lucide:mail',
  RSS: 'lucide:rss',
}
