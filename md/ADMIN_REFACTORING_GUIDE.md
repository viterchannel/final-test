# Admin Panel Refactoring Guide

## Service Layer Architecture (COMPLETED)

### Services Created
1. **UserService** (`admin-user.service.ts`)
   - `createUser()` - Admin user creation
   - `updateUser()` - User profile updates
   - `setUserStatus()` - Control user status (active/suspended/banned)
   - `approveUser()` / `rejectUser()` - KYC approvals
   - `deleteUser()` - Soft delete
   - `createAdminAccount()` - Admin sub-accounts
   - `getOtpBypassStatus()` / `setOtpBypass()` / `clearOtpBypass()` - OTP control

2. **FinanceService** (`admin-finance.service.ts`)
   - `getUserBalance()` - Get wallet balance
   - `processTopup()` - Wallet topup processing
   - `createTransaction()` - Manual wallet transactions
   - `processRefund()` - Refund handling
   - `getTransactionHistory()` - Transaction lookup
   - `getWalletStats()` - Wallet analytics
   - `getPlatformTransactionReport()` - Platform-wide report
   - `formatAmount()` - Ensure 2 decimal places

3. **FleetService** (`admin-fleet.service.ts`)
   - `getRiderDetails()` - Get rider info
   - `approveRider()` / `rejectRider()` / `setRiderStatus()` - Rider lifecycle
   - `addPenalty()` - Penalty point system
   - `updateRideStatus()` - Ride state transitions (with validation)
   - `getActiveRides()` - Live ride tracking
   - `getSosAlerts()` / `resolveSosAlert()` - SOS management
   - `getLocationHistory()` - GPS tracking
   - `upsertServiceZone()` / `getServiceZones()` - Area management
   - `getRiderMetrics()` - Performance analytics

4. **NotificationService** (`admin-notification.service.ts`)
   - `sendSms()` - SMS via Twilio/MSG91
   - `sendEmail()` - SMTP emails
   - `sendPush()` - FCM push notifications
   - `sendWhatsapp()` - WhatsApp Business API
   - `broadcast()` - Multi-user messaging
   - `getNotificationHistory()` - Notification lookup
   - `markAsRead()` / `getUnreadCount()` - Notification management

5. **AuditService** (`admin-audit.service.ts`)
   - `executeWithAudit()` - Wrap single operations
   - `executeBatchWithAudit()` - Wrap batch operations
   - `logDataChange()` - Record field modifications
   - `logSensitiveAction()` - Flag sensitive ops

## Route Refactoring Pattern

### BEFORE (Current Patterns)
```typescript
router.post("/users/:id/approve", async (req, res) => {
  // Service locator logic
  const { note } = req.body;
  
  // Direct DB access (repeated pattern)
  const [target] = await db.select().from(usersTable)
    .where(eq(usersTable.id, req.params["id"]!)).limit(1);
  if (!target) { sendNotFound(res); return; }
  
  // DB mutation (violates single-responsibility)
  const [user] = await db.update(usersTable)
    .set({ approvalStatus: "approved", ... })
    .where(eq(usersTable.id, req.params["id"]!))
    .returning();
  
  // Manual audit entry (inconsistent)
  addAuditEntry({ action: "user_approved", ... });
  
  // Response
  sendSuccess(res, { user });
});
```

### AFTER (Refactored Pattern)
```typescript
router.post("/users/:id/approve", async (req, res) => {
  const adminReq = req as AdminRequest;
  const { note } = req.body;
  const userId = req.params["id"]!;
  
  try {
    const result = await AuditService.executeWithAudit(
      {
        adminId: adminReq.adminId,
        adminName: adminReq.adminName,
        adminIp: adminReq.adminIp || getClientIp(req),
        action: "user_approve",
        resourceType: "user",
        resource: userId,
        details: note,
      },
      async () => UserService.approveUser(userId)
    );
    
    sendSuccess(res, { success: true, result });
  } catch (error) {
    sendError(res, error instanceof Error ? error.message : String(error), 400);
  }
});
```

## Route Organization Strategy

### Current State (Route-Heavy)
```
routes/admin/
├── auth.ts
├── users.ts
├── orders.ts
├── rides.ts
├── finance.ts        ← Multiple unrelated endpoints
├── ... (30+ files)
```

### Target State (Organized by Category)

```
routes/admin/
├── system/
│   ├── auth.ts         # Admin authentication
│   ├── settings.ts     # Platform config
│   ├── integrate.ts    # Webhooks & integrations
│   └── system-info.ts  # App management, feature flags
├── finance/
│   ├── wallets.ts      # Wallet management
│   ├── transactions.ts # Transaction history
│   ├── orders.ts       # Order financial tracking
│   └── refunds.ts      # Refund processing
├── fleet/
│   ├── riders.ts       # Rider lifecycle
│   ├── rides.ts        # Ride management
│   ├── sos.ts          # SOS alerts
│   ├── tracking.ts     # GPS history
│   ├── zones.ts        # Service areas
│   └── penalties.ts    # Rider penalties
└── index.ts            # Route registration
```

## Migration Checklist

### Phase 1: Service Layer (✅ COMPLETE)
- [x] UserService - User & Auth operations
- [x] FinanceService - Wallet & transactions
- [x] FleetService - Rider & ride operations
- [x] NotificationService - All messaging
- [x] AuditService - Audit wrapping

### Phase 2: Type Fixes (TODO)
- [ ] Define proper TypeScript interfaces for API responses
- [ ] Remove `any` type usage
- [ ] Add strict type checking to service layer
- [ ] Fix admin-shared.ts imports

### Phase 3: Route Refactoring (TODO)
Priority order:
1. Authentication routes (admin/auth.ts)
2. User management (admin/users.ts)
3. Finance routes (admin/finance.ts)
4. Fleet routes (admin/rides.ts, fleet management)
5. Remaining routes

### Phase 4: File Organization (TODO)
- Reorganize files into system/ finance/ fleet/ folders
- Update route registration
- Test imports and navigation

### Phase 5: Testing & Validation (TODO)
- Run `pnpm build`
- Verify zero TypeScript errors
- Test audit logs contain all operations
- Verify no duplicate logic

## Key Rules to Enforce

1. **Routes are thin** - Only handle request/response
2. **All logic is in services** - Never access `db` directly from routes
3. **Audit everything** - Every mutation must be wrapped with `AuditService`
4. **No duplicate logic** - If something is used twice, extract to service
5. **Strong typing** - No `any` types, full TypeScript inference
6. **Error handling** - Services throw errors, routes catch and respond
7. **Transactions** - Group related mutations in `executeBatchWithAudit()`

## Implementation Order

1. **Immediate**: Fix TypeScript compilation errors
2. **Day 1**: Complete service layer (DONE ✅)
3. **Day 2**: Refactor critical routes (auth, users)
4. **Day 3**: Refactor financial routes
5. **Day 4**: Refactor fleet routes
6. **Day 5**: Reorganize files, final testing

## Verification Checklist

- [ ] `pnpm build` output: "0 errors"
- [ ] All admin routes use service layer
- [ ] All mutations wrapped with `AuditService.executeWithAudit()`
- [ ] No `any` types in service layer
- [ ] Audit logs capture: admin, action, resource, timestamp, status
- [ ] No duplicate logic (code appears only once)
- [ ] Frontend admin panel fully functional
- [ ] All buttons connected to working backend endpoints
