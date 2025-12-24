-- Migration: Fix budget_categories RLS to allow inserts
-- Purpose: Add proper WITH CHECK clause for INSERT operations
-- Date: 2025-02-24
-- Issue: RLS policy was blocking inserts because it lacked WITH CHECK clause

BEGIN;

-- Drop the existing overly broad policy
DROP POLICY IF EXISTS "Users can manage accessible budget categories" ON public.budget_categories;

-- Create separate policies for each operation with proper checks
-- This follows the project's security pattern of explicit operation-specific policies

-- SELECT: Users can view budget categories for their accessible couples
CREATE POLICY "budget_categories_select"
ON public.budget_categories
FOR SELECT
TO authenticated
USING (couple_id = ANY (get_user_couple_ids()));

-- INSERT: Users can create budget categories for their accessible couples
CREATE POLICY "budget_categories_insert"
ON public.budget_categories
FOR INSERT
TO authenticated
WITH CHECK (couple_id = ANY (get_user_couple_ids()));

-- UPDATE: Users can update budget categories for their accessible couples
CREATE POLICY "budget_categories_update"
ON public.budget_categories
FOR UPDATE
TO authenticated
USING (couple_id = ANY (get_user_couple_ids()))
WITH CHECK (couple_id = ANY (get_user_couple_ids()));

-- DELETE: Users can delete budget categories for their accessible couples
CREATE POLICY "budget_categories_delete"
ON public.budget_categories
FOR DELETE
TO authenticated
USING (couple_id = ANY (get_user_couple_ids()));

-- Ensure RLS is enabled (should already be, but explicit is better)
ALTER TABLE public.budget_categories ENABLE ROW LEVEL SECURITY;

-- Grant necessary privileges (RLS will still gate access)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.budget_categories TO authenticated;

COMMIT;
