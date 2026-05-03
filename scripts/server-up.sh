#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ -f ".env" ]; then
  set -a
  . ./.env
  set +a
fi

corepack enable
pnpm install --no-frozen-lockfile

if [ "${SKIP_DB_PUSH:-0}" != "1" ]; then
  pnpm --filter @workspace/db push
fi

node scripts/build-production.mjs
node scripts/pm2-control.mjs start

echo "API is managed by PM2 on port ${API_PORT:-8080}"
echo "Customer web is managed by PM2 on port ${MOBILE_WEB_PORT:-19006}"
echo "Use deploy/Caddyfile or deploy/nginx.conf for public routing"