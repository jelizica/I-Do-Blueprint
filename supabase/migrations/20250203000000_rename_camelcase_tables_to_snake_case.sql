-- Migration: Rename Legacy camelCase Tables to snake_case
-- Issue: JES-68
-- BREAKING CHANGE: Requires application code updates
-- Strategy: Rename tables and create compatibility views for zero-downtime migration

BEGIN;

-- ============================================================================
-- PART 1: Rename Tables
-- ============================================================================

-- 1. vendorInformation → vendor_information
ALTER TABLE "vendorInformation" RENAME TO vendor_information;

-- 2. paymentPlans → payment_plans
ALTER TABLE "paymentPlans" RENAME TO payment_plans;

-- 3. myEstimatedBudget → my_estimated_budget
ALTER TABLE "myEstimatedBudget" RENAME TO my_estimated_budget;

-- 4. taxInfo → tax_info
ALTER TABLE "taxInfo" RENAME TO tax_info;

-- 5. vendorTypes → vendor_types
ALTER TABLE "vendorTypes" RENAME TO vendor_types;

-- ============================================================================
-- PART 2: Create Compatibility Views (Temporary)
-- ============================================================================

-- These views allow old code to continue working during transition
-- Remove these views after all application code is updated

CREATE VIEW "vendorInformation" AS SELECT * FROM vendor_information;
CREATE VIEW "paymentPlans" AS SELECT * FROM payment_plans;
CREATE VIEW "myEstimatedBudget" AS SELECT * FROM my_estimated_budget;
CREATE VIEW "taxInfo" AS SELECT * FROM tax_info;
CREATE VIEW "vendorTypes" AS SELECT * FROM vendor_types;

COMMENT ON VIEW "vendorInformation" IS 
'DEPRECATED: Compatibility view for legacy code. Use vendor_information table directly.
This view will be removed in a future version.';

COMMENT ON VIEW "paymentPlans" IS 
'DEPRECATED: Compatibility view for legacy code. Use payment_plans table directly.
This view will be removed in a future version.';

COMMENT ON VIEW "myEstimatedBudget" IS 
'DEPRECATED: Compatibility view for legacy code. Use my_estimated_budget table directly.
This view will be removed in a future version.';

COMMENT ON VIEW "taxInfo" IS 
'DEPRECATED: Compatibility view for legacy code. Use tax_info table directly.
This view will be removed in a future version.';

COMMENT ON VIEW "vendorTypes" IS 
'DEPRECATED: Compatibility view for legacy code. Use vendor_types table directly.
This view will be removed in a future version.';

-- ============================================================================
-- PART 3: Update Table Comments
-- ============================================================================

COMMENT ON TABLE vendor_information IS 
'Vendor contact and booking information.
Multi-tenant: Scoped by couple_id.';

COMMENT ON TABLE payment_plans IS 
'Payment schedules and plans for vendors and expenses.
Multi-tenant: Scoped by couple_id.';

COMMENT ON TABLE my_estimated_budget IS 
'User budget estimates without vendor quotes.
Multi-tenant: Scoped by couple_id (to be added).';

COMMENT ON TABLE tax_info IS 
'Tax rate information by region.
System-wide: No tenant scoping (shared reference data).';

COMMENT ON TABLE vendor_types IS 
'Vendor type categories and classifications.
System-wide: No tenant scoping (shared reference data).';

COMMIT;
