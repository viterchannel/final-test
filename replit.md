# AJKMart Super-App Monorepo

## Overview

AJKMart is a multi-service super-app platform designed for the AJK region of Pakistan. It integrates e-commerce, food delivery, ride-hailing, pharmacy services, parcel delivery, and inter-city transport into a single platform. The project aims to provide a robust, low-resource-friendly experience optimized for environments with slow networks and budget devices. The system comprises four user-facing applications (customer mobile/web, rider PWA, vendor portal, admin panel) supported by a Node.js API server and PostgreSQL database.

## User Preferences

Preferred communication style: Simple, everyday language.

## System Architecture

### Monorepo Structure

The project is structured as a pnpm workspace monorepo, enforcing pnpm usage. It includes shared libraries for database schema, API client, validation, and internationalization, consumed by various deployable applications such as the API server, admin panel, rider app, vendor app, and customer super-app. TypeScript project references are used for efficient type-checking and build processes.

### Applications

1.  **api-server**: A Node.js/Express backend providing a unified API for all clients. It uses Drizzle ORM for database interactions, Zod for validation, and Socket.IO for real-time features.
2.  **admin**: A React + Vite application serving as the central administration panel, featuring a "Command Center" design with various modules for operations, inventory, finance, safety, and configuration.
3.  **rider-app**: A React + Vite PWA for riders, including mapping, GPS tracking, order/ride management, and financial features.
4.  **vendor-app**: A React + Vite application for vendors to manage products, inventory, and orders.
5.  **ajkmart**: An Expo / React Native customer super-app, supporting mobile and web builds, with features like biometrics, deep linking for authentication, and network-aware image loading.

### Backend Architecture

The backend leverages Express with Zod validation, JWT-based authentication, CSRF protection, and rate limiting. Socket.IO facilitates real-time events. A multi-method authentication system supports Phone/Email OTP, Username/Password, OAuth, magic links, and TOTP 2FA, with methods togglable via platform configuration. A hybrid wallet model manages commissions and rider balances, with atomic transactions for critical operations. A central platform configuration endpoint allows dynamic control over features, pricing, and service settings.

### Frontend Architecture

The customer app uses Expo, supporting lazy-loaded service modules that are toggled via feature flags in platform config. React Query is used for server state management with AsyncStorage persistence for offline resilience. The project supports trilingual internationalization (English/Urdu/Roman Urdu) via a shared library. A consistent design system is applied across applications, utilizing Lucide icons for web and Ionicons for Expo, with specific color palettes per application.

### Data Layer

PostgreSQL is the chosen database, with schema managed by Drizzle ORM. Drizzle Kit is used for migrations. The schema is organized by domain, covering users, orders, products, rides, wallets, and platform settings.

### Key Architectural Decisions

-   **Single API Server**: Chosen for simplicity, cost efficiency, and easier transaction consistency, suitable for the target regional scale.
-   **pnpm Workspace**: Preferred over more complex monorepo tools for its simplicity and sufficiency for project needs.
-   **Expo for Customer App**: Enables a single codebase for iOS/Android/Web, balancing native capabilities with web compatibility.
-   **Admin-Driven Configuration**: Most business logic and feature toggles are controllable via the admin panel, reducing the need for code redeploys.
-   **Manual Payment Verification**: Aligns with local payment habits and avoids initial gateway fees by supporting bank transfers with admin verification.

## External Dependencies

### Core Runtime & Frameworks
-   **Node.js**, **Express**, **Socket.IO**, **Drizzle ORM**, **Zod** (API server).
-   **PostgreSQL** (database).
-   **React 19**, **Vite** (admin/rider/vendor web apps).
-   **Wouter**, **React Router**, **Expo Router** (routing).
-   **Expo SDK** (with `expo-secure-store`, `expo-local-authentication`, `expo-image`, `expo-auth-session`, `expo-camera`, `expo-store-review`, `expo-linking`).
-   **EAS CLI** (for native builds).

### Authentication & Security
-   **@react-oauth/google** (Google sign-in).
-   **Facebook SDK**.
-   **JWT**, **bcrypt**, **TOTP** (2FA), **reCAPTCHA v3**.

### Maps & Location
-   **Leaflet** (web maps).
-   **NetInfo** (network quality detection).

### Real-time & State
-   **Socket.IO** (real-time communication).
-   **TanStack React Query** (server state management with offline persistence).

### Payment & Wallet
-   Integration with **JazzCash**, **EasyPaisa**, **Bank Transfer** (manual verification).

### Notifications
-   **Expo push tokens** (mobile push notifications).
-   **SMS / WhatsApp / Email OTP** (provider abstracted).

### Tooling
-   **TypeScript 5.9**, **Prettier 3.8**.
-   **pnpm**.
-   **Drizzle Kit** (migrations).
-   **Sentry** (error reporting).

## Replit Environment Setup

### Workflows
- **Start application**: API server (port 5000, webview) — `pnpm --filter @workspace/api-server dev`
- **Admin App**: Admin Vite app (port 3000) — `ADMIN_PORT=3000 BASE_PATH=/admin/ pnpm --filter @workspace/admin dev`
- **Vendor App**: Vendor Vite app (port 3001) — `VENDOR_PORT=3001 BASE_PATH=/vendor/ pnpm --filter @workspace/vendor-app dev`
- **Rider App**: Rider Vite app (port 3002) — `RIDER_PORT=3002 BASE_PATH=/rider/ pnpm --filter @workspace/rider-app dev`

### Port Routing
- Port 5000 → API server (public webview, hub page at `/`)
- Port 3000 → Admin Vite dev server (proxied at `/admin/`)
- Port 3001 → Vendor Vite dev server (proxied at `/vendor/`)
- Port 3002 → Rider Vite dev server (proxied at `/rider/`)

### Key Env Vars (in .replit [userenv.shared])
- `PORT=5000` — reserved for API server. Sub-apps use `ADMIN_PORT`, `VENDOR_PORT`, `RIDER_PORT`
- `VITE_API_PROXY_TARGET=http://127.0.0.1:8080` — overridden in vite configs to hardcode port 5000
- `JWT_SECRET`, `ADMIN_JWT_SECRET`, `ADMIN_CSRF_SECRET`, `ERROR_REPORT_HMAC_SECRET` — set
- `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_CONTACT_EMAIL` — set for web push

### Database
- Replit native PostgreSQL (DATABASE_URL + PG* vars auto-set)
- Migrations applied via custom SQL runner (`artifacts/api-server/src/services/sqlMigrationRunner.ts`)
- Bootstrap migration: `lib/db/migrations/0000b_bootstrap_core_tables.sql`

### External Integrations (configured via Admin panel DB settings)
- SMS: Twilio / MSG91 / Zong (CM.com)
- WhatsApp: Meta Cloud API
- Email: SMTP (nodemailer)
- Maps: Google Maps Platform / LocationIQ / OpenStreetMap
- Payments: JazzCash, EasyPaisa
- Push: Firebase FCM + Web Push (VAPID)
- AI: Google Gemini (GEMINI_API_KEY env var needed)
- Firebase: optional (FIREBASE_SERVICE_ACCOUNT_JSON env var needed)