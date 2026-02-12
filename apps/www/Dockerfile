# syntax=docker/dockerfile:1.4

FROM oven/bun:1 AS builder
WORKDIR /app

COPY package.json bun.lock ./
RUN bun install

COPY . .

RUN --mount=type=secret,id=secrets \
    set -euo pipefail && \
    set -a && \
    . /run/secrets/secrets && \
    set +a && \
    PUBLIC_MIXPANEL_TOKEN="$MIXPANEL_TOKEN" \
    PUBLIC_SITE_URL="$SITE_URL" \
    bun run build

FROM nginx:alpine

RUN chown -R nginx:nginx /usr/share/nginx/html
COPY --from=builder --chown=nginx:nginx /app/dist /usr/share/nginx/html
USER nginx

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]