-- Migration: Update payment_type values from old to new format
-- This migration handles the transition from:
--   "single" -> "individual"
--   "custom" -> "interval" or "cyclical" (with disambiguation logic)
--
-- Created: 2025-01-28
-- Author: System Migration

-- Step 1: Create a temporary table to log ambiguous records
CREATE TABLE IF NOT EXISTS payment_type_migration_log (
    id BIGSERIAL PRIMARY KEY,
    payment_plan_id BIGINT NOT NULL,
    old_payment_type TEXT,
    new_payment_type TEXT,
    migration_status TEXT, -- 'migrated', 'ambiguous', 'manual_review'
    disambiguation_reason TEXT,
    migrated_at TIMESTAMPTZ DEFAULT NOW(),
    reviewed_by UUID,
    reviewed_at TIMESTAMPTZ
);

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_payment_type_migration_log_status 
ON payment_type_migration_log(migration_status);

-- Step 2: Migrate "single" -> "individual"
-- This is straightforward with no ambiguity
UPDATE payment_plans
SET payment_type = 'individual'
WHERE payment_type = 'single';

-- Log the migration
INSERT INTO payment_type_migration_log (
    payment_plan_id,
    old_payment_type,
    new_payment_type,
    migration_status,
    disambiguation_reason
)
SELECT 
    id,
    'single',
    'individual',
    'migrated',
    'Direct mapping: single -> individual'
FROM payment_plans
WHERE payment_type = 'individual' 
  AND created_at < NOW() - INTERVAL '1 minute' -- Only log if it was just migrated
ON CONFLICT DO NOTHING;

-- Step 3: Disambiguate "custom" -> "interval" or "cyclical"
-- Business rules for disambiguation:
-- 1. If total_payment_count = 1 -> "individual"
-- 2. If all payment amounts are equal -> "interval"
-- 3. If payment amounts vary -> "cyclical"
-- 4. If cannot determine -> mark for manual review

-- First, handle custom payments with only 1 payment
UPDATE payment_plans
SET payment_type = 'individual'
WHERE payment_type = 'custom'
  AND total_payment_count = 1;

-- Log these migrations
INSERT INTO payment_type_migration_log (
    payment_plan_id,
    old_payment_type,
    new_payment_type,
    migration_status,
    disambiguation_reason
)
SELECT 
    id,
    'custom',
    'individual',
    'migrated',
    'Single payment detected (total_payment_count = 1)'
FROM payment_plans
WHERE payment_type = 'individual' 
  AND total_payment_count = 1
  AND created_at < NOW() - INTERVAL '1 minute'
ON CONFLICT DO NOTHING;

