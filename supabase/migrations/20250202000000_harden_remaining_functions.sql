-- Migration: Harden Remaining Utility and Test Functions - Search Path Security
-- Issue: JES-74
-- Description: Add SET search_path = '' to remaining utility, test, calculation, 
--              validation, and trigger functions for defense-in-depth security
-- Date: 2025-02-02
-- Phase: 1 of 2 - Critical utility and trigger functions

-- ============================================================================
-- UTILITY: Simple utility functions (no complex schema references)
-- ============================================================================

DROP FUNCTION IF EXISTS public.extract_vendor_name(text) CASCADE;
CREATE OR REPLACE FUNCTION public.extract_vendor_name(storage_path text)
 RETURNS text
 LANGUAGE plpgsql
 SET search_path = ''
AS $function$
DECLARE
    path_parts TEXT[];
    vendor_folder TEXT;
BEGIN
    path_parts := pg_catalog.string_to_array(storage_path, '/');
    IF pg_catalog.array_length(path_parts, 1) >= 2 THEN
        vendor_folder := path_parts[2];
        vendor_folder := pg_catalog.replace(vendor_folder, '_', ' ');
        vendor_folder := pg_catalog.replace(vendor_folder, '__', ' & ');
        RETURN vendor_folder;
    END IF;
    RETURN NULL;
END;
$function$;

DROP FUNCTION IF EXISTS public.get_mime_type(text) CASCADE;
CREATE OR REPLACE FUNCTION public.get_mime_type(filename text)
 RETURNS text
 LANGUAGE plpgsql
 SET search_path = ''
AS $function$
BEGIN
    CASE 
        WHEN filename ILIKE '%.pdf' THEN RETURN 'application/pdf';
        WHEN filename ILIKE '%.doc' THEN RETURN 'application/msword';
        WHEN filename ILIKE '%.docx' THEN RETURN 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        WHEN filename ILIKE '%.jpg' OR filename ILIKE '%.jpeg' THEN RETURN 'image/jpeg';
        WHEN filename ILIKE '%.png' THEN RETURN 'image/png';
        WHEN filename ILIKE '%.gif' THEN RETURN 'image/gif';
        WHEN filename ILIKE '%.csv' THEN RETURN 'text/csv';
        WHEN filename ILIKE '%.txt' THEN RETURN 'text/plain';
        WHEN filename ILIKE '%.xlsx' THEN RETURN 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        WHEN filename ILIKE '%.xls' THEN RETURN 'application/vnd.ms-excel';
        ELSE RETURN 'application/octet-stream';
    END CASE;
END;
$function$;

DROP FUNCTION IF EXISTS public.get_document_type(text, text) CASCADE;
CREATE OR REPLACE FUNCTION public.get_document_type(filename text, path text)
 RETURNS text
 LANGUAGE plpgsql
 SET search_path = ''
AS $function$
BEGIN
    CASE 
        WHEN filename ILIKE '%contract%' OR filename ILIKE '%agreement%' THEN RETURN 'contract';
        WHEN filename ILIKE '%invoice%' OR filename ILIKE '%bill%' OR filename ILIKE '%receipt%' THEN RETURN 'invoice';
        WHEN filename ILIKE '%.jpg' OR filename ILIKE '%.jpeg' OR filename ILIKE '%.png' OR filename ILIKE '%.gif' THEN RETURN 'photo';
        WHEN filename ILIKE '%quote%' OR filename ILIKE '%estimate%' THEN RETURN 'quote';
        WHEN filename ILIKE '%menu%' OR filename ILIKE '%catalog%' OR filename ILIKE '%brochure%' THEN RETURN 'other';
        ELSE RETURN 'other';
    END CASE;
END;
$function$;

DROP FUNCTION IF EXISTS public.is_valid_phone(text) CASCADE;
CREATE OR REPLACE FUNCTION public.is_valid_phone(phone text)
 RETURNS boolean
 LANGUAGE plpgsql
 SET search_path = ''
AS $function$
BEGIN
    RETURN phone ~ '^\+?[0-9]{10,15}$';
END;
$function$;

DROP FUNCTION IF EXISTS public.categorize_meal_or_dietary(text) CASCADE;
CREATE OR REPLACE FUNCTION public.categorize_meal_or_dietary(input_text text)
 RETURNS text
 LANGUAGE plpgsql
 SET search_path = ''
