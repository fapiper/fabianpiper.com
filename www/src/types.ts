export type Site = {
  title: string
  description: string
  href: string
  author: string
  locale: string
  featuredProjectCount: number
  featuredPublicationCount: number
}

export type SocialLink = {
  href: string
  label: string
  icon?: string
}

export type IconMap = {
  [key: string]: string
}

export type ProjectLink = {
  label: string
  href: string
  icon?: string
}
