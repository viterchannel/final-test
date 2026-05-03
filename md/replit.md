# AJKMart Super App — Workspace

### Replit Webview / Preview Routing (dev)
The Replit IDE webview only registers an "artifact" preview for the API server (port 8080) and the mockup sandbox (port 8081). The other four web apps (admin, vendor, rider, ajkmart Expo) listen on non-standard ports and previously showed "Hmm... we couldn't reach this app" when their workflow preview tabs were clicked.

To make every app visible from a single working preview window, the API server now mounts dev-only HTTP+WS proxies in `artifacts/api-server/src/app.ts`:
- `/admin/*`    → `http://127.0.0.1:23744` (admin Vite, `BASE_PATH=/admin/`)
- `/vendor/*`   → `http://127.0.0.1:21463` (vendor Vite, `BASE_PATH=/vendor/`)
- `/rider/*`    → `http://127.0.0.1:22969` (rider Vite, `BASE_PATH=/rider/`)
- `/__mockup/*` → `http://127.0.0.1:8081`  (mockup sandbox Vite)
- everything else (after `/api`, `/health`) → `http://127.0.0.1:20716` (Expo customer app, `BASE_PATH=/`)

The proxies are registered with `pathFilter` (not `app.use(prefix, ...)`) so the original `/admin/...` URL is forwarded as-is — Express's prefix mounting strips the prefix from `req.url`, which collides with each Vite server's `base` and produces a redirect loop. Ports are overridable via `ADMIN_DEV_PORT`, `VENDOR_DEV_PORT`, `RIDER_DEV_PORT`, `EXPO_DEV_PORT`, `MOCKUP_DEV_PORT`. Proxies are guarded by `NODE_ENV !== "production"` so production deployments behind Caddy/Nginx are unaffected. The proxies are registered before `helmet()` so upstream Vite headers (CSP, frame options) reach the iframe untouched, and after the `/api` router so backend routes still win.

To test inside Replit: open the API Server preview tab and navigate to `/`, `/admin/`, `/vendor/`, or `/rider/`. The same paths also work via `https://${REPLIT_DEV_DOMAIN}/...`.

### Unified Environment Launchers
Four single-word commands bring the entire monorepo (API + admin + vendor + rider + ajkmart Expo + mockup sandbox) up in any of four environments. Each one auto-detects/auto-fixes whatever its environment needs.

- `replit-start` — Replit shell. Reuses Replit-assigned ports (8080 / 23744 / 21463 / 22969 / 20716 / 8081), wires `REPLIT_DEV_DOMAIN` and `REPLIT_EXPO_DEV_DOMAIN`, prints the Webview URL table.
- `codespace-start` — GitHub Codespaces. Sets `HOST=0.0.0.0` for Vite, prints `https://${CODESPACE_NAME}-<port>.app.github.dev` URLs, best-effort marks ports public via `gh codespace ports visibility`.
- `vps-start` — Ubuntu/Debian VPS. Installs missing `pnpm` / `pm2` / `caddy`, runs `pnpm install --frozen-lockfile`, pushes the DB schema, runs `scripts/build-production.mjs`, starts PM2 from `ecosystem.config.cjs`, drops `deploy/Caddyfile` (or `deploy/nginx.conf` with `--proxy=nginx`) and reloads the proxy. Prints health-probe status.
- `local-start` — macOS / Linux / WSL laptop. Creates `.env` from `deploy/env.example` if missing, installs deps, probes the Postgres URL, then delegates to `scripts/run-dev-all.mjs` (ports 8080/5173/5174/5175/19006/8081).

All four are real shell commands once the launcher symlinks itself into `~/.local/bin` (done automatically on first run; the script prints a one-line PATH hint if needed). They also work as `pnpm replit-start` / `pnpm codespace-start` / `pnpm vps-start` / `pnpm local-start`. Pass `--dry-run` to print the detected env, resolved ports/URLs, and the exact commands without spawning anything.

Source: `scripts/launchers/start.mjs` (orchestrator) and the four POSIX wrappers next to it.

### pg-connection-string SSL handling
The `pg-connection-string` v3 deprecation warning ("SSL modes 'prefer', 'require', 'verify-ca' are treated as aliases for 'verify-full'") no longer prints on API server startup. `lib/db/src/connection-url.ts` exposes `buildPgPoolConfig(url)` which strips `sslmode` / `ssl` / `uselibpqcompat` from the URL and returns explicit `ssl` options for `pg.Pool` (`{ rejectUnauthorized: true }` for verify-full / verify-ca / require / prefer; `{ rejectUnauthorized: false }` for `no-verify` or when `PGSSL_ALLOW_SELF_SIGNED=1` / `PGSSL_REJECT_UNAUTHORIZED=0`; no SSL when `sslmode=disable`). It is consumed by `lib/db/src/index.ts`, `artifacts/api-server/src/lib/db.ts`, and `artifacts/api-server/src/services/sqlMigrationRunner.ts`.

### Database Connection Priority
- The shared database package resolves the connection string in this order: `NEON_DATABASE_URL`, then `APP_DATABASE_URL`, then Replit's built-in `DATABASE_URL`.
- Runtime DB access is centralized in `lib/db/src/connection-url.ts`, used by `lib/db/src/index.ts` and `lib/db/drizzle.config.ts`.
- `scripts/post-merge.sh` uses the same priority for SQL migrations.
- This allows Neon or another external PostgreSQL database to be used as the default without hard-coding credentials in source files.

### Portable Deployment Configuration
- Added portable run/deploy files for GitHub, Codespaces, local servers, and VPS environments:
  - `scripts/run-dev-all.mjs`: starts API, admin, vendor, rider, and customer web dev servers with fixed ports.
  - `scripts/build-production.mjs`: builds API, admin, vendor, rider, and customer web outputs with production base paths.
  - `scripts/server-up.sh`: one-command VPS/server setup runner that installs packages, syncs DB schema, builds, and starts PM2.
  - `ecosystem.config.cjs`: PM2 config for API and customer web production servers.
  - `deploy/Caddyfile`: Caddy reverse proxy config for `/api`, `/admin`, `/vendor`, `/rider`, and `/`.
  - `deploy/nginx.conf`: Nginx reverse proxy config with Socket.IO upgrade support.
  - `deploy/env.example`: environment variable template for non-Replit hosting.
- Vite dev servers now proxy API requests to `VITE_API_PROXY_TARGET` (default `http://127.0.0.1:8080`) so local/Codespaces frontends can call the backend without Replit path routing.

### Professional Features Part 1

#### Vendor Weekly Schedule (`vendor_schedules` table)
- DB table: `vendor_schedules` with columns (id, vendor_id, day_of_week 0-6, open_time, close_time, is_enabled, timestamps)
- Unique index on (vendor_id, day_of_week) prevents duplicate entries
- Vendor API: `GET/PUT /vendor/schedule` for vendors to manage their weekly hours
- Admin API: `GET/PUT /admin/system/vendor-schedules/:vendorId` for admin override
- Vendor App: "Schedule" tab in Store page with per-day toggle and time pickers

#### Scheduled Maintenance Window
- Platform settings: `maintenance_scheduled_start`, `maintenance_scheduled_end`, `maintenance_scheduled_msg`
- Admin API: `GET/PUT /admin/system/maintenance-schedule` (auth-protected write)
- Public: `GET /platform-config` returns `maintenance` object with `active`, `upcoming`, `scheduledStart/End`, `message`
- Admin UI: Maintenance Schedule section in System Settings with datetime pickers and clear button

#### Data Retention Policies
- Platform settings: `retention_location_days` (90), `retention_chat_days` (180), `retention_audit_days` (365), `retention_notifications_days` (30), `retention_last_cleanup`
- Admin API: `GET/PUT /admin/system/retention-policies`, `POST /admin/system/retention-cleanup` (auth-protected)
- Cleanup deletes old records from: location_history, support_messages, auth_audit_log, notifications, location_logs
- Admin UI: Data Retention section with configurable days per category and "Run Cleanup Now" button

#### CSV / Report Export
- Admin API endpoints (all auth-protected): `/admin/system/export/{orders,users,riders,vendors,rides,financial}`
- Supports query params for filtering (status, type, dateFrom, dateTo, role)
- Proper CSV escaping (formula injection protection), Content-Type/Content-Disposition headers
- Admin UI: Export section with download buttons for each report type
- All exports capped at 5,000-10,000 rows and audited

### Smart Loading & Performance System (Customer App)

#### Network Quality Detection (`hooks/useNetworkQuality.ts`)
- Detects 2G/3G/4G/WiFi and offline state; classifies into `slow`/`moderate`/`fast` tiers
- Uses `@react-native-community/netinfo` on native, browser `navigator.connection` API on web
- Exports `getPollingIntervalForTier(tier, baseMs)` for adaptive polling intervals

#### Device Tier Detection (`context/PerformanceContext.tsx`)
- Classifies devices as `low`/`mid`/`high` using heuristic scoring: Android API version, pixel density, JS startup time
- Web: uses `navigator.deviceMemory` and `hardwareConcurrency`
- Provides unified `PerformanceConfig`: `useGradients`, `maxConcurrentImages`, `enableAnimations`, `enableParallax`, `imageQuality`, `imageMaxWidth`
- Low-tier: disables gradients (flat colors), limits concurrent images to 2, disables animations

#### Home Screen Section Components (`components/home/`)
- Refactored from monolithic `index.tsx` into: `ServiceGrid`, `BannerCarousel`, `ActiveTracker`, `FlashDeals`, `TrendingSection`, `StatsBar`, `QuickActions`
- Each section is independently importable; barrel `index.ts` exports all
- `ActiveTracker` polling adapts to network tier (30s base → 60s on slow networks)
- `ServiceGrid`/`QuickActions` skip `LinearGradient` on low-end devices

#### AdaptiveImage Component (`components/AdaptiveImage.tsx`)
- Appends `w` and `q` query params to image URIs based on device/network tier
- Shows placeholder during load, error fallback on failure, uses cache-first strategy

#### Slim API Payloads (`?slim=true`)
- Added to: `GET /products`, `GET /products/search`, `GET /orders`, `GET /vendors`
- Returns only card-view fields (50–70% smaller payloads)
- NOT applied to detail screens

#### Offline/Slow Connection Indicators (`components/OfflineBar.tsx`)
- `OfflineBar`: red banner when device is offline
- `SlowConnectionBar`: yellow banner on 2G/3G connections
- Both rendered in `_layout.tsx` under `PerformanceProvider`

#### Deferred Provider Initialization (`app/_layout.tsx`)
- Sentry/analytics init deferred by 1500ms after first render
- Push registration deferred by 2000ms post-login
- Fire-and-forget pattern with cleanup on unmount

### Error Monitor — Enhanced (Admin Panel)

#### Smart Resolution System
- **Resolution Actions**: Each error row has 3 resolution strategies: Auto Resolve (quick resolve), Create Task Plan (generates markdown task doc), Manual Resolve (opens dialog with root cause + notes fields)
- **Backup/Undo System**: Before any resolution, a snapshot is saved to `error_resolution_backups` table. Resolved errors with a backup show an "Undo" button to restore pre-resolution state. Backups have 72-hour TTL with nightly cron cleanup.
- **Resolution Method Filter**: New filter in the filter bar: "Resolution Method" (All, Manually Resolved, Auto-Resolved, Task Created)
- **Updated Badge**: Blue dot indicator on errors that were modified since last viewed

#### AI Auto-Resolve Engine
- **Settings Panel**: Collapsible "AI Auto-Resolve" panel in the header with master toggle, severity/error type filter checkboxes, duplicate detection toggle, age threshold input
- **Backend**: `GET/PUT /api/error-reports/auto-resolve-settings` for config; `POST /api/error-reports/auto-resolve-run` for manual trigger; `GET /api/error-reports/auto-resolve-log` for activity log
- **Cron Job**: Auto-resolve runs every 5 minutes via `node-cron`; checks errors against configured rules (severity filter, error type filter, duplicate detection, age threshold)
- **Activity Log**: Scrollable log in settings panel showing what the auto-resolver did (timestamp, error ID, reason, rule matched)

#### Resolution Database Schema
- **`error_resolution_backups`** table: `id`, `error_report_id`, `previous_status`, `previous_data` (JSONB), `resolution_method`, `created_at`, `expires_at`
- **`auto_resolve_log`** table: `id`, `error_report_id`, `reason`, `rule_matched`, `created_at`
- **`error_reports`** new columns: `resolution_method` (enum: manual/auto_resolved/task_created), `resolution_notes`, `root_cause`, `updated_at`
- Settings stored in `platform_settings` table under key `auto_resolve_settings`

#### Resolution API Endpoints
- `POST /api/error-reports/:id/resolve` — Resolve with method, notes, root cause (creates backup)
- `POST /api/error-reports/:id/undo` — Restore from backup
- `GET /api/error-reports/:id/backup` — Check if undo is available
- `DELETE /api/error-reports/backups/cleanup` — TTL-based backup cleanup
- `POST /api/error-reports/:id/generate-task` — Generate structured task plan markdown

#### Scan System
- **Scan Panel** (`/admin/error-monitor`): Collapsible panel with 4 scan modes: On Demand, Auto Refresh (interval: 30s/1m/5m/15m), Daily (time picker with repeat scheduling), Specific Time (one-time scheduled scan)
- **Scan API** (`POST /api/error-reports/scan`): Admin-only. Checks DB health, critical errors in last hour, unresolved critical count, error type frequency spikes, pending customer reports. Returns structured findings with severity and recommended actions.
- Auto-scan uses `setInterval`; daily/specific-time use `setTimeout` stored in component refs with cleanup on unmount.

#### Root Cause Analysis
- Each expanded error now shows a 3-column "Root Cause Analysis" panel (Likely Causes · What This Can Cause · Recommended Fixes)
- Logic is rule-based: `analyzeErrorCause()` in `error-monitor.tsx` generates contextual analysis from `errorType` + keyword analysis on `errorMessage` (auth, payment, timeout, memory, etc.)

#### Customer Error Reporting (Full Stack)
- **DB Table**: `customer_error_reports` — stores customerName, email, phone, userId, platform, appVersion, deviceInfo, screen, description, reproSteps, status (new/reviewed/closed), adminNote, reviewedAt
- **Migration**: `lib/db/migrations/0030_customer_error_reports.sql`
- **Public API** (`POST /api/error-reports/customer-report`): No auth required. Customers can submit bug reports.
- **Admin API** (`GET /api/error-reports/customer-reports`): Paginated list with status filter. (`PATCH /api/error-reports/customer-reports/:id`): Update status + add admin note.
- **Admin UI**: "Customer Reports" tab (4th tab, purple) in error monitor. Shows customer info (name, email, phone, userId, platform, version, device, screen), full description + repro steps, status workflow (new → reviewed → closed), admin note textarea with save.



### Vendor Store Pages & Product Videos

#### Product Videos (TikTok Shop-style)
- **Schema**: `videoUrl` nullable text column added to `productsTable` in `lib/db/src/schema/products.ts` (DB column: `video_url`)
- **API**: `POST /uploads/video` multipart endpoint (50MB max, MP4/MOV/WebM) in `artifacts/api-server/src/routes/uploads.ts`; vendor product create/bulk-create/PATCH accept `videoUrl` in `artifacts/api-server/src/routes/vendor.ts`
- **Vendor App**: Video upload UI with file picker, `<video>` preview, replace/remove in `artifacts/vendor-app/src/pages/Products.tsx`; `api.uploadVideo(file)` in `artifacts/vendor-app/src/lib/api.ts`
- **Customer App**: Product detail carousel (`artifacts/ajkmart/app/product/[id].tsx`) shows video as first slide using `expo-av` `<Video>` component with play/pause + mute controls; mixed `mediaItems[]` array (video + images)

#### Vendor Store Pages (Alibaba-style)
- **Food**: `/food/store/[id]` (`artifacts/ajkmart/app/food/store/[id].tsx`) — Redirect to existing `/food/restaurant/[id]` (menu layout)
- **Mart**: `/mart/store/[id]` (`artifacts/ajkmart/app/mart/store/[id].tsx`) — Dedicated branded page with hero banner, store info, open/closed badge, rating, delivery time, announcement, category chips, search, 2-column product grid with add-to-cart
- **API**: Uses `GET /vendors/:id/store` from `artifacts/api-server/src/routes/public-vendors.ts`

#### Store Navigation Entry Points
- Mart product cards: "Visit Store" link navigates to `/mart/store/[vendorId]` (`artifacts/ajkmart/app/mart/index.tsx`)
- Product detail: "Sold by" vendor section navigates to appropriate store page based on product type (`/food/store/[id]` or `/mart/store/[id]`)

### Collapsible Header System
- **`artifacts/ajkmart/hooks/useCollapsibleHeader.ts`**: Reusable hook that tracks scroll position via `Animated.event` and provides interpolated values for header collapse animations (opacity, translateY, maxHeight for search bars, subtitles, and stats rows). Configurable expanded/collapsed heights and scroll thresholds.
- Applied to: Home (search bar collapses), Food/Mart/Pharmacy (subtitle + search bar collapse), Orders (subtitle + stats row collapse). Wallet/Cart/ScreenHeader/Product detail received static spacing tightening.
- Uses `useNativeDriver: false` for layout-affecting animations (maxHeight). Scroll events composed through SmartRefresh's `onScroll` passthrough.

### Communication System — Completed

Full in-app communication system with chat, voice calling, AI moderation/translation, and admin control panel.

#### Database Schema (`lib/db/src/schema/communication.ts`)
- `communication_requests` — Request-based communication initiation between users
- `comm_conversations` — Conversation threads between two users
- `chat_messages` — Messages with content moderation (original + masked content), delivery status tracking, voice note transcript
- `call_logs` — Voice call history with duration, status, ICE server config
- `communication_roles` — Role templates for permission control (chat, voiceCall, voiceNote, fileSharing) + role-pair rules + category rules + time windows + message limits
- `communication_flags` — Flagged message tracking for admin review
- `ai_moderation_logs` — AI usage tracking (translation, compose assist, transcription)
- Users table: `ajkId` (unique AJK-XXXXXX format), `commBlocked` boolean

#### Backend Services
- **Content Moderation** (`artifacts/api-server/src/services/contentModeration.ts`): Regex-based filtering for Pakistani phone numbers, emails, CNIC, IBAN, bank accounts, addresses. Configurable via admin settings.
- **AI Service** (`artifacts/api-server/src/services/communicationAI.ts`): Translation, compose assist, role template generation via gpt-5-nano (Replit AI Integrations). Audio transcription via gpt-4o-mini-transcribe. Exponential backoff retry on 429/503/500 (3 attempts).

#### API Routes
- **User** (`/api/communication/*`): AJK ID lookup, user search, request CRUD, conversations, messages (originalContent stripped from user responses), read receipts, translate, compose-assist, call initiate/answer/end/reject, call history, voice note upload with transcript masking
- **Admin** (`/api/admin/communication/*`): Dashboard stats, conversations browser (with originalContent visible), call history, AI logs, flagged messages, role templates (AI-assisted creation with role-pair matrix), user block/unblock, settings CRUD, CSV export, gold AJK ID assignment

#### Socket.IO Events & Security
- `comm:typing:start/stop` — validated against conversation membership via `isAuthorizedForConversationRoom`
- `comm:message:delivered` — verifies emitter is conversation participant and recipient (not sender) before DB update
- `comm:call:offer/answer/ice-candidate/end` — standard signaling relay
- `comm:message:new/sent/read`, `comm:request:new/accepted/rejected`, `comm:call:incoming/answered/ended/rejected`
- Conversation rooms (`conversation:{id}`) with membership authorization on join

#### Frontend
- **Admin Panel** (`artifacts/admin/src/pages/communication.tsx`): 8-tab interface (Dashboard, Settings, AJK IDs, Conversations, Calls, AI Logs, Flagged, Roles). Role template editor includes feature permissions, role-pair matrix (6 pairs), category rules (food/mart/pharmacy/parcel), time windows, and message limits. Gold AJK ID assignment with search.
- **Vendor App** (`artifacts/vendor-app/src/pages/Chat.tsx`): Full chat UI with conversations list, requests, AJK ID search, message thread, WebRTC voice calls (RTCPeerConnection, SDP/ICE), typing indicators, delivery status. Typed interfaces throughout.
- **Rider App** (`artifacts/rider-app/src/pages/Chat.tsx`): Same as vendor with emerald theme. Typed interfaces throughout.
- **Mobile App** (`artifacts/ajkmart/app/chat/`): `index.tsx` (conversations list + requests), `[id].tsx` (chat detail + WebRTC voice calls with RTCPeerConnection, SDP/ICE, mute/unmute), `search.tsx` (AJK ID user search)

#### WebRTC Voice Calling
- P2P architecture with STUN/TURN server configuration via admin settings
- Opus codec for low-bandwidth optimization (Edge/2G compatible)
- Call signaling via Socket.IO events, full SDP/ICE exchange on all platforms (web + Expo)
- Mute/unmute, call timer, incoming call alerts, connection state monitoring

### Overview
AJKMart is a full-stack "Super App" designed for Azad Jammu & Kashmir (AJK), Pakistan. It integrates multiple services including Grocery Shopping (Mart), Food Delivery, Taxi/Bike Booking (Rides), Pharmacy, and Parcel Delivery, all unified by a digital wallet. The project aims to provide a comprehensive, localized service platform for the region.

### Built-in Error Monitoring System

Automatic error detection and reporting across all 5 apps (Customer, Rider, Vendor, Admin, API Server):

- **Database**: `error_reports` table with enums for source_app, error_type, severity, status
  - Schema: `lib/db/src/schema/error_reports.ts`
- **API Endpoints**: 
  - `POST /api/error-reports` — receives error reports from all frontend apps (no auth required)
  - `GET /api/admin/error-reports` — admin-only, filterable list with pagination
  - `GET /api/admin/error-reports/new-count` — count of "new" status errors (for sidebar badge)
  - `PATCH /api/admin/error-reports/:id` — admin updates error status
  - Routes: `artifacts/api-server/src/routes/error-reports.ts`
