FROM oven/bun:1 AS builder
WORKDIR /app

ARG MIXPANEL_TOKEN
ARG SITE_URL

ENV PUBLIC_MIXPANEL_TOKEN=$MIXPANEL_TOKEN
ENV PUBLIC_SITE_URL=$SITE_URL

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