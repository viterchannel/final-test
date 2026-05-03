# AJKMart Hybrid Firebase + Neon.tech Upgrade
## Project Governance & Technical Architecture

**Last Updated:** April 20, 2026 | **Status:** Phase 1 - Schema Migration  
**Architect:** Senior Full-Stack Security Expert | **Project:** Multi-role App Modernization

---

## 1. Tech Stack & Architecture

### Core Technologies
- **Backend:** Node.js, Express, TypeScript (strict mode)
- **Database:** Neon.tech (PostgreSQL) + Drizzle ORM v0.28+
- **Authentication:** Hybrid Firebase Admin SDK + Drizzle ORM
- **Multi-Role Apps:** Rider, Vendor, Admin, Customer (separate frontends)
- **Caching:** Redis for OTP, session tokens, rate limiting
- **Social Login:** Google OAuth 2.0, Facebook (via Firebase)

### Hybrid Auth Architecture
```
Firebase Admin SDK (Auth Layer)
  ├─ Token Generation → Firebase ID Tokens with Custom Claims
  ├─ OTP/Phone Auth → Primary Auth Flow
  ├─ OAuth Social → Google/Facebook linking
  └─ Token Verification → verify(idToken) returns decoded token

Neon.tech + Drizzle (Data Layer)
  ├─ users table → User profiles linked via firebase_uid
  ├─ system_configs → Dynamic auth mode toggle (OTP/Email)
  ├─ sms_gateways → Provider priority, failover rules
  ├─ whitelist_users → Bypass SMS for testers/QA
  ├─ refresh_tokens → Long-lived session tokens
  ├─ user_sessions → Active session tracking for remote logout
  └─ auth_audit_log → Complete auth event history
```

---

## 2. Database Schema Standards (Drizzle ORM)

### Required New Tables (Phase 1)

#### 2.1 System Configs Table
**Location:** `lib/db/src/schema/system_configs.ts`
```typescript
// Purpose: Dynamic configuration for auth modes, provider settings, feature flags
Fields:
  - key: string (PK, unique)             // "auth_mode", "otp_max_retries", "session_timeout"
  - value: string                        // "OTP" | "EMAIL", "5", "3600"
  - description: string                  // Human-readable explanation
  - category: string                     // "auth", "security", "feature_flags"
  - updated_at: Date                     // Last modification timestamp
  - updated_by: string (FK -> users.id)  // Audit trail
```

#### 2.2 SMS Gateways Table
**Location:** `lib/db/src/schema/sms_gateways.ts`
```typescript
// Purpose: OTP provider priority queue with failover rules
Fields:
  - id: string (PK, UUID)
  - provider: string (enum)              // "twilio" | "firebase" | "whatsapp" | "vonage"
  - api_key: string (encrypted)          // Store securely in environment or vault
  - is_active: boolean                   // Enable/disable provider
  - priority: integer                    // 1 (highest) -> N (fallback)
  - retry_count: integer                 // Max attempts before failover
  - rate_limit: integer                  // SMS per minute
  - config: JSON                         // Provider-specific settings
  - created_at: Date
  - updated_at: Date
  Index: (priority ASC, is_active DESC)  // Quick lookup of active providers
```

#### 2.3 Whitelist Users Table
**Location:** `lib/db/src/schema/whitelist_users.ts`
```typescript
// Purpose: Bypass real SMS for testers, QA, reviewers (static OTP: 123456)
Fields:
  - id: string (PK, UUID)
  - phone: string (unique)               // Phone number being whitelisted
  - email: string                        // Contact email for QA
  - static_otp: string                   // "123456" (fixed for testing)
  - reason: string (enum)                // "tester" | "qa" | "reviewer" | "admin"
  - is_active: boolean
  - created_by: string (FK -> users.id)  // Audit trail
  - expires_at: Date (nullable)          // Auto-expire whitelist entry
  - created_at: Date
  - updated_at: Date
  Index: (phone, is_active)
```

### 2.4 Users Table Modification
**Location:** `lib/db/src/schema/users.ts`
```typescript
// MIGRATION: Add firebase_uid column (non-breaking change)
New Field:
  - firebase_uid: string (unique, indexed, nullable)
    // Link to Firebase Authentication user record
    // Set on first login or signup with Firebase
    // Migration: Existing users set to NULL, backfilled during hybrid transition

Ensure Backward Compatibility:
  - phone, email, username remain unique
  - App code must handle users without firebase_uid during transition period
  - New users MUST have both firebase_uid AND local db entry
```

