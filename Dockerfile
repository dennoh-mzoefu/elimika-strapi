FROM node:20-alpine as base

FROM base AS deps
RUN apk add --no-cache libc6-compat python3 make g++
WORKDIR /app

COPY package*.json ./
RUN npm install --legacy-peer-deps

FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build Strapi in test mode
ENV NODE_ENV=test
RUN npm run build

FROM base AS runner
WORKDIR /app
ENV NODE_ENV test

RUN addgroup --system --gid 1001 strapi
RUN adduser --system --uid 1001 strapi

# Copy necessary files from builder
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/build ./build
COPY --from=builder /app/config ./config
COPY --from=builder /app/public ./public
COPY --from=builder /app/src ./src
COPY --from=builder /app/database ./database
COPY --from=builder /app/.env ./.env

# Create uploads directory with proper permissions
RUN mkdir -p ./public/uploads
RUN chown -R strapi:strapi /app
RUN chmod -R 755 /app/public/uploads

USER strapi
EXPOSE 1337
ENV PORT 1337
ENV HOST "0.0.0.0"

# PostgreSQL configuration for test environment
ENV DATABASE_CLIENT postgres
ENV DATABASE_HOST postgres
ENV DATABASE_PORT 5432
ENV DATABASE_NAME strapi_test
ENV DATABASE_USERNAME strapi_test
ENV DATABASE_PASSWORD strapi_test
ENV DATABASE_SSL false

# Start the app
CMD ["npm", "run", "start"]