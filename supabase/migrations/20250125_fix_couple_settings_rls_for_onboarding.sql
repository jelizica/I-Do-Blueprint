-- Fix RLS policy for couple_settings to allow INSERT for onboarding
-- This allows upsert operations when creating onboarding progress for new couples

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Users can manage their couple settings" ON couple_settings;

-- Create new policy that allows both INSERT and UPDATE
CREATE POLICY "Users can manage their couple settings"
ON couple_settings
FOR ALL
USING (
  couple_id IN (
    SELECT couple_id 
    FROM memberships 
    WHERE user_id = (SELECT auth.uid())
  )
)
WITH CHECK (
  couple_id IN (
    SELECT couple_id 
    FROM memberships 
    WHERE user_id = (SELECT auth.uid())
  )
);

-- Add comment
COMMENT ON POLICY "Users can manage their couple settings" ON couple_settings IS 
'Allows users to INSERT, UPDATE, and DELETE settings for couples they are members of. Required for onboarding upsert operations.';
