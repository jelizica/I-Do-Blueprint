-- Migration: Harden Remaining Functions - Phase 2
-- Issue: JES-74
-- Description: Complete hardening of all remaining 47 functions
-- Date: 2025-02-02
-- Phase: 2 of 2 - Complete remaining test, validation, calculation, and utility functions

-- ============================================================================
-- IMPORTANT: This migration uses a dynamic approach to harden all remaining
-- functions by recreating them with SET search_path = '' and qualifying
-- all schema references with pg_catalog. or public. as appropriate.
-- ============================================================================

-- First, let's create a helper function to add search_path to functions
CREATE OR REPLACE FUNCTION pg_temp.harden_function(
    p_schema text,
    p_function_name text,
    p_identity_args text
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_function_def text;
    v_new_function_def text;
    v_signature text;
BEGIN
    -- Build function signature
    v_signature := p_schema || '.' || p_function_name || '(' || p_identity_args || ')';
    
    -- Get current function definition
    SELECT pg_get_functiondef(p.oid) INTO v_function_def
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = p_schema 
        AND p.proname = p_function_name
        AND pg_get_function_identity_arguments(p.oid) = p_identity_args;
    
    IF v_function_def IS NULL THEN
        RAISE NOTICE 'Function not found: %', v_signature;
        RETURN;
    END IF;
    
    -- Check if already hardened
    IF v_function_def LIKE '%SET search_path%' THEN
        RAISE NOTICE 'Function already hardened: %', v_signature;
        RETURN;
    END IF;
    
    -- Add SET search_path = '' after LANGUAGE clause
    v_new_function_def := regexp_replace(
        v_function_def,
        '(LANGUAGE\s+\w+)',
        E'\\1\n SET search_path = ''''',
        'gi'
    );
    
    -- If SECURITY DEFINER is present, add after it instead
    IF v_function_def ~* 'SECURITY DEFINER' THEN
        v_new_function_def := regexp_replace(
            v_function_def,
            '(SECURITY DEFINER)',
            E'\\1\n SET search_path = ''''',
            'gi'
        );
    END IF;
    
    -- Qualify common unqualified references
    -- Replace common table/function references with schema-qualified versions
    v_new_function_def := regexp_replace(v_new_function_def, '\bstring_to_array\(', 'pg_catalog.string_to_array(', 'g');
    v_new_function_def := regexp_replace(v_new_function_def, '\barray_length\(', 'pg_catalog.array_length(', 'g');
    v_new_function_def := regexp_replace(v_new_function_def, '\breplace\(', 'pg_catalog.replace(', 'g');
    v_new_function_def := regexp_replace(v_new_function_def, '\blower\(', 'pg_catalog.lower(', 'g');
    v_new_function_def := regexp_replace(v_new_function_def, '\bupper\(', 'pg_catalog.upper(', 'g');
    v_new_function_def := regexp_replace(v_new_function_def, '\bsubstring\(', 'pg_catalog.substring(', 'g');
    v_new_function_def := regexp_replace(v_new_function_def, '\bformat\(', 'pg_catalog.format(', 'g');
    v_new_function_def := regexp_replace(v_new_function_def, '\bstring_agg\(', 'pg_catalog.string_agg(', 'g');
    v_new_function_def := regexp_replace(v_new_function_def, '\bset_config\(', 'pg_catalog.set_config(', 'g');
    v_new_function_def := regexp_replace(v_new_function_def, '\bcurrent_setting\(', 'pg_catalog.current_setting(', 'g');
    v_new_function_def := regexp_replace(v_new_function_def, '\bcurrent_date\b', 'pg_catalog.current_date', 'g');
    v_new_function_def := regexp_replace(v_new_function_def, '\bNOW\(\)', 'pg_catalog.now()', 'gi');
    v_new_function_def := regexp_replace(v_new_function_def, '\bclock_timestamp\(\)', 'pg_catalog.clock_timestamp()', 'g');
    
    -- Execute the modified function definition
    BEGIN
        EXECUTE v_new_function_def;
        RAISE NOTICE 'Successfully hardened: %', v_signature;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE WARNING 'Failed to harden %: % - %', v_signature, SQLSTATE, SQLERRM;
    END;
END;
$$;

-- ============================================================================
-- PHASE 2: Harden all remaining functions
-- ============================================================================

DO $$
DECLARE
    func_record RECORD;
    hardened_count INTEGER := 0;
    failed_count INTEGER := 0;
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Starting Phase 2: Hardening remaining functions';
    RAISE NOTICE '========================================';
    
    -- Loop through all unhardened functions
    FOR func_record IN
        SELECT 
            n.nspname as schema_name,
            p.proname as function_name,
            pg_get_function_identity_arguments(p.oid) as identity_args
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
            AND p.prokind = 'f'
            AND (
                p.proconfig IS NULL 
                OR NOT EXISTS (
                    SELECT 1 FROM unnest(p.proconfig) AS config 
                    WHERE config LIKE 'search_path=%'
                )
            )
        ORDER BY p.proname
    LOOP
        BEGIN
            PERFORM pg_temp.harden_function(
                func_record.schema_name,
                func_record.function_name,
                func_record.identity_args
            );
            hardened_count := hardened_count + 1;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Error hardening %.%: %', 
                    func_record.schema_name, func_record.function_name, SQLERRM;
                failed_count := failed_count + 1;
        END;
    END LOOP;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Phase 2 Complete';
    RAISE NOTICE 'Successfully hardened: % functions', hardened_count;
    RAISE NOTICE 'Failed: % functions', failed_count;
    RAISE NOTICE '========================================';
END $$;

-- Drop the temporary helper function
DROP FUNCTION IF EXISTS pg_temp.harden_function(text, text, text);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    unhardened_count INTEGER;
    total_functions INTEGER;
    hardened_count INTEGER;
    unhardened_list TEXT;
BEGIN
    -- Count total functions
    SELECT COUNT(*) INTO total_functions
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
        AND p.prokind = 'f';
    
    -- Count unhardened functions
    SELECT COUNT(*) INTO unhardened_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
        AND p.prokind = 'f'
        AND (
            p.proconfig IS NULL 
            OR NOT EXISTS (
                SELECT 1 FROM unnest(p.proconfig) AS config 
                WHERE config LIKE 'search_path=%'
            )
        );
    
    hardened_count := total_functions - unhardened_count;
    
    -- Get list of unhardened functions
    SELECT string_agg(p.proname, ', ' ORDER BY p.proname) INTO unhardened_list
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
        AND p.prokind = 'f'
        AND (
            p.proconfig IS NULL 
            OR NOT EXISTS (
                SELECT 1 FROM unnest(p.proconfig) AS config 
                WHERE config LIKE 'search_path=%'
            )
        );
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'JES-74 Phase 2 Verification';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total public functions: %', total_functions;
    RAISE NOTICE 'Hardened functions: % (%.1f%%)', hardened_count, (hardened_count::float / total_functions * 100);
    RAISE NOTICE 'Remaining unhardened: %', unhardened_count;
    
    IF unhardened_count > 0 THEN
        RAISE NOTICE 'Unhardened functions: %', unhardened_list;
        RAISE WARNING 'Phase 2 incomplete: % functions still need manual hardening', unhardened_count;
    ELSE
        RAISE NOTICE '========================================';
        RAISE NOTICE '✓✓✓ SUCCESS! All functions hardened! ✓✓✓';
        RAISE NOTICE '========================================';
    END IF;
END $$;
