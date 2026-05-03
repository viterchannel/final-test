# AJKMart Setup Commands

Yeh file GitHub, Codespaces, localhost aur VPS/server par AJKMart project chalane ke commands ke liye hai.

## 0. One-Word Launchers (Recommended)

Pora monorepo (API + admin + vendor + rider + ajkmart Expo + mockup sandbox) ek single command se start karne ke liye:

| Environment | Command           | Kya karta hai |
|-------------|-------------------|----------------|
| Replit      | `replit-start`    | Replit-assigned ports par sab services start, `REPLIT_DEV_DOMAIN` wire karta hai. |
| Codespaces  | `codespace-start` | `HOST=0.0.0.0`, `https://${CODESPACE_NAME}-<port>.app.github.dev` URLs print, `gh` se ports public marks. |
| VPS         | `vps-start`       | Missing `pnpm`/`pm2`/`caddy` install, `pnpm install`, DB push, build, PM2, Caddy/nginx (`--proxy=nginx`) reload. |
| Local       | `local-start`     | `.env` create from `deploy/env.example`, deps install, Postgres probe, `scripts/run-dev-all.mjs` chalata hai. |

Pehli baar chalane par script khud `~/.local/bin` mein symlinks bana deti hai, phir `replit-start` (ya koi bhi) bilkul real shell command ban jata hai. `pnpm replit-start` etc. bhi kaam karta hai. Test ke liye `--dry-run` lagayen.

## 1. Required Software

Har environment mein yeh cheezen honi chahiye:

```bash
node --version
corepack --version
git --version
```

Recommended:

```text
Node.js 20 ya newer
pnpm via corepack
Git
Neon/PostgreSQL database URL
```

## 2. Required Environment Variables

Project root mein `.env` file banayen:

```bash
cp deploy/env.example .env
```

`.env` mein minimum yeh values set karein:

```bash
NEON_DATABASE_URL="postgresql://USER:PASSWORD@HOST/DATABASE?sslmode=require"
ADMIN_SECRET="your-secure-admin-secret"
AJKMART_DOMAIN="localhost"
EXPO_PUBLIC_DOMAIN="localhost:8080"
API_PORT=8080
MOBILE_WEB_PORT=19006
NODE_ENV=development
```

Production/VPS par:

```bash
AJKMART_DOMAIN="yourdomain.com"
EXPO_PUBLIC_DOMAIN="yourdomain.com"
NODE_ENV=production
ALLOWED_ORIGINS="https://yourdomain.com"
```

## 3. Database Setup Commands

Neon ya PostgreSQL database schema create/sync:

```bash
corepack enable
pnpm install --no-frozen-lockfile
pnpm --filter @workspace/db push
```

Database connection priority:

```text
1. NEON_DATABASE_URL
2. APP_DATABASE_URL
3. DATABASE_URL
```

New Neon DB use karni ho to `.env` mein:

```bash
NEON_DATABASE_URL="your-neon-url"
```

Phir:

```bash
pnpm --filter @workspace/db push
```

## 4. GitHub Par Code Push Karna

Agar local folder se GitHub par push karna ho:

```bash
git status
git add .
git commit -m "Initial AJKMart setup"
git branch -M main
git remote add origin YOUR_GITHUB_REPO_URL
git push -u origin main
```

Agar GitHub repo already connected hai:

```bash
git status
git add .
git commit -m "Update AJKMart"
git push
```

## 5. GitHub Codespaces Setup

GitHub repo open karein, phir:

```text
Code → Codespaces → Create codespace
```

Codespace terminal mein:

```bash
corepack enable
pnpm install --no-frozen-lockfile
cp deploy/env.example .env
```

`.env` edit karein:

```bash
NEON_DATABASE_URL="your-neon-url"
ADMIN_SECRET="your-admin-secret"
AJKMART_DOMAIN="your-codespace-preview-domain"
EXPO_PUBLIC_DOMAIN="your-codespace-api-preview-domain"
API_PORT=8080
MOBILE_WEB_PORT=19006
NODE_ENV=development
```

Database schema:

```bash
pnpm --filter @workspace/db push
```

All apps one command:

```bash
node scripts/run-dev-all.mjs
```

Codespaces ports:

```text
8080  → API
5173  → Admin
5174  → Vendor
5175  → Rider
19006 → Customer web / AJKMart
```

Open these forwarded ports:

```text
Admin:       /admin/
Vendor:      /vendor/
Rider:       /rider/
Customer:    port 19006
API health:  /api/platform-config
```

## 6. Localhost Setup

Clone:

```bash
git clone YOUR_GITHUB_REPO_URL
cd YOUR_PROJECT_FOLDER
```

Install:

```bash
corepack enable
pnpm install --no-frozen-lockfile
cp deploy/env.example .env
```

`.env` example for localhost:

```bash
NEON_DATABASE_URL="your-neon-url"
ADMIN_SECRET="your-admin-secret"
AJKMART_DOMAIN="localhost"
EXPO_PUBLIC_DOMAIN="localhost:8080"
API_PORT=8080
MOBILE_WEB_PORT=19006
NODE_ENV=development
ALLOWED_ORIGINS="http://localhost:5173,http://localhost:5174,http://localhost:5175,http://localhost:19006"
```

DB sync:

```bash
pnpm --filter @workspace/db push
```

Run all apps:

