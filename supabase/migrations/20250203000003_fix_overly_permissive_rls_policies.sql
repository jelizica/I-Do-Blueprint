-- Migration: Fix Overly Permissive RLS Policies
-- Description: Replace qual='true' policies with proper couple_id-based tenant isolation
-- Issue: JES-93 - CRITICAL: Remove Overly Permissive RLS Policies Exposing Public Data
-- Created: 2025-02-03

-- ============================================================================
-- PHASE 1: Add missing couple_id column to my_estimated_budget
-- ============================================================================

-- Add couple_id column to my_estimated_budget if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'my_estimated_budget' 
    AND column_name = 'couple_id'
  ) THEN
    ALTER TABLE my_estimated_budget 
      ADD COLUMN couple_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;
    
    -- Note: In production, you would need to backfill this column with appropriate couple_id values
    -- For now, we'll make it nullable and add NOT NULL constraint after data migration
    RAISE NOTICE 'Added couple_id column to my_estimated_budget';
  END IF;
END $$;

-- ============================================================================
-- PHASE 2: Drop all overly permissive policies on user data tables
-- ============================================================================

-- affordability_gifts_contributions
DROP POLICY IF EXISTS "gifts_contributions_select_policy" ON affordability_gifts_contributions;
DROP POLICY IF EXISTS "gifts_contributions_update_policy" ON affordability_gifts_contributions;
DROP POLICY IF EXISTS "gifts_contributions_delete_policy" ON affordability_gifts_contributions;

-- affordability_inputs
DROP POLICY IF EXISTS "Enable read access for all users" ON affordability_inputs;

-- affordability_results
DROP POLICY IF EXISTS "Enable read access for all users" ON affordability_results;

-- affordability_scenarios
DROP POLICY IF EXISTS "Enable read access for all users" ON affordability_scenarios;

-- budget_development_items
DROP POLICY IF EXISTS "Development items are viewable by everyone" ON budget_development_items;

-- budget_development_scenarios
DROP POLICY IF EXISTS "Development scenarios are viewable by everyone" ON budget_development_scenarios;

-- documents
DROP POLICY IF EXISTS "Users can view all documents" ON documents;

-- gifts_and_owed
DROP POLICY IF EXISTS "Allow all operations for authenticated users" ON gifts_and_owed;

-- my_estimated_budget
DROP POLICY IF EXISTS "Enable read access for all users" ON my_estimated_budget;

-- vendor_information
DROP POLICY IF EXISTS "Enable read access for all users" ON vendor_information;

-- ============================================================================
-- PHASE 3: Create secure tenant-isolated policies for all user data tables
-- ============================================================================

-- Pattern: Users can only access data where couple_id matches their auth.uid()

-- affordability_gifts_contributions
CREATE POLICY "Couples can manage their gift contributions"
  ON affordability_gifts_contributions
  FOR ALL
  USING (couple_id = auth.uid())
  WITH CHECK (couple_id = auth.uid());

-- affordability_inputs
CREATE POLICY "Couples can manage their affordability inputs"
  ON affordability_inputs
  FOR ALL
  USING (couple_id = auth.uid())
  WITH CHECK (couple_id = auth.uid());

-- affordability_results
CREATE POLICY "Couples can manage their affordability results"
  ON affordability_results
  FOR ALL
  USING (couple_id = auth.uid())
  WITH CHECK (couple_id = auth.uid());

-- affordability_scenarios
CREATE POLICY "Couples can manage their affordability scenarios"
  ON affordability_scenarios
  FOR ALL
  USING (couple_id = auth.uid())
  WITH CHECK (couple_id = auth.uid());

-- budget_development_items
CREATE POLICY "Couples can manage their budget development items"
  ON budget_development_items
  FOR ALL
  USING (couple_id = auth.uid())
  WITH CHECK (couple_id = auth.uid());

