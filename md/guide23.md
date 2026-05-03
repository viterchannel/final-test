Goal: Perform a complete, real, non-dummy audit and validation of the entire customer application (Expo Router + React Native) as per the provided folder tree.
Scope: Frontend, backend (if any local server), database integration, API routes, UI components, buttons, navigation, state management, role-based access (admin vs user), error handling, business logic, and third-party integrations.
Output: Continuously update custom.md with step-by-step logic, pass/fail reasons, what is complete, what failed, why, and what remains. No assumptions – every function must be traced, tested, and verified as working or fixed.

📌 Core Requirements
No dummy/fake functions – every imported hook, context, API call, and utility must have real implementation and be reachable.

Full validation cycle – test each screen, button press, form submission, navigation flow, permission request, and edge case.

Error handling – every try/catch, error boundary, fallback UI, and offline scenario must work as intended.

Admin role access – verify that admin-only routes/buttons/APIs are inaccessible to normal users and work correctly for admin.

Standard structure – follow Expo best practices, proper TypeScript types, no any abuse, no missing dependencies.

Documentation in custom.md – create this file in project root if missing. Before each function/screen audit, write:

Start audit: component/hook name, expected behaviour, dependencies.

Logic walkthrough: how it should work.

Test steps.

Pass/Fail + reason.

After fix (if any), update with "✅ COMPLETE" and actual result.

🔍 Detailed Audit Steps (Follow Strictly)
1. Project Setup & Environment
Run npm install / yarn and check for missing packages.

Ensure eas.json, app.json, babel.config.js are correctly configured for development.

Verify Metro bundler starts without errors.

Check if any shims/ are correctly applied for web.

2. Authentication & Authorization
app/auth/ – login, register, forgot-password, wrong-app.

Test real signup/login (mock Firebase or real backend if present).

Check token storage (expo-secure-store), logout clears data.

Role-based access: Admin user (if seeded) should see admin panels; normal user should not.

Validate AuthContext.tsx – protect routes, redirects.

3. Tabs & Navigation
app/(tabs)/_layout.tsx – home, orders, profile, wallet.

Switch between tabs, go deep into nested screens (mart, food, pharmacy, ride, van, parcel).

Test useSmartBack hook – back navigation should not break.

4. Core Screens & Functionality
Service	Screen/Path	Key Checks
Mart	app/mart/index.tsx, store/[id].tsx	Product listing, add to cart, stock validation, price calculation, cart context update.
Food	app/food/index.tsx, restaurant/[id].tsx, store/[id].tsx	Restaurant menu, add items, cart merge with mart? Should not conflict.
Pharmacy	app/pharmacy/index.tsx, store/[id].tsx, stores.tsx	Prescription upload? Check if real image picker works.
Ride	app/ride/index.tsx, components/ride/	Location picker (useMaps), fare estimation, negotiation screen, real-time tracking (Socket.IO).
Van	app/van/index.tsx, bookings.tsx, tracking.tsx	Booking flow, driver assignment, cancellation modal.
Parcel	app/parcel/index.tsx	Sender/recipient forms, pricing logic.
Cart & Checkout	app/order/index.tsx, context/CartContext.tsx	Mixed cart items (mart+food?) – verify separation or combined logic. Place order, payment integration (if any).
Orders	app/orders/[id].tsx, (tabs)/orders.tsx	Order history, status updates, reorder button.
Profile	(tabs)/profile.tsx, components/profile/	Edit profile, addresses modal, KYC modal, delete account (check soft delete).
Wallet	(tabs)/wallet.tsx	Balance display, transactions, add money (mock or real).
Chat	app/chat/index.tsx, [id].tsx, support.tsx	Real-time messaging (Socket.IO or Firebase). Test send/receive.
Scan	app/scan.tsx	Camera permission, QR code scanning (for store/product?).
Offers	app/offers.tsx	List of coupons, apply at checkout.
Wishlist	app/wishlist.tsx, components/WishlistHeart.tsx	Add/remove, persist across sessions.
Weather	app/weather.tsx	API call, error handling if no location permission.
Recently Viewed	app/recently-viewed.tsx	Storage and display.
Rate App	app/rate-app.tsx	In-app review (expo-store-review).
5. Backend & API Validation
Check utils/api.ts – all endpoints must be real (no console.log("mock")).

Verify lib/firebase.ts – Firebase config exists, rules are secure.

If there is a local server (server/serve.js), test its endpoints (e.g., /api/orders).

Validate socket.io-client integration for ride/chat.

Check @workspace/* packages – ensure they are correctly linked and not placeholders.

6. Database & State Persistence
context/ – Auth, Cart, Theme, Language, FontSize, Performance, RiderLocation, Toast.

Persistence: AsyncStorage for cart, wishlist, recently viewed.

Offline support: OfflineBar.tsx, useNetworkQuality – show appropriate UI when offline.

React Query (@tanstack/react-query) – cache and background refetch.

7. UI & UX Integrity
All buttons must have onPress that actually does something (no empty functions).

components/ui/ – ActionButton, BottomSheet, Modal, etc. – test open/close, animations.

Accessibility: font scaling (FontSizeContext), color contrast (ThemeContext).

Forms: Input.tsx validation, error messages.

Loading & Empty states: LoadingState, EmptyState, ErrorState appear when needed.

8. Error Handling & Resilience
Trigger network failure – see if ErrorBoundary catches and shows fallback.

Cause API 500 – verify error toast from ToastContext.

Test invalid routes – +not-found.tsx displays.

Permission denied (camera, location) – PermissionGuide shows guidance.

9. Role-Based Access (Admin)
Find where admin checks occur (e.g., user.role === 'admin').

Admin-only screens: maybe vendor/[id].tsx, certain analytics.

Modify client-side storage to simulate admin – ensure backend also enforces.

If admin panel exists inside this app (not separate), test all admin actions.

10. Performance & Production Readiness
Check for memory leaks (event listeners not removed).

Bundle size – are all imports tree-shaken?

Ensure expo-updates works for OTA.

Run expo build:web and test web version (react-native-web).

📝 custom.md Workflow (Example Entries)
markdown
## Audit Log – 2025-04-23

### [START] AuthContext.tsx – login function
- **Expected**: Calls Firebase signInWithEmailAndPassword, stores token, updates state.
- **Dependencies**: firebase.ts, secure-store.
- **Test steps**: 
  1. Enter valid credentials → should redirect to home.
  2. Invalid credentials → show error toast.
- **Result**: ❌ FAIL – secure-store setItemAsync throws "undefined is not an object".
- **Reason**: Missing web shim for expo-secure-store. Need to use `shims/expo-secure-store.web.js`.
- **Fix**: Added conditional import. Retest.
- **After fix**: ✅ PASS – login works on iOS, Android, Web.

### [COMPLETE] login function fully validated.

### [START] Mart store screen – add to cart
...
🛠️ Tools & Commands to Run (Agent Must Execute)
npx expo start --tunnel (test on real device)

npm run test (if any Jest tests exist – run them)

npx tsc --noEmit (TypeScript errors)

npm run lint (if configured)

Manually simulate offline via browser devtools / network throttling.

