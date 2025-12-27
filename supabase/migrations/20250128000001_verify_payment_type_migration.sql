-- Verification script for payment_type migration
-- Run this after the main migration to verify success
-- Created: 2025-01-28

-- Step 1: Check for any remaining legacy values
DO $$
DECLARE
    v_legacy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_legacy_count
    FROM payment_plans
    WHERE payment_type IN ('single', 'custom');
    
    IF v_legacy_count > 0 THEN
        RAISE WARNING 'Found % records with legacy payment_type values', v_legacy_count;
        RAISE NOTICE 'Run: SELECT * FROM payment_type_manual_review; to review these records';
    ELSE
        RAISE NOTICE '✓ No legacy payment_type values found';
    END IF;
END $$;

-- Step 2: Verify all payment_type values are valid
DO $$
DECLARE
    v_invalid_count INTEGER;
    v_invalid_types TEXT;
BEGIN
    SELECT 
        COUNT(*),
        STRING_AGG(DISTINCT payment_type, ', ')
    INTO v_invalid_count, v_invalid_types
    FROM payment_plans
    WHERE payment_type IS NOT NULL
      AND payment_type NOT IN ('individual', 'monthly', 'interval', 'cyclical', 'deposit', 'retainer');
    
    IF v_invalid_count > 0 THEN
        RAISE WARNING 'Found % records with invalid payment_type values: %', v_invalid_count, v_invalid_types;
    ELSE
        RAISE NOTICE '✓ All payment_type values are valid';
    END IF;
END $$;

-- Step 3: Show distribution of payment types
DO $$
DECLARE
    v_record RECORD;
BEGIN
    RAISE NOTICE 'Payment Type Distribution:';
    FOR v_record IN 
        SELECT 
            COALESCE(payment_type, 'NULL') as type,
            COUNT(*) as count,
            ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
        FROM payment_plans
        GROUP BY payment_type
        ORDER BY count DESC
    LOOP
        RAISE NOTICE '  % %: % records (%%)', 
            CASE 
                WHEN v_record.type = 'individual' THEN '✓'
                WHEN v_record.type = 'monthly' THEN '✓'
                WHEN v_record.type = 'interval' THEN '✓'
                WHEN v_record.type = 'cyclical' THEN '✓'
                WHEN v_record.type IN ('single', 'custom') THEN '⚠'
                ELSE '?'
            END,
            v_record.type,
            v_record.count,
            v_record.percentage;
    END LOOP;
END $$;

-- Step 4: Check migration log status
DO $$
DECLARE
    v_migrated INTEGER;
    v_manual_review INTEGER;
    v_total INTEGER;
BEGIN
    SELECT 
        COUNT(*) FILTER (WHERE migration_status = 'migrated'),
        COUNT(*) FILTER (WHERE migration_status = 'manual_review'),
        COUNT(*)
    INTO v_migrated, v_manual_review, v_total
    FROM payment_type_migration_log;
    
    IF v_total > 0 THEN
        RAISE NOTICE 'Migration Log Summary:';
        RAISE NOTICE '  Total records: %', v_total;
        RAISE NOTICE '  ✓ Migrated: %', v_migrated;
        IF v_manual_review > 0 THEN
            RAISE NOTICE '  ⚠ Requiring manual review: %', v_manual_review;
        END IF;
    ELSE
        RAISE NOTICE 'No migration log entries found (no legacy values were present)';
    END IF;
END $$;

-- Step 5: Verify check constraint is working
DO $$
DECLARE
    v_constraint_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class cl ON cl.oid = c.conrelid
        WHERE cl.relname = 'payment_plans'
          AND c.conname = 'check_payment_type'
    ) INTO v_constraint_exists;
    
    IF v_constraint_exists THEN
        RAISE NOTICE '✓ Check constraint exists and is active';
    ELSE
        RAISE WARNING 'Check constraint not found - database may accept invalid values';
    END IF;
END $$;

-- Step 6: Test that invalid values are rejected
DO $$
BEGIN
    -- Try to insert an invalid payment_type (should fail)
    BEGIN
        INSERT INTO payment_plans (
            couple_id,
            vendor,
            payment_date,
            payment_amount,
            paid,
            payment_type,
            created_at
        ) VALUES (
            '00000000-0000-0000-0000-000000000000',
            'Test Vendor',
            NOW(),
            100.00,
            false,
            'invalid_type',
            NOW()
        );
        
        -- If we get here, the constraint is not working
        RAISE WARNING 'Check constraint is not working - invalid value was accepted';
        
        -- Clean up the test record
        DELETE FROM payment_plans 
        WHERE vendor = 'Test Vendor' 
          AND payment_type = 'invalid_type';
        
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '✓ Check constraint is working - invalid values are rejected';
    END;
END $$;

-- Step 7: Create a summary report
CREATE OR REPLACE VIEW payment_type_migration_summary AS
SELECT 
    'Total Payment Plans' as metric,
    COUNT(*)::TEXT as value
FROM payment_plans

UNION ALL

SELECT 
    'Legacy Values Remaining' as metric,
    COUNT(*)::TEXT as value
FROM payment_plans
WHERE payment_type IN ('single', 'custom')

UNION ALL

SELECT 
    'Invalid Values' as metric,
    COUNT(*)::TEXT as value
FROM payment_plans
WHERE payment_type IS NOT NULL
  AND payment_type NOT IN ('individual', 'monthly', 'interval', 'cyclical', 'deposit', 'retainer')

UNION ALL

SELECT 
    'Records Migrated' as metric,
    COUNT(*)::TEXT as value
FROM payment_type_migration_log
WHERE migration_status = 'migrated'

UNION ALL

SELECT 
    'Records Needing Review' as metric,
    COUNT(*)::TEXT as value
FROM payment_type_migration_log
WHERE migration_status = 'manual_review'
  AND reviewed_at IS NULL;

-- Display the summary
SELECT * FROM payment_type_migration_summary;

-- Final message
DO $$
DECLARE
    v_legacy_count INTEGER;
    v_manual_review_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_legacy_count
    FROM payment_plans
    WHERE payment_type IN ('single', 'custom');
    
    SELECT COUNT(*) INTO v_manual_review_count
    FROM payment_type_migration_log
    WHERE migration_status = 'manual_review'
      AND reviewed_at IS NULL;
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Payment Type Migration Verification Complete';
    RAISE NOTICE '========================================';
    
    IF v_legacy_count = 0 AND v_manual_review_count = 0 THEN
        RAISE NOTICE '✓ Migration successful - no issues found';
    ELSIF v_legacy_count > 0 THEN
        RAISE NOTICE '⚠ Action required: % legacy values need migration', v_legacy_count;
    ELSIF v_manual_review_count > 0 THEN
        RAISE NOTICE '⚠ Action required: % records need manual review', v_manual_review_count;
        RAISE NOTICE 'Query: SELECT * FROM payment_type_manual_review;';
    END IF;
    
    RAISE NOTICE '';
END $$;