-- budget_development_scenarios
CREATE POLICY "Couples can manage their budget development scenarios"
  ON budget_development_scenarios
  FOR ALL
  USING (couple_id = auth.uid())
  WITH CHECK (couple_id = auth.uid());

-- documents
CREATE POLICY "Couples can manage their documents"
  ON documents
  FOR ALL
  USING (couple_id = auth.uid())
  WITH CHECK (couple_id = auth.uid());

-- gifts_and_owed
CREATE POLICY "Couples can manage their gifts and owed records"
  ON gifts_and_owed
  FOR ALL
  USING (couple_id = auth.uid())
  WITH CHECK (couple_id = auth.uid());

-- my_estimated_budget
CREATE POLICY "Couples can manage their estimated budget"
  ON my_estimated_budget
  FOR ALL
  USING (couple_id = auth.uid())
  WITH CHECK (couple_id = auth.uid());

-- vendor_contacts
CREATE POLICY "Couples can manage their vendor contacts"
  ON vendor_contacts
  FOR ALL
  USING (couple_id = auth.uid())
  WITH CHECK (couple_id = auth.uid());

-- vendor_documents
CREATE POLICY "Couples can manage their vendor documents"
  ON vendor_documents
  FOR ALL
  USING (couple_id = auth.uid())
  WITH CHECK (couple_id = auth.uid());

-- vendor_information
CREATE POLICY "Couples can manage their vendor information"
  ON vendor_information
  FOR ALL
  USING (couple_id = auth.uid())
  WITH CHECK (couple_id = auth.uid());

-- wedding_events
CREATE POLICY "Couples can manage their wedding events"
  ON wedding_events
  FOR ALL
  USING (couple_id = auth.uid())
  WITH CHECK (couple_id = auth.uid());

-- wedding_tasks
CREATE POLICY "Couples can manage their wedding tasks"
  ON wedding_tasks
  FOR ALL
  USING (couple_id = auth.uid())
  WITH CHECK (couple_id = auth.uid());

-- ============================================================================
-- PHASE 4: Verification queries (commented out - run manually to verify)
-- ============================================================================

-- Verify no permissive policies remain on user data tables
-- SELECT tablename, policyname, qual
-- FROM pg_policies
-- WHERE qual = 'true'
--   AND schemaname = 'public'
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
--   );
-- Expected: 0 rows

-- Verify all user data tables have couple_id-based policies
-- SELECT tablename, policyname, cmd, qual
-- FROM pg_policies
-- WHERE schemaname = 'public'
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
-- ORDER BY tablename, policyname;
-- Expected: Each table should have 1 policy with couple_id = auth.uid()

-- ============================================================================
-- NOTES
-- ============================================================================

-- Lookup/Reference Tables (Intentionally Left Public):
-- - vendor_types: Shared vendor type lookup data
-- - tax_info: Shared tax rate reference data
-- - roles: System role definitions
-- - subscription_plans: Plan information for all users
-- - users_roles: Protected by service_role policies
-- - billing_events: Protected by service_role policies

-- Service Role Policies (Acceptable):
-- - guest_list: Service role can manage all guest data (admin operations)
-- - billing_events: Service role can manage billing (system operations)
-- - roles: Service role can manage roles (system operations)
-- - users_roles: Service role can manage user role assignments (system operations)

-- Migration Safety:
-- - All DROP POLICY statements use IF EXISTS to prevent errors
-- - couple_id column addition is idempotent
-- - Policies use FOR ALL to cover SELECT, INSERT, UPDATE, DELETE in one statement
-- - All policies enforce couple_id = auth.uid() for both USING and WITH CHECK

-- Post-Migration Tasks:
-- 1. Backfill couple_id in my_estimated_budget table if needed
-- 2. Test with multiple couple accounts to verify isolation
-- 3. Run verification queries to confirm no permissive policies remain
-- 4. Monitor application logs for any RLS-related errors
-- 5. Update application code if any queries relied on cross-tenant access