-- Step 4: Analyze payment patterns for remaining "custom" records
-- Create a temporary function to analyze payment uniformity
CREATE OR REPLACE FUNCTION analyze_payment_uniformity(p_expense_id UUID, p_payment_plan_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_distinct_amounts INTEGER;
    v_payment_count INTEGER;
    v_has_deposit BOOLEAN;
BEGIN
    -- Count distinct payment amounts (excluding deposits)
    SELECT 
        COUNT(DISTINCT payment_amount),
        COUNT(*),
        BOOL_OR(is_deposit)
    INTO v_distinct_amounts, v_payment_count, v_has_deposit
    FROM payment_plans
    WHERE expense_id = p_expense_id
      AND payment_plan_id = p_payment_plan_id
      AND NOT is_deposit;
    
    -- If all non-deposit payments have the same amount -> interval
    IF v_distinct_amounts = 1 THEN
        RETURN 'interval';
    -- If payments have varying amounts -> cyclical
    ELSIF v_distinct_amounts > 1 THEN
        RETURN 'cyclical';
    -- If no payments found or cannot determine -> manual review
    ELSE
        RETURN 'manual_review';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 5: Apply disambiguation logic to remaining "custom" records
-- Update to "interval" where all amounts are equal
WITH custom_analysis AS (
    SELECT DISTINCT
        pp.id,
        pp.expense_id,
        pp.payment_plan_id,
        analyze_payment_uniformity(pp.expense_id, pp.payment_plan_id) as suggested_type
    FROM payment_plans pp
    WHERE pp.payment_type = 'custom'
)
UPDATE payment_plans pp
SET payment_type = ca.suggested_type
FROM custom_analysis ca
WHERE pp.id = ca.id
  AND ca.suggested_type IN ('interval', 'cyclical');

-- Log the disambiguated migrations
INSERT INTO payment_type_migration_log (
    payment_plan_id,
    old_payment_type,
    new_payment_type,
    migration_status,
    disambiguation_reason
)
SELECT 
    pp.id,
    'custom',
    pp.payment_type,
    'migrated',
    CASE 
        WHEN pp.payment_type = 'interval' THEN 'Uniform payment amounts detected'
        WHEN pp.payment_type = 'cyclical' THEN 'Varying payment amounts detected'
    END
FROM payment_plans pp
WHERE pp.payment_type IN ('interval', 'cyclical')
  AND pp.created_at < NOW() - INTERVAL '1 minute'
ON CONFLICT DO NOTHING;

-- Step 6: Mark remaining ambiguous records for manual review
INSERT INTO payment_type_migration_log (
    payment_plan_id,
    old_payment_type,
    new_payment_type,
    migration_status,
    disambiguation_reason
)
SELECT 
    id,
    payment_type,
    NULL,
    'manual_review',
    'Could not automatically determine correct payment type'
FROM payment_plans
WHERE payment_type = 'custom'
  OR payment_type = 'manual_review'
ON CONFLICT DO NOTHING;

-- Step 7: Create a view for operators to review ambiguous records
CREATE OR REPLACE VIEW payment_type_manual_review AS
SELECT 
    log.id as log_id,
    log.payment_plan_id,
    pp.expense_id,
    pp.vendor,
    pp.payment_amount,
    pp.payment_date,
    pp.total_payment_count,
    pp.is_deposit,
    pp.is_retainer,
    log.old_payment_type,
    log.disambiguation_reason,
    log.migrated_at,
    -- Suggest a type based on available data
    CASE 
        WHEN pp.total_payment_count = 1 THEN 'individual'
        WHEN pp.is_deposit THEN 'individual'
        ELSE 'interval'
    END as suggested_type
FROM payment_type_migration_log log
JOIN payment_plans pp ON pp.id = log.payment_plan_id
WHERE log.migration_status = 'manual_review'
  AND log.reviewed_at IS NULL
ORDER BY log.migrated_at DESC;

-- Step 8: Create a function to manually resolve ambiguous records
CREATE OR REPLACE FUNCTION resolve_payment_type_migration(
    p_log_id BIGINT,
    p_new_payment_type TEXT,
    p_reviewed_by UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_payment_plan_id BIGINT;
BEGIN
    -- Validate the new payment type
    IF p_new_payment_type NOT IN ('individual', 'monthly', 'interval', 'cyclical', 'deposit', 'retainer') THEN
        RAISE EXCEPTION 'Invalid payment type: %', p_new_payment_type;
    END IF;
    
    -- Get the payment plan ID
    SELECT payment_plan_id INTO v_payment_plan_id
    FROM payment_type_migration_log
    WHERE id = p_log_id;
    
    IF v_payment_plan_id IS NULL THEN
        RAISE EXCEPTION 'Migration log entry not found: %', p_log_id;
    END IF;
    
    -- Update the payment plan
    UPDATE payment_plans
    SET payment_type = p_new_payment_type
    WHERE id = v_payment_plan_id;
    
    -- Update the migration log
    UPDATE payment_type_migration_log
    SET 
        new_payment_type = p_new_payment_type,
        migration_status = 'migrated',
        reviewed_by = p_reviewed_by,
        reviewed_at = NOW()
    WHERE id = p_log_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 9: Add comments for documentation
COMMENT ON TABLE payment_type_migration_log IS 
'Tracks the migration of payment_type values from old format (single, custom) to new format (individual, interval, cyclical)';

COMMENT ON FUNCTION resolve_payment_type_migration IS 
'Manually resolves ambiguous payment type migrations. Usage: SELECT resolve_payment_type_migration(log_id, ''interval'', user_id);';

COMMENT ON VIEW payment_type_manual_review IS 
'Shows payment records that require manual review for payment type migration';

-- Step 10: Clean up the temporary function
DROP FUNCTION IF EXISTS analyze_payment_uniformity(UUID, UUID);

-- Step 11: Generate migration summary report
DO $$
DECLARE
    v_total_migrated INTEGER;
    v_manual_review INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_total_migrated
    FROM payment_type_migration_log
    WHERE migration_status = 'migrated';
    
    SELECT COUNT(*) INTO v_manual_review
    FROM payment_type_migration_log
    WHERE migration_status = 'manual_review';
    
    RAISE NOTICE 'Payment Type Migration Summary:';
    RAISE NOTICE '  - Total records migrated: %', v_total_migrated;
    RAISE NOTICE '  - Records requiring manual review: %', v_manual_review;
    
    IF v_manual_review > 0 THEN
        RAISE NOTICE 'Run: SELECT * FROM payment_type_manual_review; to see records needing review';
    END IF;
END $$;