AS $function$
BEGIN
    IF input_text ILIKE '%vegetarian%' THEN RETURN 'vegetarian';
    ELSIF input_text ILIKE '%vegan%' THEN RETURN 'vegan';
    ELSIF input_text ILIKE '%gluten%' THEN RETURN 'gluten_free';
    ELSIF input_text ILIKE '%kosher%' THEN RETURN 'kosher';
    ELSIF input_text ILIKE '%halal%' THEN RETURN 'halal';
    ELSE RETURN 'standard';
    END IF;
END;
$function$;

-- ============================================================================
-- UPDATE TRIGGERS: Simple timestamp update functions
-- ============================================================================

DROP FUNCTION IF EXISTS public.update_documents_updated_at() CASCADE;
CREATE OR REPLACE FUNCTION public.update_documents_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path = ''
AS $function$
BEGIN
    NEW.updated_at = pg_catalog.now();
    RETURN NEW;
END;
$function$;

DROP FUNCTION IF EXISTS public.update_feature_flags_updated_at() CASCADE;
CREATE OR REPLACE FUNCTION public.update_feature_flags_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path = ''
AS $function$
BEGIN
    NEW.updated_at = pg_catalog.now();
    NEW.version = OLD.version + 1;
    RETURN NEW;
END;
$function$;

DROP FUNCTION IF EXISTS public.update_monthly_cash_flow_updated_at() CASCADE;
CREATE OR REPLACE FUNCTION public.update_monthly_cash_flow_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path = ''
AS $function$
BEGIN
    NEW.updated_at = pg_catalog.now();
    RETURN NEW;
END;
$function$;

DROP FUNCTION IF EXISTS public.update_affordability_gifts_contributions_updated_at() CASCADE;
CREATE OR REPLACE FUNCTION public.update_affordability_gifts_contributions_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path = ''
AS $function$
BEGIN
    NEW.updated_at = pg_catalog.now();
    RETURN NEW;
END;
$function$;

DROP FUNCTION IF EXISTS public.increment_palette_version() CASCADE;
CREATE OR REPLACE FUNCTION public.increment_palette_version()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path = ''
AS $function$
BEGIN
    NEW.version := COALESCE(OLD.version, 0) + 1;
    NEW.updated_at := pg_catalog.now();
    RETURN NEW;
END;
$function$;

-- ============================================================================
-- CALCULATION FUNCTIONS: Simple math functions
-- ============================================================================

DROP FUNCTION IF EXISTS public.calculate_precise_remainder(numeric, numeric) CASCADE;
CREATE OR REPLACE FUNCTION public.calculate_precise_remainder(expense_amount numeric, line_items_total numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 SET search_path = ''
AS $function$
BEGIN
    RETURN expense_amount - line_items_total;
END;
$function$;

DROP FUNCTION IF EXISTS public.should_auto_calculate_starting_balance(uuid, date, numeric) CASCADE;
CREATE OR REPLACE FUNCTION public.should_auto_calculate_starting_balance(
    couple_id_param uuid, 
    month_param date, 
    current_starting_balance numeric
)
 RETURNS boolean
 LANGUAGE plpgsql
 SET search_path = ''
AS $function$
BEGIN
    RETURN current_starting_balance IS NULL OR current_starting_balance = 0;
END;
$function$;

-- ============================================================================
-- UTILITY FUNCTIONS: Configuration and debugging
-- ============================================================================

DROP FUNCTION IF EXISTS public.set_allocation_debug_logging(boolean) CASCADE;
CREATE OR REPLACE FUNCTION public.set_allocation_debug_logging(enabled boolean)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path = ''
AS $function$
BEGIN
    IF enabled THEN
        PERFORM pg_catalog.set_config('app.debug_allocation_validation', 'true', false);
    ELSE
        PERFORM pg_catalog.set_config('app.debug_allocation_validation', 'false', false);
    END IF;
END;
$function$;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    unhardened_count INTEGER;
    total_functions INTEGER;
    hardened_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_functions
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
        AND p.prokind = 'f';
    
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
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Migration JES-74 Phase 1 Complete';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total public functions: %', total_functions;
    RAISE NOTICE 'Hardened functions: % (%.1f%%)', hardened_count, (hardened_count::float / total_functions * 100);
    RAISE NOTICE 'Remaining unhardened: %', unhardened_count;
    RAISE NOTICE '========================================';
    
    IF unhardened_count > 0 THEN
        RAISE NOTICE 'Note: % functions still need hardening in Phase 2', unhardened_count;
    ELSE
        RAISE NOTICE '✓ All public functions successfully hardened!';
    END IF;
END $$;
