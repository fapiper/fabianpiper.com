import type { IconMap, SocialLink, Site } from '@/types'

export const SITE: Site = {
  title: 'Fabian Piper',
  description:
    "I'm a Software Engineer and Researcher based in Berlin, Germany. Find a selection of my projects, contributions, and publications. Please feel free to reach out!",
  href: 'https://glg.fabianpiper.com',
  author: 'fapiper',
  locale: 'en-US',
  featuredProjectCount: 4,
  featuredPublicationCount: 3,
  pageSize: 6,
}

export const NAV_LINKS: SocialLink[] = [
  {
    href: '/projects',
    label: 'projects',
  },
  {
    href: '/publications',
    label: 'publications',
  },
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
]

export const ICON_MAP: IconMap = {
  Website: 'lucide:globe',
  GitHub: 'lucide:github',
  LinkedIn: 'lucide:linkedin',
  Email: 'lucide:mail',
}
