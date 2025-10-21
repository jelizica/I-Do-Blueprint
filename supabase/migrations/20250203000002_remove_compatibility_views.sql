-- Migration: Remove Compatibility Views for Renamed Tables
-- Issue: JES-68
-- All application code has been updated to use snake_case table names
-- These compatibility views are no longer needed

BEGIN;

-- ============================================================================
-- Remove Compatibility Views
-- ============================================================================

-- Drop the deprecated compatibility views
DROP VIEW IF EXISTS "vendorInformation" CASCADE;
DROP VIEW IF EXISTS "paymentPlans" CASCADE;
DROP VIEW IF EXISTS "myEstimatedBudget" CASCADE;
DROP VIEW IF EXISTS "taxInfo" CASCADE;
DROP VIEW IF EXISTS "vendorTypes" CASCADE;

-- Log the cleanup
COMMENT ON TABLE vendor_information IS 
'Vendor contact and booking information.
Multi-tenant: Scoped by couple_id.
Note: Renamed from vendorInformation in migration 20250203000000.';

COMMENT ON TABLE payment_plans IS 
'Payment schedules and plans for vendors and expenses.
Multi-tenant: Scoped by couple_id.
Note: Renamed from paymentPlans in migration 20250203000000.';

COMMENT ON TABLE my_estimated_budget IS 
'User budget estimates without vendor quotes.
Multi-tenant: Scoped by couple_id (to be added).
Note: Renamed from myEstimatedBudget in migration 20250203000000.';

COMMENT ON TABLE tax_info IS 
'Tax rate information by region.
System-wide: No tenant scoping (shared reference data).
Note: Renamed from taxInfo in migration 20250203000000.';

COMMENT ON TABLE vendor_types IS 
'Vendor type categories and classifications.
System-wide: No tenant scoping (shared reference data).
Note: Renamed from vendorTypes in migration 20250203000000.';

COMMIT;
