# AJKMart Technical Guide

Yeh guide project languages, backend, frontend, routing, database, connection flow, debugging aur upgrade process explain karti hai.

## 1. Project Overview

AJKMart ek multi-app platform hai:

```text
Customer App: AJKMart Super App
Admin Panel: AJKMart Admin
Vendor App: Vendor dashboard
Rider App: Rider dashboard
API Server: Backend API
Database: PostgreSQL / Neon
```

Project monorepo structure use karta hai:

```text
artifacts/
  api-server/     Backend API
  admin/          Admin web app
  vendor-app/     Vendor web app
  rider-app/      Rider web app
  ajkmart/        Customer Expo app

lib/
  db/             Database schema + Drizzle connection
  api-client-react/
  api-zod/
  i18n/
  service-constants/

deploy/
  Caddyfile
  nginx.conf
  env.example

scripts/
  run-dev-all.mjs
  build-production.mjs
  server-up.sh
  pm2-control.mjs
```

## 2. Languages and Main Technologies

### Backend

```text
Language: TypeScript / JavaScript
Runtime: Node.js
Framework: Express
Database ORM: Drizzle ORM
Database Driver: pg
Realtime: Socket.IO
Scheduler: node-cron
Logging: pino
Build: esbuild
```

### Frontend Web Apps

```text
Language: TypeScript / TSX
Framework: React
Build tool: Vite
Styling: Tailwind CSS + component libraries
Routing: Wouter / app-specific routing
Realtime client: socket.io-client
```

### Customer App

```text
Language: TypeScript / TSX
Framework: Expo + React Native
Web mode: Expo web
Routing: expo-router
State: React Context + React Query
```

### Database

```text
Database: PostgreSQL
Hosted option: Neon
ORM: Drizzle ORM
Schema folder: lib/db/src/schema
Connection file: lib/db/src/connection-url.ts
```

## 3. Backend Structure

Backend location:

```text
artifacts/api-server
```

Important files:

```text
artifacts/api-server/src/index.ts
artifacts/api-server/src/app.ts
artifacts/api-server/src/routes/index.ts
artifacts/api-server/src/routes/
artifacts/api-server/src/middleware/
artifacts/api-server/src/services/
artifacts/api-server/src/lib/
```

### Backend Start Flow

`src/index.ts`:

```text
1. Reads PORT
2. Creates HTTP server
3. Initializes Socket.IO
4. Initializes web push
5. Runs startup migrations
6. Ensures missing tables/columns
7. Initializes Express app
8. Starts listening
9. Starts dispatch/cron systems
```

### Express App Flow

`src/app.ts`:

```text
1. pino request logger
2. security headers middleware
3. CORS
4. body parser limits
5. rate limit middleware
6. static uploads at /api/uploads
7. API router mounted at /api
8. API 404 handler
9. global error handler
```

## 4. Backend Routes

Main route index:

```text
artifacts/api-server/src/routes/index.ts
```

Routes are mounted under:

```text
/api
```

Examples:

```text
/api/platform-config
/api/products
/api/orders
/api/auth
/api/admin/*
/api/vendor/*
/api/rider/*
/api/uploads/*
/api/socket.io
```

Admin APIs:

```text
/api/admin/*
```

Vendor APIs:

```text
/api/vendor/*
```

Rider APIs:

```text
/api/rider/*
```

Customer/public APIs:

```text
/api/products
/api/vendors
/api/orders
/api/payments
/api/rides
/api/maps
```

## 5. Database System

Database package:

```text
lib/db
```

Important files:

```text
lib/db/src/connection-url.ts
lib/db/src/index.ts
lib/db/drizzle.config.ts
lib/db/src/schema/
lib/db/migrations/
```

### Connection Priority

App database URL is resolved in this order:

```text
1. NEON_DATABASE_URL
2. APP_DATABASE_URL
3. DATABASE_URL
```

This means Neon default banani ho to:

```bash
NEON_DATABASE_URL="your-neon-url"
```

### DB Schema Sync

```bash
pnpm --filter @workspace/db push
```

### Runtime DB Usage

Backend imports:

```ts
import { db } from "@workspace/db";
```

Then queries use Drizzle:

```ts
await db.select().from(usersTable);
await db.insert(usersTable).values(...);
await db.update(usersTable).set(...);
```

## 6. Frontend Apps

### Admin Panel

Location:

```text
artifacts/admin
```

Run:

```bash
PORT=5173 BASE_PATH=/admin/ pnpm --filter @workspace/admin dev
```

URL:

```text
http://localhost:5173/admin/
```

### Vendor App

Location:

```text
artifacts/vendor-app
```

Run:

```bash
PORT=5174 BASE_PATH=/vendor/ pnpm --filter @workspace/vendor-app dev
```

URL:

```text
http://localhost:5174/vendor/
```

### Rider App

Location:

```text
artifacts/rider-app
```

Run:

```bash
PORT=5175 BASE_PATH=/rider/ pnpm --filter @workspace/rider-app dev
```

URL:

```text
http://localhost:5175/rider/
```

### Customer App

Location:

```text
artifacts/ajkmart
```

Run web:

```bash
PORT=19006 EXPO_PUBLIC_DOMAIN=localhost:8080 pnpm --filter @workspace/ajkmart dev:web
```

Production build:

```bash
EXPO_PUBLIC_DOMAIN=yourdomain.com BASE_PATH=/ pnpm --filter @workspace/ajkmart build
```

Production serve:

```bash
PORT=19006 BASE_PATH=/ pnpm --filter @workspace/ajkmart serve
```

## 7. Frontend and Backend Connection

### Replit

Replit routes apps by path:

```text
/        Customer app
/api     Backend API
/admin   Admin panel
/vendor  Vendor app
/rider   Rider app
```

### Local / Codespaces

The Vite apps have API proxy:

```text
VITE_API_PROXY_TARGET=http://127.0.0.1:8080
```

So frontend calls:

```text
/api/*
```

and Vite forwards them to:

```text
http://127.0.0.1:8080/api/*
```

Vendor/rider also support:

```text
/vendor/api/* → /api/*
/rider/api/*  → /api/*
```

### VPS / Production

Use Caddy or Nginx:

```text
/api     → API server port 8080
/admin   → static admin build
/vendor  → static vendor build
/rider   → static rider build
/        → customer web server port 19006
```

## 8. Realtime Socket.IO

Backend Socket.IO path:

```text
/api/socket.io
```

Reverse proxy must support websocket upgrade.

Nginx config already includes:

```text
Upgrade
Connection
proxy_http_version 1.1
```

If realtime chat/ride tracking stops working, check:

```text
1. /api/socket.io route is proxied
2. websocket upgrade headers exist
3. API server is running
4. frontend domain and backend domain match expected CORS/proxy setup
```

## 9. Uploads

Backend serves uploads from:

```text
/api/uploads
```

Local folder:

```text
artifacts/api-server/uploads
```

On VPS, keep this folder persistent. If server is rebuilt or moved, copy uploads folder too.

## 10. Error Debugging

### API Not Starting

Check:

```bash
pnpm dlx pm2 logs ajkmart-api
```

Or local:

```bash
PORT=8080 NODE_ENV=development pnpm --filter @workspace/api-server dev
```

Common causes:

```text
PORT missing
NEON_DATABASE_URL missing
Database schema not pushed
Invalid ADMIN_SECRET
Port already in use
```

Fix:

```bash
pnpm --filter @workspace/db push
pnpm dlx pm2 restart ajkmart-api
```

### Frontend Opens But API Fails

Check browser console and API URL.

Local:

```text
VITE_API_PROXY_TARGET=http://127.0.0.1:8080
```

Production:

```text
https://yourdomain.com/api/platform-config
```

If this URL fails, backend/proxy issue hai.

### Admin/Vendor/Rider Blank Page

Check base path:

```text
Admin BASE_PATH=/admin/
Vendor BASE_PATH=/vendor/
Rider BASE_PATH=/rider/
```

Rebuild:

```bash
node scripts/build-production.mjs
pnpm dlx pm2 restart all
```

Reload proxy:

```bash
sudo systemctl reload caddy
```

or:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

### Database Error

Check env:

```bash
echo $NEON_DATABASE_URL
```

Check schema:

```bash
pnpm --filter @workspace/db push
```

If Neon password changed, update `.env`, then:

```bash
pnpm dlx pm2 restart all
```

### Customer App API Error

Customer app uses:

```text
EXPO_PUBLIC_DOMAIN
```

If production domain is `ajkmart.com`:

```bash
EXPO_PUBLIC_DOMAIN=ajkmart.com
```

Customer app calls:

```text
https://ajkmart.com/api
```

After changing `EXPO_PUBLIC_DOMAIN`, rebuild customer app:

```bash
EXPO_PUBLIC_DOMAIN=ajkmart.com BASE_PATH=/ pnpm --filter @workspace/ajkmart build
pnpm dlx pm2 restart ajkmart-mobile-web
```

## 11. How To Upgrade Backend

Backend code usually lives in:

```text
artifacts/api-server/src/routes
artifacts/api-server/src/services
artifacts/api-server/src/middleware
artifacts/api-server/src/lib
```

### Add New API Route

1. Create or edit route file in:

```text
artifacts/api-server/src/routes/
```

2. Register route in:

```text
artifacts/api-server/src/routes/index.ts
```

3. Use database from:

```ts
import { db } from "@workspace/db";
```

4. Restart API:

```bash
PORT=8080 NODE_ENV=development pnpm --filter @workspace/api-server dev
```

Production:

```bash
pnpm --filter @workspace/api-server build
pnpm dlx pm2 restart ajkmart-api
```

## 12. How To Upgrade Database

Schema files:

```text
lib/db/src/schema/
```

Steps:

```text
1. Add/change table schema in lib/db/src/schema
2. Export it from schema index if needed
3. Run schema push
4. Restart API
```

Commands:

```bash
pnpm --filter @workspace/db push
pnpm dlx pm2 restart ajkmart-api
```

If adding a safe data migration, add SQL file in:

```text
lib/db/migrations/
```

Then restart API. Startup migration runner will apply pending SQL files.

## 13. How To Upgrade Frontend

Admin:

```text
artifacts/admin/src
```

Vendor:

```text
artifacts/vendor-app/src
```

Rider:

```text
artifacts/rider-app/src
```

Customer:

```text
artifacts/ajkmart
```

### Frontend API Call Pattern

Web apps call backend through:

```text
/api
```

or app base path plus API:

```text
BASE_URL + api/...
```

Do not hard-code random localhost URLs inside app code. Use existing API helpers and environment variables.

### Rebuild After Frontend Change

```bash
node scripts/build-production.mjs
pnpm dlx pm2 restart all
```

## 14. Local Development Workflow

Start everything:

```bash
node scripts/run-dev-all.mjs
```

Open:

```text
Admin:        http://localhost:5173/admin/
Vendor:       http://localhost:5174/vendor/
Rider:        http://localhost:5175/rider/
Customer:     http://localhost:19006
API:          http://localhost:8080/api/platform-config
```

If one app is enough:

```bash
PORT=8080 NODE_ENV=development pnpm --filter @workspace/api-server dev
PORT=5173 BASE_PATH=/admin/ pnpm --filter @workspace/admin dev
```

## 15. Production Deployment Workflow

On server:

```bash
cd /srv/ajkmart
git pull
pnpm install --no-frozen-lockfile
pnpm --filter @workspace/db push
node scripts/build-production.mjs
pnpm dlx pm2 restart all
```

If first time:

```bash
bash scripts/server-up.sh
```

## 16. Safe Upgrade Checklist

Before upgrade:

```text
1. Backup database or confirm Neon backup is available
2. Pull latest code
3. Install dependencies
4. Push DB schema
5. Build production
6. Restart PM2
7. Check API health
8. Check frontend pages
```

Commands:

```bash
git pull
pnpm install --no-frozen-lockfile
pnpm --filter @workspace/db push
node scripts/build-production.mjs
pnpm dlx pm2 restart all
curl http://localhost:8080/api/platform-config
```

## 17. Common Ports

```text
8080  API
5173  Admin dev
5174  Vendor dev
5175  Rider dev
19006 Customer web
80    HTTP public proxy
443   HTTPS public proxy
```

## 18. Which File To Change For What

```text
Database connection:
  lib/db/src/connection-url.ts

Database schema:
  lib/db/src/schema/

API routes:
  artifacts/api-server/src/routes/

API boot/start:
  artifacts/api-server/src/index.ts

Express middleware and error handling:
  artifacts/api-server/src/app.ts

Admin UI:
  artifacts/admin/src/

Vendor UI:
  artifacts/vendor-app/src/

Rider UI:
  artifacts/rider-app/src/

Customer app:
  artifacts/ajkmart/

VPS process manager:
  ecosystem.config.cjs

Caddy routing:
  deploy/Caddyfile

Nginx routing:
  deploy/nginx.conf

Local all-app runner:
  scripts/run-dev-all.mjs

Production build:
  scripts/build-production.mjs

One-command server setup:
  scripts/server-up.sh
```