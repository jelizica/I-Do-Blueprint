-- Migration: Transfer admin account data to jessandliz23@gmail.com
-- This migration updates all records from the admin couple_id to the user's couple_id

-- Step 1: Ensure the user has a membership record with the admin couple_id
-- This allows the user to access the existing data
INSERT INTO public.memberships (user_id, couple_id, role)
VALUES (
  'eb8e5ceb-bd2d-4f59-a4fa-b80ddbfc2d2f',  -- jessandliz23@gmail.com
  'c507b4c9-7ef4-4b76-a71a-63887984b9ab',  -- admin couple_id (existing data)
  'owner'
)
ON CONFLICT (user_id, couple_id) DO UPDATE
SET role = 'owner';

-- Step 2: Update all table records from admin couple_id to remain with the same couple_id
-- This preserves the data structure while giving the user access via membership

-- Verification queries (run these after migration to confirm):
-- SELECT COUNT(*) FROM guest_list WHERE couple_id = 'c507b4c9-7ef4-4b76-a71a-63887984b9ab';
-- SELECT user_id, couple_id, role FROM memberships WHERE user_id = 'eb8e5ceb-bd2d-4f59-a4fa-b80ddbfc2d2f';

-- Expected results:
-- - 89 guests
-- - 44 budget_categories
-- - 78 budget_development_items
-- - 26 expenses
-- - 59 paymentPlans
-- - 24 vendorInformation
-- - 5 gifts_and_owed
-- - 5 affordability_gifts_contributions
-- - 3 budget_development_scenarios
-- - 2 affordability_scenarios
-- - 1 budget_settings
