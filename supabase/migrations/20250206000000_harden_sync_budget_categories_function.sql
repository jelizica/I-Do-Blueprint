-- Migration: Harden sync_budget_categories_with_vendor_types() Against search_path Attacks
-- Issue: JES-98
-- Date: 2025-02-06
--
-- This migration fixes a HIGH severity security vulnerability where the SECURITY DEFINER
-- function sync_budget_categories_with_vendor_types() had a mutable search_path, creating
-- a privilege escalation risk.
--
-- SECURITY IMPACT:
-- - Without SET search_path, attackers could manipulate which schema objects the function uses
-- - Since the function runs as SECURITY DEFINER (elevated privileges), this creates privilege escalation
-- - Adding SET search_path = public, pg_temp locks down the function to only use trusted schemas
--
-- REFERENCES:
-- - PostgreSQL SECURITY DEFINER: https://www.postgresql.org/docs/current/sql-createfunction.html
-- - search_path Security: https://www.postgresql.org/docs/current/ddl-schemas.html#DDL-SCHEMAS-PATH

-- =============================================================================
-- DROP EXISTING VULNERABLE FUNCTION
-- =============================================================================

DROP FUNCTION IF EXISTS public.sync_budget_categories_with_vendor_types() CASCADE;

-- =============================================================================
-- CREATE HARDENED FUNCTION WITH search_path PROTECTION
-- =============================================================================

CREATE OR REPLACE FUNCTION public.sync_budget_categories_with_vendor_types()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp  -- ✅ CRITICAL: Prevents search_path attacks
AS $$
DECLARE
    category_exists BOOLEAN;
BEGIN
    -- Only proceed if vendor_type is not null
    IF NEW.vendor_type IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Check if a budget category exists for this vendor_type
    -- Explicitly qualify table names for extra security (defense in depth)
    SELECT EXISTS(
        SELECT 1 FROM public.budget_categories 
        WHERE category_name = NEW.vendor_type
        AND couple_id = NEW.couple_id
    ) INTO category_exists;
    
    -- If category doesn't exist, create it with default values
    IF NOT category_exists THEN
        INSERT INTO public.budget_categories (
            category_name,
            couple_id,
            allocated_amount,
            spent_amount,
            typical_percentage,
            is_essential,
            description
        ) VALUES (
            NEW.vendor_type,
            NEW.couple_id,
            1000.00, -- Default allocation
            0.00,
            3.0, -- Default percentage
            false, -- Default to non-essential
            'Auto-created category for ' || NEW.vendor_type || ' vendors'
        );
        
        RAISE NOTICE 'Created new budget category: % for couple: %', NEW.vendor_type, NEW.couple_id;
    END IF;
    
    RETURN NEW;
END;
$$;

-- =============================================================================
-- RESTORE TRIGGER (if it was dropped by CASCADE)
-- =============================================================================

-- Check if trigger exists on vendor_information table and recreate if needed
DO $
BEGIN
    -- Try snake_case table name first (current naming convention)
    BEGIN
        DROP TRIGGER IF EXISTS sync_budget_categories_trigger ON public.vendor_information;
        
        CREATE TRIGGER sync_budget_categories_trigger
            AFTER INSERT OR UPDATE OF vendor_type
            ON public.vendor_information
            FOR EACH ROW
            EXECUTE FUNCTION public.sync_budget_categories_with_vendor_types();
            
        RAISE NOTICE 'Recreated trigger: sync_budget_categories_trigger on vendor_information';
    EXCEPTION
        WHEN undefined_table THEN
            -- Try camelCase table name (legacy naming)
            BEGIN
                DROP TRIGGER IF EXISTS sync_budget_categories_trigger ON public."vendorInformation";
                
                CREATE TRIGGER sync_budget_categories_trigger
                    AFTER INSERT OR UPDATE OF vendor_type
                    ON public."vendorInformation"
                    FOR EACH ROW
                    EXECUTE FUNCTION public.sync_budget_categories_with_vendor_types();
                    
                RAISE NOTICE 'Recreated trigger: sync_budget_categories_trigger on vendorInformation (legacy)';
            EXCEPTION
                WHEN undefined_table THEN
                    RAISE NOTICE 'Neither vendor_information nor vendorInformation table exists, skipping trigger creation';
            END;
    END;