- **Backend Auto-Capture**: Express global error handler in `app.ts` auto-logs all unhandled errors
  - Utility: `artifacts/api-server/src/lib/error-capture.ts`
- **Frontend Auto-Capture**: Each app has an error reporter utility that hooks into:
  - React Error Boundaries (component crashes)
  - `window.onerror` and `unhandledrejection` listeners
  - `console.error` override (for UI errors)
  - API fetch interceptors (for failed API calls)
  - Files: `artifacts/admin/src/lib/error-reporter.ts`, `artifacts/rider-app/src/lib/error-reporter.ts`, `artifacts/vendor-app/src/lib/error-reporter.ts`, `artifacts/ajkmart/utils/error-reporter.ts`
- **Admin Panel**: "Error Monitor" page at `/error-monitor`
  - Page: `artifacts/admin/src/pages/error-monitor.tsx`
  - Sidebar nav item with badge showing count of "new" errors
  - Filterable by date range, source app, severity, status, error type
  - Expandable rows showing full stack trace and metadata
  - Admin can change error status (New → Acknowledged → In Progress → Resolved)
- **Auto-Classification**: DB/auth/payment errors → Critical; 500s → Critical; 4xx → Medium; UI errors → Minor

### Admin Customer Support Features — Completed

Three new admin management pages added under the "Customer Support" sidebar group (cyan color):

#### 1. Support Chat Inbox (`/support-chat`)
- **Page**: `artifacts/admin/src/pages/support-chat.tsx`
- **API**: `artifacts/api-server/src/routes/admin/support-chat.ts`
- Endpoints: `GET /admin/support-chat/conversations`, `GET /admin/support-chat/conversations/:userId`, `POST /admin/support-chat/conversations/:userId/reply`, `PATCH /admin/support-chat/conversations/:userId/resolve`
- Real-time updates via Socket.IO (`support_message` event); sidebar shows unread counts
- Mark conversations resolved/reopened; admin replies appear in customer chat instantly

#### 2. FAQ Management (`/faq-management`)
- **Page**: `artifacts/admin/src/pages/faq-management.tsx`
- **API**: `artifacts/api-server/src/routes/admin/faq.ts`
- Full CRUD for FAQ entries; categories: Orders, Payment, Delivery, Account, Offers, Pharmacy, Rides, Parcel, Van, General
- Toggle active/inactive (hidden from customers); sort order control; search and filter by category
- `GET /api/platform-config/faqs` now reads from DB with fallback to hardcoded defaults

#### 3. Search Analytics (`/search-analytics`)
- **Page**: `artifacts/admin/src/pages/search-analytics.tsx`
- Displays trending search terms from `/api/products/trending-searches`
- Shows top 20 trending products from `/api/recommendations/trending` with period selector (Today, 7d, 30d)
- Engagement breakdown guide (views, wishlist, cart, trending score, ratings, conversions)

#### DB Changes
- **`lib/db/src/schema/faqs.ts`** — new FAQs table (id, category, question, answer, is_active, sort_order, created_at, updated_at)
- **`lib/db/src/schema/support_messages.ts`** — added `is_read_by_admin` and `is_resolved` columns
- `ensureFaqsTable()` and updated `ensureSupportMessagesTable()` run at server startup for safe migrations

#### i18n Keys Added (all 3 languages)
- `navSupportChat`, `navFaqMgmt`, `navSearchAnalytics`, `navCustomerSupport`

### Pro Offers & Promotions Engine — Completed

Enterprise-grade campaign manager and promotions system replacing scattered promo codes / flash deals with a unified Promotions Hub.

#### Database Schema (`lib/db/src/schema/`)
- **`campaigns.ts`** — Campaign grouping table with theme, colors, budget, status lifecycle, priority ordering
- **`offers.ts`** — Unified offers table with 9 offer types (percentage, flat_discount, bogo, free_delivery, combo, first_order, cashback, happy_hour, category), targeting rules JSON, offer_redemptions and campaign_participations tables
- Backward compatible: existing `promo_codes` and `flash_deals` tables preserved

#### API (`artifacts/api-server/src/routes/promotions.ts`)
- **Public**: `GET /promotions/public` (live offers with grouped sections), `GET /promotions/for-you` (personalized), `POST /promotions/validate` (code validation)
- **Admin CRUD**: campaigns and offers CRUD, bulk pause/activate, clone offers, analytics aggregation, AI recommendation engine
- **Approval workflow**: `POST /offers/:id/submit` (marketing → pending_approval), `POST /offers/:id/approve` + `POST /offers/:id/reject` (manager/super only via `managerAuth` middleware)
- **Bookmarking**: `POST /promotions/bookmarks/:offerId` (toggle) + `GET /promotions/bookmarks` — stored as `offer_redemptions` with `orderId=NULL` and `discount='0'`; all real redemption queries exclude bookmarks via `orderId IS NOT NULL`
- **Security**: Non-manager roles restricted to `draft`/`pending_approval` status on create/update; `GET /offers/pending` registered before `GET /offers/:id` to prevent Express route collision
- **Vendor**: `GET /promotions/vendor/campaigns`, `POST /promotions/vendor/campaigns/:id/participate`, `DELETE /promotions/vendor/participations/:id`
- Mounted at `/promotions` and `/admin/promotions`

#### Admin UI (`artifacts/admin/src/pages/promotions-hub.tsx`)
- Tabs: Offers, Campaigns, Analytics, AI Insights
- Template selector for 9 offer types
- Targeting rules, bulk actions, campaign color editor
- AI recommendations panel, offer analytics
- Approval Queue panel (orange) showing pending offers with approve/reject buttons
- Submit for Approval button on draft offer cards
- Status filter dropdown with all statuses including `pending_approval` and `rejected`
- Admin sidebar: "Promotions Hub" entry (Megaphone icon) replacing Flash Deals nav
- i18n key `navPromotionsHub` added to all 3 language blocks (en, ur, en-PK)

#### Customer App (`artifacts/ajkmart/`)
- **`app/offers.tsx`** — Dedicated Offers & Deals screen with tabs (All, Flash, Free Ship, Cashback, New User, Saved 🔖), horizontal grouped sections, For You personalized section, offer detail bottom sheet with "Use Now" → cart routing, bookmark toggle icon on each offer card
- **`app/(tabs)/index.tsx`** — `OffersStrip` component added to home screen (between Flash Deals and Trending), shows offer count badge and category quick-access cards

#### Vendor App (`artifacts/vendor-app/`)
- **`src/pages/Campaigns.tsx`** — New Campaigns page: browse active platform campaigns, join via participation request, withdraw pending requests, status tracking (pending/approved/rejected)
- Navigation: Campaigns route added to SideNav and BottomNav (🎯 icon)
- i18n key `campaignsLabel` added to all 3 language blocks

### Ride Booking Flow — Visual & UX Overhaul

The customer app's ride journey screens (RideBookingForm, NegotiationScreen, RideTracker, CancelModal) received a full InDrive-inspired dark-accent redesign. Key additions:
- `constants/rideTokens.ts` — ride-scoped design tokens (dark bg, amber accent, emerald, SOS red)
- Amber gradient CTAs ("Book Now" + "Offer Your Fare"), consistent across all ride screens
- Negotiation screen: radar/pulse animation, bid cards with Accept + Counter actions, BidCardSkeleton
- RideTracker: persistent SOS in header, prominent OTP card, dark gradient header
- CancelModal: dark ride-mode treatment (amber accents, translucent footer)
- Reanimated entry animations on service cards, bid cards, and OTP card
- All SSE/socket/OTP/SOS/cancel API wiring preserved

### Admin Orders Module Refactoring — Completed Changes

#### Modular Component Structure (`artifacts/admin/src/pages/orders/`)
- **`index.tsx`** — Main Orders page component (~380 lines, down from 1094). Composes all sub-components.
- **`constants.ts`** — Shared constants (STATUS_LABELS, ALLOWED_TRANSITIONS, PAGE_SIZES), types (SortKey, SortDir), helper functions (isTerminal, canCancel, allowedNext, escapeCSV, exportOrdersCSV).
- **`GpsMiniMap.tsx`** — Leaflet-based GPS mini-map showing customer/delivery locations.
- **`GpsStampCard.tsx`** — GPS location details card with mismatch warnings and reverse geocoding.
- **`SortHeader.tsx`** — Reusable sortable column header button.
- **`OrdersStatsCards.tsx`** — Statistics grid (Total, Pending, Active, Delivered, Revenue).
- **`OrdersFilterBar.tsx`** — Search, type filter, status filter, date range filter with clear-all.
- **`OrdersTable.tsx`** — Desktop data table with sortable columns, inline status dropdowns, pagination.
- **`OrdersMobileList.tsx`** — Mobile card-based order list with pagination.
- **`OrderDetailDrawer.tsx`** — Order detail drawer/dialog with all sub-sections.
- **`CancelConfirmDialog.tsx`** — Cancel order confirmation dialog with wallet refund notice.
- **`RefundConfirmDialog.tsx`** — Refund dialog with quick-select percentages and validation.
- **`DeliverConfirmDialog.tsx`** — Delivery confirmation dialog.
- **`RiderAssignPanel.tsx`** — Rider search and assignment panel.

#### Backend Efficiency Fix (`artifacts/api-server/src/routes/admin/orders.ts`)
- **`GET /orders-enriched`**: Replaced fetching ALL users with SQL LEFT JOIN on users table. Added server-side filtering (status, type, date range, search via ILIKE) and pagination support with `page` and `limit` query params.

#### Accessibility & Semantic HTML
- Proper heading hierarchy (H1 page title, H2 section headers, H3 sub-sections) with sr-only labels.
- All interactive elements have aria-labels. Role attributes on filter groups, alerts, pagination nav.
- Keyboard navigation on table rows and card items (Enter/Space to open detail drawer).
- Minimum 36px touch targets on all interactive elements.

### Guest-to-Auth Flow Audit & Hardening — Completed Changes

#### AuthGateSheet Component
- **`artifacts/ajkmart/components/AuthGateSheet.tsx`**: New bottom-sheet auth prompt with `AuthGateSheet` (sign-in prompt with "Sign In" and "Continue Browsing" buttons), `RoleBlockSheet` (blocks vendor/rider accounts from customer actions), and `useAuthGate`/`useRoleGate` hooks for consistent gating pattern.

#### Auth Gating Applied Across Screens
- **`app/food/index.tsx`**, **`app/mart/index.tsx`**, **`app/product/[id].tsx`**, **`app/search.tsx`**, **`app/pharmacy/index.tsx`**, **`components/WishlistHeart.tsx`**, **`components/ride/RideBookingForm.tsx`**, **`app/cart/index.tsx`**: All auth-required actions (add to cart, place order, book ride, wishlist toggle, prescription upload) now show `AuthGateSheet` for guests and `RoleBlockSheet` for vendor/rider accounts instead of crashing or silently failing.

#### Profile Section Audit, Fixes & Refactor
- **`app/(tabs)/profile.tsx`** refactored from ~2390 lines to ~713 lines. Six modal components extracted into `components/profile/`:
  - `KycModal.tsx` — KYC verification flow
  - `EditProfileModal.tsx` — Profile editing with avatar upload
  - `NotificationsModal.tsx` — Notification list with routing
  - `DeleteAccountRow.tsx` — Account deletion with confirmation
  - `PrivacyModal.tsx` — Privacy, security, 2FA, language, password change
  - `AddressesModal.tsx` — Saved addresses CRUD
  - `shared.ts` — Shared styles, constants, and utilities
  - `index.ts` — Barrel exports
- Bug fixes applied: `stripPkCode()` for phone display, `activeOpacity={1}` on modal overlays, KYC MIME caching from picker, notification `typeMap` expanded (food/mart/pharmacy/parcel/deals), `n.link` deep link fallback, platform config cities with fallback.
- **`artifacts/api-server/src/routes/settings.ts`**: PUT endpoint now whitelists allowed fields (boolean toggles + language) and validates types before writing to DB.
- **`artifacts/api-server/src/routes/users.ts`**: Profile update now checks CNIC uniqueness across users.
- **`artifacts/api-server/src/routes/kyc.ts`**: Both submit endpoints validate DOB format (YYYY-MM-DD), reject future dates, and validate gender enum (male/female).

#### Null/Undefined Crash Fixes
- **`app/(tabs)/profile.tsx`**: Optional chaining on `user.name.split`, `user.avatar.startsWith`, `user.username`, `user.city`, `user.area`, `user.address`, `user.latitude`, `user.longitude`, `user.cnic`.

#### Ghost Cart State on Logout
- **`context/AuthContext.tsx`**: Socket disconnect happens before state clear; `@ajkmart_cart` AsyncStorage key cleared in `doLogout`.
- **`context/CartContext.tsx`**: Watches token transition from truthy to null — resets in-memory cart items and ack state on logout.
- **`app/_layout.tsx`**: React Query cache cleared when user transitions from logged-in to logged-out.

#### Guest Browsing Routes
- **`app/_layout.tsx`**: `GUEST_BROWSABLE` route set allows guests to browse food, mart, ride, pharmacy, parcel, product, search, cart, and categories screens without forced redirect to auth. Auth-required actions within these screens are gated at the action level via AuthGateSheet.

#### Home Screen Service Navigation
- **`app/(tabs)/index.tsx`**: Service grid/list no longer redirects guests to `/auth`; guests navigate directly to service screens where action-level auth gates handle protected operations. Lock badge icons removed.

### Wallet MPIN Security & Hide/Unhide — Completed Changes

#### Database Schema (`lib/db/src/schema/users.ts`)
- **`wallet_pin_hash`**: Bcrypt-hashed 4-digit MPIN for wallet transaction security
- **`wallet_pin_attempts`**: Failed MPIN attempt counter (locks after 5 failed attempts)
- **`wallet_pin_locked_until`**: Timestamp for MPIN lock expiry (30-minute lockout)
- **`wallet_hidden`**: Boolean flag for hiding wallet balance display

#### API — MPIN Routes (`artifacts/api-server/src/routes/wallet.ts`)
- **POST `/wallet/pin/setup`**: Create 4-digit MPIN (bcrypt hashed, 10 rounds). Rejects if already set.
- **POST `/wallet/pin/verify`**: Verify MPIN, returns temporary `pinToken` (5-min TTL). Tracks failed attempts (5 max → 30-min lockout).
- **POST `/wallet/pin/change`**: Change MPIN (requires old PIN verification). Invalidates all existing pinTokens.
- **POST `/wallet/pin/forgot`**: Send OTP to registered phone for MPIN reset. Rate-limited (3 per 5 min).
- **POST `/wallet/pin/reset-confirm`**: Verify OTP and set new MPIN. Validates OTP hash + expiry.
- **PATCH `/wallet/visibility`**: Toggle wallet balance hide/unhide (persisted server-side).
- **GET `/wallet`**: Response now includes `pinSetup` (boolean) and `walletHidden` (boolean).
- **`/send` and `/withdraw`**: Require `x-wallet-pin-token` header when user has MPIN set and `wallet_mpin_enabled` platform setting is on. Token is single-use.

#### Admin — MPIN Management
- **POST `/admin/users/:id/reset-wallet-pin`** (`artifacts/api-server/src/routes/admin/users.ts`): Admin force-resets user's MPIN (clears hash, attempts, lock).
- **Admin User Detail** (`artifacts/admin/src/pages/users.tsx`): Shows "Wallet MPIN" card with reset button when user has MPIN set.
- **Platform Config** (`artifacts/api-server/src/routes/platform-config.ts`): `wallet_mpin_enabled` setting exposed as `customer.mpinEnabled`.

#### Customer App — MPIN UI (`artifacts/ajkmart/app/(tabs)/wallet.tsx`)
- **Balance Hide/Unhide**: Eye icon toggle next to balance amount. Shows "Rs. ••••••" when hidden. Persisted via PATCH `/wallet/visibility`.
- **MPIN Setup Modal**: 4-digit PIN entry with visual dot indicators, create → confirm flow.
- **MPIN Verify Modal**: Auto-submits on 4th digit. Shows remaining attempts on wrong PIN. "Forgot MPIN?" link.
- **MPIN Forgot Modal**: Two-step OTP flow — request OTP → enter OTP + new PIN.
- **MPIN Change Modal**: Two-step — enter current PIN → enter new PIN.
- **Security Card**: Shows "Wallet Security" section with "Create MPIN" or "Change MPIN" button based on setup status.
- **Transaction Protection**: Send/Withdraw buttons trigger MPIN verification first when PIN is set. Pin token passed via `x-wallet-pin-token` header.

### Demo Data & Admin Data Management Controls — Completed Changes

#### API — System Data Management Endpoints (`artifacts/api-server/src/routes/system.ts`)
- **POST `/admin/system/remove-all`**: Transactional wipe of all user-generated data (orders, rides, pharmacy, parcels, wallet transactions, reviews, notifications, products, banners, promos, flash deals, vendor/rider profiles, service zones, users). Preserves admin_accounts + platform_settings. Creates undo snapshot before executing.
- **POST `/admin/system/seed-demo`**: Seeds comprehensive AJK-themed demo data — 22 users (8 customers, 8 riders, 6 vendors), vendor/rider profiles, 3 service zones, 38+ mart/food products, 24 orders, 15 rides, 6 pharmacy orders, 6 parcel bookings, 32 wallet transactions, 22 reviews, 12 notifications, 6 banners, 5 promo codes, flash deals, and saved addresses. Creates undo snapshot.
- **`ensureSystemVendor()`**: Creates `ajkmart_system` vendor user if missing, fixing FK constraint issue when seeding products after a data wipe.
- **GET `/admin/system/stats`**: Extended with vendorProfiles, riderProfiles, serviceZones counts.

#### API — Admin User Creation (`artifacts/api-server/src/routes/admin/users.ts`)
- **POST `/admin/users`**: New endpoint for creating users from admin panel. Supports phone, name, role (customer/rider/vendor), city, area, email. Auto-approves and sets initial wallet balance.

#### Admin Panel — System & Data UI (`artifacts/admin/src/pages/settings-system.tsx`)
- Redesigned with 3 prominent action buttons: Remove All Data (red, requires typing REMOVE to confirm), Load Demo Data (green, requires typing DEMO to confirm), Add Custom Data (blue, opens form panel).
- Custom data entry forms for Users, Products, Promo Codes, and Banners with validation and correct API paths.
- Retained DB stats display, backup/restore functionality, and undo system with countdown timers.
- Legacy reset actions collapsed under "Advanced Reset Actions" toggle.

### White Label Delivery Access Control — Completed Changes

#### Database Schema
- **`lib/db/src/schema/delivery_whitelist.ts`**: Three new tables — `delivery_whitelist` (type, targetId, serviceType, status, validUntil, deliveryLabel, notes, createdBy), `delivery_access_requests` (vendorId, serviceType, status, requestedAt, resolvedAt, resolvedBy, notes), `system_audit_log` (adminId, adminName, action, targetType, targetId, oldValue, newValue).
- **`lib/db/migrations/0022_delivery_access_control.sql`**: Migration file matching Drizzle schema exactly.

#### API — Delivery Access Library
- **`artifacts/api-server/src/lib/delivery-access.ts`**: Core utility with `checkDeliveryEligibility(userId, vendorId, serviceType)` for full eligibility check and `checkUserOnlyEligibility(userId, serviceType)` for cart pre-check (no vendorId). Uses 5-min TTL cache (`_whitelistCache`) with `invalidateDeliveryAccessCache()`. Supports four modes: `all` (everyone allowed), `stores` (vendor whitelist only), `users` (user whitelist only), `both` (both must be whitelisted). Fail-open on errors.

#### API — Admin Endpoints
- **`artifacts/api-server/src/routes/admin/delivery-access.ts`**: Full admin CRUD — GET/PUT mode, GET/POST/DELETE whitelist entries (with DB-level search filtering pre-pagination), GET/PATCH requests (approve auto-creates whitelist entry + sends notification), GET audit log. All changes logged to `system_audit_log`.

#### API — Customer & Vendor Endpoints
- **`artifacts/api-server/src/routes/delivery-eligibility.ts`**: GET `/delivery/eligibility` for customer pre-check (supports both full check with vendorId and user-only check without). Vendor endpoints: GET `/vendor/delivery-status` (per-service-type status), POST `/vendor/delivery-request` (submit access request).

#### API — Order Enforcement
- POST `/orders` enforces delivery eligibility server-side, returns 403 with `reasonCode: "delivery_not_eligible"` when blocked.

#### Admin UI
- **`artifacts/admin/src/pages/delivery-access.tsx`**: Full admin page with mode selector (all/stores/users/both), whitelist management with search/filter, request management with approve/reject, audit log viewer. Routed in App.tsx and AdminLayout.tsx with i18n.
- **`artifacts/admin/src/pages/vendors.tsx`**: Inline delivery toggle badges on vendor cards (click to whitelist/unwhitelist). Pending delivery request count badge with one-click approve action. Uses `vendorWhitelistMap` (targetId → whitelistEntryId) for delete operations.

#### Vendor App
- **`artifacts/vendor-app/src/pages/Dashboard.tsx`**: Per-service-type delivery status display (Active/Pending/Request button for mart/food/pharmacy/parcel). API methods `getDeliveryAccessStatus()` and `requestDeliveryAccess()` in api.ts.

#### Customer App
- **`artifacts/ajkmart/app/cart/index.tsx`**: Delivery eligibility pre-check on cart load — passes `productId` from first cart item to resolve vendorId server-side for store-level blocking. Shows store-specific and user-specific blocking messages. Prominent "Delivery Unavailable" yellow banner with "Self-Pickup Instead" green button replaces Place Order button when blocked. Self-pickup orders use `paymentMethod: "pickup"` which bypasses delivery eligibility on server. Server-side 403 errors from POST /orders read `ApiError.data.reasonCode` and `ApiError.data.error` for delivery-specific messaging.

