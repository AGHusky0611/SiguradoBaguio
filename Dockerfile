FROM node:20-alpine AS base
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

COPY package.json package-lock.json turbo.json .npmrc ./
COPY apps/web/package.json ./apps/web/package.json
COPY apps/api/package.json ./apps/api/package.json
COPY packages/ui/package.json ./packages/ui/package.json
COPY packages/eslint-config/package.json ./packages/eslint-config/package.json
COPY packages/typescript-config/package.json ./packages/typescript-config/package.json

RUN npm ci

COPY apps ./apps
COPY packages ./packages

RUN npm run build -- --filter=web

EXPOSE 3000

CMD ["npm", "--workspace=apps/web", "run", "start", "--", "--hostname", "0.0.0.0", "--port", "3000"]