```bash
node scripts/run-dev-all.mjs
```

Local URLs:

```text
API:          http://localhost:8080/api
Admin:        http://localhost:5173/admin/
Vendor:       http://localhost:5174/vendor/
Rider:        http://localhost:5175/rider/
Customer app: http://localhost:19006
```

## 7. VPS / Own Server Setup

Ubuntu server example:

```bash
sudo apt update
sudo apt install -y git curl
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
corepack enable
```

Clone to `/srv/ajkmart`:

```bash
sudo mkdir -p /srv/ajkmart
sudo chown -R $USER:$USER /srv/ajkmart
git clone YOUR_GITHUB_REPO_URL /srv/ajkmart
cd /srv/ajkmart
```

Create env:

```bash
cp deploy/env.example .env
nano .env
```

Production `.env`:

```bash
NEON_DATABASE_URL="your-neon-url"
ADMIN_SECRET="your-admin-secret"
AJKMART_DOMAIN="yourdomain.com"
EXPO_PUBLIC_DOMAIN="yourdomain.com"
APP_ROOT=/srv/ajkmart
API_PORT=8080
MOBILE_WEB_PORT=19006
NODE_ENV=production
ALLOWED_ORIGINS="https://yourdomain.com"
```

One-command server setup:

```bash
bash scripts/server-up.sh
```

This command does:

```text
1. corepack enable
2. pnpm install --no-frozen-lockfile
3. pnpm --filter @workspace/db push
4. production build
5. PM2 start
```

## 8. VPS With Caddy Reverse Proxy

Install Caddy:

```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
```

Copy config:

```bash
sudo cp deploy/Caddyfile /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

Routes:

```text
https://yourdomain.com/        → Customer app
https://yourdomain.com/api     → Backend API
https://yourdomain.com/admin   → Admin panel
https://yourdomain.com/vendor  → Vendor app
https://yourdomain.com/rider   → Rider app
```

## 9. VPS With Nginx Reverse Proxy

Install:

```bash
sudo apt update
sudo apt install -y nginx
```

Copy config:

```bash
sudo cp deploy/nginx.conf /etc/nginx/sites-available/ajkmart
sudo ln -sf /etc/nginx/sites-available/ajkmart /etc/nginx/sites-enabled/ajkmart
sudo nginx -t
sudo systemctl reload nginx
```

For HTTPS:

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
```

## 10. PM2 Commands

Start:

```bash
node scripts/pm2-control.mjs start
```

Stop:

```bash
node scripts/pm2-control.mjs stop
```

Logs:

```bash
pnpm dlx pm2 logs
```

List:

```bash
pnpm dlx pm2 list
```

Restart:

```bash
pnpm dlx pm2 restart all
```

Save startup:

```bash
pnpm dlx pm2 save
pnpm dlx pm2 startup
```

## 11. Customer App AJKMart Run Commands

Development web:

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

Customer app API connection:

```text
EXPO_PUBLIC_DOMAIN=yourdomain.com
Customer app calls: https://yourdomain.com/api
```

Local development:

```text
EXPO_PUBLIC_DOMAIN=localhost:8080
Customer app calls: https://localhost:8080/api
```

If localhost HTTPS issue aaye, use public tunnel/Codespaces forwarded HTTPS domain for `EXPO_PUBLIC_DOMAIN`.

## 12. Individual App Commands

API:

```bash
PORT=8080 NODE_ENV=development pnpm --filter @workspace/api-server dev
```

Admin:

```bash
PORT=5173 BASE_PATH=/admin/ pnpm --filter @workspace/admin dev
```

Vendor:

```bash
PORT=5174 BASE_PATH=/vendor/ pnpm --filter @workspace/vendor-app dev
```

Rider:

```bash
PORT=5175 BASE_PATH=/rider/ pnpm --filter @workspace/rider-app dev
```

Customer:

```bash
PORT=19006 EXPO_PUBLIC_DOMAIN=localhost:8080 pnpm --filter @workspace/ajkmart dev:web
```

## 13. Production Build Commands

All production build:

```bash
node scripts/build-production.mjs
```

Manual builds:

```bash
NODE_ENV=production pnpm --filter @workspace/api-server build
PORT=5173 BASE_PATH=/admin/ pnpm --filter @workspace/admin build
PORT=5174 BASE_PATH=/vendor/ pnpm --filter @workspace/vendor-app build
PORT=5175 BASE_PATH=/rider/ pnpm --filter @workspace/rider-app build
EXPO_PUBLIC_DOMAIN=yourdomain.com BASE_PATH=/ pnpm --filter @workspace/ajkmart build
```

## 14. Update Existing Server

```bash
cd /srv/ajkmart
git pull
pnpm install --no-frozen-lockfile
pnpm --filter @workspace/db push
node scripts/build-production.mjs
pnpm dlx pm2 restart all
```

## 15. Quick Health Checks

API:

```bash
curl http://localhost:8080/api/platform-config
```

Admin build exists:

```bash
ls artifacts/admin/dist/public
```

Vendor build exists:

```bash
ls artifacts/vendor-app/dist/public
```

Rider build exists:

```bash
ls artifacts/rider-app/dist/public
```

PM2 status:

```bash
pnpm dlx pm2 list
```

Caddy status:

```bash
sudo systemctl status caddy
```

Nginx status:

```bash
sudo nginx -t
sudo systemctl status nginx
```