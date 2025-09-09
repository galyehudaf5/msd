# syntax=docker/dockerfile:1.7

# Base context with manifest files
FROM node:22-alpine AS base
WORKDIR /app
COPY package.json package-lock.json* ./

# Install all deps (incl. dev) for lint/tests with cache
FROM base AS deps
RUN --mount=type=cache,target=/root/.npm npm ci --ignore-scripts

# Lightweight smoke stage (no full test suite) to ensure app boots
FROM deps AS smoke
COPY src/ src/
# Start app briefly, hit /health, then exit; keeps build fast
RUN set -eux; \
	node src/server.js & pid=$!; \
	sleep 1; \
	wget -qO- http://127.0.0.1:8080/health | grep 'ok' >/dev/null; \
	kill $pid || true

# Install only production deps for the runtime image
FROM base AS prod-deps
RUN --mount=type=cache,target=/root/.npm npm ci --omit=dev --ignore-scripts

# Minimal runtime image
FROM node:22-alpine AS runtime
ENV NODE_ENV=production
WORKDIR /app
COPY --from=prod-deps /app/node_modules node_modules
COPY src/ src/
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 CMD wget -qO- http://127.0.0.1:8080/health || exit 1
EXPOSE 8080
USER node
CMD ["node","src/server.js"]