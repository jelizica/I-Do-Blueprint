-- Migration: Fix vendor email unique constraint to allow multiple empty/null emails
-- Date: 2025-01-28
-- Description: Replaces the strict unique constraint on vendor email with a partial unique index
--              that only enforces uniqueness for non-null, non-empty email values.
--              This allows multiple vendors to have no email while still preventing duplicate emails.

-- Step 1: Drop the existing unique constraint first (constraint must be dropped before index)
ALTER TABLE public.vendor_information DROP CONSTRAINT IF EXISTS unique_vendor_email;

-- Step 2: Now drop any remaining indexes (in case they exist independently)
DROP INDEX IF EXISTS unique_vendor_email;
DROP INDEX IF EXISTS vendor_information_email_key;
DROP INDEX IF EXISTS idx_vendor_email_unique;

-- Step 3: Create a partial unique index that only applies to non-null, non-empty emails
-- This allows:
--   - Multiple vendors with NULL email ✓
--   - Multiple vendors with empty string '' email ✓
--   - Only ONE vendor with a specific non-empty email per couple ✓
-- 
-- The index is scoped by couple_id so different couples can have vendors with the same email
CREATE UNIQUE INDEX IF NOT EXISTS idx_vendor_email_unique_per_couple
ON public.vendor_information (couple_id, email)
WHERE email IS NOT NULL AND email != '';

-- Add comment explaining the constraint
COMMENT ON INDEX idx_vendor_email_unique_per_couple IS 
'Partial unique index ensuring email uniqueness per couple only for non-null, non-empty emails.
Multiple vendors can have NULL or empty email values.
Created in migration 20250128000003.';
