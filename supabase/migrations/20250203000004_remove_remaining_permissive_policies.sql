-- Migration: Remove Remaining Overly Permissive RLS Policies
-- Description: Remove auth.role() = 'authenticated' policies that bypass couple_id checks
-- Issue: JES-93 - CRITICAL: Remove Overly Permissive RLS Policies Exposing Public Data (Phase 2)
-- Created: 2025-02-03

-- ============================================================================
-- PHASE 1: Remove overly permissive auth.role() policies
-- ============================================================================

-- These policies allow ANY authenticated user to access data without couple_id validation
-- The secure couple_id-based policies created in the previous migration will handle access control

-- affordability_inputs
DROP POLICY IF EXISTS "Enable delete for authenticated users only" ON affordability_inputs;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON affordability_inputs;
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON affordability_inputs;

-- affordability_results
DROP POLICY IF EXISTS "Enable delete for authenticated users only" ON affordability_results;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON affordability_results;
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON affordability_results;

-- affordability_scenarios
DROP POLICY IF EXISTS "Enable delete for authenticated users only" ON affordability_scenarios;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON affordability_scenarios;
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON affordability_scenarios;

-- budget_development_items
DROP POLICY IF EXISTS "Development items can be managed by authenticated users" ON budget_development_items;

-- budget_development_scenarios
DROP POLICY IF EXISTS "Development scenarios can be managed by authenticated users" ON budget_development_scenarios;

-- vendor_contacts
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON vendor_contacts;

-- vendor_documents
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON vendor_documents;

-- vendor_information
DROP POLICY IF EXISTS "Enable delete for authenticated users only" ON vendor_information;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON vendor_information;
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON vendor_information;

-- wedding_events
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON wedding_events;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON wedding_events;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON wedding_events;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON wedding_events;

-- wedding_tasks
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON wedding_tasks;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON wedding_tasks;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON wedding_tasks;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON wedding_tasks;

-- ============================================================================
-- PHASE 2: Remove duplicate/redundant policies that may cause conflicts
-- ============================================================================

-- affordability_gifts_contributions - has duplicate insert policy with qual: "true"
DROP POLICY IF EXISTS "gifts_contributions_insert_policy" ON affordability_gifts_contributions;

-- ============================================================================
-- PHASE 3: Verification queries (commented out - run manually to verify)
-- ============================================================================

-- Verify no auth.role() = 'authenticated' policies remain on user data tables
-- SELECT tablename, policyname, cmd, qual
-- FROM pg_policies
-- WHERE schemaname = 'public'
--   AND (
--     qual LIKE '%auth.role()%authenticated%'
--     OR with_check LIKE '%auth.role()%authenticated%'
--   )
--   AND tablename IN (
--     'affordability_gifts_contributions',
--     'affordability_inputs',
--     'affordability_results',
--     'affordability_scenarios',
--     'budget_development_items',
--     'budget_development_scenarios',
--     'documents',
--     'gifts_and_owed',
--     'vendor_contacts',
--     'vendor_documents',
--     'vendor_information',
--     'wedding_events',
--     'wedding_tasks'
--   );
-- Expected: 0 rows

-- Verify secure policies are still in place
-- SELECT tablename, policyname, cmd, qual
-- FROM pg_policies
-- WHERE schemaname = 'public'
--   AND policyname LIKE 'Couples can manage%'
--   AND tablename IN (
--     'affordability_gifts_contributions',
--     'affordability_inputs',
--     'affordability_results',
--     'affordability_scenarios',
--     'budget_development_items',
--     'budget_development_scenarios',
--     'documents',
--     'gifts_and_owed',
--     'my_estimated_budget',
--     'vendor_contacts',
--     'vendor_documents',
--     'vendor_information',
--     'wedding_events',
--     'wedding_tasks'
--   )
-- ORDER BY tablename;
-- Expected: 14 rows (one for each table)

-- ============================================================================
-- NOTES
-- ============================================================================

-- Why These Policies Are Dangerous:
-- - auth.role() = 'authenticated' allows ANY logged-in user to access data
-- - No couple_id validation means cross-tenant data access is possible
-- - Violates multi-tenant isolation principles
-- - Creates security vulnerability where User A can access User B's data

-- Safe Policies Already in Place:
-- - "Couples can manage their [resource]" policies use couple_id = auth.uid()
-- - These provide proper tenant isolation
-- - Users can only access their own couple's data
-- - Follows security best practices

-- Additional Secure Policies:
-- - Admin policies (auth.uid() = '00000000-0000-0000-0000-000000000000')
-- - get_user_tenant_ids() and get_user_couple_id() function-based policies
-- - can_user_access_tenant() function-based policies
-- These are all secure and provide proper access control

-- Migration Safety:
-- - All DROP POLICY statements use IF EXISTS to prevent errors
-- - Secure policies remain in place after removing permissive ones
-- - No data loss or functionality impact expected
-- - Application should continue to work normally with proper tenant isolation