### Dynamic Categories System — Completed Changes

#### Database Schema
- **`lib/db/src/schema/categories.ts`**: New `categories` table with fields: id, name, icon, type (mart/food/pharmacy), parentId (self-referencing hierarchy), sortOrder, isActive, timestamps.

#### API Endpoints
- **`artifacts/api-server/src/routes/categories.ts`**: Replaced hardcoded category arrays with database-driven categories. Endpoints: GET `/categories` (hierarchical list with children and product counts), GET `/categories/tree` (full tree for admin), POST/PATCH/DELETE for CRUD, POST `/categories/reorder`. Auto-seeds initial categories from previous hardcoded data.
- **`artifacts/api-server/src/routes/admin.ts`**: Admin-specific category management routes: GET `/admin/categories/tree`, POST/PATCH/DELETE for admin CRUD.

#### Admin Panel
- **`artifacts/admin/src/pages/categories.tsx`**: Categories management page with expandable tree view, type filtering (mart/food/pharmacy), add/edit/delete dialogs, parent category selection, icon picker, active/inactive toggle, sort order management.
- **`artifacts/admin/src/App.tsx`**: Route registered at `/categories`.
- **`artifacts/admin/src/components/layout/AdminLayout.tsx`**: Navigation entry added under "Vendor Portal" group.

#### Mobile App
- **`artifacts/ajkmart/app/categories/index.tsx`**: Full-screen categories browsing with AliExpress-style sidebar navigation. Left sidebar shows top-level categories with active indicator, right panel shows sub-categories grid and product list filtered by selected category.
- **`artifacts/ajkmart/app/search.tsx`**: Enhanced filter panel with price range inputs, star rating filter chips (Any, 3★+, 3.5★+, 4★+, 4.5★+), clear all button, and apply filters button.

#### API Client
- **`lib/api-client-react/src/discovery.ts`**: Added `getHierarchicalCategories` function and `HierarchicalCategory` interface.
- **`lib/api-client-react/src/index.ts`**: Exported new function and type.

#### i18n
- **`lib/i18n/src/index.ts`**: Added `navCategories` translation key in English, Urdu, and Hindi sections.

### Product Reviews, Wishlist & Image Gallery — Completed Changes

#### Backend
- **`artifacts/api-server/src/routes/wishlist.ts`**: New wishlist API with POST add, DELETE remove, GET list, GET check endpoints (all auth-protected, user-scoped).
- **`artifacts/api-server/src/routes/reviews.ts`**: Extended with GET `/reviews/product/:productId` (paginated), GET `/reviews/product/:productId/summary` (avg/distribution), and new `orderType: "product"` branch in POST that validates product existence instead of order ownership. Duplicate check uses `productId + userId` for product reviews.

#### API Client
- **`lib/api-client-react/src/discovery.ts`**: Added `getWishlist`, `addToWishlist`, `removeFromWishlist`, `checkWishlist`, `getProductReviews`, `getProductReviewSummary`, `submitProductReview`, `uploadImage` functions with TypeScript types (`WishlistItem`, `ProductReview`, `ProductReviewsResponse`, `ReviewSummary`).

#### Mobile App (AJKMart)
- **`artifacts/ajkmart/components/WishlistHeart.tsx`**: Reusable heart toggle component with optimistic updates, scale animation, wishlist query cache hydration.
- **`artifacts/ajkmart/app/product/[id].tsx`**: Full rewrite with wishlist heart, full-screen image viewer, multi-image carousel with dot indicators, reviews section with rating bars/distribution, Write Review modal (star picker + text + up to 3 photos via image picker).
- **`artifacts/ajkmart/app/wishlist.tsx`**: Dedicated wishlist screen with 2-column grid, remove-with-animation, auth guard, empty/error/loading states.
- **`artifacts/ajkmart/app/(tabs)/profile.tsx`**: Added "My Wishlist" entry in activity section.
- **`artifacts/ajkmart/app/(tabs)/index.tsx`**: Heart icons on trending products and flash deal cards.
- **`artifacts/ajkmart/app/mart/index.tsx`**: Heart icons on FlashCard and ProductCard components.
- **`artifacts/ajkmart/app/search.tsx`**: Heart icons on search result cards.

### Step 3: UI/UX & Refactoring — Completed Changes

#### B-17/B-21: Admin Route Split
- **`artifacts/api-server/src/routes/admin.ts`**: Refactored from 5267-line monolith into a thin barrel file mounting 7 sub-routers.
- **`artifacts/api-server/src/routes/admin-shared.ts`**: Shared exports (AdminRequest type, stripUser, adminAuth, getPlatformSettings, revokeAllUserSessions, serializeSosAlert, notification key constants, DEFAULT_PLATFORM_SETTINGS, login attempt map, ride/location defaults).
- **`artifacts/api-server/src/routes/admin/auth.ts`**: Admin login/register/logout.
- **`artifacts/api-server/src/routes/admin/users.ts`**: User management, ban/unban, identity edits, KYC, debt.
- **`artifacts/api-server/src/routes/admin/orders.ts`**: Order management, status updates, rider assignment.
- **`artifacts/api-server/src/routes/admin/rides.ts`**: Ride management, service types, cancellation, refunds.
- **`artifacts/api-server/src/routes/admin/finance.ts`**: Payouts, commission, vendor/rider financials.
- **`artifacts/api-server/src/routes/admin/content.ts`**: Banners, FAQs, promos, categories, flash deals.
- **`artifacts/api-server/src/routes/admin/system.ts`**: Settings, notifications, audit, analytics, SOS.

#### B-20: Pino Structured Logging
- Replaced all `console.log/error/warn` with pino `logger.info/error/warn` in rider.ts (22), security.ts (10), rides.ts (6), wallet.ts (4), admin/finance.ts (4), reviews.ts.
- Logger imported from `artifacts/api-server/src/lib/logger.ts`.

#### B-18: TypeScript `any` Type Cleanup
- Replaced `catch (e: any)` → `catch (e: unknown)` across all route files.
- Replaced `(req as any).adminId` → `(req as AdminRequest).adminId` in admin sub-routers.
- Replaced `req.body as any` → `req.body as Record<string, unknown>` in content routes.
- Replaced loose `any[]` → `unknown[]` or typed arrays in finance, system routes.
- Remaining `as any` casts are legitimate Drizzle ORM dynamic query patterns.

#### A-04: ARIA Accessibility
- **`artifacts/admin/src/components/ui/dialog.tsx`**: Added `aria-describedby={undefined}` to suppress Radix warning, `aria-label="Close dialog"` on close button.
- **`artifacts/admin/src/components/ui/sheet.tsx`**: Same ARIA fixes for sheet overlay component.

### Step 2: API & Frontend Sync — Completed Changes

#### C-06: Payment Status Route Alias
- **`artifacts/api-server/src/routes/payments.ts`**: Added `GET /:orderId/status` route alias alongside legacy `GET /order-status/:orderId`. Customer app calls `/payments/{orderId}/status` — now correctly routed. Both paths share `handleOrderPaymentStatus()` handler.

#### S-02: Vehicle Registration Field Alias
- **`artifacts/api-server/src/routes/rider.ts`**: `profileSchema` now accepts `vehicleRegistration` as alias for `vehicleRegNo`. Uses Zod `.transform()` to normalize.

#### S-03: KYC Photo Field Aliases
- **`artifacts/api-server/src/routes/kyc.ts`**: `POST /kyc/submit` now accepts photo fields under multiple names: `frontIdPhoto`/`idFront`/`idPhoto`, `backIdPhoto`/`idBack`, `selfiePhoto`/`selfie`. Resolves mismatch between different clients.

#### S-04: Pharmacy Prescription — Already Working
- Customer app sends `prescriptionPhotoUri` which matches backend expectation. No fix needed.

#### Zod Validation Added
- **`users.ts`**: `profileUpdateSchema` with CNIC preprocess (strips dashes/spaces before validating 13 digits), `deleteAccountSchema`.
- **`wallet.ts`**: `depositSchema`, `sendSchema`, `withdrawSchema` — validates amount, paymentMethod, transactionId, receiverPhone, accountNumber.
- **`payments.ts`**: `paymentInitiateSchema` — validates gateway, amount, orderId.

#### Response Standardization
- Profile update, payment status endpoints now return `{ success: true, ... }` alongside flat fields for backward compatibility.

### Critical Bug Fixes (Step 1) — Completed Changes

#### D-01 & D-02: Foreign Key References + Cascade Deletes
- **All schema files in `lib/db/src/schema/`**: Added `.references(() => usersTable.id, { onDelete: "cascade" })` to all `userId` columns across 25+ tables. Added ride/product/route FK references with appropriate cascade/set-null behavior.
- **`lib/db/migrations/0018_add_foreign_keys.sql`**: SQL migration file for reference (schema was applied via `drizzle-kit push`).
- Created `ajkmart_system` user record to satisfy products FK constraint for system-generated products.

#### B-01: Ride Endpoint Auth Middleware
- **`artifacts/api-server/src/routes/rides.ts`**: Replaced inline JWT parsing on `GET /:id` and `GET /:id/track` with standard `customerAuth` middleware. Removed unused `verifyUserJwt` import.

#### B-02: SOS Admin Auth Guard
- **`artifacts/api-server/src/routes/sos.ts`**: Replaced custom `getAdminFromRequest()` helper with proper `adminAuth` middleware from `admin.ts` on all admin endpoints (`GET /alerts`, `PATCH /acknowledge`, `PATCH /resolve`). Also converted `POST /` SOS trigger to use `customerAuth` middleware.

#### B-03: Login Rate Limiting — Already Implemented
- `handleUnifiedLogin` already uses `checkLockout`/`recordFailedAttempt`/`resetAttempts` from `security.ts`. No changes needed.

#### B-04: Wallet Deposit Rate Limiting
- **`artifacts/api-server/src/routes/wallet.ts`**: Added `checkAvailableRateLimit` (10 requests per 15 minutes, keyed by IP+userId) to `POST /deposit` endpoint.

#### B-05: Ride Wallet Transaction Atomicity — Already Implemented
- Wallet deduction + ride creation already wrapped in `db.transaction()`. Fixed `any` type on `rideRecord` to `typeof ridesTable.$inferSelect`.

#### B-06: P2P Transfer Race Condition Fix
- **`artifacts/api-server/src/routes/wallet.ts`**: Added `SELECT ... FOR UPDATE` on sender row in P2P transfer transaction to prevent concurrent overspend.

#### B-07: BroadcastRide Skip Busy Riders
- **`artifacts/api-server/src/routes/rides.ts`**: Added active-ride check in `broadcastRide()` to skip riders who already have an active ride (accepted/arrived/in_transit status).

### Sort/Filter Bar — Completed Changes

#### Mart & Food Screens (Server-Side Sort)
- **`app/mart/index.tsx`**, **`app/food/index.tsx`**: Horizontal sort chip bar (Default, Price Low→High, Price High→Low, Popular, Top Rated, Newest) below category tabs. Sort passed as `sort` query param to `useGetProducts` for server-side ordering.
- **API**: `GET /products` accepts `sort` param (`price_asc`, `price_desc`, `popular`, `rating`, `newest`) with `ORDER BY` in SQL query.

#### Pharmacy Screen (Client-Side Sort)
- **`app/pharmacy/index.tsx`**: Sort chip bar (Default, Price Low→High, Price High→Low) below category tabs, above Rx notice. Client-side sorting in `filtered` useMemo since pharmacy uses `loadMeds` fetch. Default order = newest (API returns by createdAt desc).

#### i18n
- Sort chip labels (`priceLowHigh`, `priceHighLow`, `popular`, `topRated`, `newest`, `defaultLabel`) added in English, Urdu, and Roman Urdu in `lib/i18n/src/index.ts`.

### Pull-to-Refresh & UI Polish — Completed Changes

#### PullToRefresh Component (All 3 Web Apps)
- **`artifacts/vendor-app/src/components/PullToRefresh.tsx`**: Shared pull-to-refresh wrapper with touch gesture detection, animated spinner, "last updated" timestamp, and configurable accent color (orange for vendor).
- **`artifacts/rider-app/src/components/PullToRefresh.tsx`**: Same component with green accent for rider app.
- **`artifacts/admin/src/components/PullToRefresh.tsx`**: Same component with blue accent for admin panel.

#### Pull-to-Refresh Integration (All Data Pages)
- **Vendor App:** Dashboard, Orders, Products, Wallet — all wrapped with PullToRefresh. Each page invalidates its relevant React Query keys on pull.
- **Rider App:** History, Earnings, Wallet, Notifications — all wrapped with PullToRefresh.
- **Admin Panel:** Dashboard, Orders, Users, Riders, Vendors — all wrapped with PullToRefresh.

### Phase 4: Ride Booking & Fare Logic — Completed Changes

#### P4-T001 — DB Migration 0016 + rides schema update
- **`lib/db/migrations/0016_ride_phase4.sql`**: Added columns: `trip_otp`, `otp_verified`, `is_parcel`, `receiver_name`, `receiver_phone`, `package_type`, `arrived_at`, `started_at`, `completed_at`, `cancelled_at`.
- **`lib/db/src/schema/rides.ts`**: Schema updated with all new fields.

#### P4-T002 — Routing-provider road distance in fare engine
- **`artifacts/api-server/src/routes/rides.ts`**: `getRoadDistanceKm()` helper added — tries Google Directions → Mapbox Directions → haversine fallback. Used in `/estimate` and `POST /` ride creation. Response includes `distanceSource`.

#### P4-T003 — OTP system + parcel support + event timestamps
- **`artifacts/api-server/src/routes/rides.ts`**: `bookRideSchema` accepts `isParcel`, `receiverName`, `receiverPhone`, `packageType`. Parcel fields stored in DB.
- **`artifacts/api-server/src/routes/rider.ts`**: OTP generated on accept (both accept-bid and rider accept). `POST /rider/rides/:id/verify-otp` endpoint validates OTP, sets `otpVerified=true`. PATCH status records `arrivedAt/startedAt/completedAt/cancelledAt`. `in_transit` gated on `otpVerified`.
- **`artifacts/api-server/src/lib/socketio.ts`**: `emitRideOtp()` emits `ride:otp` event to customer's user room and the ride room.
- **`artifacts/api-server/src/routes/rides.ts`** `formatRide()`: Now includes all new timestamp fields + OTP/parcel fields in every response.

#### P4-T004 — Admin rides page enhanced with audit timestamps
- **`artifacts/admin/src/pages/rides.tsx`**: Detail modal now shows Parcel Info section (receiver, phone, package type), OTP Status badge (Verified/Pending with code), and full Event Timeline grid (Requested/Accepted/Arrived/Started/Completed/Cancelled + Last updated).
- **`artifacts/api-server/src/routes/admin.ts`**: `GET /admin/rides/:id` now returns all new fields: `arrivedAt`, `startedAt`, `completedAt`, `cancelledAt`, `tripOtp`, `otpVerified`, `isParcel`, `receiverName`, `receiverPhone`, `packageType`.

#### P4-T005 — Admin Fleet Map active-trip focus mode
- **`artifacts/admin/src/pages/live-riders-map.tsx`**: `makeRiderIcon` now accepts `hasActiveTrip` parameter. When a rider has a `currentTripId`, two concentric pulsing red rings animate around their marker. Icon cache key updated to include trip state.

#### Rider Dashboard Deep Audit & Refactor
- **`artifacts/rider-app/src/pages/Home.tsx`**: Refactored from 1673 lines to ~875 lines. All interactive elements audited button-by-button. State management kept in parent, sub-components receive handlers via props.
- **`artifacts/rider-app/src/components/dashboard/`**: 16 sub-component files extracted:
  - `helpers.ts` — formatCurrency (handles NaN/negative/Infinity), timeAgo, buildMapsDeepLink, ACCEPT_TIMEOUT_SEC, SVC_NAMES
  - `LiveClock.tsx`, `AcceptCountdown.tsx`, `RequestAge.tsx` — time display widgets
  - `Icons.tsx` — OrderTypeIcon, RideTypeIcon
  - `MiniMap.tsx` — Leaflet mini-map with platform map config (Mapbox/Google/OSM with rider-app override)
  - `SkeletonHome.tsx` — loading skeleton
  - `StatsGrid.tsx` — 4-column stats grid (deliveries, earnings, week, lifetime)
  - `OnlineToggleCard.tsx` — online/offline toggle with debounce, silence button
  - `SilenceControls.tsx` — timed mute (15/30/60m) with countdown display
  - `FixedBanners.tsx` (in SystemWarnings) — connection-lost, zone warning, wake-lock warning (fixed-position)
  - `InlineWarnings.tsx` (in SystemWarnings) — GPS, restriction, rider notice, cancel/ignore stats, low wallet
  - `OrderRequestCard.tsx` — delivery request card with accept/reject/dismiss/mini-map
  - `RideRequestCard.tsx` — ride request card with bargaining, counter offer validation (per-vehicle-type min fare + max multiplier)
  - `OfflineConfirmDialog.tsx` — confirm going offline with pending requests
  - `ActiveTaskBanner.tsx` — active task tracker banner (green/amber variants, top/bottom position)
  - `RequestListHeader.tsx` — request list header with live badge
  - `index.ts` — barrel exports
- Accessibility: aria-labels on all icon-only buttons, role="switch" on toggle, role="timer" on countdown, role="alert" on warnings, role="dialog" on confirm modal, role="list" on stats grid
- SEO: h1 for greeting, `<header>` and `<main>` semantic elements, meta description added to index.html
- Bug fixes: formatCurrency guards NaN/negative/Infinity, silence timer display shows correct minutes, duplicate drain handler registration removed (App.tsx handles globally)

#### P4-T006 — Rider App OTP entry step + parcel badge
- **`artifacts/rider-app/src/pages/Active.tsx`**: At `arrived` status with `!otpVerified` → shows blue "Verify OTP to Start" button. OTP modal with 4-digit input calls `POST /rider/rides/:id/verify-otp`. After verification, shows normal "Start Ride" button. `verifyOtpMut` mutation added.
- **`artifacts/rider-app/src/pages/Home.tsx`**: Parcel rides show `📦 Parcel` amber badge on request cards.
- **`artifacts/rider-app/src/lib/api.ts`**: `verifyRideOtp(id, otp)` method added.

#### P4-T007 — Customer Booking Web Portal (DELETED)
- **Removed**: `artifacts/customer` web portal was deleted at user's request.

### Step 1: Design System & Shared Components + Backend Foundation — Completed Changes

#### Frontend Design Tokens
- **`artifacts/ajkmart/constants/colors.ts`**: Added `gradients` export (primary, mart, food, ride, wallet, pharmacy, parcel, success, danger, dark), `serviceColors` lookup (main/light/dark per service), `xxxxl: 48` to spacing, service dark tint variants (martDark, foodDark, rideDark, walletDark, pharmacyDark, parcelDark).

#### New/Upgraded UI Components
- **`artifacts/ajkmart/components/ui/Avatar.tsx`**: New — initials fallback with deterministic color hash, supports xs/sm/md/lg/xl sizes, image URI or name-based rendering.
- **`artifacts/ajkmart/components/ui/Divider.tsx`**: New — horizontal divider with optional centered label, configurable color and spacing.
- **`artifacts/ajkmart/components/ui/Tag.tsx`**: New — pill tag with variant colors (success/warning/danger/info/neutral/primary), optional icon, removable with onRemove callback, outlined mode.
- **`artifacts/ajkmart/components/ui/ErrorState.tsx`**: New — error display with icon/emoji, title, subtitle, retry button.
- **`artifacts/ajkmart/components/ui/Modal.tsx`**: New — centered modal overlay with title, subtitle, close button, content slot.
- **`artifacts/ajkmart/components/ui/ScreenContainer.tsx`**: New — layout primitive wrapping SafeAreaView + scroll + keyboard avoidance. Configurable edges, scroll/static, background color.
- **`artifacts/ajkmart/components/ui/Input.tsx`**: Upgraded — added `success` state, `showCharCount`/`maxLength` char counter, `clearable` with clear button, `rightElement` slot, `onClear` callback.
- **`artifacts/ajkmart/components/ui/index.ts`**: Updated barrel export with all new components (Avatar, Divider, ErrorState, Modal, ScreenContainer, SkeletonBlock, SmartRefresh, Tag).

#### Backend API Response Standardization
- **`artifacts/api-server/src/lib/response.ts`**: New — shared response helpers: `sendSuccess`, `sendCreated`, `sendError`, `sendErrorWithData`, `sendValidationError`, `sendUnauthorized`, `sendForbidden`, `sendNotFound`, `sendTooManyRequests`, `sendInternalError`. All enforce `{ success, data?, error?, message? }` format with bilingual defaults (EN error + UR message via DEFAULT_UR lookup).
- **`artifacts/api-server/src/app.ts`**: Global error handler upgraded — maps error codes to bilingual messages (EN/UR), structured Pino logging with IP/code/method/url, standardized `{ success, error, message, code }` format.
- **`artifacts/api-server/src/routes/health.ts`**: Upgraded — returns DB status with latency, uptime seconds, timestamp, service health object. Uses `sendSuccess` helper. Returns 503 with full `data` payload on degraded status.
- **`artifacts/api-server/src/middleware/security.ts`**: All middleware responses (customerAuth, riderAuth, requireRole, rateLimitMiddleware, verifyCaptcha, idorGuard) standardized to `{ success: false, error, message }` format with bilingual EN/UR messages.
- **`artifacts/api-server/src/middleware/validate.ts`**: New — Zod validation middleware factory: `validate({ body?, query?, params? })`, `validateBody`, `validateQuery`, `validateParams`. Returns structured `{ success: false, error, message, code: "VALIDATION" }` with bilingual error messages and Pino logging.
- **Response helpers imported in 37/39 route files** (excluding `auth.ts` per user instruction and `admin.ts` barrel-only file). Fully converted routes: categories, wishlist, notifications, products, banners, addresses, reviews, users, health, push, uploads, sos, settings, platform-config. Remaining routes have imports ready for incremental body conversion.

