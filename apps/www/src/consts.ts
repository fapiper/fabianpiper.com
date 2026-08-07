import type { SvgComponent } from "astro/types"
import Email from "@/assets/icons/email.svg"
import GitHub from "@/assets/icons/github.svg"
import Linkedin from "@/assets/icons/linkedin.svg"

export const SITE = {
  title: "Fabian Piper",
  description:
    "I'm a Software Engineer based in Berlin, Germany. Find a selection of my projects, contributions, and publications. Please feel free to reach out!",
  locale: "en-US",
  dir: "ltr",
  featuredProjectCount: 4,
  featuredPublicationCount: 3,
  pageSize: 6,
  defaultPageImage: "/static/opengraph-image.png",
  defaultPostImage: "/static/1200x630.png",
} as const

export const NAVIGATION = [
  {
    href: "/projects",
    label: "Projects",
  },
  {
    href: "/publications",
    label: "Publications",
  },
]

export const SOCIALS: { href: string; label: string; icon: SvgComponent }[] = [
  { href: "https://github.com/fapiper", label: "GitHub", icon: GitHub },
  {
    href: "https://linkedin.com/in/fabian-piper",
    label: "LinkedIn",
    icon: Linkedin,
  },
  { href: "mailto:hello@fabianpiper.com", label: "Email", icon: Email },
]
