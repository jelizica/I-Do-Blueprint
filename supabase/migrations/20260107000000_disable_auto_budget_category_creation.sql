-- Migration: Disable Auto-Creation of Budget Categories from Vendor Types
-- Issue: I Do Blueprint-cjdm
-- Date: 2026-01-07
--
-- This migration disables the automatic creation of budget categories when vendors
-- are inserted or updated. Categories should only be created:
-- 1. During onboarding (default categories)
-- 2. Manually by users through the UI
--
-- WHAT THIS FIXES:
-- - Removes the trigger that auto-creates budget categories with "Auto-created category for X vendors" description
-- - Prevents unwanted category proliferation when vendors are added
-- - Maintains data integrity by keeping the function available for potential future use
--
-- IMPACT:
-- - Existing auto-created categories will remain in the database (can be manually deleted if desired)
-- - New vendors will NOT automatically create budget categories
-- - Users must manually create categories or assign vendors to existing categories

-- =============================================================================
-- DROP THE AUTO-CREATION TRIGGER
-- =============================================================================

-- Drop trigger from vendor_information table (current naming convention)
DROP TRIGGER IF EXISTS sync_budget_categories_trigger ON public.vendor_information;

-- Drop trigger from legacy table name if it exists
DO $$
BEGIN
    DROP TRIGGER IF EXISTS sync_budget_categories_trigger ON public."vendorInformation";
EXCEPTION
    WHEN undefined_table THEN
        -- Table doesn't exist, skip
        NULL;
END $$;

-- =============================================================================
-- KEEP THE FUNCTION (for potential future manual use)
-- =============================================================================

-- Note: We're keeping the sync_budget_categories_with_vendor_types() function
-- in case it's needed for manual category synchronization in the future.
-- The function is harmless without the trigger - it will never execute automatically.

-- =============================================================================
-- VERIFICATION
-- =============================================================================

-- Verify trigger is dropped
DO $
DECLARE
    v_trigger_count INTEGER;
BEGIN
    -- Check only the current table (vendor_information)
    SELECT COUNT(*) INTO v_trigger_count
    FROM pg_trigger
    WHERE tgname = 'sync_budget_categories_trigger'
      AND tgrelid = 'public.vendor_information'::regclass;
    
    IF v_trigger_count > 0 THEN
        RAISE EXCEPTION 'VERIFICATION FAILED: Trigger still exists';
    ELSE
        RAISE NOTICE '✅ VERIFICATION PASSED: Auto-creation trigger successfully removed';
    END IF;
END $;

-- =============================================================================
-- CLEANUP QUERY (OPTIONAL - RUN MANUALLY IF DESIRED)
-- =============================================================================

-- To remove existing auto-created categories, run this query manually:
-- 
-- DELETE FROM public.budget_categories
-- WHERE description LIKE 'Auto-created category for % vendors';
--
-- WARNING: This will delete all auto-created categories. Make sure to:
-- 1. Backup your data first
-- 2. Reassign any vendors/expenses that reference these categories
-- 3. Verify no important data is lost

-- =============================================================================
-- NOTES
-- =============================================================================

-- WHAT THIS MIGRATION DOES:
-- - Drops the trigger that automatically creates budget categories
-- - Keeps the function for potential future use
-- - Verifies the trigger is removed
--
-- WHAT THIS MIGRATION DOES NOT DO:
-- - Does not delete existing auto-created categories (manual cleanup required)
-- - Does not modify the function itself
-- - Does not affect manual category creation
--
-- TESTING:
-- After applying this migration:
-- 1. Insert a new vendor with a vendor_type
-- 2. Verify NO budget category is auto-created
-- 3. Verify existing categories remain unchanged
-- 4. Verify manual category creation still works
--
-- ROLLBACK:
-- To re-enable auto-creation (not recommended), run:
-- CREATE TRIGGER sync_budget_categories_trigger
--     AFTER INSERT OR UPDATE OF vendor_type
--     ON public.vendor_information
--     FOR EACH ROW
--     EXECUTE FUNCTION public.sync_budget_categories_with_vendor_types();