### User Preferences
- I want iterative development.
- Ask before making major changes.
- Do not make changes to folder `artifacts/ajkmart`.
- Do not make changes to file `artifacts/api-server/src/routes/auth.ts`.
- Prefer clear and concise explanations.

### Phase 3: Live Tracking & Map Integration — Completed Changes

#### T001 — Socket.io: vehicleType + currentTripId in location broadcast
- **`artifacts/api-server/src/lib/socketio.ts`**: `emitRiderLocation` signature extended with optional `vehicleType?` and `currentTripId?` fields.
- **`artifacts/api-server/src/routes/locations.ts`**: `broadcastRiderLocation` now fetches `vehicleType` from the `users` table and includes it in the socket emission. `currentTripId` is broadcast when set.

#### T002 — Secure Map Config API endpoint
- **`artifacts/api-server/src/routes/maps.ts`**: `GET /api/maps/config` endpoint added. Returns `{ provider, token, searchProvider, searchToken, routingProvider, enabled, defaultLat, defaultLng }` from `platform_settings` (DB-managed). API keys are served per-request so they never appear in frontend build artifacts. The active provider's token is returned — never all keys at once.

#### T003 — Admin Maps & API Settings tab (fully rebuilt)
- **`artifacts/admin/src/pages/settings-integrations.tsx`**: Maps tab completely rewritten with:
  - **Active Map Provider** selector (OSM / Mapbox GL JS / Google Maps) with visual card-picker UI
  - **Mapbox token input** shown conditionally when Mapbox is selected
  - **Google API key input** shown conditionally when Google is selected
  - **Search/Autocomplete API** selector (Google Places / LocationIQ) with provider-specific key fields
  - **LocationIQ API key input** shown conditionally when LocationIQ is selected
  - **Routing Engine** selector (Mapbox Directions / Google Directions)
  - All existing Maps Usage toggles and Fare Calculation fields retained

#### T004 — UniversalMap component (lazy Mapbox loading)
- **`artifacts/admin/src/components/UniversalMap.tsx`**: Created. Provides a provider-agnostic map component:
  - **Leaflet implementation**: Uses react-leaflet MapContainer with OSM/Mapbox raster/Google tile URL switching. Supports normalised `MapMarkerData[]` and `MapPolylineData[]` props. Renders username labels above markers and 50%-opacity dimmed state.
  - **Mapbox GL JS implementation**: Lazily loaded via `React.lazy + import("react-map-gl")` — only downloaded when Mapbox provider is active, keeping the initial bundle lean. Uses GeoJSON Source/Layer for polylines and `<Marker>` for custom HTML markers.
  - **`artifacts/admin/src/global.d.ts`**: Ambient module declarations for `react-map-gl` and `mapbox-gl` to satisfy `tsc --noEmit` in the pnpm virtual-store layout.

#### T005 — Admin Fleet Map enhancements
- **`artifacts/admin/src/pages/live-riders-map.tsx`**:
  - **Dynamic tile layer**: Reads provider + token from `/api/maps/config` at runtime. Supports Mapbox raster, Google Maps, and OSM tile URLs — no hardcoded provider in source.
  - **Username labels**: `makeRiderIcon` now accepts an optional `label` string rendered as a floating dark pill above each marker. Toggleable via "Labels" button in the map toolbar.
  - **Dimmed offline markers**: Riders offline but active in the last 24 h render at 50% opacity via `wasRecentlyActive()` helper — visually distinct from never-seen riders.
  - **vehicleType + currentTripId from socket**: `rider:location` handler extracts both fields into `vehicleTypeOverrides` and `currentTripIdOverrides` state; applied when merging riders. Popup shows active trip ID when set.
  - **History Playback floating panel**: A frosted-glass overlay appears on the map when any rider is selected. Contains date picker, GPS point count, and a range slider for scrubbing through the route. Uses the existing `useRiderRoute` hook and `Polyline` render — no new endpoints needed.
  - **Icon cache updated**: Cache key now includes `dimmed`, `label`, and status to prevent stale icon reuse.

#### T006 — Rider App GPS interval: 4 min → 5 seconds
- **`artifacts/rider-app/src/pages/Home.tsx`**: `IDLE_INTERVAL_MS` changed from `4 * 60 * 1000` (4 minutes) to `5 * 1000` (5 seconds). Riders now emit their GPS position every 5 s even when stationary, giving the Admin fleet map near-real-time updates. The `MIN_DISTANCE_METERS = 25` filter is still active to suppress duplicate sends when the rider hasn't moved.

### Phase 2 Cleanup — Completed Changes

#### 1. Security Fixes (Critical)
- **`artifacts/api-server/src/services/password.ts`**: Removed hardcoded JWT secret fallback (`"ajkmart-secret-2024"`) and TOTP encryption key fallback (`"ajkmart-totp-default-key-2024"`). Both now call `resolveRequiredSecret()` which throws an explicit error at call time if the env vars are missing — no more silent weak-key fallbacks.
- **`artifacts/api-server/src/routes/auth.ts`**: Dev OTP is now gated by BOTH `NODE_ENV === "development"` AND `ALLOW_DEV_OTP === "true"` env var. A single misconfigured `NODE_ENV` can no longer leak OTP codes into production API responses.

#### 2. Code Consolidation — requireRole Factory
- **`artifacts/api-server/src/middleware/security.ts`**: Added `requireRole(role, opts?)` factory function. Replaces the four separate `customerAuth`, `riderAuth`, `vendorAuth` (local copy in vendor.ts), and `adminAuth` middlewares with a single, DRY, configurable pattern. Supports `opts.vendorApprovalCheck` for vendor-specific pending/rejected status messages. Sets `req.customerId`, `req.customerUser`, `req.riderId`/`riderUser`, and `req.vendorId`/`vendorUser` as appropriate.
- **`artifacts/api-server/src/routes/vendor.ts`**: Removed the 50-line duplicate local `vendorAuth` function. Now uses `router.use(requireRole("vendor", { vendorApprovalCheck: true }))` — one line.

#### 3. Ghost Rider Fix — Heartbeat Expiry
- **`artifacts/api-server/src/lib/socketio.ts`**: Enhanced the stale-location cleanup interval. It now:
  1. Queries for all riders whose `live_locations.updatedAt` is older than 5 minutes (before deleting).
  2. Emits `rider:offline` event to `admin-fleet` for each stale rider with `{ userId, isOnline: false, reason: "heartbeat_timeout" }`.
  3. Updates `users.is_online = false` in the database for all affected riders (prevents ghost-online status in DB).
  4. Deletes the stale `live_locations` rows to remove ghost markers from the Admin fleet map.

#### 4. New Profile Tables (Schema Refactor — Phase 2)
- **`lib/db/src/schema/rider_profiles.ts`**: New table `rider_profiles` — stores all rider-specific fields: `vehicleType`, `vehiclePlate`, `vehicleRegNo`, `drivingLicense`, `vehiclePhoto`, `documents`. Linked to `users` by `userId`.
- **`lib/db/src/schema/vendor_profiles.ts`**: New table `vendor_profiles` — stores all vendor/store-specific fields: `storeName`, `storeCategory`, `storeBanner`, `storeDescription`, `storeHours`, `storeAnnouncement`, `storeMinOrder`, `storeDeliveryTime`, `storeIsOpen`, `storeAddress`, `businessType`, `businessName`, `ntn`. Linked to `users` by `userId`.
- **`lib/db/src/schema/users.ts`**: Vendor and rider fields marked as `DEPRECATED` with clear comments. They are retained for backward compatibility. Phase 3 will remove them after all queries are updated to JOIN the new profile tables.
- **`lib/db/migrations/0011_rider_vendor_profiles.sql`**: Creates both tables and populates them from existing `users` data.

#### 5. Static Data — AJK Cities in Database
- **`lib/db/migrations/0012_seed_ajk_locations.sql`**: Seeds all 15 AJK fallback cities (Muzaffarabad, Mirpur, Rawalakot, etc.) into the `popular_locations` table. They can now be managed, edited, or extended from the Admin Panel. The hardcoded array in `maps.ts` remains as a last-resort safety net if the DB is unavailable.

#### Important Environment Variables Added
- `ALLOW_DEV_OTP=true` — must be explicitly set alongside `NODE_ENV=development` for dev OTP mode to expose codes in API responses. Default: not set (production-safe).

### System Architecture

**Monorepo and Core Technologies:**
The project is structured as a pnpm monorepo using TypeScript. The frontend leverages Expo React Native with NativeWind for mobile applications, while the backend is an Express 5 REST API utilizing PostgreSQL and Drizzle ORM. Authentication is primarily phone number and OTP-based. API interactions are defined using OpenAPI 3.1, with Orval codegen generating React Query hooks and Zod schemas for validation. State management uses `AuthContext` and `CartContext` with AsyncStorage for persistence, and navigation is handled by `expo-router`.

**UI/UX and Theming:**
- **Color Scheme:** Primary blue (`#1A56DB`), accent amber (`#F59E0B`), and success green (`#10B981`).
- **Font:** Inter (400, 500, 600, 700). Noto Nastaliq Urdu (400, 500, 600, 700) for Urdu RTL text.
- **i18n:** Multi-language support via `@workspace/i18n` shared library. Supports 5 language modes: English, Urdu, Roman Urdu, English+Roman Urdu (dual), English+Urdu (dual). Uses `tDual()` for dual-line translations and `t()` for single-line. RTL support via `isRTL()`. All user-facing strings across all 3 client apps use translation keys. Nastaliq font loaded via Google Fonts CDN (web) and `@expo-google-fonts/noto-nastaliq-urdu` (mobile).
- **Application Structure:**
    - **Customer App (Expo React Native):** Features include grocery, food delivery, ride booking, pharmacy, parcel delivery, cart, checkout, order history, digital wallet, and user profile. Full auth system with 7 login methods (Phone OTP, Email OTP, Username/Password, Google, Facebook, Magic Link, Biometric) gated by admin platform config toggles. Includes AliExpress-style 5-step registration (Phone Verify → Personal Details → Address/GPS/City → Security/CNIC → Success with Account Level Badge), forgot/reset password with 2FA, 2FA setup/disable in profile, deep link handling for magic links. Auth screens: `app/auth/index.tsx` (login), `app/auth/register.tsx` (register), `app/auth/forgot-password.tsx` (reset). Auth context (`context/AuthContext.tsx`) manages 2FA pending state, biometric credentials via expo-secure-store, and proactive token refresh. Packages: expo-local-authentication, expo-secure-store, expo-auth-session.
    - **Admin Dashboard (React-Vite):** Provides comprehensive management for users, vendors, riders, services, system configurations (delivery fees, feature toggles, loyalty programs, payout rules), and content. It includes professional renderers for settings management with live previews and validation.
    - **Rider App (React-Vite):** Mobile-first web app for drivers using the **Dark Hero Design System** across ALL pages — auth (Login, Register, ForgotPassword), main (Home, Active, Notifications, Profile, Wallet, Earnings, History), settings (SecuritySettings), utility (NotFound, MaintenanceScreen). Design tokens: `bg-[#F5F6F8]` page bg, dark gradient hero `from-gray-900 via-gray-900 to-gray-800` with `rounded-b-[2rem]`, frosted glass stat chips `bg-white/[0.06] backdrop-blur-sm`, `rounded-3xl` content cards, pill filter tabs `rounded-full bg-gray-900` active, `bg-gray-900` primary buttons, decorative circles (`bg-green-500/[0.04]`, `bg-white/[0.02]`). Auth pages use full-screen dark gradient with centered white card. BottomNav uses `bg-gray-900/10` active pill + `bg-gray-900` indicator bar. AnnouncementBar uses `bg-gray-900`. **Full multilingual support** — `useLanguage.ts` fetches user language from `/api/settings` on startup, saves language back to server on change, supports all 5 languages. Profile page shows a 5-language picker. Professionally redesigned Home, Active, Profile, Notifications, Wallet, Earnings, and History pages. Home: skeleton loading, time-based greeting, wallet card, premium toggle, gradient stats, request cards with gradient icons, typed toasts, press animations, ID-based new-request detection. Active: enhanced elapsed timer with progress bar, order-type-specific gradient headers (food=orange/red, mart=blue/indigo, parcel=teal/cyan), ride cards with violet/purple gradient, premium step progress with ring indicators and animated progress bars, gradient nav/call buttons, enhanced proof-of-delivery with overlay, glassmorphism cancel modal, gradient action buttons with press animations. Notifications: premium header with animated ping unread indicator, glassmorphism stat cards with staggered animations, enhanced filter tabs with gradient active state, individual notification cards with gradient icon backgrounds and unread dot indicators, enhanced empty state with View All CTA, "mark all read" success toast. All pages share: robust toast system with timer ref cleanup, gradient button design language, decorative background circles. Also includes: circular profile completion indicator, stats grid, date-grouped transactions and notifications, individual notification mark-as-read (PATCH /rider/notifications/:id/read), 7-day earnings chart, COD remittance tracking, pending withdrawal request cards with status badges, achievements system, and error-handled mutations. Full auth system with Login (Phone OTP, Email OTP, Username/Password, Google, Facebook, Magic Link, Biometric) and 4-step Registration (Personal Info with optional username → Vehicle & Documents → Security Setup → Verification). "Back to Login" link visible on all registration steps. Email OTP fallback on phone OTP step (if SMS fails). 2FA setup/disable in Profile security section (QR via backend data URL, manual key, backup codes). Uses Wouter routing, TanStack Query, Tailwind CSS, and Lucide icons. Features include online/offline toggles, active deliveries/rides, history, earnings, and wallet. **Rider App Modules** are admin-controlled via platform settings (`rider_module_wallet`, `rider_module_earnings`, `rider_module_history`, `rider_module_2fa_required`, `rider_module_gps_tracking`, `rider_module_profile_edit`, `rider_module_support_chat`); disabled modules hide routes and nav items. `getRiderModules()` helper in `useConfig.ts` provides typed access. It enforces max deliveries and manages withdrawal requests based on platform settings.
    - **Vendor App (React-Vite):** Mobile-first web app for store owners with an orange theme. Features include dashboard, order management, product CRUD (including bulk adds), wallet, analytics, store configuration (banner, hours, announcements, promos), and notifications. It enforces max product limits and manages withdrawals. Auth: login supports OTP bypass (auto-login when `otpRequired: false`), registration has required username with real-time `/auth/check-available` uniqueness check (auto-suggested from name), username persisted server-side via `/auth/vendor-register`.

**Key Features and Implementations:**
- **Authentication:** JWT-based authentication across all user roles (customer, rider, vendor). **Unified Identity System (Binance-style):** Phone, email, and username all link to one account with no duplicates. Unified `/auth/login` endpoint accepts `{ identifier, password }` where identifier is auto-detected as phone (0/3/+92 prefix), email (@), or username. Lockout keyed by user ID (prevents rotation bypass). Admin can edit identity fields via `PATCH /admin/users/:id/identity` with case-insensitive uniqueness checks. All 3 client login forms (customer, vendor, rider) accept phone/email/username in the identifier field. Supports multiple login methods including Phone OTP, Email OTP, Username/Password, Email Registration (with verification email via nodemailer/SMTP), Google Social Login, Facebook Social Login, and Passwordless Magic Links. Includes role-specific registration (customer/rider/vendor) with CNIC validation, password strength rules, reCAPTCHA v3 middleware (fail-closed), OTP-based password reset with email delivery, TOTP-based 2FA (RFC 6238) with backup codes, trusted device fingerprinting (30-day expiry), and admin force-disable 2FA. TOTP secrets encrypted at rest via AES-256-GCM. Magic link tokens are hashed and single-use with 15-min expiry. Per-role auth toggle enforcement via platform_settings (JSON format: `{"customer":"on","rider":"on","vendor":"on"}`). All auth toggle checks use `isAuthMethodEnabled()` for consistent parsing. Runtime feature flags are loaded by `getPlatformSettings()` in `routes/admin-shared.ts` (single source of truth, real DB read of `platform_settings` with 30s in-memory cache + graceful fallback on DB failure). User approval workflows for riders and vendors managed via the admin panel.
  - **Unified Multi-Role Auth Flow:** `POST /auth/check-identifier` discovers account and returns `action` (send_phone_otp, send_email_otp, login_password, force_google, force_facebook, register, no_method), `otpChannels`, `canMerge`, `deviceFlagged`, `hasGoogle`, `hasFacebook`. All 3 client apps use a single "Continue" entry point that calls check-identifier first.
  - **Dynamic OTP Routing:** `POST /auth/send-otp` tries WhatsApp → SMS → Email failover (role-aware channel selection via `isAuthMethodEnabled()`). Returns `{ channel, fallbackChannels }` — canonical values only (`sms`/`whatsapp`/`email`). Client passes optional `preferredChannel` to override priority. In production, returns 502 if all channels fail. All 3 client apps display delivery channel indicator and fallback buttons.
  - **Dev OTP Mode:** Admin-controlled per-user `devOtpEnabled` flag. When enabled via SecurityModal, `/auth/send-otp` returns `{ otp, devMode: true }` in response body (skips SMS if delivery fails). Customer app shows OTP via `DevOtpBanner` on all auth screens (login, register, forgot-password). Toggle persisted in `users.dev_otp_enabled` column.
  - **Force Social Login:** `force_google`/`force_facebook` actions hard-block login regardless of local feature toggles, showing clear error message if social provider isn't available in the app.
  - **Account Merge/Link:** `POST /auth/send-merge-otp` sends OTP to a new phone/email for linking (requires JWT auth), storing `pendingMergeIdentifier` to cryptographically bind the OTP to the target. `POST /auth/merge-account` verifies OTP AND identifier match before linking. Prevents linking identifiers already used by other accounts. `check-identifier` returns `canMerge: true` when the identifier is new and could be linked.
  - **Shared Auth Components:** `components/auth-shared.tsx` provides reusable components (`OtpDigitInput`, `AuthButton`, `PasswordStrengthBar`, `AlertBox`, `PhoneInput`, `InputField`, `StepProgress`, `ChannelBadge`, `FallbackChannelButtons`, `DevOtpBanner`, `Divider`, `SocialButton`) used across all 3 auth pages to eliminate duplication.
  - **Shared User-Area Components:** `components/user-shared.tsx` provides `AnimatedPressable`, `SectionHeader`, `SkeletonBlock`, `SkeletonRows`, `FilterChip`, `StatCard`, `ListItem`, `GradientCard`, `EmptyState`, `StatusBadge`, `Divider`, `CardSurface`, `SearchHeader`, `CategoryPill`, `CountdownTimer`, `SkeletonLoader` used across Home/Orders pages.
  - **Accessibility (Binance-quality redesign):** All 4 user-area pages (Home, Orders, Wallet, Profile) have comprehensive `accessibilityRole`, `accessibilityLabel`, and `accessibilityState` on every interactive Pressable — including main page elements, modal buttons (deposit/withdraw/send/QR/edit profile/notifications/privacy/2FA/addresses), filter chips, quick amount selectors, city/language pickers, action cards, error retry banners, sign-out confirmation, and address CRUD actions.