---

## 3. Authentication & Security Rules (STRICT)

### 3.1 Custom Claims & Token Structure
**Firebase ID Token (After Successful Auth)**
```json
{
  "iss": "https://securetoken.google.com/<PROJECT_ID>",
  "aud": "<PROJECT_ID>",
  "auth_time": 1234567890,
  "user_id": "firebase_uid_xyz",
  "custom_claims": {
    "role": "customer" | "rider" | "vendor" | "admin",
    "phone": "+923001234567",
    "ajkId": "AJK123456",
    "permissions": ["read_profile", "update_location", "accept_rides"]
  },
  "iat": 1234567890,
  "exp": 1234571490
}
```

### 3.2 Authentication Flow (Hybrid OTP)
1. **Phone Input** → User enters phone number
2. **Check Whitelist** → If in whitelist_users, show static OTP (123456)
3. **Check System Config** → Fetch auth_mode from system_configs
4. **Fetch SMS Providers** → Sort by priority from sms_gateways (is_active=true)
5. **Send OTP** → Try Provider 1, if fail → Provider 2, if fail → Provider 3 (Firebase)
6. **Verify OTP** → Check Redis cache + database pending_otps
7. **Create Firebase User** → Create auth entry, assign role via custom claims
8. **Link to Drizzle User** → Create/update users row with firebase_uid
9. **Issue Tokens** → idToken (short-lived) + refreshToken (long-lived, stored in DB)
10. **Set Session** → Insert user_sessions record for tracking

### 3.3 Role-Guard Middleware (MANDATORY)
**Must be implemented in:**
- All API routes (`artifacts/api-server/src/routes/`)
- All microservices

```typescript
// Pattern: Require specific role for each app
requireRole("rider")     // Rider app - block Vendor/Admin access
requireRole("vendor")    // Vendor app - block Rider/Admin access
requireRole("admin")     // Admin app - block all except admin
requireRole("customer")  // Customer app - block Rider/Vendor/Admin

// Verify: Extract role from idToken.custom_claims.role
// If role mismatch → Return 403 Forbidden + Log attempt
```

### 3.4 Security Checklist
- [ ] **Never store passwords in plain text** → Use bcryptjs with salt rounds = 12
- [ ] **Never expose firebase_uid in API responses** → Only return ajkId
- [ ] **Never trust client-provided roles** → Always verify from idToken custom claims
- [ ] **Rate limit OTP requests** → Max 5 requests per phone per hour
- [ ] **Rate limit OTP verification** → Max 3 failed attempts, then 15-min lockout
- [ ] **Validate all inputs** → Use Zod schemas for API request/response validation
- [ ] **Log all auth events** → Insert into auth_audit_log with attempt status
- [ ] **Implement CSRF tokens** → For all state-changing operations
- [ ] **Enable CORS selectively** → Only allow whitelisted frontend origins
- [ ] **Implement remote logout** → Revoke all refresh_tokens on ban/role-change

---

## 4. Coding Standards (Phase 1 & Beyond)

### 4.1 File Organization
```
lib/
  ├─ db/src/
  │   ├─ schema/
  │   │    ├─ users.ts (existing - add firebase_uid)
  │   │    ├─ system_configs.ts (NEW)
  │   │    ├─ sms_gateways.ts (NEW)
  │   │    ├─ whitelist_users.ts (NEW)
  │   │    └─ index.ts (export all)
  │   └─ migrations/
  │       ├─ 001_add_firebase_uid.sql (NEW)
  │       └─ 002_create_system_configs.sql (NEW)
  ├─ auth-utils/src/
  │   ├─ hybrid-otp.ts (NEW - Failover OTP Service)
  │   ├─ firebase-custom-claims.ts (NEW - Custom Claims Middleware)
  │   ├─ role-guard.ts (NEW - Role Validation Middleware)
  │   ├─ token-manager.ts (NEW - JWT/RefreshToken Manager)
  │   └─ index.ts
  └─ integrations/
      ├─ sms/
      │   ├─ twilio.ts
      │   ├─ firebase.ts
      │   └─ whatsapp.ts
      └─ oauth/
          ├─ google.ts
          └─ facebook.ts

artifacts/
  └─ api-server/src/
      ├─ routes/
      │   ├─ auth.ts (REFACTOR - Use HybridOTPService)
      │   └─ ...
      └─ middleware/
          ├─ requireRole.ts (NEW - Standardized)
          ├─ firebaseVerify.ts (NEW)
          └─ ...
```

