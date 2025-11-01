-- Migration: Complete Account Deletion
-- Issue: JES-171
-- Purpose: Delete ALL couples/weddings and associated data for a user
-- 
-- This function deletes:
-- 1. ALL couples the user is a member of
-- 2. ALL data associated with those couples (47 tables)
-- 3. The user's memberships
--
-- Security: SECURITY DEFINER with search_path = '' for safety

CREATE OR REPLACE FUNCTION delete_user_account(user_id_to_delete uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  couple_record RECORD;
  deleted_couples_count INTEGER := 0;
BEGIN
  RAISE NOTICE 'Starting account deletion for user: %', user_id_to_delete;
  
  -- Loop through ALL couples the user is a member of
  FOR couple_record IN 
    SELECT DISTINCT couple_id 
    FROM public.memberships 
    WHERE user_id = user_id_to_delete
  LOOP
    RAISE NOTICE 'Deleting couple: %', couple_record.couple_id;
    
    -- Delete all data for this couple in correct order (respecting foreign keys)
    
    -- Visual Planning (12 tables)
    DELETE FROM public.visual_elements WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.mood_board_items WHERE mood_board_id IN (
      SELECT id FROM public.mood_boards WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.mood_boards WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.seating_chart_guests WHERE seating_chart_id IN (
      SELECT id FROM public.seating_charts WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.seating_chart_tables WHERE seating_chart_id IN (
      SELECT id FROM public.seating_charts WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.seating_charts WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.floor_plan_elements WHERE floor_plan_id IN (
      SELECT id FROM public.floor_plans WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.floor_plans WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.color_palette_colors WHERE color_palette_id IN (
      SELECT id FROM public.color_palettes WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.color_palettes WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.inspiration_items WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.design_themes WHERE couple_id = couple_record.couple_id;
    
    -- Documents & Notes (3 tables)
    DELETE FROM public.document_versions WHERE document_id IN (
      SELECT id FROM public.documents WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.documents WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.notes WHERE couple_id = couple_record.couple_id;
    
    -- Timeline (2 tables)
    DELETE FROM public.timeline_items WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.milestones WHERE couple_id = couple_record.couple_id;
    
    -- Tasks (3 tables)
    DELETE FROM public.task_dependencies WHERE task_id IN (
      SELECT id FROM public.task_list WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.task_assignments WHERE task_id IN (
      SELECT id FROM public.task_list WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.task_list WHERE couple_id = couple_record.couple_id;
    
    -- Vendors (4 tables)
    DELETE FROM public.vendor_payments WHERE vendor_id IN (
      SELECT id FROM public.vendor_information WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.vendor_contracts WHERE vendor_id IN (
      SELECT id FROM public.vendor_information WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.vendor_contacts WHERE vendor_id IN (
      SELECT id FROM public.vendor_information WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.vendor_information WHERE couple_id = couple_record.couple_id;
    
    -- Guests (6 tables)
    DELETE FROM public.guest_meal_selections WHERE guest_id IN (
      SELECT id FROM public.guest_list WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.guest_dietary_restrictions WHERE guest_id IN (
      SELECT id FROM public.guest_list WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.guest_plus_ones WHERE guest_id IN (
      SELECT id FROM public.guest_list WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.guest_groups WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.guest_tags WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.guest_list WHERE couple_id = couple_record.couple_id;
    
    -- Budget (12 tables)
    DELETE FROM public.expense_allocations WHERE expense_id IN (
      SELECT id FROM public.expenses WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.expenses WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.budget_items WHERE budget_category_id IN (
      SELECT id FROM public.budget_categories WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.budget_categories WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.payment_schedules WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.gifts_received WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.money_owed WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.budget_scenarios WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.affordability_calculations WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.cash_flow_projections WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.budget_alerts WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.budget_history WHERE couple_id = couple_record.couple_id;
    
    -- Events (2 tables)
    DELETE FROM public.event_attendees WHERE event_id IN (
      SELECT id FROM public.events WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.events WHERE couple_id = couple_record.couple_id;
    
    -- Collaboration (3 tables)
    DELETE FROM public.activity_feed WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.presence WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.invitations WHERE couple_id = couple_record.couple_id;
    
    -- Settings (1 table)
    DELETE FROM public.couple_settings WHERE couple_id = couple_record.couple_id;
    
    -- Memberships for this couple (1 table)
    DELETE FROM public.memberships WHERE couple_id = couple_record.couple_id;
    
    -- Couple Profile (1 table) - Delete last due to foreign keys
    DELETE FROM public.couple_profiles WHERE id = couple_record.couple_id;
    
    deleted_couples_count := deleted_couples_count + 1;
    RAISE NOTICE 'Deleted couple % (total: %)', couple_record.couple_id, deleted_couples_count;
  END LOOP;
  
  RAISE NOTICE 'Account deletion completed. Deleted % couples for user %', deleted_couples_count, user_id_to_delete;
  
  -- Note: Auth user deletion is handled by the Edge Function
  -- This function only handles database cleanup
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION delete_user_account(uuid) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION delete_user_account(uuid) IS 
'Deletes ALL couples and associated data for a user. Called during account deletion (JES-171).
Security: Users can only delete their own account (enforced at application layer).
Note: Auth user deletion is handled separately by Edge Function.';
