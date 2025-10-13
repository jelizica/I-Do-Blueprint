-- Migration: Enable RLS and Create Security Policies
-- This migration enables Row Level Security on all user data tables and creates
-- policies that restrict access to only the authenticated user's couple data.
-- This allows removal of the service-role key from the application.

-- =============================================================================
-- HELPER FUNCTION: Get couple_id for authenticated user
-- =============================================================================

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS public.get_user_couple_id();

-- Create function to get the couple_id for the current authenticated user
CREATE OR REPLACE FUNCTION public.get_user_couple_id()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_couple_id UUID;
BEGIN
  -- Get the couple_id for the authenticated user from memberships table
  SELECT couple_id INTO user_couple_id
  FROM public.memberships
  WHERE user_id = auth.uid()
  LIMIT 1;

  RETURN user_couple_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_user_couple_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_couple_id() TO anon;

-- =============================================================================
-- GUEST LIST
-- =============================================================================

ALTER TABLE guest_list ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view guests for their couple
CREATE POLICY "Users can view own couple guests" ON guest_list
  FOR SELECT
  USING (couple_id = public.get_user_couple_id());

-- Policy: Users can insert guests for their couple
CREATE POLICY "Users can insert own couple guests" ON guest_list
  FOR INSERT
  WITH CHECK (couple_id = public.get_user_couple_id());

-- Policy: Users can update their own couple's guests
CREATE POLICY "Users can update own couple guests" ON guest_list
  FOR UPDATE
  USING (couple_id = public.get_user_couple_id())
  WITH CHECK (couple_id = public.get_user_couple_id());

-- Policy: Users can delete their own couple's guests
CREATE POLICY "Users can delete own couple guests" ON guest_list
  FOR DELETE
  USING (couple_id = public.get_user_couple_id());

-- =============================================================================
-- VENDORS
-- =============================================================================

