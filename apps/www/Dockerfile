# syntax=docker/dockerfile:1.4

FROM oven/bun:1 AS builder
WORKDIR /app

COPY package.json bun.lock ./
RUN bun install

COPY . .

RUN --mount=type=secret,id=MIXPANEL_TOKEN \
    --mount=type=secret,id=SITE_URL \
    PUBLIC_MIXPANEL_TOKEN=$(cat /run/secrets/MIXPANEL_TOKEN) \
    PUBLIC_SITE_URL=$(cat /run/secrets/SITE_URL) \
    bun run build

FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]