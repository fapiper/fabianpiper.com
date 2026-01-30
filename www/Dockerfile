FROM oven/bun:1 AS builder
WORKDIR /app

ARG PUBLIC_MIXPANEL_TOKEN
ARG PUBLIC_SITE_URL

ENV PUBLIC_MIXPANEL_TOKEN=$PUBLIC_MIXPANEL_TOKEN
ENV PUBLIC_SITE_URL=$PUBLIC_SITE_URL

COPY package.json .
COPY bun.lock .
RUN bun install
COPY . .
RUN bun run build

FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]