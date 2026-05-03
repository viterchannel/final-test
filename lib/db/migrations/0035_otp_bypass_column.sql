-- Add OTP bypass column for admin-controlled temporary login bypass
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "otp_bypass_until" timestamp;
