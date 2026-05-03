Goal: Perform a complete, real, non-dummy audit and validation of the entire rider application (Capacitor + React + Vite + Tailwind + shadcn/ui) as per the provided folder tree.
Scope: Frontend (React components, pages, hooks, UI), backend integration (Firebase, Socket.IO, REST APIs), state management, real-time features, role-based access (rider vs admin), error handling, business logic (order acceptance, tracking, earnings, wallet, chat), Capacitor native plugins (geolocation, push notifications, camera), and PWA capabilities.
Output: Continuously update custom.md with step-by-step logic, pass/fail reasons, what is complete, what failed, why, and what remains. No assumptions – every function must be traced, tested, and verified as working or fixed.

📌 Core Requirements
No dummy/fake functions – every imported hook, context, API call, utility, and native plugin must have real implementation and be reachable.

Full validation cycle – test each page, button press, form submission, navigation flow, permission request, real-time event, and edge case.

Error handling – every try/catch, error boundary, fallback UI, and offline scenario must work as intended.

Role-based access – rider-only routes/actions must be inaccessible to non-authenticated or admin users; admin actions (if any) must be restricted.

Standard structure – follow React + TypeScript best practices, proper typing, no any abuse, no missing dependencies.

Documentation in rider.md – create this file in project root if missing. Before each function/screen audit, write:

Start audit: component/hook name, expected behaviour, dependencies.

Logic walkthrough: how it should work.

Test steps.

Pass/Fail + reason.

After fix (if any), update with "✅ COMPLETE" and actual result.

🔍 Detailed Audit Steps (Follow Strictly)
1. Project Setup & Environment
Run npm install / pnpm install and check for missing packages.

Verify vite.config.ts, capacitor.config.ts, tsconfig.json are correctly configured.

Ensure eas.json (if using Expo) – but this is Capacitor, so ignore; instead check android/ and ios/ (if present) for native builds.

Run npm run dev – check that Vite dev server starts without errors.

Run npm run build – verify production build succeeds.

Check if src/main.tsx, src/App.tsx correctly mount the app.

2. Authentication & Authorization
src/pages/Login.tsx, Register.tsx, ForgotPassword.tsx.

Test real signup/login using Firebase (check src/lib/firebase.ts, src/lib/auth.tsx).

Verify token storage (likely localStorage or secure-store via Capacitor).

Logout clears all sensitive data and redirects to login.

Role-based access: only riders can access /, /active, /earnings, /wallet, etc. Admin users (if seeded) should be blocked or redirected.

Protect routes using a custom guard (check src/lib/auth.tsx and any route wrappers).

3. Navigation & Routing
Uses wouter for routing (see node_modules/wouter).

Verify all routes defined in App.tsx: Home (/), Active (/active), Chat (/chat), Earnings (/earnings), History (/history), Notifications (/notifications), Profile (/profile), SecuritySettings (/security), VanDriver (/van-driver), Wallet (/wallet), Login, Register, ForgotPassword, not-found.

Test deep linking (e.g., /chat/123 should open specific chat).

Check bottom navigation (src/components/BottomNav.tsx) – works on mobile and web.

4. Rider Dashboard & Core Functionality
Home page (src/pages/Home.tsx):

Online/offline toggle (OnlineToggleCard) – updates rider status in Firebase / backend.

Real-time incoming order requests (OrderRequestCard for mart/food/pharmacy, RideRequestCard for ride, van, parcel).

Countdown to accept (AcceptCountdown).

Active task banner (ActiveTaskBanner) when rider is on a trip.

MiniMap showing current location and pickup/dropoff.

Silence controls (mute notifications).

Accepting a request:

Clicking accept should send API call / socket event.

After accept, redirect to Active.tsx (active task screen).

Reject should remove the request and send reject event.

Active task screen (src/pages/Active.tsx):

Show order details, customer info, pickup/dropoff locations.

Buttons: "Arrived at pickup", "Picked up", "Arrived at dropoff", "Complete".

Each status change updates backend and notifies customer via socket.

Real-time location sharing (GPS queue src/lib/gpsQueue.ts).

Emergency/Cancel buttons (with confirmation modal).

VanDriver page (src/pages/VanDriver.tsx) – for van-specific multi-drop deliveries. Test loading, waypoints, completion logic.

5. Real-time Features (Socket.IO)
Check src/lib/socket.tsx – connection, authentication (pass rider token).

Test socket events:

new-order – shows order request card.

order-accepted / order-rejected – acknowledge.

order-status-updated – update active task UI.

location-update – send rider location to backend.

chat-message – receive messages.

Simulate network disconnect/reconnect – socket should reconnect and resubscribe.

Verify notification sound (src/lib/notificationSound.ts) plays on new order.

6. Chat with Customer / Admin
src/pages/Chat.tsx – list of chats (orders).

