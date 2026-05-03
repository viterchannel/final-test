# Admin Service Layer Quick Reference Guide

## Service Layer Architecture

### The 5 Core Services

1. **UserService** - User lifecycle, auth, OTP, profiles, status
2. **FinanceService** - Wallets, transactions, topups, refunds
3. **FleetService** - Riders, rides, SOS, tracking, zones, penalties
4. **NotificationService** - SMS, Email, Push, WhatsApp, broadcasts
5. **AuditService** - Wraps operations with automatic audit logging

### Standard Route Pattern (After Refactoring)

Every admin operation should follow this pattern:

```typescript
router.post("/admin/resource/:id/action", async (req, res) => {
  const adminReq = req as AdminRequest;
  const { param1, param2 } = req.body;
  const resourceId = req.params.id!;

  try {
    // Step 1: Wrap operation with AuditService
    const result = await AuditService.executeWithAudit(
      {
        // Step 2: Provide audit context
        adminId: adminReq.adminId,
        adminName: adminReq.adminName,
        adminIp: adminReq.adminIp || getClientIp(req),
        action: "action_name",           // What was done
        resourceType: "resource",         // What was affected
        resource: resourceId,             // Which specific resource
        details: "Optional context"       // Why/How
      },
      // Step 3: Call the service
      () => ServiceLayer.method(resourceId, param1, param2)
    );

    // Step 4: Return success
    sendSuccess(res, result);
  } catch (error: unknown) {
    // Step 5: Handle errors
    const message = error instanceof Error ? error.message : String(error);
    sendError(res, message, 400);
  }
});
```

## Refactored Routes (Completed)

### Authentication
- **File:** `routes/admin/auth.ts`
- **Refactored:** Admin account creation
- **Service:** UserService.createAdminAccount()

### Users
- **File:** `routes/admin/users.ts`
- **Refactored:** Create, Approve, Reject, Delete, Wallet Topup
- **Services:** UserService, FinanceService

### Finance
- **File:** `routes/admin/finance.ts`  
- **Refactored:** Vendor payout, Vendor credit
- **Service:** FinanceService.createTransaction()

## Common Errors & Fixes

### Error: Import not found
**Problem:** Service imports with wrong path
**Fix:** Use full path from project root
```typescript
// ❌ Wrong
import { UserService } from "./services/admin-user";

// ✅ Correct  
import { UserService } from "../../services/admin-user.service.js";
```