ALTER TABLE "vendorInformation" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own couple vendors" ON "vendorInformation"
  FOR SELECT
  USING (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can insert own couple vendors" ON "vendorInformation"
  FOR INSERT
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can update own couple vendors" ON "vendorInformation"
  FOR UPDATE
  USING (couple_id = public.get_user_couple_id())
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can delete own couple vendors" ON "vendorInformation"
  FOR DELETE
  USING (couple_id = public.get_user_couple_id());

-- =============================================================================
-- EXPENSES
-- =============================================================================

ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own couple expenses" ON expenses
  FOR SELECT
  USING (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can insert own couple expenses" ON expenses
  FOR INSERT
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can update own couple expenses" ON expenses
  FOR UPDATE
  USING (couple_id = public.get_user_couple_id())
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can delete own couple expenses" ON expenses
  FOR DELETE
  USING (couple_id = public.get_user_couple_id());

-- =============================================================================
-- PAYMENT PLANS
-- =============================================================================

ALTER TABLE "paymentPlans" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own couple payments" ON "paymentPlans"
  FOR SELECT
  USING (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can insert own couple payments" ON "paymentPlans"
  FOR INSERT
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can update own couple payments" ON "paymentPlans"
  FOR UPDATE
  USING (couple_id = public.get_user_couple_id())
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can delete own couple payments" ON "paymentPlans"
  FOR DELETE
  USING (couple_id = public.get_user_couple_id());

-- =============================================================================
-- BUDGET CATEGORIES
-- =============================================================================

ALTER TABLE budget_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own couple budget categories" ON budget_categories
  FOR SELECT
  USING (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can insert own couple budget categories" ON budget_categories
  FOR INSERT
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can update own couple budget categories" ON budget_categories
  FOR UPDATE
  USING (couple_id = public.get_user_couple_id())
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can delete own couple budget categories" ON budget_categories
  FOR DELETE
  USING (couple_id = public.get_user_couple_id());

-- =============================================================================
-- BUDGET SETTINGS
-- =============================================================================

ALTER TABLE budget_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own couple budget settings" ON budget_settings
  FOR SELECT
  USING (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can insert own couple budget settings" ON budget_settings
  FOR INSERT
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can update own couple budget settings" ON budget_settings
  FOR UPDATE
  USING (couple_id = public.get_user_couple_id())
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can delete own couple budget settings" ON budget_settings
  FOR DELETE
  USING (couple_id = public.get_user_couple_id());

-- =============================================================================
-- GIFTS AND OWED
-- =============================================================================

ALTER TABLE gifts_and_owed ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own couple gifts" ON gifts_and_owed
  FOR SELECT
  USING (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can insert own couple gifts" ON gifts_and_owed
  FOR INSERT
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can update own couple gifts" ON gifts_and_owed
  FOR UPDATE
  USING (couple_id = public.get_user_couple_id())
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can delete own couple gifts" ON gifts_and_owed
  FOR DELETE
  USING (couple_id = public.get_user_couple_id());

-- =============================================================================
-- BUDGET DEVELOPMENT SCENARIOS
-- =============================================================================

ALTER TABLE budget_development_scenarios ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own couple scenarios" ON budget_development_scenarios
  FOR SELECT
  USING (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can insert own couple scenarios" ON budget_development_scenarios
  FOR INSERT
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can update own couple scenarios" ON budget_development_scenarios
  FOR UPDATE
  USING (couple_id = public.get_user_couple_id())
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can delete own couple scenarios" ON budget_development_scenarios
  FOR DELETE
  USING (couple_id = public.get_user_couple_id());

-- =============================================================================
-- BUDGET DEVELOPMENT ITEMS
-- =============================================================================

ALTER TABLE budget_development_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own couple budget items" ON budget_development_items
  FOR SELECT
  USING (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can insert own couple budget items" ON budget_development_items
  FOR INSERT
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can update own couple budget items" ON budget_development_items
  FOR UPDATE
  USING (couple_id = public.get_user_couple_id())
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can delete own couple budget items" ON budget_development_items
  FOR DELETE
  USING (couple_id = public.get_user_couple_id());

-- =============================================================================
-- EXPENSE BUDGET ALLOCATIONS
-- =============================================================================

ALTER TABLE expense_budget_allocations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own couple allocations" ON expense_budget_allocations
  FOR SELECT
  USING (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can insert own couple allocations" ON expense_budget_allocations
  FOR INSERT
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can update own couple allocations" ON expense_budget_allocations
  FOR UPDATE
  USING (couple_id = public.get_user_couple_id())
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can delete own couple allocations" ON expense_budget_allocations
  FOR DELETE
  USING (couple_id = public.get_user_couple_id());

-- =============================================================================
-- AFFORDABILITY SCENARIOS
-- =============================================================================

ALTER TABLE affordability_scenarios ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own couple affordability scenarios" ON affordability_scenarios
  FOR SELECT
  USING (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can insert own couple affordability scenarios" ON affordability_scenarios
  FOR INSERT
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can update own couple affordability scenarios" ON affordability_scenarios
  FOR UPDATE
  USING (couple_id = public.get_user_couple_id())
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can delete own couple affordability scenarios" ON affordability_scenarios
  FOR DELETE
  USING (couple_id = public.get_user_couple_id());

-- =============================================================================
-- AFFORDABILITY GIFTS CONTRIBUTIONS
-- =============================================================================

ALTER TABLE affordability_gifts_contributions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own couple contributions" ON affordability_gifts_contributions
  FOR SELECT
  USING (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can insert own couple contributions" ON affordability_gifts_contributions
  FOR INSERT
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can update own couple contributions" ON affordability_gifts_contributions
  FOR UPDATE
  USING (couple_id = public.get_user_couple_id())
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can delete own couple contributions" ON affordability_gifts_contributions
  FOR DELETE
  USING (couple_id = public.get_user_couple_id());

-- =============================================================================
-- TAX INFO
-- =============================================================================

-- Note: taxInfo is reference data (no couple_id column)
-- It should be readable by all authenticated users but only modifiable by admins

ALTER TABLE "taxInfo" ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read tax info
CREATE POLICY "Users can view tax info" ON "taxInfo"
  FOR SELECT
  TO authenticated
  USING (true);

-- Only service role can modify (via migrations/admin operations)
-- No INSERT/UPDATE/DELETE policies for regular users

-- =============================================================================
-- WEDDING EVENTS
-- =============================================================================

ALTER TABLE wedding_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own couple events" ON wedding_events
  FOR SELECT
  USING (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can insert own couple events" ON wedding_events
  FOR INSERT
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can update own couple events" ON wedding_events
  FOR UPDATE
  USING (couple_id = public.get_user_couple_id())
  WITH CHECK (couple_id = public.get_user_couple_id());

CREATE POLICY "Users can delete own couple events" ON wedding_events
  FOR DELETE
  USING (couple_id = public.get_user_couple_id());

-- =============================================================================
-- VENDOR REVIEWS (if exists)
-- =============================================================================

-- Check if vendor_reviews table exists and enable RLS
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'vendor_reviews') THEN
    ALTER TABLE vendor_reviews ENABLE ROW LEVEL SECURITY;

    CREATE POLICY "Users can view own couple vendor reviews" ON vendor_reviews
      FOR SELECT
      USING (couple_id = public.get_user_couple_id());

    CREATE POLICY "Users can insert own couple vendor reviews" ON vendor_reviews
      FOR INSERT
      WITH CHECK (couple_id = public.get_user_couple_id());

    CREATE POLICY "Users can update own couple vendor reviews" ON vendor_reviews
      FOR UPDATE
      USING (couple_id = public.get_user_couple_id())
      WITH CHECK (couple_id = public.get_user_couple_id());

    CREATE POLICY "Users can delete own couple vendor reviews" ON vendor_reviews
      FOR DELETE
      USING (couple_id = public.get_user_couple_id());
  END IF;
END $$;

-- =============================================================================
-- CATEGORY BENCHMARKS (if exists - likely reference data)
-- =============================================================================

-- Category benchmarks are likely reference data (not couple-specific)
-- So they should be readable by all authenticated users but not writable
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'category_benchmarks') THEN
    ALTER TABLE category_benchmarks ENABLE ROW LEVEL SECURITY;

    -- All authenticated users can read benchmarks
    CREATE POLICY "Users can view category benchmarks" ON category_benchmarks
      FOR SELECT
      TO authenticated
      USING (true);

    -- Only service role can modify (via migrations/admin operations)
    -- No INSERT/UPDATE/DELETE policies for regular users
  END IF;
END $$;

-- =============================================================================
-- VENDOR PAYMENT SUMMARY VIEW (if exists)
-- =============================================================================

DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_views WHERE schemaname = 'public' AND viewname = 'vendor_payment_summary') THEN
    -- Views inherit RLS from underlying tables, so no additional policy needed
    -- But we can add explicit policy if the view is materialized
    NULL;
  END IF;
END $$;

-- =============================================================================
-- VENDOR CONTRACT SUMMARY VIEW (if exists)
-- =============================================================================

DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_views WHERE schemaname = 'public' AND viewname = 'vendor_contract_summary') THEN
    -- Views inherit RLS from underlying tables
    NULL;
  END IF;
END $$;

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

-- To verify RLS is enabled on all tables, run:
-- SELECT tablename, rowsecurity
-- FROM pg_tables
-- WHERE schemaname = 'public'
-- AND tablename NOT LIKE 'pg_%'
-- ORDER BY tablename;

-- To verify policies exist, run:
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
-- FROM pg_policies
-- WHERE schemaname = 'public'
-- ORDER BY tablename, policyname;

-- =============================================================================
-- NOTES
-- =============================================================================

-- After applying this migration:
-- 1. All user data is protected by RLS
-- 2. Users can only access data for their own couple_id
-- 3. The application can use the anon key (regular authenticated client)
-- 4. The service-role key should be removed from the app bundle
-- 5. Test all CRUD operations with an authenticated user to ensure they work

-- If any operations fail after this migration:
-- 1. Check that the user is properly authenticated (auth.uid() returns a value)
-- 2. Check that the user has a couple_id in the couples table
-- 3. Check that the data being accessed has the correct couple_id
-- 4. Check the Supabase logs for RLS policy violations