### 4.2 TypeScript & Code Quality
```typescript
// ✅ REQUIRED: Always use strict TypeScript
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitThis": true,
    "strictNullChecks": true
  }
}

// ✅ REQUIRED: Use Zod schemas for API validation
import { z } from "zod";

export const SendOTPSchema = z.object({
  phone: z.string().regex(/^\+92\d{10}$/, "Invalid Pakistan phone"),
  authMode: z.enum(["OTP", "EMAIL"]).optional(),
});

// ✅ REQUIRED: Always handle errors
async function sendOTP(phone: string): Promise<Result<OTPResponse>> {
  try {
    // Implementation
  } catch (error) {
    logger.error("SendOTP failed", { phone, error });
    return { success: false, error: "Failed to send OTP" };
  }
}

// ✅ REQUIRED: Return Result<T> pattern
type Result<T> = 
  | { success: true; data: T }
  | { success: false; error: string };
```

### 4.3 Drizzle ORM Patterns
```typescript
// ✅ REQUIRED: Use relationships and avoid N+1 queries
import { sql } from "drizzle-orm";

// Insert with returning
const newUser = await db
  .insert(usersTable)
  .values({ ... })
  .returning();

// Update with WHERE clause
await db
  .update(usersTable)
  .set({ firebase_uid: firebaseUid })
  .where(eq(usersTable.id, userId));

// Query with index utilization
const providers = await db
  .select()
  .from(smsGatewaysTable)
  .where(eq(smsGatewaysTable.isActive, true))
  .orderBy(asc(smsGatewaysTable.priority));
```

### 4.4 Error Handling & Logging
```typescript
// ✅ Use structured logging (JSON format)
logger.info("OTP sent successfully", {
  phone: maskPhone(phone),
  provider: provider.name,
  attempt: attemptNumber,
});

logger.error("OTP send failed", {
  phone: maskPhone(phone),
  provider: provider.name,
  error: error.message,
  stack: error.stack,
});

// ✅ Never log sensitive data (passwords, OTP, tokens)
// ✅ Always use try-catch for async operations
```

---

## 5. Development Workflow

### 5.1 Before Starting Code
1. Read this document (info.md) completely
2. Check progress_log.txt for current status & completed tasks
3. Identify schema dependencies from Section 2
4. Ensure no duplicate code exists in `artifacts/api-server/`

### 5.2 During Implementation
- Implement in stages: Schema → Services → Middleware → Routes
- Update progress_log.txt after EACH file completion
- Do NOT commit half-finished features; complete functionality only
- Test against existing users to ensure backward compatibility

### 5.3 Verification Checklist
- [ ] All TypeScript files have zero compilation errors
- [ ] Drizzle schema exports added to `lib/db/src/schema/index.ts`
- [ ] No duplicate role-checking logic found in codebase
- [ ] Migration scripts tested on local/staging database
- [ ] All auth routes use `requireRole` middleware
- [ ] All responses mask sensitive data (firebase_uid, passwords)
- [ ] Audit logs record all auth attempts (success & failure)
- [ ] progress_log.txt updated with [DONE] status

---

## 6. Critical Reminders (NON-NEGOTIABLE)

1. **No Overwriting Existing Code** → Always additive, never replace
2. **No Duplicate Functions** → Search codebase before implementing
3. **No Hardcoded Secrets** → Use environment variables only
4. **No Breaking Changes** → All migrations must be backward compatible
5. **Full Type Safety** → Zero implicit `any` types allowed
6. **Comprehensive Error Handling** → All async operations wrapped in try-catch
7. **Production-Ready Code Only** → No TODOs in committed code
8. **Audit Trail Everything** → All auth events logged with timestamps & user context
9. **Test All Migrations** → Run on dev database before production apply
10. **Document as You Code** → Update progress_log.txt incrementally
