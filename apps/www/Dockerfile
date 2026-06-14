# syntax=docker/dockerfile:1.4

# Build on native CI platform (x86_64) to avoid QEMU emulation for bun install/build.
# The dist/ output is static files (HTML/CSS/JS) and therefore platform-agnostic.
FROM --platform=$BUILDPLATFORM oven/bun:1 AS builder
WORKDIR /app
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

COPY package.json bun.lock ./
RUN bun install

COPY . .

RUN --mount=type=secret,id=secrets \
    set -a && \
    . /run/secrets/secrets && \
    set +a && \
    PUBLIC_MIXPANEL_TOKEN="${MIXPANEL_TOKEN:-}" \
    PUBLIC_SITE_URL="${SITE_URL:-}" \
    bun run build

FROM nginxinc/nginx-unprivileged:1.27-alpine

COPY --from=builder --chown=nginx:nginx /app/dist /usr/share/nginx/html

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
