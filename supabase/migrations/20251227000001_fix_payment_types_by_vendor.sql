-- Fix payment types based on actual vendor payment structures
-- This migration corrects payment_type values to match the actual business logic

-- Update payment types based on vendor names
UPDATE payment_plans 
SET payment_type = 'monthly'
WHERE vendor ILIKE '%Menashe%' OR vendor ILIKE '%Sons%';

UPDATE payment_plans 
SET payment_type = 'interval'
WHERE vendor ILIKE '%Marissa%' OR vendor ILIKE '%Solini%' OR vendor ILIKE '%Photography%';

UPDATE payment_plans 
SET payment_type = 'cyclical'
WHERE vendor ILIKE '%Truly%' OR vendor ILIKE '%Trusted%' OR vendor ILIKE '%Events%';

UPDATE payment_plans 
SET payment_type = 'individual'
WHERE vendor ILIKE '%Saltwater%' OR vendor ILIKE '%Farm%';

-- Pinewood Baking: Set retainer for deposits, individual for regular payments
UPDATE payment_plans 
SET payment_type = 'retainer'
WHERE (vendor ILIKE '%Pinewood%' OR vendor ILIKE '%Baking%')
  AND is_deposit = true;

UPDATE payment_plans 
SET payment_type = 'individual'
WHERE (vendor ILIKE '%Pinewood%' OR vendor ILIKE '%Baking%')
  AND is_deposit = false;

UPDATE payment_plans 
SET payment_type = 'interval'
WHERE vendor ILIKE '%Timberline%' OR vendor ILIKE '%Tide%';

-- Set all other payment plans to individual (if not already set by above rules)
UPDATE payment_plans 
SET payment_type = 'individual'
WHERE payment_type IS NULL
   OR payment_type NOT IN ('monthly', 'interval', 'cyclical', 'retainer');

-- Verify the results
DO $$
DECLARE
  monthly_count INTEGER;
  interval_count INTEGER;
  cyclical_count INTEGER;
  individual_count INTEGER;
  retainer_count INTEGER;
  invalid_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO monthly_count FROM payment_plans WHERE payment_type = 'monthly';
  SELECT COUNT(*) INTO interval_count FROM payment_plans WHERE payment_type = 'interval';
  SELECT COUNT(*) INTO cyclical_count FROM payment_plans WHERE payment_type = 'cyclical';
  SELECT COUNT(*) INTO individual_count FROM payment_plans WHERE payment_type = 'individual';
  SELECT COUNT(*) INTO retainer_count FROM payment_plans WHERE payment_type = 'retainer';
  
  SELECT COUNT(*) INTO invalid_count
  FROM payment_plans
  WHERE payment_type IS NOT NULL 
    AND payment_type NOT IN ('individual', 'monthly', 'interval', 'cyclical', 'deposit', 'retainer');
  
  RAISE NOTICE 'Payment type distribution:';
  RAISE NOTICE '  Monthly: %', monthly_count;
  RAISE NOTICE '  Interval: %', interval_count;
  RAISE NOTICE '  Cyclical: %', cyclical_count;
  RAISE NOTICE '  Individual: %', individual_count;
  RAISE NOTICE '  Retainer: %', retainer_count;
  
  IF invalid_count > 0 THEN
    RAISE EXCEPTION 'Migration failed: % rows have invalid payment_type values', invalid_count;
  END IF;
  
  RAISE NOTICE 'Migration successful: All payment_type values are valid';
END $$;

-- Add helpful comment
COMMENT ON TABLE payment_plans IS 
'Payment schedules for vendors. Payment types:
- monthly: Menashe & Sons (recurring monthly)
- interval: Marissa Solini Photography, Timberline & Tide (custom intervals)
- cyclical: Truly Trusted Events (varying payment schedule)
- individual: Saltwater Farm, Pinewood Baking (non-deposit), and all others (one-time)
- retainer: Pinewood Baking deposits (retainer payments)';
