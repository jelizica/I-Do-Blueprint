-- Migration: Fix mutable search_path in update_updated_at_column function
-- Issue: JES-146
-- Description: Sets search_path = '' on the update_updated_at_column function to prevent
--              schema poisoning attacks. This is a critical security fix.
-- Impact: 42 tables use this trigger function
-- Date: 2025-10-24

-- Drop and recreate the function with search_path security setting
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- Add comment documenting the security setting
COMMENT ON FUNCTION public.update_updated_at_column() IS 
'Automatically updates the updated_at column to the current timestamp. 
SECURITY: search_path is set to empty string to prevent schema poisoning attacks.
Used by triggers on 42 tables across the database.';
