-- Migration: Add partial payment tracking fields to payment_plans table
-- Purpose: Track original scheduled amounts, actual amounts paid, and carryover amounts
--          to support partial payments and overpayments with audit trail

-- Add columns for partial payment tracking
ALTER TABLE payment_plans
ADD COLUMN IF NOT EXISTS original_amount numeric,
ADD COLUMN IF NOT EXISTS amount_paid numeric DEFAULT 0,
ADD COLUMN IF NOT EXISTS carryover_amount numeric DEFAULT 0,
ADD COLUMN IF NOT EXISTS carryover_from_id bigint REFERENCES payment_plans(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS is_carryover boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS payment_recorded_at timestamptz;

-- Backfill original_amount from payment_amount for existing records
UPDATE payment_plans
SET original_amount = payment_amount
WHERE original_amount IS NULL;

-- Make original_amount NOT NULL after backfill
ALTER TABLE payment_plans
ALTER COLUMN original_amount SET NOT NULL;

-- Add comment for documentation
COMMENT ON COLUMN payment_plans.original_amount IS 'The originally scheduled payment amount (immutable after creation)';
COMMENT ON COLUMN payment_plans.amount_paid IS 'The actual amount paid by the user (may differ from payment_amount for partial/over payments)';
COMMENT ON COLUMN payment_plans.carryover_amount IS 'Amount carried over from a previous underpayment';
COMMENT ON COLUMN payment_plans.carryover_from_id IS 'Reference to the payment that generated this carryover';
COMMENT ON COLUMN payment_plans.is_carryover IS 'True if this payment was auto-created from an underpayment';
COMMENT ON COLUMN payment_plans.payment_recorded_at IS 'Timestamp when the payment was actually recorded/made';

-- Create index for carryover lookups
CREATE INDEX IF NOT EXISTS idx_payment_plans_carryover_from
ON payment_plans(carryover_from_id)
WHERE carryover_from_id IS NOT NULL;

-- Create index for finding carryover payments
CREATE INDEX IF NOT EXISTS idx_payment_plans_is_carryover
ON payment_plans(is_carryover)
WHERE is_carryover = true;
