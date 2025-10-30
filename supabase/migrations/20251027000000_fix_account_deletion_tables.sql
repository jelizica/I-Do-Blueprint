-- Migration: Fix Complete Account Deletion - Correct Table Names
-- Issue: JES-171
-- Purpose: Fix delete_user_account() to use actual table names that exist in database
-- 
-- This replaces the previous function with correct table references

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
    DELETE FROM public.asset_color_extractions WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.palette_versions WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.palette_exports WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.palette_shares WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.palette_generations WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.mood_boards WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.color_palettes WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.seat_assignments WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.seating_tables WHERE seating_chart_id IN (
      SELECT id FROM public.seating_charts WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.seating_charts WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.style_preferences WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.visual_planning_shares WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.visual_planning_analytics WHERE couple_id = couple_record.couple_id;
    
    -- Documents & Notes (2 tables)
    DELETE FROM public.documents WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.notes WHERE couple_id = couple_record.couple_id;
    
    -- Timeline (3 tables)
    DELETE FROM public.timeline_items WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.wedding_milestones WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.wedding_timeline WHERE couple_id = couple_record.couple_id;
    
    -- Tasks (3 tables)
    DELETE FROM public.reminders WHERE task_id IN (
      SELECT id FROM public.wedding_tasks WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.wedding_subtasks WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.wedding_tasks WHERE couple_id = couple_record.couple_id;
    
    -- Vendors (5 tables)
    DELETE FROM public.vendor_contact_communications WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.vendor_contacts WHERE vendor_id IN (
      SELECT id FROM public.vendor_information WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.vendor_reviews WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.vendor_documents WHERE vendor_id IN (
      SELECT id FROM public.vendor_information WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.vendor_information WHERE couple_id = couple_record.couple_id;
    
    -- Guests (6 tables)
    DELETE FROM public.guest_communications WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.guest_meal_selections WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.preparation_schedule WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.rsvp_workflow WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.guest_groups WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.guest_list WHERE couple_id = couple_record.couple_id;
    
    -- Budget (15 tables)
    DELETE FROM public.expense_budget_allocations WHERE expense_id IN (
      SELECT id FROM public.expenses WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.expense_line_items WHERE expense_id IN (
      SELECT id FROM public.expenses WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.payment_plans WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.expenses WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.budget_development_items WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.budget_development_scenarios WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.affordability_results WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.affordability_gifts_contributions WHERE scenario_id IN (
      SELECT id FROM public.affordability_scenarios WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.affordability_inputs WHERE scenario_id IN (
      SELECT id FROM public.affordability_scenarios WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.affordability_scenarios WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.monthly_cash_flow WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.gifts_and_owed WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.gift_received WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.money_owed WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.budget_categories WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.budget_milestones WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.budget_settings WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.my_estimated_budget WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.tax_info WHERE couple_id = couple_record.couple_id;
    
    -- Events (2 tables)
    DELETE FROM public.meal_options WHERE event_id IN (
      SELECT id FROM public.wedding_events WHERE couple_id = couple_record.couple_id
    );
    DELETE FROM public.wedding_events WHERE couple_id = couple_record.couple_id;
    
    -- Collaboration (7 tables)
    DELETE FROM public.activity_events WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.edit_locks WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.presence WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.invitations WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.collaborators WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.conflict_resolutions WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.communication_templates WHERE couple_id = couple_record.couple_id;
    
    -- Settings & Admin (4 tables)
    DELETE FROM public.couple_settings WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.export_templates WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.tenant_usage WHERE couple_id = couple_record.couple_id;
    DELETE FROM public.subscriptions WHERE tenant_id = couple_record.couple_id;
    
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
Note: Auth user deletion is handled separately by Edge Function.
Updated: 2025-10-27 - Fixed to use actual table names that exist in database.';