### Error: Field doesn't exist
**Problem:** Using wrong field name from database
**Fix:** Check schema (it's `roles` plural, not `role`)
```typescript
// ❌ Wrong
if (user.role === "rider")

// ✅ Correct
if (user.roles.includes("rider"))
```

### Error: Amount as string vs number
**Problem:** FinanceService expects number, not string
**Fix:** Convert strings to numbers
```typescript
// ❌ Wrong
FinanceService.processTopup(userId, "100", paymentMethod)

// ✅ Correct
FinanceService.processTopup({
  userId,
  amount: Number(amount),
  paymentMethod: "admin_topup"
})
```

## Testing Refactored Operations

### 1. User Creation

```bash
curl -X POST http://localhost:8080/admin/users \
  -H "Content-Type: application/json" \
  -H "x-admin-secret: your-secret" \
  -d '{
    "phone": "03001234567",
    "name": "Test User",
    "role": "customer",
    "tempPassword": "StrongPassword123!"
  }'
```

### 2. User Approval

```bash
curl -X POST http://localhost:8080/admin/users/USER_ID/approve \
  -H "x-admin-secret: your-secret" \
  -d '{"note": "KYC verified"}'
```

### 3. Wallet Topup

```bash
curl -X POST http://localhost:8080/admin/users/USER_ID/wallet-topup \
  -H "x-admin-secret: your-secret" \
  -d '{"amount": 500, "description": "Admin topup"}'
```

### 4. Check Audit Logs

```bash
curl http://localhost:8080/admin/audit-logs \
  -H "x-admin-secret: your-secret"
```

## Key Benefits

✅ **Zero Code Duplication** - Business logic defined once, reused everywhere
✅ **Automatic Auditing** - Every operation logged with admin context
✅ **Type Safety** - Strong TypeScript types across all operations
✅ **Error Consistency** - All errors handled the same way
✅ **Validation Centralized** - Business rules in one place
✅ **Easy Testing** - Services can be tested independently
✅ **Easy Maintenance** - To fix a bug, update the service once

## Adding a New Service Method

### Step 1: Add to Service
```typescript
// admin-user.service.ts
export class UserService {
  static async blockUser(userId: string) {
    const [user] = await db
      .update(usersTable)
      .set({ isActive: false, updatedAt: new Date() })
      .where(eq(usersTable.id, userId))
      .returning();
    
    if (!user) throw new Error("User not found");
    return { success: true };
  }
}
```

### Step 2: Add Route
```typescript
// admin/users.ts
router.post("/users/:id/block", async (req, res) => {
  const adminReq = req as AdminRequest;
  const userId = req.params.id!;

  try {
    await AuditService.executeWithAudit(
      {
        adminId: adminReq.adminId,
        adminName: adminReq.adminName,
        adminIp: adminReq.adminIp || getClientIp(req),
        action: "user_block",
        resourceType: "user",
        resource: userId,
      },
      () => UserService.blockUser(userId)
    );

    sendSuccess(res, { success: true });
  } catch (error: unknown) {
    sendError(res, error instanceof Error ? error.message : String(error), 400);
  }
});
```

That's it! Auditing, error handling, logging all automatic.

## Troubleshooting

**Q: Audit logs not showing up?**
A: Check that AuditService.executeWithAudit() is wrapping the operation

**Q: Service returns error "User not found"?**
A: Service throws errors, routes catch and return proper HTTP responses

**Q: Type errors when building?**
A: Ensure you're using the correct field names and types from database schema

**Q: Operation not audited?**
A: Make sure you used AuditService.executeWithAudit(), not just calling service directly

## Service Method Reference

### UserService
- `createUser(input)` - Create new user
- `updateUser(userId, input)` - Update profile
- `setUserStatus(userId, status)` - Set active/suspended/banned
- `approveUser(userId)` - Approve KYC
- `rejectUser(userId, reason)` - Reject user
- `deleteUser(userId)` - Soft delete
- `createAdminAccount(input)` - Create sub-admin
- `getOtpBypassStatus(userId)` - Check OTP bypass
- `setOtpBypass(userId, hours)` - Set OTP bypass
- `clearOtpBypass(userId)` - Clear OTP bypass

### FinanceService
- `getUserBalance(userId)` - Get wallet balance
- `processTopup(input)` - Process topup
- `createTransaction(input)` - Manual transaction
- `processRefund(input)` - Process refund
- `getTransactionHistory(userId)` - Get history
- `getWalletStats(userId)` - Get analytics
- `getPlatformTransactionReport()` - Platform report

### FleetService
- `getRiderDetails(riderId)` - Get rider info
- `approveRider(riderId)` - Approve rider
- `rejectRider(riderId)` - Reject rider
- `setRiderStatus(riderId, status)` - Change status
- `addPenalty(riderId, points)` - Add penalty points
- `updateRideStatus(rideId, status)` - Change ride state
- `getActiveRides()` - Get live rides
- `getSosAlerts()` - Get SOS alerts
- `resolveSosAlert(alertId)` - Resolve SOS
- `getLocationHistory(riderId)` - Get GPS history
- `upsertServiceZone(zone)` - Manage zones
- `getServiceZones()` - Get all zones
- `getRiderMetrics(riderId)` - Get performance data

---

**Version:** 1.0  
**Last Updated:** 2025-04-21  
**Status:** Production Ready ✅
