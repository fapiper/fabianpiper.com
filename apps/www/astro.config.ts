import { defineConfig } from "astro/config"
import sitemap from "@astrojs/sitemap"
import { satteri } from "@astrojs/markdown-satteri"
import {
  blockExpressiveCode,
  inlineExpressiveCode,
} from "./src/lib/expressive-code"
import { temmlMath } from "./src/lib/math"
import { calloutDirective } from "./src/lib/callout"
import { externalLinks } from "./src/lib/external-links"
import { headingNamespace } from "./src/lib/heading-namespace"
import { headingAnchors } from "./src/lib/heading-anchors"
import mixpanel from "astrojs-mixpanel"
import { loadEnv } from "vite"

const { PUBLIC_MIXPANEL_TOKEN, PUBLIC_SITE_URL } = loadEnv(
  process.env.NODE_ENV!,
  process.cwd(),
  "",
)

export default defineConfig({
  site: PUBLIC_SITE_URL,
  compressHTML: true,
  prefetch: { prefetchAll: true },
  integrations: [
    sitemap({
      filter: (page) =>
        !/\/projects\/[^/]+\/[^/]+\/?$/.test(page) &&
        !/\/publications\/[^/]+\/[^/]+\/?$/.test(page) &&
        !/\/blog\/[^/]+\/[^/]+\/?$/.test(page) &&
        !/\/authors\/[^/]+\/?$/.test(page) &&
        !page.includes("/tags/"),
    }),
    ...(PUBLIC_MIXPANEL_TOKEN
      ? [
          mixpanel({
            token: PUBLIC_MIXPANEL_TOKEN,
            config: {
              api_host: "https://api-eu.mixpanel.com",
            },
            autoTrack: true,
          }),
        ]
      : []),
  ],
  markdown: {
    syntaxHighlight: false,
    processor: satteri({
      features: { directive: true, math: true },
      mdastPlugins: [calloutDirective, inlineExpressiveCode, temmlMath],
      hastPlugins: [
        externalLinks,
        blockExpressiveCode,
        headingNamespace,
        headingAnchors,
      ],
    }),
  },
})