END $;

-- =============================================================================
-- GRANT PERMISSIONS
-- =============================================================================

-- Note: SECURITY DEFINER functions don't need EXECUTE permissions for the trigger
-- The trigger will execute with the function owner's privileges automatically
-- However, we grant for consistency with other functions

GRANT EXECUTE ON FUNCTION public.sync_budget_categories_with_vendor_types() TO authenticated;

-- =============================================================================
-- VERIFICATION
-- =============================================================================

-- Verify search_path is set correctly
DO $$
DECLARE
    v_search_path TEXT;
BEGIN
    SELECT unnest(proconfig)::text INTO v_search_path
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE p.proname = 'sync_budget_categories_with_vendor_types'
      AND n.nspname = 'public'
      AND unnest(proconfig)::text LIKE 'search_path=%';
    
    IF v_search_path IS NULL THEN
        RAISE EXCEPTION 'VERIFICATION FAILED: search_path not set on function';
    ELSIF v_search_path != 'search_path=public, pg_temp' THEN
        RAISE WARNING 'search_path set but may not match expected value: %', v_search_path;
    ELSE
        RAISE NOTICE '✅ VERIFICATION PASSED: search_path correctly set to: %', v_search_path;
    END IF;
END $$;

-- =============================================================================
-- SECURITY AUDIT QUERY
-- =============================================================================

-- Run this query to verify no SECURITY DEFINER functions remain vulnerable:
-- 
-- SELECT 
--   n.nspname as schema,
--   p.proname as function_name,
--   CASE 
--     WHEN EXISTS (
--       SELECT 1 FROM unnest(p.proconfig) AS config 
--       WHERE config LIKE 'search_path=%'
--     ) THEN 'PROTECTED ✅'
--     ELSE 'VULNERABLE ⚠️'
--   END as security_status
-- FROM pg_proc p
-- JOIN pg_namespace n ON p.pronamespace = n.oid
-- WHERE p.prosecdef = true
--   AND n.nspname = 'public'
-- ORDER BY 
--   CASE 
--     WHEN EXISTS (
--       SELECT 1 FROM unnest(p.proconfig) AS config 
--       WHERE config LIKE 'search_path=%'
--     ) THEN 1
--     ELSE 0
--   END,
--   p.proname;

-- =============================================================================
-- NOTES
-- =============================================================================

-- WHAT THIS FIXES:
-- - Prevents attackers from creating malicious schemas/tables that hijack function behavior
-- - Locks down the function to only use objects in 'public' and 'pg_temp' schemas
-- - Eliminates privilege escalation risk via search_path manipulation
--
-- WHY search_path = public, pg_temp:
-- - 'public' = Your application's schema with trusted objects
-- - 'pg_temp' = Session-specific temporary tables (safe, isolated per session)
-- - Excludes user-controlled schemas that could contain malicious objects
--
-- TESTING:
-- After applying this migration:
-- 1. Insert a new vendor with a vendor_type
-- 2. Verify a budget category is auto-created
-- 3. Verify the category has the correct couple_id
-- 4. Verify no errors occur
-- 5. Run the security audit query above to confirm all functions are protected
--
-- ATTACK SCENARIO PREVENTED:
-- Before fix: Attacker could do:
--   CREATE SCHEMA attacker_schema;
--   CREATE TABLE attacker_schema.budget_categories (...); -- malicious table
--   SET search_path = attacker_schema, public;
--   -- Function would use attacker's table with elevated privileges
--
-- After fix: Function always uses public.budget_categories regardless of caller's search_path
