-- Update payment_type constraint to reflect actual business payment types
-- This migration updates the check constraint to use meaningful payment type values

-- Step 1: Drop the old constraint
ALTER TABLE payment_plans DROP CONSTRAINT IF EXISTS check_payment_type;

-- Step 2: Update existing data BEFORE adding new constraint
-- Map old generic values to new meaningful values
UPDATE payment_plans 
SET payment_type = CASE 
  WHEN payment_type = 'single' THEN 'individual'
  WHEN payment_type = 'yearly' THEN 'interval'  -- yearly is a type of interval
  WHEN payment_type = 'custom' THEN 'interval'  -- custom intervals
  WHEN payment_type = 'monthly' THEN 'monthly'  -- stays the same
  ELSE payment_type  -- keep any other values (deposit, retainer, etc.)
END
WHERE payment_type IN ('single', 'yearly', 'custom');

-- Step 3: Add new constraint with meaningful payment types
ALTER TABLE payment_plans ADD CONSTRAINT check_payment_type 
  CHECK (payment_type IN ('individual', 'monthly', 'interval', 'cyclical', 'deposit', 'retainer'));

-- Add comment explaining the payment types
COMMENT ON COLUMN payment_plans.payment_type IS 
'Type of payment plan:
- individual: One-time payment
- monthly: Recurring monthly payment
- interval: Recurring payment at custom intervals
- cyclical: Custom payment schedule with varying amounts
- deposit: Initial deposit payment
- retainer: Retainer payment';

-- Verify the migration
DO $$
DECLARE
  invalid_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO invalid_count
  FROM payment_plans
  WHERE payment_type IS NOT NULL 
    AND payment_type NOT IN ('individual', 'monthly', 'interval', 'cyclical', 'deposit', 'retainer');
  
  IF invalid_count > 0 THEN
    RAISE EXCEPTION 'Migration failed: % rows have invalid payment_type values', invalid_count;
  END IF;
  
  RAISE NOTICE 'Migration successful: All payment_type values are valid';
END $$;