- **Rider Profile Image Upload:** Riders can upload profile photos from Profile page via camera icon overlay on avatar. Photos uploaded as base64, stored via `/api/uploads/`, URL saved to `avatar` column via `PATCH /rider/profile`. Server validates avatar URLs must start with `/api/uploads/`. Avatar displayed in profile card and included in `/rider/me` response for customer-facing ride data.
- **Rating & Review System (Full):** Complete review pipeline across all 4 apps. DB schema: `reviewsTable` and `rideRatingsTable` both have soft-delete columns (`hidden`, `deletedAt`, `deletedBy`). Security: IDOR fix (userId filter on GET /reviews), self-rating guard on ride ratings (customerId !== riderId). Endpoints: `GET /reviews/my` (customer's own order + ride reviews merged), `GET /vendor/reviews` (auth'd, paginated, star breakdown, masked names), `GET /rider/reviews` (returns avg + total + list), admin endpoints `GET/PATCH/DELETE /admin/reviews/:id`, `GET/PATCH/DELETE /admin/ride-ratings/:id` (hide + soft-delete). UI: Vendor app has dedicated Reviews page (`/reviews`) with sidebar link, star breakdown chart, filters; Admin has Review Management page (`/reviews`) with type/stars/status filters, hide/show toggle, soft-delete action; Rider Profile.tsx shows reviews section with empty state polish; Customer Expo app has My Reviews screen (`/my-reviews`) reachable from profile. i18n: new keys `reviews`, `customerFeedback`, `noReviews`, `myReviews`, `reviewManagement`, `allReviews`, `hideReview`, `unhideReview`, `deleteReview`, `reviewHidden`, `reviewDeleted`, `rideReviews`, `orderReviews`, `reviewType`, `reviewStatus`, `navReviews`, `navReviewsMgmt` added in English, Urdu, and Roman Urdu.
- **Advanced Review & Rating System (Task #2):**
  - **AI Moderation:** Review submissions go through OpenAI (Replit-proxied `gpt-5-mini`) content moderation. Flagged reviews are saved with `status = "pending_moderation"` and hidden from public. Reviews with no AI credentials fall through as `status = "visible"`.
  - **Vendor Replies:** Vendors can POST/PUT/DELETE replies on their reviews via `/reviews/:id/vendor-reply` (vendor auth required). Reply + timestamp stored in `vendorReply`/`vendorRepliedAt` columns.
  - **Admin Moderation Queue:** `GET /admin/reviews/moderation-queue` returns all pending reviews. `PATCH /admin/reviews/:id/approve` and `reject` manage moderation decisions.
  - **Bulk CSV Export/Import:** `GET /admin/reviews/export` streams a CSV with auth header. `POST /admin/reviews/import` accepts CSV text, imports with de-duplication.
  - **Auto-Suspension Job:** `POST /admin/jobs/rating-suspension` checks riders/vendors with <2.5 avg rating in last 30 days (min 10 reviews), suspends them, sends in-app notification. Respects `adminOverrideSuspension` flag. Override endpoints for riders and vendors. Thresholds configurable in platform settings.
  - **Schema changes:** `reviewsTable` gained `status`, `moderationNote`, `vendorReply`, `vendorRepliedAt` (plus `hidden`, `deletedAt`, `deletedBy` from Task #1). `usersTable` gained `autoSuspendedAt`, `autoSuspendReason`, `adminOverrideSuspension`.
  - **Admin Panel:** `/reviews` page enhanced with moderation queue modal, bulk export/import, run-auto-suspend button. Riders/Vendors pages show "Override Suspend" button for auto-suspended accounts.
  - **Vendor App:** `/reviews` page enhanced with reply form (post/edit/delete), review status badges. `postVendorReply/updateVendorReply/deleteVendorReply` APIs added.
- **Rider KYC Document Upload System:** All 4 documents mandatory during registration: Vehicle Photo, CNIC Front, CNIC Back, and Driving License Photo. Documents stored as structured JSON in `documents` column: `{files: [{type, url, label}...], note?: string}`. Vehicle photo also stored in separate `vehiclePhoto` column. Riders can attach optional notes during registration. Admin KYC review modal (`KycDocModal` in `users.tsx`) parses both `vehiclePhoto` and `documents` JSON with URL-based deduplication, backward compatible with legacy array format `[{type, url}]`. Admin pending approval list shows doc count badge (green=4+, amber=partial, red=none) and note indicator. Admin verification checklist with interactive checkboxes and "all checks passed" indicator. Correction request supports actual document types (cnic_front, cnic_back, driving_license, vehicle_photo, all).
- **Dynamic Platform Settings:** Almost all operational parameters (delivery fees, commission rates, minimum order values, withdrawal limits, feature toggles, loyalty points, cashback, etc.) are centrally managed via the Admin Dashboard and dynamically enforced across the API and client applications.
- **Order and Delivery Management:** Comprehensive order processing, including fare calculation (dynamic based on service type and distance), delivery fee application (mart, food, pharmacy, parcel), GST calculation, and cashback/loyalty point integration. Supports scheduled orders and cancellation windows.
- **Digital Wallet:** Functionality for top-ups, transfers (P2P), withdrawals for riders and vendors, and tracking of transactions (e.g., earnings, bonuses, loyalty points, cashback). Wallet limits and withdrawal availability are dynamically configured.
- **Ride Bargaining (Mol-Tol System):** An advanced bidding system for rides where customers can offer a fare, and multiple riders can submit bids. Customers can accept bids live, leading to dynamic fare negotiation.
- **Product Management:** Vendors can manage products, including bulk additions with image and description support, inventory tracking, and category assignments.
- **Notifications:** In-app notification systems for various events across all applications.
- **Location Services:** Integration with mapping services for autocomplete, geocoding, distance matrix calculations, and real-time location tracking for rides/deliveries.
- **Security:** Implementation of signed JWTs for authentication, input validation using Zod schemas, and role-based access control for API endpoints. Admin endpoints use a separate `ADMIN_JWT_SECRET` (required env var, minimum 32 chars enforced at startup, server will not start without it). `JWT_SECRET` also enforced to ≥32 chars. Server-side price verification on order placement. Deposit TxID duplicate protection with normalized case-insensitive matching. OTP bypass is only allowed when `NODE_ENV` is explicitly `"development"` or `"test"` (never when unset). TOTP secrets encrypted at rest using AES-256-GCM. `GET /rides/:id/event-logs` uses timing-safe secret comparison. Route shadowing fixed: `/admin/system` router is mounted before `/admin` router. Platform settings PUT/PATCH endpoints validate numeric and boolean keys before persisting. Email delivery via nodemailer. **Critical Bug Fixes (Task #4):** Admin cannot cancel/refund delivered/completed orders (free-goods exploit closed). Rider order status transitions enforced via `ORDER_RIDER_TRANSITIONS` state machine (prevents skipping states like confirmed→delivered). Ride/order delivery financial operations (rider earnings, platform fees) are now atomic — status update and wallet operations in ONE database transaction (prevents "completed but unpaid" state). All wallet deductions in rides.ts use atomic SQL (`wallet_balance - X` with `gte` floor guard) instead of JavaScript math (eliminates double-spending race conditions). Cancel-fee deduction verifies row-update success before inserting ledger entry.

- **Payment Provider Abstraction:** Centralized payment SDK in `api-server/src/lib/payment-providers.ts` with `getProviderConfig()`, `validatePaymentAmount()`, hash builders for JazzCash/EasyPaisa, and `SUPPORTED_GATEWAYS` type. Payments route refactored to use abstraction layer.
- **Rider Order Rejection:** Riders can reject delivery orders via `POST /rider/orders/:id/reject` with reason. Rider app Home has Reject button alongside Accept/Ignore on order request cards.
- **Order Ready Notifications:** When vendor marks order "ready", socket broadcasts `order:update` to admin/vendor/rider rooms and notifies all online riders of available pickups via `rider:new-request`.
- **AI/ML Recommendations:** API endpoints at `/api/recommendations/trending`, `/for-you`, `/similar/:productId`, `/frequently-bought`. Interaction tracking via `POST /recommendations/track`. Customer app home screen shows "Trending Now" horizontal product carousel. Product detail auto-tracks views.
- **Dynamic Banner Management:** Admin CRUD at `/api/banners` with placement (home/mart/food), gradient colors, date ranges, sort order. Customer app home screen renders dynamic banners from API with auto-scroll carousel.
- **Product Variant System:** DB schema `product_variants` (label, sku, price, stock, attributes JSONB). API endpoints at `/api/variants/product/:productId`. Product detail page shows variant selector chips with price/stock info. Search page enhanced with sort options (price, rating, newest) and price/rating filter bar.

**Database Schema Highlights:**
- `usersTable`: Stores user details, including auth-related fields (nationalId, googleId, facebookId, totpSecret, totpEnabled, backupCodes, trustedDevices, biometricEnabled), rider fields (vehicleRegNo, drivingLicense), vendor fields (businessName, storeAddress, ntn), approval status, and roles.
- `magicLinkTokensTable`: Stores magic link tokens for passwordless login (id, userId, tokenHash unique, expiresAt, usedAt, createdAt).
- `productsTable`, `ordersTable`: Core commerce data.
- `walletTransactionsTable`: Records all financial movements within the digital wallet.
- `ridesTable`, `rideBidsTable`, `liveLocationsTable`: For ride-hailing and tracking. Rides table includes dispatch fields: `dispatched_rider_id`, `dispatch_attempts` (JSON), `dispatch_loop_count`, `dispatched_at`, `expires_at`.
- `rideRatingsTable`: Post-ride customer ratings (1-5 stars + comment). Unique index on ride_id prevents duplicates.
- `riderPenaltiesTable`: Tracks rider ignore/cancel penalties with daily limits and wallet deductions.
- `popularLocationsTable`: Admin-managed points of interest for quick selection.
- `schoolRoutesTable`, `schoolSubscriptionsTable`: For managing school transport services.
- `productVariantsTable`: Product variants with label, SKU, price, stock, attributes (JSONB), and inStock flag.
- `bannersTable`: Dynamic promotional banners with placement, service targeting, gradient colors, date ranges, and sort order.
- `userInteractionsTable`: Tracks user product interactions (view/cart/purchase/wishlist) for recommendation engine.

### Shared Auth Utilities (`@workspace/auth-utils`)
- **Location:** `lib/auth-utils/`
- **CAPTCHA:** `executeCaptcha(action, siteKey?)` for web (reCAPTCHA v3 invisible); `CaptchaModal` WebView component for Expo mobile (import from `@workspace/auth-utils/captcha/native`)
- **OAuth:** `useGoogleLogin()` and `useFacebookLogin()` hooks for web; `useGoogleLoginNative()` and `useFacebookLoginNative()` hooks for Expo (import from `@workspace/auth-utils/oauth/native`)
- **2FA Components:** `TwoFactorSetup` (QR code, manual key copy, 6-digit TOTP input with auto-submit, backup codes with download/copy); `TwoFactorVerify` (TOTP input, backup code toggle, trust device checkbox)
- **Magic Link:** `MagicLinkSender` component with email input, rate-limit-aware countdown, and status feedback
- **Environment secrets needed:** `RECAPTCHA_SITE_KEY`, `RECAPTCHA_SECRET_KEY`, `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `FACEBOOK_APP_ID`, `FACEBOOK_APP_SECRET`

### External Dependencies

- **PostgreSQL:** Primary database.
- **Drizzle ORM:** Object-Relational Mapper for database interactions.
- **Express 5:** Backend web framework.
- **Expo React Native:** Frontend framework for customer mobile app.
- **React-Vite:** Frontend framework for Admin, Rider, and Vendor web apps.
- **NativeWind:** Utility-first CSS framework for React Native.
- **OpenAPI 3.1:** API specification.
- **Orval codegen:** Generates API client and hooks.
- **React Query:** Data fetching and caching for frontend.
- **Zod:** Schema validation library.
- **AsyncStorage:** For client-side data persistence in React Native (non-sensitive: user profile cache, biometric preference, language).
- **expo-secure-store:** Encrypted storage for auth tokens (access token, refresh token, biometric token). Fallback to AsyncStorage on unsupported platforms.
- **jsonwebtoken:** For JWT generation and verification.
- **crypto.scryptSync:** For password hashing.
- **react-native-qrcode-svg:** For generating real QR codes in the wallet Receive Money modal.

### White Label Delivery Access Control (Task #5)

**DB Schema:**
- `lib/db/src/schema/delivery_whitelist.ts`: Three new tables — `delivery_whitelist` (vendor/user whitelisting with service type, expiry, status), `delivery_access_requests` (vendor requests for delivery access), `system_audit_log` (admin action audit trail).

**API Server:**
- `artifacts/api-server/src/lib/delivery-access.ts`: Core `checkDeliveryEligibility(userId, vendorId, serviceType)` utility supporting four modes (`all`, `stores`, `users`, `both`) with 5-min caching and auto-expiry of expired whitelist entries.
- `artifacts/api-server/src/routes/admin/delivery-access.ts`: Full admin CRUD — GET/PUT mode, POST/PATCH/DELETE whitelist entries, bulk import, request management (approve/reject), audit log.
- `artifacts/api-server/src/routes/vendor.ts`: Added `GET /vendor/delivery-access/status` (returns per-service-type whitelist status + pending requests) and `POST /vendor/delivery-access/request`.
- `artifacts/api-server/src/routes/delivery-eligibility.ts`: Customer-facing `GET /delivery/eligibility` pre-check endpoint (fail-open on errors).
- Server-side enforcement on `POST /orders` blocks ineligible orders at placement time.

**Admin Panel:**
- `artifacts/admin/src/pages/delivery-access.tsx`: Full management UI with mode selection cards, whitelist management (add/edit/delete), access request approval queue, and audit log viewer.
- `artifacts/admin/src/pages/vendors.tsx`: Delivery badge on vendor cards showing whitelist status when mode is `stores` or `both`.
- `artifacts/admin/src/hooks/use-admin.ts`: Hooks for all delivery access admin operations.

**Vendor App:**
- `artifacts/vendor-app/src/pages/Dashboard.tsx`: Delivery access status banner showing enabled/disabled/pending state with "Request Access" button.
- `artifacts/vendor-app/src/lib/api.ts`: Added `getDeliveryAccessStatus()` and `requestDeliveryAccess()` API calls.

**Customer App:**
- `artifacts/ajkmart/app/cart/index.tsx`: Pre-checkout eligibility check calls `/delivery/eligibility`. Skips `no_vendor` reason (fail-open for store-level checks, handled server-side on order). Blocks only on `user_not_whitelisted` with user-friendly message.

**Design Decisions:**
- Fail-open: Cart pre-check without vendorId skips store-based denial; server enforces definitive check at order time.
- In-flight orders unaffected — eligibility only checked at placement time.
- i18n keys added: `navDeliveryAccess` in English, Urdu, and Roman Urdu.

### Order-to-Delivery Stabilization (Task #1 Rider-Admin Sync + Order Reliability)

**Server-Side (API Server):**
- `orders.ts`: Socket.io broadcast on order creation (`order:new`) and update (`order:update`) to admin-fleet and vendor rooms. Wallet balance broadcast (`wallet:update`) after wallet payment deduction. **Critical bugfix**: Cancel handler now atomically refunds wallet inside a DB transaction (was calculating refund amount but never crediting it). Retry-safe 4xx vs 5xx distinction.
- `wallet.ts`: Added `broadcastWalletUpdate()` after admin topup, auto-approved deposits, and P2P transfers. Both sender and receiver get real-time balance updates via Socket.io.
- `rides.ts`: Added `broadcastWalletUpdate()` after ride cancellation refund/fee deduction.
- `socketio.ts`: Added `rider:heartbeat` server handler — validates rider JWT, rebroadcasts batteryLevel to admin-fleet. Added `emitRiderStatus()` for instant online/offline status changes.

**Rider App (`Home.tsx`):**
- Socket.io heartbeat: 30-second interval emitting `rider:heartbeat` with battery level. Auto-joins personal `rider:{userId}` room for admin chat and push notifications.
- Battery API integration: reads `navigator.getBattery()` level, includes in GPS location updates and heartbeat payloads.
- GPS location updates now include `batteryLevel` field.

**Admin Map (`live-riders-map.tsx`):**
- Real-time `rider:status` listener: updates isOnline without page refresh when riders toggle online/offline.
- `rider:heartbeat` and `rider:location` listeners: update battery level in real-time.
- `order:new` / `order:update` listeners: invalidate order queries for instant admin notification.
- Sidebar: search input (by name/phone/vehicle), status filter buttons (All/Online/Busy/Offline), battery level display with color coding (red ≤20%, amber ≤50%, green >50%).
- Selected rider detail panel: battery level display.

**Vendor App (`Orders.tsx`):**
- `order:new` and `order:update` Socket.io listeners: invalidate vendor order queries for instant notification without polling.

**Customer App (`AuthContext.tsx`):**
- Socket.io connection: connects when logged in, auto-joins personal room via JWT auth.
- `wallet:update` listener: instantly updates user wallet balance in AuthContext and persists to AsyncStorage. No page refresh needed.

**Customer App (`cart/index.tsx`):**
- Exponential backoff retry: `placeOrder` retries up to 3 times with 1s/2s/4s delays on 5xx errors. 4xx errors (validation) fail immediately without retry. Cart only clears after confirmed 200 OK response.

**Offline GPS Queue (Rider App `api.ts`):**
- IndexedDB-based offline GPS ping queue (`enqueueGpsPing`/`drainGpsQueue`). Location updates queue when offline, drain via `POST /rider/location/batch` on reconnect.

### Auth Security Hardening (Customer Mobile App Audit)

**Files modified:** `context/AuthContext.tsx`, `app/_layout.tsx`, `app/auth/index.tsx`, `app/auth/register.tsx`, `app/auth/forgot-password.tsx`, `api-server/src/routes/auth.ts`

**Critical Security Fixes:**
1. Server-side OTP verification before password reset — new `POST /auth/verify-reset-otp` endpoint validates OTP against server before allowing password step (was client-only check)
2. Duplicate magic link listener removed from `auth/index.tsx` — centralized in `_layout.tsx` `MagicLinkHandler` to prevent double API calls and race conditions
3. Cryptographically secure nonce for Google OAuth — uses `crypto.getRandomValues(Uint8Array(16))` with `expo-crypto` SHA-256 fallback (no Math.random)
4. Stale closure fixes in `AuthContext` — `userRef`/`tokenRef`/`doLogoutRef` pattern ensures callbacks always see latest state
5. Auth tokens (access + refresh + biometric) migrated from AsyncStorage to SecureStore (hardware-encrypted on iOS/Android); fallback to AsyncStorage on web
6. Registration partial token cleaned up on back-navigation (prevents stale token reuse)
7. OTP bypass blocked server-side for new users; existing users redirected to password auth
8. OTP removed from ALL dev API responses (5 occurrences in auth.ts)
9. Account enumeration removed from check-identifier (generic responses)
10. Account deletion PII scrub: phone scrambled, email/username/cnic/address/area/city/lat/lng all cleared
11. Address endpoint enforces max 5 addresses + field length limits server-side

**Medium Fixes:**
5. All `doLogout()` calls properly awaited (unauthorized handler, proactive refresh, `clearSuspended`)
6. Biometric cancel vs fatal failure — only hardware/lockout failures disable biometric; user cancel/system cancel/fallback do NOT
7. Proactive token refresh uses `doLogoutRef.current()` to always call latest logout implementation
8. `handleCompleteProfile` loading state fix — proper error handling prevents infinite spinner
9. `setOtpSent(true)` placement in register flow — set inside registration block to prevent half-registered state on retry

**UI/UX Fixes:**
10. Confirm password fields added to both register (Step 3) and forgot-password flows with real-time mismatch feedback
11. Email regex validation (`/^[^\s@]+@[^\s@]+\.[^\s@]+$/`) applied consistently across all auth screens
12. `AuthGuard` segments dependency — effect now includes `segments` in deps for proper re-evaluation on navigation
13. Unused imports cleaned up (`TextInput`, `ActivityIndicator`, dead `loginResultRef`)

### Live Fleet Tracking — Complete System (Task #3)

**API Server:**
- `rider.ts`: Added `POST /rider/sos` — broadcasts SOS alert (with GPS coordinates, rideId, rider info) to admin-fleet via Socket.io. Added `GET /rider/osrm-route` — proxy endpoint that fetches turn-by-turn directions from the free public OSRM router (router.project-osrm.org), returns `{distanceM, durationSec, geometry, steps}`.
- `admin.ts`: Added `GET /admin/fleet-analytics?from=&to=` — returns heatmap ping data (up to 10K points), average ride response time, per-rider haversine distance totals, and active rider count for the date range.
- `socketio.ts`: Added `rider:sos` event relay (rider→admin-fleet broadcast), `admin:chat` event relay (admin→rider:{userId} personal room), auto-join personal room for JWT-authenticated riders on connect. Added `emitRiderSOS()` and `emitAdminChatReply()` exports.

**Admin Map (`live-riders-map.tsx`) — Complete Rewrite:**
- Correct color logic: Green=Online/idle, **Red=Busy/On Trip** (was incorrectly Orange), Grey=Offline
- Vehicle-type service icons: 🏍️ Bike/motorcycle, 🚗 Car, 🛺 Rickshaw, 🚐 Van, 🚛 Truck, 🔧 Service provider, 👤 Customer
- SOS banner: real-time red alert bar at top when any rider sends SOS. Shows rider name/phone/coordinates/time, Reply/Dismiss buttons.
- SOS chat modal: admin can type reply → emitted via `admin:chat` socket to `rider:{userId}` room. Chat history displayed per rider.
- SOS markers: 🆘 Leaflet markers at SOS coordinates on the map.
- Analytics tab: fleet heatmap (Leaflet Circle overlays per ping), top-rider distance bar chart (Recharts), stat cards for total pings, avg response time, active rider count. Configurable date range.
- Socket.io live connection now attempts join on connect, handles pruning of >500 rider overrides.

**Rider Web App (`Active.tsx`):**
- `SosButton` updated to capture current GPS position (via `navigator.geolocation.getCurrentPosition` with fallback to `riderPos` from `watchPosition`) before POSTing to `/rider/sos` with lat/lng.
- `TurnByTurnPanel` component: collapsible accordion that calls `/rider/osrm-route` and renders numbered step-by-step directions with distance. Shown for: pickup (ride accepted), drop-off (ride arrived/in_transit), store (order pickup phase), customer (order delivery phase).

**Mobile Rider App (`RiderLocationContext.tsx`) — previously completed:**
- Dual-mode tracking: 4min idle / 8sec active order intervals
- AsyncStorage persistence of `isOnline` for auto-resume on reboot
- `hasActiveTask` polling every 15s via `/rider/active`
- Sends `action: "on_trip"` during active delivery

### Admin Panel UI/UX & Bug Fix (Task #4)

All changes are in `artifacts/admin/src/`:

**Shared Component Library (`components/AdminShared.tsx`)**
- `Toggle`, `Field`, `SecretInput`, `StatusBadge` — shared across settings, security, flash-deals
- Added `SLabel` (section heading) and `ModeBtn` (pill mode button) — previously duplicated inline in settings.tsx

**Mobile Card-Views**
- `orders.tsx`, `users.tsx`, `products.tsx`: Added `sm:hidden` card layouts for mobile and `hidden sm:block` for desktop tables

**Mobile Header Declutter (`AdminLayout.tsx`)**
- Language selector hidden from header on mobile (`hidden sm:block`), shown in sidebar on mobile (`lg:hidden`)

**Live Riders Map (`live-riders-map.tsx`)**
- Fully rewritten using `react-leaflet` (MapContainer/TileLayer/Marker/Popup) — no more script tag injection
- Map center reads from platform settings (`map_default_lat`, `map_default_lng`)

**Currency De-hardcoding**
- `formatCurrency()` from `lib/format.ts` used everywhere in place of hardcoded `` `Rs. ${n}` `` strings
- Files updated: `orders.tsx`, `users.tsx`, `rides.tsx`, `parcel.tsx`, `pharmacy.tsx`, `CodRemittances.tsx`, `Withdrawals.tsx`, `DepositRequests.tsx`
- `CodRemittances.tsx`, `Withdrawals.tsx`, `DepositRequests.tsx`: replaced local `fc` helper with `const fc = formatCurrency`

**Button Loading States**
- All mutation buttons across all pages use `isPending`/`isLoading` + `disabled` + spinner pattern (was already consistent; confirmed across all 8+ pages)

**Settings.tsx Split (5232 → 2435 lines)**
- `settings-payment.tsx` (~1027 lines): GatewayCard, BankSection, CODSection, WalletSection, PaymentRules, PaymentSection
- `settings-integrations.tsx` (~574 lines): IntCard, IntStatusBadge, IntegrationsSection  
- `settings-security.tsx` (~764 lines): SecPanel, SecuritySection
- `settings-system.tsx` (~481 lines): SystemSection (DB management)
- settings.tsx imports from sub-files via `import { X } from "./settings-*"`

**StatusBadge Adoption**
- `orders.tsx` and `rides.tsx` now import and use `StatusBadge` from AdminShared for read-only status displays
- SelectTrigger status coloring still uses `getStatusColor` (requires CSS class string, not a component)

**Vendor Commission Centralization**
- `vendors.tsx`: added `DEFAULT_VENDOR_COMMISSION_PCT = 15` named constant; fallback reads from it instead of inline `"15"`

### Customer App — 33-Issue Deep Trace Fix (Task #10)

All changes are client-side only (`artifacts/ajkmart/`):

**AuthContext (`context/AuthContext.tsx`)**
- Proactive token refresh uses `refreshTimerRef` and re-schedules after each successful refresh (sliding window — prevents single-run expiry).
- Biometric save now resets loading state in `finally` block (no stuck spinner).

**LanguageContext (`context/LanguageContext.tsx`)**
- Was a stub returning only `"en"`. Now fully implemented: reads from AsyncStorage, supports all 5 modes (en, ur, roman, dual-en, dual-ur), syncs to server after login. Applies `I18nManager.forceRTL` for Urdu modes.

**CartContext (`context/CartContext.tsx`)**
- Now uses `useAuth()` internally (no prop drilling of `authToken`).
- `authTokenRef` pattern retained — always reads latest token without re-running effects, with AsyncStorage fallback for pre-hydration edge cases.
- Cart type conflict (mart vs food) banner added; UI warns user when mixing service types.

**PlatformConfigContext (`context/PlatformConfigContext.tsx`)**
- Polling interval previously ignored admin-configured value; now correctly uses `platform_config_poll_interval_sec` setting.
- Added cleanup on unmount to prevent memory leaks from orphaned interval.

**useApiCall (`hooks/useApiCall.ts`)**
- Has retry logic with `retryCount` / `retrying` state exposed to callers.
- `retry()` callback allows manual re-execution after failure.

**useRideStatus (`hooks/useRideStatus.ts`)**
- Replaced native `EventSource` (which cannot send custom headers) with a `fetch`-based streaming reader using `ReadableStream` and `AbortController`. Auth token is now sent via `Authorization: Bearer` header — no longer exposed in the URL query string.
- `closeSse()` now aborts the `AbortController` — cleans up the in-flight fetch stream on reconnect/unmount.
- `closeSse()` called before `connectSse()` in `reconnect()` — prevents duplicate streams.
- Memory leak fixed: `mountedRef` checked before every `setRide`/`setConnectionType` call inside the stream reader loop.
- Falls back to polling after 3 consecutive SSE failures.

**useMaps (`hooks/useMaps.ts`)**
- `resolveLocation()` now accepts optional `showError` callback and returns `null` on failure (instead of throwing) — prevents unhandled promise rejections.
- Null-island coordinates (0,0) are rejected and treated as geocode failures.

**RideBookingForm (`components/ride/RideBookingForm.tsx`)**
- `selectPickup` / `selectDrop`: switched from try/catch throw to null-return pattern from `resolveLocation`, with inline `showToast` error callback.
- `showToast` added to `useCallback` dependency arrays.
- Fare estimate type now validated against allowed values before API call.
- `debouncedEstimate` timer properly cleared on unmount via `useRef`.

**ride/index.tsx (`app/ride/index.tsx`)**
- On failed ride-load by URL param, now correctly sets `setRideLoadError(true)` (was incorrectly resetting booked state to `unknown`).
- Error state UI shown to user instead of silent failure.
- "Try Again" button now increments `retryNonce` state which is in the fetch `useEffect` deps — actually re-fetches the ride instead of just clearing the error flag.

**order/index.tsx (`app/order/index.tsx`)**
- Cancellation window now uses the server `Date` response header (`serverNow` state) instead of `Date.now()` — closes client clock-manipulation loophole.

**orders.tsx (`app/(tabs)/orders.tsx`)**
- `readyForPickup` status label was missing — added translated label in all 3 language sections of `@workspace/i18n`.
- Server-side timestamps used for order time display (no more client clock drift).
- `authHeaders` type fixed (was `any`, now properly typed).

**wallet.tsx (`app/(tabs)/wallet.tsx`)**
- Deposit min/max limits now read from `PlatformConfigContext` (not hardcoded).
- Transaction icon selected by `tx.type` field (not tx.amount sign — avoids wrong icon on refunds).
- Duplicate submission guard added via `isSubmittingRef` — prevents double-tap deposit.

**profile.tsx (`app/(tabs)/profile.tsx`)**
- Data export button now shows `Alert.alert` confirmation dialog before calling API.
- Cooldown timer (60 seconds) prevents re-export spam; button disabled and shows countdown.
- Cooldown interval cleared on unmount via `exportCooldownRef`.

**mart/index.tsx (`app/mart/index.tsx`)**
- Flash deals discount % now uses `Number(p.originalPrice)` safety cast to avoid NaN on string values.
- `addedTimerRef` uses `useRef` (not a plain variable) so timer is properly cleared on unmount — no stale-closure memory leak.
- `allProducts` now includes flash deal items in all views (previously excluded them from the main grid).
- Cart type banner shown when user tries to add mart item with active food cart (and vice versa).

**food/index.tsx (`app/food/index.tsx`)**
- Same `useRef` animation timer fix as mart.
- Cart type banner shown when user tries to add food item with active mart cart.

---

### Customer App Full-Stack Overhaul (Task #5)
1. **Pre-login Language Selector:** English/Urdu/Mixed toggle on auth screen. Language persists in AsyncStorage before login, syncs to server after login. RTL support for Urdu via `I18nManager.forceRTL`. LanguageProvider wraps AuthProvider in `_layout.tsx`.
2. **Robust Session Management:** `custom-fetch` retries network errors and 5xx with exponential backoff (up to 3 retries). Proactive token refresh 60s before JWT expiry via `scheduleProactiveRefresh` in AuthContext. Only forced logout on genuine 401 after refresh token failure. Access token TTL: 1 hour (short-lived for security). Refresh token TTL: 90 days (long-lived for persistent sessions). On app load, if stored access token is expired but refresh token exists, proactively calls `/api/auth/refresh` before restoring session. If expired with no refresh token, clears auth state and requires fresh login. All `expiresAt` responses in auth routes use `ACCESS_TOKEN_TTL_SEC` constant (no hardcoded values). All auth screen buttons use `TouchableOpacity` instead of `Pressable` for reliable web compatibility inside ScrollView.
3. **P2P Topup with Admin Approval:** New `/api/wallet/p2p-topup` endpoint creates pending deposit with `paymentMethod: "p2p"`. Admin approves via existing DepositRequests page. Wallet screen shows "P2P Topup" button and pending topup count banner.
4. **QR/Barcode Payment:** Real QR code generation in Receive Money modal using `react-native-qrcode-svg` (encodes phone, ID, name as JSON). Decoded QR data pre-fills Send Money form.
5. **Admin Settings Enforcement:** Maintenance mode overlay in `_layout.tsx`. Service toggles on home screen already enforced. Cart uses `PlatformConfigContext` for delivery fees instead of redundant API fetch. Pharmacy checkout enforces COD limit from `orderRules.maxCodAmount` and auto-switches to wallet when exceeded. Wallet feature toggle controls wallet payment option visibility.
6. **Audit & Bug Fixes:** Eliminated redundant platform-config API fetch in cart checkout (now uses context). Consistent error handling across screens.
7. **Dynamic Service Architecture:** Centralized service registry in `constants/serviceRegistry.ts` (imports shared metadata from `@workspace/service-constants` in `lib/service-constants/`). All service definitions (icons, colors, gradients, routes, labels, banners, quick actions) live in one place. Home screen adapts layout: single-service mode (full-page hero with service-specific branding), two-service mode (dual hero cards), multi-service mode (hero + grid cards). BannerCarousel and quick actions derived from registry via `getActiveBanners()` and `getActiveQuickActions()`. Bottom tab bar is dynamic — adapts labels and visibility based on active services (hides wallet tab if wallet off, changes tab labels contextually). ServiceGuard uses registry-backed labels with shared `ServiceKey` type. Admin panel imports `ADMIN_SERVICE_LIST` from `@workspace/service-constants` for service management cards. Adding a new service only requires: (1) adding to the shared metadata, (2) adding to the service registry, (3) creating the route, (4) adding the feature flag. Deep-link protection via `withServiceGuard` HOC — wraps each service screen's default export. Applied to all 5 service screens: mart, food, ride, pharmacy, parcel.
### InDrive-Style Ride Dispatch Framework
- **Broadcast Dispatch Model:** When a ride is requested, notifications are sent to ALL nearby online riders within admin-configured radius (not one-at-a-time). Every 10s dispatch cycle re-broadcasts to catch newly-online riders. First rider to accept wins via atomic `WHERE riderId IS NULL`. After `dispatch_broadcast_timeout_sec` (default 120s) with no acceptance, ride is expired with customer notification.
- **Dispatch Settings (Admin-configurable):** `dispatch_broadcast_timeout_sec` (120), `dispatch_min_radius_km` (5), `dispatch_avg_speed_kmh` (25), `dispatch_ride_start_proximity_m` (200).
- **Radius-Filtered Requests:** `GET /rider/requests` now filters rides by rider's distance within `dispatch_min_radius_km`, sorted by proximity (nearest first). Riders only see rides they can realistically reach.
- **Ignore Penalty System:** `POST /rider/rides/:id/ignore` tracks daily ignores via `rider_penalties` table. Exceeding `rider_ignore_limit_daily` triggers wallet penalty (`rider_ignore_penalty_amount`). Optional account restriction via `rider_ignore_restrict_enabled`. Warning notification at limit, penalty notification above.
- **Cancel Penalty System:** Pre-existing `handleCancelPenalty()` in `rider.ts` uses `rider_cancel_limit_daily`, `rider_cancel_penalty_amount`, `rider_cancel_restrict_enabled`.
- **Post-Ride Rating:** `POST /rides/:id/rate` (customer auth). 1-5 stars + optional comment. Unique DB constraint prevents duplicates. Customer app submits rating on tap with response.ok validation.
- **Professional Cancel Flow:** `CancelModal` component in orders.tsx provides reason selection (order/ride-specific), refund/fee info display, loading state, and dismiss protection while loading. Both `PATCH /orders/:id/cancel` and `PATCH /rides/:id/cancel` accept optional `reason` field. API response (refundAmount, cancellationFee) used for authoritative post-cancel toast messages.
- **Payment Method Filtering:** `GET /rides/payment-methods` returns only admin-enabled payment methods (cash, wallet, jazzcash, easypaisa). Customer app filters displayed options by these settings. Ride booking payment UI renders each method with its own label, icon, and color (Cash=green/cash-outline, Wallet=blue/wallet-outline, JazzCash=red/phone-portrait, EasyPaisa=green/phone-portrait).
- **Notification Sound:** Professional 8-tone double-burst in `notificationSound.ts`. Silence mode API: `silenceFor(minutes)`, `isSilenced()`, `unsilence()`, `getSilenceRemaining()` using localStorage. Rider App Home shows mute button with 15/30/60min duration picker.
- **Customer App Theme:** Ride tracker searching screen uses rider app dark theme (gray-900 gradient, green accents) for consistent brand experience.
- **Dispatch Status:** `GET /rides/:id/status` returns dispatch metadata (loop count, attempts, expiry) for customer polling.
- **Ride State Machine:** `RIDE_STATUS_TRANSITIONS` map in `rider.ts` enforces valid status transitions: `accepted→[arrived,cancelled]`, `arrived→[in_transit,cancelled]`, `in_transit→[completed,cancelled]`. Prevents status jumps (e.g. `accepted→completed` is blocked).
- **Arrival Proximity Validation:** When a rider marks "arrived", the server validates their GPS distance from the pickup point using Haversine formula against `dispatch_ride_start_proximity_m` (default 500m). Prefers server-stored `live_locations` (trusted) over client-supplied coordinates. Rejects if no location is available or distance exceeds threshold.

### Real-Time Fleet Tracking (Task #5)

**DB layer:**
- `location_logs` table added (`lib/db/src/schema/location_logs.ts`): userId, role, lat/lng, accuracy, speed, heading, batteryLevel, isSpoofed, createdAt. Compound index on `(user_id, created_at)` for time-range queries. Migrated via `pnpm run push`.

**Backend (`artifacts/api-server/`):**
- `socket.io` installed; `lib/socketio.ts` initialises Socket.io on the shared `http.Server` at path `/api/socket.io`. Rooms: `admin-fleet`, `ride:{rideId}`, `vendor:{vendorId}`.
- `routes/locations.ts` upgraded: every `POST /locations/update` pings are logged to `location_logs`, server-side Haversine distance throttle (25m via `gps_min_distance_meters` setting), emits `customer:location` to `admin-fleet`, new `DELETE /locations/clear` endpoint clears a user's live location on logout (authenticated by Bearer JWT).
- `routes/rider.ts` upgraded: every `PATCH /rider/location` ping logs to `location_logs`, emits `rider:location` to `admin-fleet` + `ride:{rideId}` rooms; `rideId` passed in request body. Fixed duplicate `const now` variable by renaming inner one to `nowDate`.
- `routes/admin.ts`: `GET /admin/riders/:userId/route?date=YYYY-MM-DD` fleet history API returns hourly buckets from `location_logs`.

**Admin map (`artifacts/admin/src/pages/live-riders-map.tsx`):**
- Socket.io client (`socket.io-client`) connects to `admin-fleet` room, receives live `rider:location` events.
- Green (online <2min) / orange (stale 2-10min) / gray (offline >10min) color-coded Leaflet markers.
- Toggleable blue customer location layer.
- Breadcrumb polyline for selected rider; time-slider route playback (`useRiderRoute` hook).
- "Last seen X min ago" shown for offline riders.

**Rider web app (`artifacts/rider-app/`):**
- `Active.tsx`: `updateLocation` now passes `rideId: data?.ride?.id` so socket room `ride:{rideId}` receives real-time events.
- `lib/api.ts` `updateLocation` signature extended with optional `rideId`.

**Vendor app (`artifacts/vendor-app/src/pages/Orders.tsx`):**
- Connects to `vendor:{userId}` socket room on mount; displays live "Rider X km away, ETA ~Y min" badge computed via Haversine distance from vendor's browser geolocation.

**Customer mobile app (`artifacts/ajkmart/`):**
- `context/AuthContext.tsx`: On login, if role=customer, requests foreground location permission (non-blocking) and posts location to `POST /locations/update`; on logout, calls `DELETE /locations/clear` to remove customer from the live map.
- `components/ride/RideTracker.tsx`: Socket.io client installed (`socket.io-client` added to ajkmart). While ride is in active status, connects to `ride:{rideId}` room and listens for `rider:location`. Live socket position is preferred over polling data in the distance/ETA badge (green dot indicator when live position is active).

### Accordion Components
- **Customer App (Expo):** Custom `Accordion` component at `artifacts/ajkmart/components/Accordion.tsx` with animated chevron rotation, `LayoutAnimation` transitions, icon/badge support. `AccordionGroup` wrapper for grouped sections. Used in: Profile (Help & Support sections), Privacy Modal (Notification/Privacy/Security/Account sections), Orders (expandable item lists on OrderCard and PharmacyCard).
- **Rider App (React-Vite):** Radix-based `AccordionGroup` component at `artifacts/rider-app/src/components/Accordion.tsx`. Used in: Earnings (breakdown sections), SecuritySettings (info sections).
- **Vendor App (React-Vite):** Uses `@radix-ui/react-accordion` directly. Used in: Store (operating hours sections), Profile (bank details, payout policy).

### Safe Area / Edge-to-Edge Display
- **Customer App (Expo):** Uses `SafeAreaProvider` + `useSafeAreaInsets` with `topPad = Platform.OS === "web" ? 67 : insets.top` pattern on all tab and service screens.
- **Rider App (React-Vite):** `index.html` has `viewport-fit=cover` + PWA/iOS meta tags. `index.css` defines `--sat/--sar/--sab/--sal` CSS variables. All page headers use `style={{ paddingTop: "calc(env(safe-area-inset-top, 0px) + 3.5rem)" }}` instead of fixed `pt-14`. BottomNav and App.tsx content area use `env(safe-area-inset-bottom)` for bottom spacing.
- **Vendor App (React-Vite):** `index.html` has `viewport-fit=cover`. `Header.tsx` component centrally applies `paddingTop: calc(env(safe-area-inset-top, 0px) + 2.5rem)`. BottomNav uses `env(safe-area-inset-bottom)`.

- **Mapping APIs:** Google Maps Platform (or similar) for autocomplete, geocoding, and distance calculations (gated by `maps_places_autocomplete`, `maps_geocoding`, `maps_distance_matrix` settings).
- **Sentry:** For error tracking and performance monitoring (configured via `sentry_dsn`, `sentry_env`, etc.).
- **Analytics Platform:** For tracking user behavior (configured via `analytics_platform`, `tracking_id`).

### KYC (Know Your Customer) System — Completed

#### Database
- **`lib/db/src/schema/kyc_verifications.ts`**: `kyc_verifications` table. Fields: `id`, `userId`, `status` (`pending|approved|rejected|resubmit`), personal info (`fullName`, `cnic`, `dateOfBirth`, `gender`, `address`, `city`), document photos (`frontIdPhoto`, `backIdPhoto`, `selfiePhoto`), review fields (`rejectionReason`, `reviewedBy`, `reviewedAt`), timestamps. Migrated via `pnpm --filter @workspace/db push`.

#### Backend (`artifacts/api-server/src/routes/kyc.ts`)
- `GET  /api/kyc/status` — Customer: returns current KYC status + submitted record details
- `POST /api/kyc/submit` — Customer: multipart form with personal info + 3 photos (CNIC front/back, selfie). Saves to `uploads/kyc/`. Validates CNIC is 13 digits. Updates `users.kycStatus = "pending"`.
- `GET  /api/kyc/admin/list` — Admin: paginated list with status filter, joined with user data
- `GET  /api/kyc/admin/:id` — Admin: full detail of one record with photo URLs
- `POST /api/kyc/admin/:id/approve` — Admin: sets status `approved`, syncs `users.kycStatus = "verified"`, copies CNIC/name/city to users table
- `POST /api/kyc/admin/:id/reject` — Admin: sets status `rejected` with reason, updates `users.kycStatus = "rejected"`

#### Customer Portal (`artifacts/customer/src/pages/Profile.tsx`)
- New **KYC tab** (4th tab, with red `!` badge if not verified or rejected)
- **Step 0**: Status view — shows verified badge, pending review message, rejection reason, benefit list, or start button
- **Step 1**: Personal Info form (fullName, CNIC, DOB, gender, address, city)
- **Step 2**: CNIC front + back photo upload with preview
- **Step 3**: Selfie with CNIC photo upload
- **Step 4**: Review all data + submit
- `KycSection` component fetches status from `GET /api/kyc/status`, submits via `FormData` to `POST /api/kyc/submit`

#### Admin Panel (`artifacts/admin/src/pages/kyc.tsx` + `App.tsx` + `AdminLayout.tsx`)
- Route `/kyc` added to `App.tsx`
- **KYC** nav item added under "User Management" in sidebar (`AdminLayout.tsx`, uses `BadgeCheck` icon)
- `navKyc` translation key added to all 3 language blocks in `lib/i18n/src/index.ts`
- Admin page: stats cards (Total/Pending/Approved/Rejected), filter tabs, sortable table with user info + CNIC + status + submission date
- Click row → slide-in detail panel with personal details, zoomable document photos (fullscreen modal), approve/reject buttons
- Reject modal with quick-select rejection reasons + custom reason textarea
### Task #6 — Full QA & Security Audit (Completed)

#### XSS Vulnerabilities Fixed

All user-supplied string fields sanitized with `stripHtml()` (strips HTML tags via `s.replace(/<[^>]*>/g, "").trim()`):

| Route | Fields Fixed | Session |
|-------|-------------|---------|
| `/parcel-bookings` (POST) | `senderName`, `receiverName`, `pickupAddress`, `dropAddress`, `description` | Previous |
| `/pharmacy-orders` (POST) | `deliveryAddress` | Previous |
| `/addresses` (POST + PUT) | `label`, `address`, `city` | Task #6 |
| `/orders` (POST) | `deliveryAddress` | Task #6 |
| `/users/profile` (PUT) | `address`, `city` | Task #6 |
| `/rides` (POST) | `pickupAddress`, `dropAddress`, `bargainNote`, `receiverName`, `packageType`, `rateRide.comment` | Task #6 |
| `/reviews` (POST) | `comment` | Task #6 |

#### Security Audit Results (All PASSING)

- **JWT alg:none**: Blocked (401) — algorithm whitelist enforced
- **Expired JWT**: Blocked (401)
- **IDOR** (orders/rides/addresses/pharmacy/parcels): Blocked (403/404) — userId scope enforced on all queries
- **SQL injection**: Safe — all queries use Drizzle ORM parameterized statements; injection strings return empty results
- **Mass assignment** (isAdmin, role, walletBalance): Blocked — Zod `.strip()` on profile schema
- **Negative price injection**: Blocked — per-item validation on all order routes
- **Cart price injection**: Server overrides with DB price; returns 409 if mismatch
- **OTP brute force**: Blocked — rate limiter + single-use OTP enforcement
- **Admin endpoints with user token**: Blocked (401) — separate `adminAuth` middleware
- **New account order limit**: 3 orders in first 7 days (configurable via `security_new_acct_limit`)
- **Same-address rate limit**: Enforced on orders, pharmacy orders
- **Wallet negative deposit**: Blocked (400 validation)
- **Large wallet deposit**: Max limit enforced per settings

#### Functional Testing Summary

All 23 core user flows tested and verified:
Auth (OTP send/verify) → Profile (GET/PUT) → Products/Categories/Flash deals → Banners → Cart validate → Mart order → Food order → Order cancel → Wallet balance → Wallet payment order → Address CRUD → Ride estimate → Ride book → Ride cancel → Pharmacy order → Parcel booking (wallet + COD) → Review submit → Notifications list → Mark all read

#### Route Clarifications Documented

- Categories: `GET /api/categories?type=mart|food` (not `/products/categories`)
- Flash deals: `GET /api/products/flash-deals`
- Seed: `POST /api/seed/products` with `x-admin-token` header
- Parcel: requires `senderPhone`, `parcelType` (not `packageType`)
- Reviews: require `orderType` field; ALL review types enforce delivery/completion status — product reviews require delivered/completed order with matching product, ride reviews require `completed` status, pharmacy/parcel/general orders require `delivered`/`completed` status. New `GET /reviews/can-review/:productId` endpoint checks purchase+delivery eligibility and duplicate review status. Frontend product page shows contextual review CTA (Write Review / Reviewed badge / "Buy & receive to review" hint). Error handling uses HTTP status codes (403/409) for reliable detection across English/Urdu responses.
- Pharmacy: items must include `price` and `quantity` (digital pharmacy catalog model)
- Notifications unread count: returned as `unreadCount` in `GET /api/notifications` response

### Map Pin Location, Scheduled Rides, Van Service & Pool Rides — Completed

#### T001: Map Pin Location Picker
- **`artifacts/api-server/src/routes/maps.ts`**: `/api/maps/picker` serves a full HTML+Leaflet page with `window.parent.postMessage` for location selection.
- **`artifacts/ajkmart/components/ride/MapPickerModal.tsx`**: Native WebView-based modal wrapper that captures `postMessage` events from the map picker.
- **`artifacts/ajkmart/components/ride/MapPickerModal.web.tsx`**: Web-specific implementation using `<iframe>` instead of WebView, with origin validation (`event.origin === PICKER_ORIGIN`), `allow="geolocation"` attribute, and proper sandbox permissions.
- **`artifacts/ajkmart/components/ride/RideBookingForm.tsx`**: Integrated MapPickerModal for both pickup and drop location selection via map pins. Layout compacted: reduced gradient header padding, smaller inputs/icons, compact service type cards (130px width, 120px minHeight), GPS button in header bar, tighter scroll area padding (16px vs 20px).

#### T002: Scheduled Rides + Multi-Stop
- **`artifacts/api-server/src/routes/rides.ts`**: Both wallet and cash ride INSERT calls persist `isScheduled`, `scheduledAt`, `stops`, `isPoolRide`; scheduled rides get status `"scheduled"`; broadcast skipped at booking.
- **`dispatchScheduledRides()`**: Exported function activates scheduled rides within 15-minute window; cron in `index.ts` runs every minute.

#### T003: Commercial Van Service (Full Stack + Professional Upgrade)
- **Schema (`lib/db/src/schema/van_service.ts`)**: Five tables: `vanRoutesTable` (with `fareWindow/fareAisle/fareEconomy` tiered pricing), `vanVehiclesTable`, `vanDriversTable` (unique `vanCode`, `approvalStatus`), `vanSchedulesTable` (with `tripStatus`, `driverId`), `vanBookingsTable` (with `seatTiers`, `tierBreakdown` JSONB).
- **Migration**: `ensureVanServiceUpgrade()` in `admin-shared.ts` — idempotent `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` for tiered pricing columns, seat tiers, tier breakdown, trip status, and `CREATE TABLE IF NOT EXISTS van_drivers`.
- **Backend (`artifacts/api-server/src/routes/van.ts`)**: Full van API with tiered fare calculation, van driver CRUD (`/api/van/admin/drivers` with auto-generated `VAN-XXX` codes), start-trip/end-trip with socket.io broadcasting, GPS location endpoint with schedule ownership + trip-status authorization, 6 push notification events (booking confirmed, booking cancelled/refund, passenger boarded, trip started, trip completed, new passenger notification to driver).
- **Socket.io**: `emitVanLocation()` and `emitVanTripUpdate()` functions in `socketio.ts`; van room pattern `van:{scheduleId}:{date}` auto-joined on connection.
- **Customer App (`artifacts/ajkmart/app/van/`)**: Redesigned seat map with tier color-coding (gold=Window, blue=Aisle, green=Economy), tier legend with per-tier fares, running total by tier, ticket-style booking confirmation with Van Code. `bookings.tsx` shows tier badges per seat. `tracking.tsx` provides live GPS tracking via Socket.io.
- **Rider App (`artifacts/rider-app/src/pages/VanDriver.tsx`)**: Start Trip / End Trip buttons with browser GPS broadcasting every 5s, tier badges on passenger seats, Van Code in header. `App.tsx` restricts `van_driver` role users to VanDriver-only view.
- **Admin Panel (`artifacts/admin/src/pages/van.tsx`)**: 6-tab management (Routes with 3 fare fields, Vehicles with interactive seat-tier editor, Schedules with Van Code display, Drivers tab with create/approve/suspend, Bookings with tier column and revenue totals, Rules tab with configurable van settings).

#### T004: Van Service Admin Rules & Controls
- **`artifacts/api-server/src/routes/admin-shared.ts`**: 17 `van_` prefixed keys in `DEFAULT_PLATFORM_SETTINGS` — booking (min advance hours, max seats, cancellation window, refund type/pct, seat hold), operational (min passengers, pre-departure check hours, auto-notify cancel), driver (max trips/day, rest hours, require start trip), pricing (peak/weekend/holiday surcharges, peak hours spec, holiday dates JSON).
- **`artifacts/api-server/src/routes/platform-config.ts`**: Exposed van settings as `van` section in platform config response.
- **`artifacts/api-server/src/routes/van.ts`**: `getVanSettings()` helper reads all van_ settings via `getPlatformSettings()`; booking creation enforces min advance hours, max seats, peak/weekend/holiday surcharges via `isInPeakHours()` + `calculateSurcharge()`; cancellation uses dynamic window + refund policy (full/partial/none); schedule creation checks driver max trips/day and rest hours.
- **`artifacts/admin/src/pages/van.tsx`**: Added fifth "Rules" tab with 4 collapsible sections (Booking, Operational, Driver, Pricing), inline-editable rows saved via `PATCH /api/admin/system/platform-settings/:key`, and "+ Add Custom Rule" dialog with "Pending implementation" badge for unknown keys.
- **`artifacts/api-server/src/routes/admin/conditions.ts`**: 5 van-specific condition templates in `DEFAULT_RULES` (excessive cancellations 30d, no-shows >2/>4, driver missed start trip >3/>5); van metrics evaluation (`van_cancellation_count_30d` queries van_bookings, `van_noshow_count` counts boarded=null completed bookings, `van_driver_missed_start` placeholder); `reconcileUserFlags()` updated to select metadata and handle van-specific service blocks via `metadata.blockedService === "van"`.
- **`artifacts/admin/src/pages/condition-rules.tsx`**: 3 new van metrics added to METRICS dropdown (Van Cancellations 30d, Van No-Shows, Van Driver Missed Start Trip).

#### T004: Ride Sharing / Pool Rides
- **Pool matching logic** in `rides.ts`: On `isPoolRide=true` booking, searches within 500m radius and 20-min window for same-direction, same-type pool rides with under 3 passengers; groups them under shared `poolGroupId` or creates new group.
- **`GET /api/rides/pool/:groupId`**: Returns all rides in a pool group with passenger count.
- **`artifacts/rider-app/src/pages/Home.tsx`**: Pool ride requests show "👥 Pool" badge.
- **`artifacts/rider-app/src/pages/Active.tsx`**: Active pool rides show "POOL" indicator badge in ride header.
- Pool fields (`isPoolRide`, `poolGroupId`) included in all ride API responses via `formatRide` spread.

### Security, QA & Stability Audit — Session Fixes

#### Ghost State on Logout (React Query Cache)
- **`artifacts/ajkmart/context/AuthContext.tsx`**: Added `useQueryClient` import and `queryClient.clear()` call at end of `doLogout()` — ensures all React Query cached data (orders, profile, wishlist etc.) is wiped on logout, preventing stale data from flashing when another session starts.
- **`artifacts/vendor-app/src/lib/auth.tsx`**: Same fix — `useQueryClient` + `queryClient.clear()` added to `logout()` function.
- **`artifacts/rider-app/src/lib/auth.tsx`**: Same fix — `useQueryClient` + `queryClient.clear()` added to `logout()` function.

#### Product Detail Discount Badge Position
- **`artifacts/ajkmart/app/product/[id].tsx`**: Moved `discountBadge` style from `top: 16, left: 16` (overlapping the floating back button) to `bottom: 24, left: 16` (bottom-left of the image carousel, clear of all navigation buttons). Badge now shows correctly below the dot indicators row at a different horizontal position.

#### Admin Panel Password Form Accessibility
- **`artifacts/admin/src/pages/login.tsx`**: Added a hidden `<input type="text" name="username" autoComplete="username" value="admin" readOnly hidden />` field before the admin secret password input, silencing browser accessibility warnings about password forms without associated username fields.

#### API Security Audit (Verified Correct)
- All vendor routes protected by `requireRole("vendor", { vendorApprovalCheck: true })` at router level.
- All rider routes protected by `riderAuth` at router level.
- All wallet routes use `customerAuth` per-endpoint.
- Seed routes protected by `adminAuth`.
- Admin routes protected by `adminAuth` from `admin-shared.ts`.
- JWT middleware: hard 401 on missing/invalid token, role check, ban check, token version check (session revocation).

#### Screens Audited & Verified Clean
- Customer app: Home (guest), Mart, Pharmacy, Search, Product Detail, Cart, Food, Ride, Parcel screens — all load correctly, no crashes.
- Auth gates: Orders, Wallet, Profile properly redirect guests to login.
- Admin panel: `/dashboard`, `/users`, and all 25+ protected routes redirect to login without token.
- Vendor app: All routes behind global `!user → <Login />` guard; multi-step registration embedded in Login component.
- Rider app: `/dashboard` and all routes redirect to login; `/register` and `/forgot-password` are public.

#### Bug Fix: Orders Tab Auth Gate (Consistency)
- **`artifacts/ajkmart/app/(tabs)/orders.tsx`**: Replaced `AuthGateSheet` bottom-sheet modal (dark overlay) with the same inline full-screen gate pattern used in Wallet and Profile tabs — receipt icon, bold title, subtitle, "Sign In / Register" button, and "Continue Browsing" link. Uses `AsyncStorage.setItem("@ajkmart_auth_return_to", ...)` for deep-link return on login.

#### Bug Fix: Wallet Deposit Modal Error Message
- **`artifacts/ajkmart/app/(tabs)/wallet.tsx`**: When no deposit methods are configured (JazzCash/EasyPaisa/Bank all disabled in platform settings), the modal now says "Deposit Not Available — JazzCash, EasyPaisa, and Bank Transfer are not yet enabled. Please contact support to add funds." instead of the misleading "Could not load payment methods. Please try again."

#### Bug Fix: Profile City Chip Active State
- **`artifacts/ajkmart/app/(tabs)/profile.tsx`**: `chip.active` style was empty `{}` — no visual feedback when a city chip is selected in the registration/edit profile modal. Fixed to `{ backgroundColor: C.primarySoft, borderColor: C.primary }` and `chip.textActive` to `{ color: C.primary }` so the selected city is visually distinct.

#### Payment Method Seeding
- **`artifacts/api-server/src/routes/seed.ts`**: Seed endpoint (`POST /api/seed/products`) now upserts 15 platform settings to enable JazzCash (manual), EasyPaisa (manual), and Bank Transfer as payment methods with placeholder account details. Uses `onConflictDoUpdate` to ensure the demo always has working deposit methods. Admin can override these values in the admin panel at any time.

#### Bug Fix: Profile `fetchAll` Stale Token (Bug #4)
- **`artifacts/ajkmart/app/(tabs)/profile.tsx`**: `fetchAll` `useCallback` was declared with `[user?.id]` as its dependency array, but the callback closes over `token` from `useAuth()`. After a token refresh, the old stale token was used for all profile API calls. Fixed by adding `token` to the dependency array: `}, [user?.id, token])`.

#### Bug Fix: Wallet Send — Receiver Not Found Not Caught (Bug #5)
- **`artifacts/ajkmart/app/(tabs)/wallet.tsx`**: `handleSendContinue` called `POST /wallet/resolve-phone`, but did not check the `found` field in the response. When a phone number had no AJKMart account, the app silently advanced to the send confirmation screen with a blank receiver name — allowing the user to attempt a transfer to a non-existent account. Fixed by checking `!data.found` after the API call and showing a toast error ("No AJKMart account found with this phone number.") and returning early. Also added a `catch` block that shows a toast on network errors and returns early, preventing the confirm step from being reached.

#### Bug Fix: AuthContext Token Refresh — Wrong User Shape (Bug #6, Critical)
- **`artifacts/ajkmart/context/AuthContext.tsx`** line 207 (proactive refresh) and line 505 (biometric login): After token refresh, the profile endpoint `/api/users/profile` returns `{ success, data: {...user fields...} }`. Both occurrences of `const freshUser: AppUser = meData.user || meData` were wrong — `meData.user` is `undefined` because the user is nested under `meData.data`, causing the entire API response envelope to be stored as the user object. Fixed both to `meData.data || meData.user || meData`. This bug caused incorrect user state after any background token refresh.

#### Bug Fix: ActiveTrackerStrip Never Shows (Bug #8)
- **`artifacts/ajkmart/app/(tabs)/index.tsx`** lines 279-280: `ActiveTrackerStrip` fetches `GET /api/orders?status=active` and `GET /api/rides?status=active`, both returning `{ orders: [...] }` and `{ rides: [...] }` objects (not arrays). The code checked `Array.isArray(ordersData)` which was always false, so `activeOrders` and `activeRides` were always empty — the strip never appeared even when the user had active orders or rides. Fixed to `(ordersData?.orders ?? []).filter(...)` and `(ridesData?.rides ?? []).filter(...)` with `Array.isArray` fallback for defensive compatibility.

### Profile Section Full Audit & Fix — Completed (19 Tasks)

#### Backend Security (api-server)

- **`artifacts/api-server/src/routes/users.ts`**:
  - Task 1: Session revocation now targets only the specific session (not all refresh tokens for the user)
  - Task 2: delete-account uses `GDEL_` prefix with `isBanned: false` so the original phone can re-register
  - Task 3: Email uniqueness enforced on profile update — rejects if email already belongs to another user
  - Task 5: Avatar field stripped from `profileUpdateSchema` — avatar can only be changed via `POST /avatar`
  - Task 14: export-data DB queries wrapped in try/catch with proper error logging
  - Task 15: In-memory per-user rate limiting (10 req/min) on `/profile` and `/avatar` endpoints

- **`artifacts/api-server/src/routes/kyc.ts`**:
  - Task 6: base64 MIME validation — GIF/unknown types rejected; magic byte check rejects unknown format (null) AND MIME mismatch; 5MB cap per photo
  - Task 7: Duplicate CNIC blocked across different users (within same transaction)
  - Task 8: KYC re-submission wrapped in DB transaction for race-condition safety
  - Task 9: KYC admin approval only syncs name if user's current name is null
  - Task 10: adminId fallback "admin" removed — 403 if adminId missing from JWT
  - Task 11: Role guard added — customers allowed only if `wallet_kyc_required=on` OR `upload_kyc_docs=on` in platform config

- **`artifacts/api-server/src/routes/addresses.ts`**:
  - Task 12: set-default and add/update operations wrapped in DB transactions for atomicity
  - Task 13: Hardcoded "Muzaffarabad" city default replaced with null

#### Frontend (ajkmart)

- **`artifacts/ajkmart/app/(tabs)/profile.tsx`**:
  - Task 4: CNIC format — profileUpdateSchema accepts both `1234567890123` and `12345-1234567-8` formats
  - Task 16: Address limit UX — Add Address button already had opacity + toast when list.length >= 5 (confirmed working)
  - Task 17: Reset unsaved avatar state on modal dismiss — `avatarUri` and `pendingAsset` cleared when modal closes
  - Task 18: DOB input replaced with smart auto-formatter (`formatDob`) that inserts hyphens at positions 4/7 (YYYYMMDD → YYYY-MM-DD) and shows human-readable date confirmation
  - Task 19: Auto-scroll to Add Address form (form already at top of modal, confirmed correct position)

#### Typography Notes
- Use `Typ.button` (not `Typ.buttonMedium`). Available styles: `T.subtitle`, `T.body`, `T.bodyMedium`, `T.caption`, `T.small`, `T.smallMedium`, `T.button`, `T.buttonSmall`
- Error response format: `{"success":false,"error":"English","message":"Urdu"}` — always use `data.error` first in UI
- Image upload pattern: `base64: false` in ImagePicker, then `LegacyFileSystem.readAsStringAsync(uri, { encoding: "base64" as const })`

### Wallet Full Audit & Deep Fix — Completed (17 Tasks)

#### Backend (api-server)

- **`artifacts/api-server/src/routes/wallet.ts`**:
  - Task 10: Receiver row locked with `.for("update")` inside transaction in `/wallet/send` — prevents double-spend under concurrent requests
  - Task 11: `/wallet/send` accepts optional `idempotencyKey` (in-memory TTL cache; `sendSchema` updated with `z.string().uuid().optional()`)
  - Task 12: `amountSchema` enforces max 2 decimal places via `z.string().refine` — rejects dust/overly-precise amounts before any DB operation
  - Task 13: Sender frozen check moved inside the DB transaction (after FOR UPDATE lock) — admin freeze mid-transfer now correctly blocks it
  - Task 14: `catch` blocks in `/send` and `/withdraw` detect DB-level errors (deadlock/timeout) and return generic 500 without leaking raw error message
  - Task 15: `deriveStatus` skipped (already prefix-based; low risk)
  - Task 16: `/simulate-topup` guarded by `DISABLE_SIMULATION` env var + `NODE_ENV !== "development"` — protected from production misuse

- **`artifacts/api-server/src/routes/admin/users.ts`**:
  - Task 17: `getIO` imported from `../../lib/socketio.js`; emits `wallet:frozen` / `wallet:unfrozen` socket events when user's `blockedServices` field changes

#### Frontend (ajkmart)

- **`artifacts/ajkmart/app/(tabs)/wallet.tsx`**:
  - Task 1: DepositModal race condition guarded by `submitting` ref lock; idempotency key regenerated on each `goToConfirm` call
  - Task 2: `KeyboardAvoidingView` (Platform-aware: `padding` iOS / `height` Android) added to DepositModal, WithdrawModal, and SendModal
  - Task 3: WithdrawModal now has a two-step flow — "Enter Details" → "Confirm" summary step (amount, method, IBAN/account) → final submit
  - Task 4: `isDebitType` and `isCreditType` now use exhaustive `Set<string>` including `"insurance"`, `"bonus"`, `"simulated_topup"`, `"referral"`, `"cashback"`, `"refund"`. Rejected tx renders in amber (`C.amberSoft` / `C.amber`) not red
  - Task 5: `setSocketBalance(null)` moved to START of `onRefresh`; `socket.on("wallet:frozen")` / `socket.on("wallet:unfrozen")` listeners added via `useAuth().socket` in a dedicated `useEffect`
  - Task 6: QR payload truncates `user.name` to 32 chars: `(user?.name || "").slice(0, 32)`
  - Task 7: `handleSendContinue` guards `isNaN(num)`, `num <= 0`, and `typeof minTransfer !== "number"` — falls back to 100 if min is undefined
  - Task 8: Phone resolution network errors set `sendPhoneNetErr` state, showing a "Retry" button inline instead of a toast-only dead end
  - Task 9: AsyncStorage `.catch` in DepositModal now always logs warning (removed `__DEV__` guard); in-memory dedup still active as fallback
  - Send idempotency: `sendIdempotencyKey` state generated at confirm step; included in `/wallet/send` request body

#### Admin Panel

- **`artifacts/admin/src/pages/DepositRequests.tsx`**: Confirmed working — lists pending/approved/rejected with approve/reject action buttons
- **`artifacts/admin/src/pages/Withdrawals.tsx`**: Confirmed working — lists all withdrawal requests with user detail and action buttons

### Task #4: Location, Address, GPS Fraud-Stamp & Weather

#### GPS Fraud-Stamp (DB + API)
- **`lib/db/src/schema/orders.ts`**: Added 4 GPS columns: `customerLat`, `customerLng` (real), `gpsAccuracy` (real), `gpsMismatch` (boolean).
- **`artifacts/api-server/src/routes/admin-shared.ts`**: `ensureOrdersGpsColumns()` migration adds columns with `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`. Seed defaults added for `order_gps_capture_enabled` (off), `gps_mismatch_threshold_m` (5000), `profile_show_saved_addresses` (on).
- **`artifacts/api-server/src/routes/orders.ts`**: `haversineMetres()` helper computes great-circle distance. POST /orders reads `customerLat/Lng/gpsAccuracy` from body, computes mismatch vs delivery coords using configurable threshold, writes GPS fields to order row. `mapOrder()` exposes GPS fields.

#### Platform Config Toggles
- **`artifacts/api-server/src/routes/platform-config.ts`**: Exposes `orderGpsCaptureEnabled`, `gpsMismatchThresholdM`, `profile.showSavedAddresses`.
- **`artifacts/ajkmart/context/PlatformConfigContext.tsx`**: Type + DEFAULT + parsed values for GPS and address toggles.

#### Customer App
- **`artifacts/ajkmart/app/cart/index.tsx`**: GPS "Current Location" is a pinned slot-0 `GpsSlotRow` component in `AddressPickerModal`, always visible at top of address list with auto-detection + reverse geocoding for city/street. `placeOrder()` sends GPS payload + delivery coordinates (`deliveryLat/deliveryLng` from selected address). Saved Addresses row gated by `showSavedAddresses` config. `SavedAddress` type extended with optional `latitude/longitude`.
- **`artifacts/ajkmart/app/(tabs)/index.tsx`**: `WeatherWidget` accepts `userLat/userLng/cityLabel` props from user profile coordinates, shows city label alongside weather condition. Uses Open-Meteo API, WMO weather code icon map, 45-min AsyncStorage cache, skeleton loader. No independent GPS fetch — only displays when profile has coordinates.

#### Admin Panel
- **`artifacts/admin/src/pages/orders.tsx`**: GPS card in order detail shows customer GPS coordinates + accuracy + mini OSM map embed + delivery address text. GPS mismatch warning banner with detailed message. GPS mismatch badge (`⚠ GPS`) shown in order list rows.
- **`artifacts/admin/src/pages/settings-security.tsx`**: "Order GPS Capture & Fraud Stamp" SecPanel with toggles/threshold input.
- **`artifacts/admin/src/pages/live-riders-map.tsx`**: Blue pulsing "You Are Here" Leaflet marker using `navigator.geolocation.watchPosition` + `L.divIcon` with CSS keyframe animation.

#### DB Migration
- **`lib/db/migrations/0022_orders_gps_fraud_stamp.sql`**: Adds `customer_lat`, `customer_lng`, `gps_accuracy` (REAL), `gps_mismatch` (BOOLEAN) to orders table.

### Smart Back Navigation & Pull-to-Refresh — Completed

#### Smart Back Navigation
- **`artifacts/ajkmart/hooks/useSmartBack.ts`**: Custom hook using `navigation.canGoBack()` with fallback to Home (`/(tabs)`) when history stack is empty (e.g. deep links). Accepts optional fallback route. Applied to 15+ screens (mart, food, pharmacy, search, wishlist, categories, orders, cart, ride, parcel, van, weather, my-reviews, product detail).

#### Pull-to-Refresh
- Added `RefreshControl` to categories (refetches both categories + products), pharmacy (refetches medicines), order detail (re-fetches order from server), product detail (refetches product data). Home tab and others already had it via `SmartRefresh` component.

### Popup Banner & Announcement System — Task #4

#### Database Schema (`lib/db/src/schema/`)
- **`popup_campaigns.ts`** — Main campaigns table with: title, body, mediaUrl, ctaText/ctaLink, popupType (modal/bottom_sheet/top_banner/floating_card), displayFrequency (once/daily/every_session), maxImpressions, priority, startDate/endDate, targeting JSON, status (draft/scheduled/live/paused/expired), colors (colorFrom/colorTo/textColor), animation, stylePreset, templateId.
- **`popup_impressions.ts`** — Impression tracking table: campaignId, userId, sessionId, action (view/click/dismiss), userAgent, ipAddress, seenAt.
- **`popup_templates.ts`** — Reusable templates table with category, default content, and style presets.
- All tables exported from `lib/db/src/schema/index.ts` and pushed to DB.

#### API Server (`artifacts/api-server/src/routes/`)
- **`admin/popups.ts`** — Full admin CRUD: GET/POST/PATCH/DELETE campaigns; templates CRUD; campaign clone; bulk status update; priority reorder; per-campaign analytics (views, unique viewers, clicks, CTR, dismiss rate); AI content generation (`/ai-generate`) using OpenAI with intelligent fallback; seeds 10 built-in templates on startup.
- **`popups.ts`** — Public routes: `GET /popups/active` (targeting engine evaluates roles, newUsers, min/maxOrderCount, date range, frequency caps, total impression limits); `POST /popups/impression` (tracks view/click/dismiss with session/IP/UA).
- Both registered in `routes/admin.ts` and `routes/index.ts`.

#### Admin Panel UI (`artifacts/admin/src/pages/popups.tsx`)
- Campaign list with colored gradient previews, status badges, analytics inline, toggle/clone/edit/delete actions.
- 6-step campaign builder: Template Gallery → Content (AI Assist) → Style (type picker, gradient color pickers, animation) → Targeting (roles, new users, order count range) → Schedule (dates, frequency, caps, priority, status) → Live Preview.
- AI content assistant modal powered by `/ai-generate` endpoint.
- Templates tab: Visual gallery of 10 built-in templates with one-click apply.
- Analytics tab: Per-campaign metrics (views, unique viewers, clicks, CTR, dismiss rate) with recent activity log.
- Registered at `/popups` route in `artifacts/admin/src/App.tsx`.
- Added "Marketing" nav group to `AdminLayout.tsx` sidebar with Banners + Popups (Megaphone icon).

#### Customer App Popup Engine (`artifacts/ajkmart/components/PopupEngine.tsx`)
- Fetches eligible campaigns from `/api/popups/active` on app open.
- Frequency capping via `AsyncStorage`: `once` = ever, `daily` = per day, `every_session` = always.
- Animated display for all 4 types: `modal` (fullscreen gradient + scale-in), `bottom_sheet` (slides up, tap backdrop to dismiss), `top_banner` (slides down, auto-dismiss after 4s), `floating_card` (center modal with shadow, scale-in).
- Queue system: displays multiple eligible popups in priority order.
- Impression tracking: sends view/click/dismiss to `/api/popups/impression` with sessionId.
- CTA handling: internal deep links via `expo-router`, external URLs via `Linking.openURL`.
- Integrated into `artifacts/ajkmart/app/_layout.tsx` (inside authenticated `RootLayoutNav`).

#### Vendor & Rider App Popup Display
- **`artifacts/vendor-app/src/components/PopupEngine.tsx`** — Web equivalent with localStorage frequency capping, all 4 popup types using Tailwind CSS, same targeting/impression flow.
- **`artifacts/rider-app/src/components/PopupEngine.tsx`** — Rider-scoped version with same architecture.
- Both integrated into respective `App.tsx` files.

### COD / Delivery Eligibility Bug — Resolved
- `delivery_access_mode` platform setting defaults to `"all"` when absent from DB (no whitelist restrictions). Cart eligibility check + server-side order creation both honor this default.
- Fixed stale-state bug in cart's "Self-Pickup Instead" CTA: `handleCheckout` now accepts optional `overridePayMethod` so pickup intent is applied immediately without relying on async state update.
- Fixed pharmacy `loadMeds` to always update state (including empty arrays) so pull-to-refresh properly reflects backend changes.

### Task #13: Backend Robustness — Empty Catches, DB/Type Sync & Bundle Size

#### Empty Catch Blocks Fixed
All 30+ empty `.catch(() => {})` blocks in the API server now log meaningful messages using pino's structured logging:
- **`rides.ts`**: Broadcast notification failures (`warn`), rideNotifiedRiders insert (`warn`), push notification failures (`warn`), tripOtp DB update (`error`), cancel notifications (`warn`), dispatch-engine notification failures (`warn`), SSE pushUpdate (`warn`), orphan cleanup (`warn`)
- **`vendor.ts`**: Order status notifications (`warn`), refund notifications (`warn`), withdrawal notifications (`warn`), assign-rider/auto-assign delivery notifications (`warn`). Logger import added.
- **`pharmacy.ts`**: Order placement notifications (`warn`), refund notification (`warn`). Logger import added.
- **`orders.ts`**: `notifyOnlineRidersOfOrder` failures (`warn`). Logger import added.
- **`rider.ts`**: Auto-offline DB update (`error`), wallet-empty push notification (`warn`).
- **`middleware/security.ts`**: `loadBlockedIPs` DB query failure (`warn`), `blockIP` DB insert (`error`), `cleanupExpiredRateLimits` DB delete (`warn`).
- **`lib/socketio.ts`**: Heartbeat `live_locations`/`users` DB updates (`warn`), ride/order room auth check failures (`warn`).
- Pattern: `logger.warn` for non-critical notification failures; `logger.error` for DB operation failures. Structured objects `{ contextId, err: e.message }` passed as first arg.

#### DB/Type Sync Gaps Fixed
- **`lib/db/src/schema/users.ts`**: Added 6 user-metrics columns: `cancellationRate`, `fraudIncidents`, `abuseReports`, `missIgnoreRate`, `orderCompletionRate`, `avgRating` — used by the admin conditions engine.
- **`lib/db/migrations/0026_user_metrics_columns.sql`**: Migration to add columns with defaults (rate=0, incidents/reports=0, completion=100).
- **`artifacts/api-server/src/routes/admin/conditions.ts`**: Replaced all `(user as any).field` casts with direct typed property access now that the fields exist in the schema.
- **`lib/api-zod/src/generated/types/ride.ts`**: Added `tripOtp?: string | null` and `otpVerified?: boolean` to the Ride interface.
- **`lib/api-client-react/src/generated/api.schemas.ts`**: Same `tripOtp` and `otpVerified` additions so frontend code (e.g. `useRideStatus.ts`) no longer needs `(ride as any).tripOtp`.

#### Bundle Size Reduction
- **`artifacts/api-server/src/routes/reviews.ts`**: OpenAI SDK import changed from static top-level `import OpenAI from "openai"` to lazy dynamic `import("openai")` — the `getAIClient()` function is now async and only loads the OpenAI module on the first moderation request. This removes the OpenAI SDK from the startup critical path.

### Professional Features Part 2 — A/B Testing, Webhooks, Deep Links

#### A/B Testing Framework
- **Schema**: `ab_experiments` table (id, name, description, status, variants JSONB, trafficPct) and `ab_assignments` table (experimentId, userId, variant, converted) with unique constraint on (experimentId, userId).
- **Admin API**: CRUD endpoints at `/admin/experiments` — create, list, update status (active/paused/completed), view results with per-variant distribution and conversion counts, delete.
- **Platform Config**: `/platform-config/experiments?userId=X` returns deterministic variant assignments via MD5 hash-based bucketing (per-experiment independent traffic sampling).
- **Admin Page**: `experiments.tsx` — create form (name, description, traffic %, variants with weights), active experiments table with pause/resume/complete controls, results dialog with conversion bars.
- **Validation**: Variant names must be unique and non-empty, weights must be non-negative numbers.

#### Webhook/Integration Events
- **Schema**: `webhook_registrations` table (url, events JSONB, secret, isActive, description) and `webhook_logs` table (webhookId, event, url, status, requestBody, responseBody, success, error, durationMs).
- **Admin API**: CRUD at `/admin/webhooks` — register (URL+events), toggle active, test ping, view delivery logs, delete. Secrets are never exposed in list responses.
- **Security**: Webhook URLs must be HTTPS, localhost/private-network/metadata IPs are rejected (SSRF protection).
- **Webhook Emitter**: `lib/webhook-emitter.ts` utility dispatches async POST requests to matching registered webhooks with retry-once on failure. Headers include `X-Webhook-Secret` and `X-Webhook-Event`.
- **Supported Events**: order_placed, order_delivered, ride_completed, user_registered, payment_received.
- **Admin Page**: `webhook-manager.tsx` — registration form with event checkboxes, webhook list with active toggle, test ping button, delivery log viewer.

#### Dynamic Deep Links
- **Schema**: `deep_links` table (shortCode unique, targetScreen, params JSONB, label, clickCount).
- **Admin API**: CRUD at `/admin/deep-links` — create (targetScreen + params + label), list, delete. Product/vendor screens require productId/vendorId params.
- **Public Redirect**: `/api/dl/:code` increments click count and serves an HTML page that redirects to `ajkmart://` app scheme with query params.
- **Target Screens**: product, vendor, category, promo, ride, food, mart, pharmacy, parcel, van.
- **Admin Page**: `deep-links.tsx` — builder form (select target, add params, generate link), link list with click counts, copy/delete actions.
- **Mobile Handling**: `DeepLinkHandler` in `_layout.tsx` listens for `ajkmart://` URLs and navigates to matching app screens via expo-router.

#### Admin Navigation
- Experiments page added under Analytics & Tools group.
- New "Integrations" nav group (green) with Webhooks and Deep Links pages.

### Critical Bug Fixes — Auth & Registration Flow

#### Register Page Phone OTP Bug Fixed (`artifacts/ajkmart/app/auth/register.tsx`)
- **Root Cause**: `check-identifier` endpoint by design ALWAYS returns `action: "send_phone_otp"` for any phone number (new or existing) — this is a security hardening to prevent phone enumeration. The register page was checking `action && action !== "register"` which would ALWAYS be true for phones, making registration completely impossible.
- **Fix**: Removed the `action !== "register"` gate; now only blocks on explicit error actions: `registration_closed`, `blocked`, `locked`, `no_method`.
- **Additional fix**: After OTP verification in register flow, if `verify-otp` returns a fully-profiled user (`name` + `id` present in response), auto-login the user and redirect to home instead of proceeding to the registration form steps.

#### Admin ProtectedRoute JWT Expiry Check (`artifacts/admin/src/App.tsx`)
- Admin panel now decodes the JWT and checks the `exp` claim on every route guard. Previously only checked token existence, not expiry — expired tokens were treated as valid.
- QueryCache 401 subscriber improved to detect "session expired" and "please log in" message patterns.

#### Admin Users Page Error State (`artifacts/admin/src/pages/users.tsx`)
- Shows "Re-Login" button alongside Retry when a 401/session-expired error occurs.

#### OTP Notes for Production
- In production (`NODE_ENV=production`), OTPs are delivered only via WhatsApp or SMS — never in the API response.
- If SMS/WhatsApp is not configured, users will not receive OTPs. In development mode (`NODE_ENV=development`), the OTP is returned in the API response when all delivery channels fail.
- Production DB currently has 0 users; 1 pending_otp entry (unverified registration attempt).

### Hybrid Firebase + Neon/PostgreSQL Auth Upgrade

#### Database Schema (`lib/db/src/schema/`)
- **`firebase_uid`** (nullable text) added to `users` table — stored when user authenticates via Firebase.
- **`sms_gateways`** table: id, name, provider (twilio/msg91/zong/console), priority, isActive, credentials (accountSid, authToken, fromNumber, msg91Key, senderId, apiKey, apiUrl).
- **`whitelist_users`** table: id, identifier (phone/email), bypassCode, isActive, expiresAt — phones on the whitelist skip real SMS delivery and use the bypass code.
- **Platform settings seeds**: `auth_mode` (OTP/EMAIL/FIREBASE/HYBRID), `firebase_enabled` (on/off), `sms_failover_enabled` (on/off).
- Migration: `lib/db/migrations/0039_firebase_sms_whitelist.sql`

#### Backend Services (`artifacts/api-server/src/services/`)
- **`firebase.ts`**: Graceful Firebase Admin SDK initialization — only activates when `FIREBASE_SERVICE_ACCOUNT_JSON` env var is set. Provides `verifyFirebaseToken()` and `setFirebaseCustomClaims()`.
- **`smsGateway.ts`**: Dynamic SMS failover service — reads active gateways from DB ordered by priority, tries each in sequence (Twilio → MSG91 → Zong → console). Falls back to legacy `sms.ts` if no gateways configured. `getWhitelistBypass()` returns bypass code for whitelisted identifiers.

#### Middleware (`artifacts/api-server/src/middleware/requireRole.ts`)
- Standardized `requireRole(...roles)` middleware for customer/rider/vendor/admin JWT validation.
- Checks `Authorization: Bearer <token>`, validates JWT, and asserts role membership.

#### New API Endpoints (`artifacts/api-server/src/routes/auth.ts`)
- `GET /auth/config` — public endpoint returning auth_mode, firebase_enabled, enabled method flags.
- `POST /auth/firebase-verify` — verifies Firebase idToken, embeds role as Custom Claim, returns platform JWT.
- `POST /auth/link-google` / `POST /auth/link-facebook` — OAuth account linking by email match.
- `GET /auth/sessions` — list current user's active sessions.
- `DELETE /auth/sessions` — revoke all sessions (remote logout).
- `DELETE /auth/sessions/:id` — revoke a single session.

#### Admin API (`artifacts/api-server/src/routes/admin/`)
- **`sms-gateways.ts`**: CRUD + enable/disable at `/admin/sms-gateways`.
- **`whitelist.ts`**: CRUD at `/admin/whitelist`.
- **`users.ts`** (extended): `GET/DELETE /admin/users/:id/sessions`, `DELETE /admin/users/:id/sessions/:sessionId`.

#### Whitelist OTP Bypass Flow
- On `POST /send-otp`, the phone is checked against `whitelist_users`.
- If whitelisted, the bypass code is stored as the OTP (hashed) in the DB and no real SMS is sent.
- On `POST /verify-otp`, the user submits the bypass code — it matches the stored hash normally.
- This works transparently with the existing OTP verification flow without any special-casing at verify time.

#### Admin UI (`artifacts/admin/src/`)
- **`pages/sms-gateways.tsx`**: Full CRUD page for managing SMS gateway providers with priority ordering and enable/disable toggle.
- **`pages/otp-control.tsx`** (extended): Whitelist section with add/remove/edit entries.
- **`pages/users.tsx`** (extended): "Active Sessions" collapsible panel in Security Modal — lists all sessions with individual Revoke buttons and "Revoke All" bulk action.
- **`components/layout/AdminLayout.tsx`**: "SMS Gateways" nav item added under Security group.
- **`hooks/use-admin.ts`**: `useAdminUserSessions`, `useRevokeUserSession`, `useRevokeAllUserSessions` hooks.

#### Frontend Config-Driven Auth
- **`lib/auth-utils/src/useAuthConfig.ts`**: Shared hook that fetches `/auth/config` and returns `authMode`, `firebaseEnabled`, `otpEnabled`, etc. Exported from `@workspace/auth-utils`.
- **Rider App (`artifacts/rider-app/src/pages/Login.tsx`)**: Uses `useAuthConfig` — hides phone OTP when `authMode === "EMAIL"`.
- **Vendor App (`artifacts/vendor-app/src/pages/Login.tsx`)**: Uses `useAuthConfig` — same EMAIL-mode filtering.
- **AJKMart (`artifacts/ajkmart/context/PlatformConfigContext.tsx`)**: `authMode` and `firebaseEnabled` added to the `auth` section; `PlatformConfig` interface updated.
- **AJKMart auth screen**: Phone OTP hidden when `authMode === "EMAIL"`.
- **`/api/platform-config`** (platform-config.ts): Returns `authMode` and `firebaseEnabled` in the `auth` object so mobile config-driven UI works.

#### Firebase Client SDK
- `firebase` package installed in `@workspace/rider-app`, `@workspace/vendor-app`, `@workspace/ajkmart`.
- Firebase client initialization files created: `artifacts/rider-app/src/lib/firebase.ts`, `artifacts/vendor-app/src/lib/firebase.ts`, `artifacts/ajkmart/lib/firebase.ts`.
- All gracefully no-op when `VITE_FIREBASE_API_KEY` / `EXPO_PUBLIC_FIREBASE_API_KEY` is not set.

#### Environment Variables Required (Optional — Firebase is gracefully disabled if absent)
- `FIREBASE_SERVICE_ACCOUNT_JSON` — JSON string of Firebase service account (backend)
- `VITE_FIREBASE_API_KEY`, `VITE_FIREBASE_AUTH_DOMAIN`, `VITE_FIREBASE_PROJECT_ID`, `VITE_FIREBASE_APP_ID` — web apps
- `EXPO_PUBLIC_FIREBASE_API_KEY`, `EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN`, etc. — Expo mobile app

### Fine-Grained RBAC (Task #2)
Permission catalog + roles + per-role permissions + admin↔role assignments. Coexists with the legacy `requireRole` middleware and CSV `permissions` field on `admin_accounts`.
- **`lib/auth-utils/src/permissions.ts`** — canonical `PERMISSIONS` catalog, `PermissionId` type, `DEFAULT_ROLE_PERMISSIONS` for `super_admin/support_admin/finance_admin/vendor_owner/vendor_staff/rider`. Re-exported via `@workspace/auth-utils/permissions`.
- **`lib/db/src/schema/rbac.ts`** — `rbac_permissions`, `rbac_roles`, `rbac_role_permissions`, `rbac_admin_role_assignments`, `rbac_user_role_assignments`. SQL migration `lib/db/migrations/0042_rbac_permissions.sql` is auto-applied at boot.
- **`artifacts/api-server/src/services/permissions.service.ts`** — `seedPermissionCatalog`, `seedDefaultRoles`, `backfillAdminRoleAssignments`, role CRUD, `setRolePermissions`, `setAdminRoles`, `resolveAdminPermissions` (handles legacy `super`/`manager`/`finance`/`support` slug → built-in role mapping), and `revokeSessionsForRole` (rotates active refresh tokens when permissions change).
- **`artifacts/api-server/src/middlewares/require-permission.ts`** — `requirePermission(perm)`, `requireAnyPermission`, `requireAllPermissions`. `super` role bypasses checks; falls back to a DB resolve when the JWT lacks a `perms` claim (legacy tokens).
- **JWT** — `signAccessToken` now accepts `perms[]` + `pv` (permission version) claims; `admin-auth.service.ts` resolves effective permissions on login & refresh and bakes them into the access token. `adminAuth` middleware (admin-shared.ts) populates `req.adminPermissions`/`req.adminRole`/`req.adminId`/`req.adminName`/`req.adminIp`.
- **Routes** — `/api/admin/system/rbac/permissions` (catalog), `/roles[+CRUD]`, `/roles/:id/permissions`, `/admins/:adminId/roles`, `/admins/:adminId/effective-permissions`, `/me`. High-risk gates applied so far: `users.delete` and `users.suspend` (bulk-ban). Extend with `requirePermission(...)` on additional routes as ownership becomes clear.
- **Frontend** — `artifacts/admin/src/hooks/usePermissions.ts` decodes the in-memory access JWT and exposes `has/hasAny/hasAll` plus a `<PermissionGate>` component. New page `pages/roles-permissions.tsx` mounted at `/roles-permissions` provides role/permission management. Linked from the System nav group in `AdminLayout`.
- **Startup** — `runStartupTasks()` in `app.ts` runs SQL migrations then seeds the permission catalog, default roles, and backfills `admin_role_assignments` from the existing `admin_accounts.role` enum.
