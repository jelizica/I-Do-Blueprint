-- Backfill missing payment plan metadata
-- This migration adds payment_order, total_payment_count, and payment_plan_type
-- to payment plans that are missing this information

-- Step 1: Add payment_order based on payment_date for plans missing it
WITH numbered_payments AS (
  SELECT 
    id,
    expense_id,
    ROW_NUMBER() OVER (PARTITION BY expense_id ORDER BY payment_date, created_at) as calculated_order,
    COUNT(*) OVER (PARTITION BY expense_id) as calculated_total
  FROM payment_plans
  WHERE payment_order IS NULL
    AND expense_id IN (
      SELECT expense_id 
      FROM payment_plans 
      GROUP BY expense_id 
      HAVING COUNT(*) > 1
    )
)
UPDATE payment_plans pp
SET 
  payment_order = np.calculated_order,
  total_payment_count = np.calculated_total
FROM numbered_payments np
WHERE pp.id = np.id;

-- Step 2: Infer payment_plan_type based on payment_type
UPDATE payment_plans
SET payment_plan_type = CASE
  WHEN payment_type = 'monthly' THEN 'simple-recurring'
  WHEN payment_type = 'interval' THEN 'interval-recurring'
  WHEN payment_type = 'cyclical' THEN 'cyclical-recurring'
  WHEN payment_type = 'individual' AND total_payment_count > 1 THEN 'installment'
  WHEN payment_type = 'retainer' THEN 'retainer-based'
  WHEN payment_type = 'deposit' THEN 'deposit-based'
  ELSE 'one-time'
END
WHERE payment_plan_type IS NULL;

-- Step 3: Verify the backfill
DO $$
DECLARE
  plans_with_metadata INTEGER;
  plans_without_metadata INTEGER;
  multi_payment_plans INTEGER;
BEGIN
  -- Count multi-payment plans with complete metadata
  SELECT COUNT(DISTINCT expense_id) INTO plans_with_metadata
  FROM payment_plans
  WHERE payment_order IS NOT NULL 
    AND total_payment_count IS NOT NULL
    AND payment_plan_type IS NOT NULL
    AND expense_id IN (
      SELECT expense_id 
      FROM payment_plans 
      GROUP BY expense_id 
      HAVING COUNT(*) > 1
    );
  
  -- Count multi-payment plans still missing metadata
  SELECT COUNT(DISTINCT expense_id) INTO plans_without_metadata
  FROM payment_plans
  WHERE (payment_order IS NULL OR total_payment_count IS NULL OR payment_plan_type IS NULL)
    AND expense_id IN (
      SELECT expense_id 
      FROM payment_plans 
      GROUP BY expense_id 
      HAVING COUNT(*) > 1
    );
  
  -- Total multi-payment plans
  SELECT COUNT(DISTINCT expense_id) INTO multi_payment_plans
  FROM payment_plans
  GROUP BY expense_id
  HAVING COUNT(*) > 1;
  
  RAISE NOTICE 'Backfill Results:';
  RAISE NOTICE '  Multi-payment plans: %', multi_payment_plans;
  RAISE NOTICE '  Plans with complete metadata: %', plans_with_metadata;
  RAISE NOTICE '  Plans still missing metadata: %', plans_without_metadata;
  
  IF plans_without_metadata > 0 THEN
    RAISE WARNING 'Some plans still missing metadata - may need manual review';
  ELSE
    RAISE NOTICE '✅ All multi-payment plans now have complete metadata';
  END IF;
END $$;

-- Add helpful comment
COMMENT ON COLUMN payment_plans.payment_plan_type IS 
'Type of payment plan structure:
- simple-recurring: Regular recurring payments (monthly)
- interval-recurring: Custom interval payments (quarterly, semi-annual, etc.)
- cyclical-recurring: Varying amounts on recurring schedule
- installment: Multiple individual payments for a single expense
- retainer-based: Retainer payment structure
- deposit-based: Deposit payment structure
- one-time: Single payment (no plan)';
