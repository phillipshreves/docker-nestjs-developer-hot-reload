# syntax=docker/dockerfile:1
# This is a multi-part build to reduce deployment size

# dev image
FROM node:18-bullseye-slim AS development
WORKDIR /app/src
COPY --chown=node:node package*.json  ./
RUN apt-get update && apt-get install -y procps
RUN npm ci
COPY --chown=node:node . .
USER node

# build image
FROM node:18-bullseye-slim AS build
WORKDIR /app/src
COPY --chown=node:node package*.json  ./
COPY --chown=node:node --from=development /app/src/node_modules ./node_modules
COPY --chown=node:node . .
RUN npm run build
ENV NODE_ENV production
RUN npm ci --omit=dev && npm cache clean --force
USER node

# prod image
FROM node:18-bullseye-slim AS production
COPY --chown=node:node --from=build /app/src/node_modules ./node_modules
COPY --chown=node:node --from=build /app/src/dist ./dist

CMD ["node", "dist/main.js"]