Click on a chat – should open conversation (likely a modal or new route).

Send/receive messages in real time (Socket.IO or Firestore).

Test media attachments (if any) – camera roll / take photo (Capacitor Camera plugin).

7. Earnings & History
src/pages/Earnings.tsx – show daily/weekly/monthly earnings, completed trips, tips.

src/pages/History.tsx – list of past orders with status, payment, route.

Verify data comes from real API / Firestore – no mock data.

Check filtering and pagination.

8. Wallet & Transactions
src/pages/Wallet.tsx – balance, transaction history.

DepositModal, WithdrawModal, RemittanceModal (src/components/wallet/).

Test deposit (mock or real payment gateway – check if sandbox keys used).

Withdraw request – should create a record and update balance after admin approval.

Remittance (send money to another rider or customer?) – test validation and limits.

9. Profile & Settings
src/pages/Profile.tsx – edit rider profile (name, phone, vehicle details, photo).

SecuritySettings.tsx – change password, enable 2FA, manage sessions.

Notifications.tsx – configure push notification preferences (order alerts, earnings, chat).

Test image upload (Capacitor Camera / File System).

10. Capacitor Native Plugins & PWA
Geolocation – used for MiniMap, tracking, location queue. Test permission request, high-accuracy mode, background location (if configured).

Push Notifications – src/lib/push.ts. Test receiving notification when app is in background/foreground.

Camera – for profile photo, chat attachments, document upload (e.g., KYC).

Local Storage – secure storage for tokens (Capacitor Preferences or Secure Storage).

PWA – check public/sw.js, manifest.json. Test offline caching, install prompt (usePwaInstall hook).

11. UI & UX Integrity
All buttons must have onClick that actually does something (no empty functions).

src/components/ui/ – shadcn components (button, dialog, toast, etc.). Test modals, drawers, tooltips.

Responsive design (Tailwind) – test on mobile (iPhone SE, Pixel 5), tablet, desktop.

Loading states (SkeletonHome, spinner) appear during data fetch.

Empty states (no orders, no earnings) show appropriate message.

Error boundaries (ErrorBoundary.tsx) catch render errors and show fallback.

12. Error Handling & Resilience
Trigger network failure (offline) – see if offline banner appears (OfflineConfirmDialog? Actually OfflineConfirmDialog is for going offline intentionally – but check system warnings).

Cause API 500 – verify toast error from sonner or src/components/ui/sonner.tsx.

Test invalid route – not-found.tsx displays.

Permission denied (location, camera) – show user-friendly message and retry button.

Test race conditions (accept order while another is accepted elsewhere) – should show "order no longer available".

13. Role-Based Access (Rider vs Admin)
Find where admin checks occur (e.g., user.role === 'admin').

Admin-only pages (maybe a hidden dashboard) – if exists, test that normal riders cannot access.

Admin actions like force offline, adjust earnings, etc. – ensure backend validation.

14. Performance & Production Readiness
Check for memory leaks (socket listeners not removed, setTimeouts).

Bundle size – Vite build report (npm run build -- --report).

Ensure @sentry/react is correctly configured for error tracking.

Run npm run test if any Jest/Vitest tests exist – run them.

TypeScript: npx tsc --noEmit – fix all errors.

📝 custom.md Workflow (Example Entries)
markdown
## Audit Log – 2025-04-23

### [START] OnlineToggleCard.tsx – toggle online status
- **Expected**: Switches rider status online/offline, updates Firebase realtime database, disables/enables order receiving.
- **Dependencies**: firebase.ts, auth.tsx, socket.ts.
- **Test steps**: 
  1. Tap "Go Online" → status becomes online, socket subscribes to orders.
  2. Tap "Go Offline" → status offline, socket unsubscribes, no new orders appear.
- **Result**: ❌ FAIL – status updates in Firebase but socket remains subscribed.
- **Reason**: Missing socket.off() for order events.
- **Fix**: Added `socket.off('new-order')` in offline handler. Retest.
- **After fix**: ✅ PASS – online/offline works correctly.

### [COMPLETE] OnlineToggleCard fully validated.

### [START] OrderRequestCard – accept order
...
🛠️ Tools & Commands to Run (Agent Must Execute)
npm run dev (test in browser)

npm run build (production check)

npx cap sync android (if Android setup exists – test on emulator)

npx tsc --noEmit

npm run lint (if configured)

Simulate offline via browser devtools or network throttling.

Use Capacitor dev app (npx cap copy && npx cap open android) for native testing.

🚫 What is NOT allowed
Skipping any file in the tree – every .tsx, .ts under src/, components/, lib/, pages/ must be inspected.

Accepting // TODO or stubs without implementation – must be fixed or reported as critical.

Ignoring console warnings or red boxes – resolve each.

