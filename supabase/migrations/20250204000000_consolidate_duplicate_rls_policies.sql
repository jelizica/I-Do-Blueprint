-- Migration: Consolidate Duplicate and Conflicting RLS Policies
-- Issue: JES-94
-- Description: Reduces 13-16 policies per table down to 1 consolidated policy
-- Strategy: Aggressive consolidation using FOR ALL with couple_id scoping

-- ============================================================================
-- PART 1: DROP ALL EXISTING POLICIES ON MULTI-TENANT TABLES
-- ============================================================================

-- Guest Management Tables
DROP POLICY IF EXISTS "Admin can do everything" ON guest_list;
DROP POLICY IF EXISTS "Allow admin user access to admin tenant data" ON guest_list;
DROP POLICY IF EXISTS "Allow authenticated users access to guest data" ON guest_list;
DROP POLICY IF EXISTS "Allow service role full access" ON guest_list;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON guest_list;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON guest_list;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON guest_list;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON guest_list;
DROP POLICY IF EXISTS "Users can delete guests" ON guest_list;
DROP POLICY IF EXISTS "Users can delete own couple guests" ON guest_list;
DROP POLICY IF EXISTS "Users can insert guests" ON guest_list;
DROP POLICY IF EXISTS "Users can insert own couple guests" ON guest_list;
DROP POLICY IF EXISTS "Users can update guests" ON guest_list;
DROP POLICY IF EXISTS "Users can update own couple guests" ON guest_list;
DROP POLICY IF EXISTS "Users can view own couple guests" ON guest_list;
DROP POLICY IF EXISTS "Users can view their guests" ON guest_list;

DROP POLICY IF EXISTS "Admin can do everything" ON guest_groups;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON guest_groups;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON guest_groups;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON guest_groups;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON guest_groups;
DROP POLICY IF EXISTS "Users can delete guest groups" ON guest_groups;
DROP POLICY IF EXISTS "Users can insert guest groups" ON guest_groups;
DROP POLICY IF EXISTS "Users can update guest groups" ON guest_groups;
DROP POLICY IF EXISTS "Users can view their guest groups" ON guest_groups;

DROP POLICY IF EXISTS "Admin can do everything" ON guest_communications;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON guest_communications;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON guest_communications;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON guest_communications;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON guest_communications;
DROP POLICY IF EXISTS "Users can delete guest communications" ON guest_communications;
DROP POLICY IF EXISTS "Users can insert guest communications" ON guest_communications;
DROP POLICY IF EXISTS "Users can update guest communications" ON guest_communications;
DROP POLICY IF EXISTS "Users can view their guest communications" ON guest_communications;

DROP POLICY IF EXISTS "Admin can do everything" ON guest_meal_selections;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON guest_meal_selections;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON guest_meal_selections;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON guest_meal_selections;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON guest_meal_selections;
DROP POLICY IF EXISTS "Users can delete guest meal selections" ON guest_meal_selections;
DROP POLICY IF EXISTS "Users can insert guest meal selections" ON guest_meal_selections;
DROP POLICY IF EXISTS "Users can update guest meal selections" ON guest_meal_selections;
DROP POLICY IF EXISTS "Users can view their guest meal selections" ON guest_meal_selections;

-- Budget Tables
DROP POLICY IF EXISTS "Admin can do everything" ON budget_categories;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON budget_categories;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON budget_categories;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON budget_categories;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON budget_categories;
DROP POLICY IF EXISTS "Users can delete budget categories" ON budget_categories;
DROP POLICY IF EXISTS "Users can delete own couple budget categories" ON budget_categories;
DROP POLICY IF EXISTS "Users can insert budget categories" ON budget_categories;
DROP POLICY IF EXISTS "Users can insert own couple budget categories" ON budget_categories;
DROP POLICY IF EXISTS "Users can update budget categories" ON budget_categories;
DROP POLICY IF EXISTS "Users can update own couple budget categories" ON budget_categories;
DROP POLICY IF EXISTS "Users can view own couple budget categories" ON budget_categories;
DROP POLICY IF EXISTS "Users can view their budget categories" ON budget_categories;

DROP POLICY IF EXISTS "Admin can do everything" ON expenses;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON expenses;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON expenses;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON expenses;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON expenses;
DROP POLICY IF EXISTS "Users can delete expenses" ON expenses;
DROP POLICY IF EXISTS "Users can delete own couple expenses" ON expenses;
DROP POLICY IF EXISTS "Users can insert expenses" ON expenses;
DROP POLICY IF EXISTS "Users can insert own couple expenses" ON expenses;
DROP POLICY IF EXISTS "Users can update expenses" ON expenses;
DROP POLICY IF EXISTS "Users can update own couple expenses" ON expenses;
DROP POLICY IF EXISTS "Users can view own couple expenses" ON expenses;
DROP POLICY IF EXISTS "Users can view their expenses" ON expenses;

DROP POLICY IF EXISTS "Admin can do everything" ON expense_budget_allocations;
DROP POLICY IF EXISTS "Users can delete expense budget allocations" ON expense_budget_allocations;
DROP POLICY IF EXISTS "Users can delete own couple allocations" ON expense_budget_allocations;
DROP POLICY IF EXISTS "Users can delete their expense budget allocations" ON expense_budget_allocations;
DROP POLICY IF EXISTS "Users can insert expense budget allocations" ON expense_budget_allocations;
DROP POLICY IF EXISTS "Users can insert own couple allocations" ON expense_budget_allocations;
DROP POLICY IF EXISTS "Users can insert their expense budget allocations" ON expense_budget_allocations;
DROP POLICY IF EXISTS "Users can update expense budget allocations" ON expense_budget_allocations;
DROP POLICY IF EXISTS "Users can update own couple allocations" ON expense_budget_allocations;
DROP POLICY IF EXISTS "Users can update their expense budget allocations" ON expense_budget_allocations;
DROP POLICY IF EXISTS "Users can view own couple allocations" ON expense_budget_allocations;
DROP POLICY IF EXISTS "Users can view their expense budget allocations" ON expense_budget_allocations;

DROP POLICY IF EXISTS "Users can delete expense line items" ON expense_line_items;
DROP POLICY IF EXISTS "Users can insert expense line items" ON expense_line_items;
DROP POLICY IF EXISTS "Users can update expense line items" ON expense_line_items;
DROP POLICY IF EXISTS "Users can view their expense line items" ON expense_line_items;

DROP POLICY IF EXISTS "Admin can do everything" ON budget_settings;
DROP POLICY IF EXISTS "Users can delete budget settings" ON budget_settings;
DROP POLICY IF EXISTS "Users can delete own couple budget settings" ON budget_settings;
DROP POLICY IF EXISTS "Users can insert budget settings" ON budget_settings;
DROP POLICY IF EXISTS "Users can insert own couple budget settings" ON budget_settings;
DROP POLICY IF EXISTS "Users can update budget settings" ON budget_settings;
DROP POLICY IF EXISTS "Users can update own couple budget settings" ON budget_settings;
DROP POLICY IF EXISTS "Users can view own couple budget settings" ON budget_settings;
DROP POLICY IF EXISTS "Users can view their budget settings" ON budget_settings;

DROP POLICY IF EXISTS "Admin can do everything" ON budget_milestones;
DROP POLICY IF EXISTS "Users can delete budget milestones" ON budget_milestones;
DROP POLICY IF EXISTS "Users can insert budget milestones" ON budget_milestones;
DROP POLICY IF EXISTS "Users can update budget milestones" ON budget_milestones;
DROP POLICY IF EXISTS "Users can view their budget milestones" ON budget_milestones;

DROP POLICY IF EXISTS "Admin can do everything" ON budget_development_items;
DROP POLICY IF EXISTS "Couples can manage their budget development items" ON budget_development_items;
DROP POLICY IF EXISTS "Users can delete budget items" ON budget_development_items;
DROP POLICY IF EXISTS "Users can delete own couple budget items" ON budget_development_items;
DROP POLICY IF EXISTS "Users can insert budget items" ON budget_development_items;
DROP POLICY IF EXISTS "Users can insert own couple budget items" ON budget_development_items;
DROP POLICY IF EXISTS "Users can update budget items" ON budget_development_items;
DROP POLICY IF EXISTS "Users can update own couple budget items" ON budget_development_items;
DROP POLICY IF EXISTS "Users can view own couple budget items" ON budget_development_items;
DROP POLICY IF EXISTS "Users can view their budget items" ON budget_development_items;

DROP POLICY IF EXISTS "Admin can do everything" ON budget_development_scenarios;
DROP POLICY IF EXISTS "Couples can manage their budget development scenarios" ON budget_development_scenarios;
DROP POLICY IF EXISTS "Users can delete budget scenarios" ON budget_development_scenarios;
DROP POLICY IF EXISTS "Users can delete own couple scenarios" ON budget_development_scenarios;
DROP POLICY IF EXISTS "Users can insert budget scenarios" ON budget_development_scenarios;
DROP POLICY IF EXISTS "Users can insert own couple scenarios" ON budget_development_scenarios;
DROP POLICY IF EXISTS "Users can update budget scenarios" ON budget_development_scenarios;
DROP POLICY IF EXISTS "Users can update own couple scenarios" ON budget_development_scenarios;
DROP POLICY IF EXISTS "Users can view own couple scenarios" ON budget_development_scenarios;
DROP POLICY IF EXISTS "Users can view their budget scenarios" ON budget_development_scenarios;

-- Affordability Tables
DROP POLICY IF EXISTS "Admin can do everything" ON affordability_inputs;
DROP POLICY IF EXISTS "Couples can manage their affordability inputs" ON affordability_inputs;
DROP POLICY IF EXISTS "Users can delete affordability inputs" ON affordability_inputs;
DROP POLICY IF EXISTS "Users can insert affordability inputs" ON affordability_inputs;
DROP POLICY IF EXISTS "Users can update affordability inputs" ON affordability_inputs;
DROP POLICY IF EXISTS "Users can view their affordability inputs" ON affordability_inputs;

DROP POLICY IF EXISTS "Admin can do everything" ON affordability_results;
DROP POLICY IF EXISTS "Couples can manage their affordability results" ON affordability_results;
DROP POLICY IF EXISTS "Users can delete affordability results" ON affordability_results;
DROP POLICY IF EXISTS "Users can insert affordability results" ON affordability_results;
DROP POLICY IF EXISTS "Users can update affordability results" ON affordability_results;
DROP POLICY IF EXISTS "Users can view their affordability results" ON affordability_results;

DROP POLICY IF EXISTS "Admin can do everything" ON affordability_scenarios;
DROP POLICY IF EXISTS "Couples can manage their affordability scenarios" ON affordability_scenarios;
DROP POLICY IF EXISTS "Users can delete affordability scenarios" ON affordability_scenarios;
DROP POLICY IF EXISTS "Users can delete own couple affordability scenarios" ON affordability_scenarios;
DROP POLICY IF EXISTS "Users can insert affordability scenarios" ON affordability_scenarios;
DROP POLICY IF EXISTS "Users can insert own couple affordability scenarios" ON affordability_scenarios;
DROP POLICY IF EXISTS "Users can update affordability scenarios" ON affordability_scenarios;
DROP POLICY IF EXISTS "Users can update own couple affordability scenarios" ON affordability_scenarios;
DROP POLICY IF EXISTS "Users can view own couple affordability scenarios" ON affordability_scenarios;
DROP POLICY IF EXISTS "Users can view their affordability scenarios" ON affordability_scenarios;

DROP POLICY IF EXISTS "Admin can do everything" ON affordability_gifts_contributions;
DROP POLICY IF EXISTS "Couples can manage their gift contributions" ON affordability_gifts_contributions;
DROP POLICY IF EXISTS "Users can delete affordability gifts contributions" ON affordability_gifts_contributions;
DROP POLICY IF EXISTS "Users can delete own couple contributions" ON affordability_gifts_contributions;
DROP POLICY IF EXISTS "Users can insert affordability gifts contributions" ON affordability_gifts_contributions;
DROP POLICY IF EXISTS "Users can insert own couple contributions" ON affordability_gifts_contributions;
DROP POLICY IF EXISTS "Users can update affordability gifts contributions" ON affordability_gifts_contributions;
DROP POLICY IF EXISTS "Users can update own couple contributions" ON affordability_gifts_contributions;
DROP POLICY IF EXISTS "Users can view own couple contributions" ON affordability_gifts_contributions;
DROP POLICY IF EXISTS "Users can view their affordability gifts contributions" ON affordability_gifts_contributions;

DROP POLICY IF EXISTS "Admin can do everything" ON gifts_and_owed;
DROP POLICY IF EXISTS "Couples can manage their gifts and owed records" ON gifts_and_owed;
DROP POLICY IF EXISTS "Users can delete gifts and owed" ON gifts_and_owed;
DROP POLICY IF EXISTS "Users can delete own couple gifts" ON gifts_and_owed;
DROP POLICY IF EXISTS "Users can insert gifts and owed" ON gifts_and_owed;
DROP POLICY IF EXISTS "Users can insert own couple gifts" ON gifts_and_owed;
DROP POLICY IF EXISTS "Users can update gifts and owed" ON gifts_and_owed;
DROP POLICY IF EXISTS "Users can update own couple gifts" ON gifts_and_owed;
DROP POLICY IF EXISTS "Users can view own couple gifts" ON gifts_and_owed;
DROP POLICY IF EXISTS "Users can view their gifts and owed" ON gifts_and_owed;

DROP POLICY IF EXISTS "Enable delete for authenticated users" ON gift_received;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON gift_received;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON gift_received;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON gift_received;

DROP POLICY IF EXISTS "Enable delete for authenticated users" ON money_owed;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON money_owed;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON money_owed;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON money_owed;

-- Vendor Tables
DROP POLICY IF EXISTS "Admin can do everything" ON vendor_information;
DROP POLICY IF EXISTS "Couples can manage their vendor information" ON vendor_information;
DROP POLICY IF EXISTS "Users can delete own couple vendors" ON vendor_information;
DROP POLICY IF EXISTS "Users can delete vendors" ON vendor_information;
DROP POLICY IF EXISTS "Users can insert own couple vendors" ON vendor_information;
DROP POLICY IF EXISTS "Users can insert vendors" ON vendor_information;
DROP POLICY IF EXISTS "Users can update own couple vendors" ON vendor_information;
DROP POLICY IF EXISTS "Users can update vendors" ON vendor_information;
DROP POLICY IF EXISTS "Users can view own couple vendors" ON vendor_information;
DROP POLICY IF EXISTS "Users can view their vendors" ON vendor_information;

DROP POLICY IF EXISTS "Admin can do everything" ON vendor_contacts;
DROP POLICY IF EXISTS "Couples can manage their vendor contacts" ON vendor_contacts;
DROP POLICY IF EXISTS "Users can delete vendor contacts" ON vendor_contacts;
DROP POLICY IF EXISTS "Users can insert vendor contacts" ON vendor_contacts;
DROP POLICY IF EXISTS "Users can update vendor contacts" ON vendor_contacts;
DROP POLICY IF EXISTS "Users can view their vendor contacts" ON vendor_contacts;

DROP POLICY IF EXISTS "Admin can do everything" ON vendor_documents;
DROP POLICY IF EXISTS "Couples can manage their vendor documents" ON vendor_documents;
DROP POLICY IF EXISTS "Users can delete vendor documents" ON vendor_documents;
DROP POLICY IF EXISTS "Users can insert vendor documents" ON vendor_documents;
DROP POLICY IF EXISTS "Users can update vendor documents" ON vendor_documents;
DROP POLICY IF EXISTS "Users can view their vendor documents" ON vendor_documents;

DROP POLICY IF EXISTS "Admin can do everything" ON vendor_reviews;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON vendor_reviews;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON vendor_reviews;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON vendor_reviews;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON vendor_reviews;
DROP POLICY IF EXISTS "Users can delete own couple vendor reviews" ON vendor_reviews;
DROP POLICY IF EXISTS "Users can delete vendor reviews" ON vendor_reviews;
DROP POLICY IF EXISTS "Users can insert own couple vendor reviews" ON vendor_reviews;
DROP POLICY IF EXISTS "Users can insert vendor reviews" ON vendor_reviews;
DROP POLICY IF EXISTS "Users can update own couple vendor reviews" ON vendor_reviews;
DROP POLICY IF EXISTS "Users can update vendor reviews" ON vendor_reviews;
DROP POLICY IF EXISTS "Users can view own couple vendor reviews" ON vendor_reviews;
DROP POLICY IF EXISTS "Users can view their vendor reviews" ON vendor_reviews;

DROP POLICY IF EXISTS "Admin can do everything" ON vendor_contact_communications;
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON vendor_contact_communications;
DROP POLICY IF EXISTS "Users can delete vendor contact communications" ON vendor_contact_communications;
DROP POLICY IF EXISTS "Users can insert vendor contact communications" ON vendor_contact_communications;
DROP POLICY IF EXISTS "Users can update vendor contact communications" ON vendor_contact_communications;
DROP POLICY IF EXISTS "Users can view their vendor contact communications" ON vendor_contact_communications;

DROP POLICY IF EXISTS "Users can delete custom categories for their couple" ON vendor_custom_categories;
DROP POLICY IF EXISTS "Users can insert custom categories for their couple" ON vendor_custom_categories;
DROP POLICY IF EXISTS "Users can update custom categories for their couple" ON vendor_custom_categories;
DROP POLICY IF EXISTS "Users can view custom categories for their couple" ON vendor_custom_categories;

-- Task and Timeline Tables
DROP POLICY IF EXISTS "Admin can do everything" ON wedding_tasks;
DROP POLICY IF EXISTS "Couples can manage their wedding tasks" ON wedding_tasks;
DROP POLICY IF EXISTS "Users can delete tasks" ON wedding_tasks;
DROP POLICY IF EXISTS "Users can insert tasks" ON wedding_tasks;
DROP POLICY IF EXISTS "Users can update tasks" ON wedding_tasks;
DROP POLICY IF EXISTS "Users can view their tasks" ON wedding_tasks;

DROP POLICY IF EXISTS "Admin can do everything" ON wedding_subtasks;
DROP POLICY IF EXISTS "Users can delete subtasks" ON wedding_subtasks;
DROP POLICY IF EXISTS "Users can delete their own wedding subtasks" ON wedding_subtasks;
DROP POLICY IF EXISTS "Users can insert subtasks" ON wedding_subtasks;
DROP POLICY IF EXISTS "Users can insert their own wedding subtasks" ON wedding_subtasks;
DROP POLICY IF EXISTS "Users can update subtasks" ON wedding_subtasks;
DROP POLICY IF EXISTS "Users can update their own wedding subtasks" ON wedding_subtasks;
DROP POLICY IF EXISTS "Users can view their own wedding subtasks" ON wedding_subtasks;
DROP POLICY IF EXISTS "Users can view their subtasks" ON wedding_subtasks;

DROP POLICY IF EXISTS "Admin can do everything" ON wedding_timeline;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON wedding_timeline;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON wedding_timeline;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON wedding_timeline;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON wedding_timeline;
DROP POLICY IF EXISTS "Users can delete wedding timeline" ON wedding_timeline;
DROP POLICY IF EXISTS "Users can insert wedding timeline" ON wedding_timeline;
DROP POLICY IF EXISTS "Users can update wedding timeline" ON wedding_timeline;
DROP POLICY IF EXISTS "Users can view their wedding timeline" ON wedding_timeline;

DROP POLICY IF EXISTS "Admin can do everything" ON wedding_events;
DROP POLICY IF EXISTS "Couples can manage their wedding events" ON wedding_events;
DROP POLICY IF EXISTS "Users can delete own couple events" ON wedding_events;
DROP POLICY IF EXISTS "Users can delete wedding events" ON wedding_events;
DROP POLICY IF EXISTS "Users can insert own couple events" ON wedding_events;
DROP POLICY IF EXISTS "Users can insert wedding events" ON wedding_events;
DROP POLICY IF EXISTS "Users can update own couple events" ON wedding_events;
DROP POLICY IF EXISTS "Users can update wedding events" ON wedding_events;
DROP POLICY IF EXISTS "Users can view own couple events" ON wedding_events;
DROP POLICY IF EXISTS "Users can view their wedding events" ON wedding_events;

DROP POLICY IF EXISTS "Admins can manage all milestones" ON wedding_milestones;
DROP POLICY IF EXISTS "Users can create milestones in their tenant" ON wedding_milestones;
DROP POLICY IF EXISTS "Users can view milestones in their tenant" ON wedding_milestones;

-- Document and Communication Tables
DROP POLICY IF EXISTS "Admin can do everything" ON documents;
DROP POLICY IF EXISTS "Couples can manage their documents" ON documents;
DROP POLICY IF EXISTS "Users can create documents" ON documents;
DROP POLICY IF EXISTS "Users can delete documents" ON documents;
DROP POLICY IF EXISTS "Users can insert documents" ON documents;
DROP POLICY IF EXISTS "Users can update documents" ON documents;
DROP POLICY IF EXISTS "Users can view their documents" ON documents;

DROP POLICY IF EXISTS "Admin can do everything" ON communication_templates;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON communication_templates;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON communication_templates;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON communication_templates;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON communication_templates;
DROP POLICY IF EXISTS "Users can delete communication templates" ON communication_templates;
DROP POLICY IF EXISTS "Users can insert communication templates" ON communication_templates;
DROP POLICY IF EXISTS "Users can update communication templates" ON communication_templates;
DROP POLICY IF EXISTS "Users can view their communication templates" ON communication_templates;

-- Seating and Meal Tables
DROP POLICY IF EXISTS "Admin can do everything" ON seating_charts;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON seating_charts;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON seating_charts;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON seating_charts;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON seating_charts;
DROP POLICY IF EXISTS "Users can delete seating charts" ON seating_charts;
DROP POLICY IF EXISTS "Users can insert seating charts" ON seating_charts;
DROP POLICY IF EXISTS "Users can update seating charts" ON seating_charts;
DROP POLICY IF EXISTS "Users can view their seating charts" ON seating_charts;

DROP POLICY IF EXISTS "Admin can do everything" ON seating_tables;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON seating_tables;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON seating_tables;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON seating_tables;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON seating_tables;
DROP POLICY IF EXISTS "Users can delete seating tables" ON seating_tables;
DROP POLICY IF EXISTS "Users can insert seating tables" ON seating_tables;
DROP POLICY IF EXISTS "Users can update seating tables" ON seating_tables;
DROP POLICY IF EXISTS "Users can view their seating tables" ON seating_tables;

DROP POLICY IF EXISTS "Admin can do everything" ON seat_assignments;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON seat_assignments;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON seat_assignments;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON seat_assignments;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON seat_assignments;
DROP POLICY IF EXISTS "Users can delete seat assignments" ON seat_assignments;
DROP POLICY IF EXISTS "Users can insert seat assignments" ON seat_assignments;
DROP POLICY IF EXISTS "Users can update seat assignments" ON seat_assignments;
DROP POLICY IF EXISTS "Users can view their seat assignments" ON seat_assignments;

DROP POLICY IF EXISTS "Admin can do everything" ON meal_options;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON meal_options;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON meal_options;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON meal_options;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON meal_options;
DROP POLICY IF EXISTS "Users can delete meal options" ON meal_options;
DROP POLICY IF EXISTS "Users can insert meal options" ON meal_options;
DROP POLICY IF EXISTS "Users can update meal options" ON meal_options;
DROP POLICY IF EXISTS "Users can view their meal options" ON meal_options;

DROP POLICY IF EXISTS "Admin can do everything" ON meal_dietary_mapping_rules;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON meal_dietary_mapping_rules;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON meal_dietary_mapping_rules;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON meal_dietary_mapping_rules;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON meal_dietary_mapping_rules;
DROP POLICY IF EXISTS "Users can delete meal dietary mapping rules" ON meal_dietary_mapping_rules;
DROP POLICY IF EXISTS "Users can insert meal dietary mapping rules" ON meal_dietary_mapping_rules;
DROP POLICY IF EXISTS "Users can update meal dietary mapping rules" ON meal_dietary_mapping_rules;
DROP POLICY IF EXISTS "Users can view their meal dietary mapping rules" ON meal_dietary_mapping_rules;

DROP POLICY IF EXISTS "Admin can do everything" ON preparation_schedule;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON preparation_schedule;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON preparation_schedule;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON preparation_schedule;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON preparation_schedule;
DROP POLICY IF EXISTS "Users can delete preparation schedule" ON preparation_schedule;
DROP POLICY IF EXISTS "Users can insert preparation schedule" ON preparation_schedule;
DROP POLICY IF EXISTS "Users can update preparation schedule" ON preparation_schedule;
DROP POLICY IF EXISTS "Users can view their preparation schedule" ON preparation_schedule;

DROP POLICY IF EXISTS "Admin can do everything" ON rsvp_workflow;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON rsvp_workflow;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON rsvp_workflow;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON rsvp_workflow;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON rsvp_workflow;
DROP POLICY IF EXISTS "Users can delete rsvp workflow" ON rsvp_workflow;
DROP POLICY IF EXISTS "Users can insert rsvp workflow" ON rsvp_workflow;
DROP POLICY IF EXISTS "Users can update rsvp workflow" ON rsvp_workflow;
DROP POLICY IF EXISTS "Users can view their rsvp workflow" ON rsvp_workflow;

-- Payment and Settings Tables
DROP POLICY IF EXISTS "Admin can do everything" ON payment_plans;
DROP POLICY IF EXISTS "Allow development inserts" ON payment_plans;
DROP POLICY IF EXISTS "Users can delete own couple payments" ON payment_plans;
DROP POLICY IF EXISTS "Users can delete payments" ON payment_plans;
DROP POLICY IF EXISTS "Users can insert own couple payments" ON payment_plans;
DROP POLICY IF EXISTS "Users can insert payments" ON payment_plans;
DROP POLICY IF EXISTS "Users can update own couple payments" ON payment_plans;
DROP POLICY IF EXISTS "Users can update payments" ON payment_plans;
DROP POLICY IF EXISTS "Users can view own couple payments" ON payment_plans;
DROP POLICY IF EXISTS "Users can view payments" ON payment_plans;

DROP POLICY IF EXISTS "Admin can do everything" ON couple_settings;
DROP POLICY IF EXISTS "Service role can manage all couple settings" ON couple_settings;
DROP POLICY IF EXISTS "Users can delete settings" ON couple_settings;
DROP POLICY IF EXISTS "Users can delete their own couple settings" ON couple_settings;
DROP POLICY IF EXISTS "Users can insert settings" ON couple_settings;
DROP POLICY IF EXISTS "Users can insert their own couple settings" ON couple_settings;
DROP POLICY IF EXISTS "Users can update settings" ON couple_settings;
DROP POLICY IF EXISTS "Users can update their own couple settings" ON couple_settings;
DROP POLICY IF EXISTS "Users can view their own couple settings" ON couple_settings;
DROP POLICY IF EXISTS "Users can view their settings" ON couple_settings;

DROP POLICY IF EXISTS "Users can manage tenant cash flow data" ON monthly_cash_flow;
DROP POLICY IF EXISTS "Users can modify tenant cash flow data" ON monthly_cash_flow;

-- Notes and Reminders
DROP POLICY IF EXISTS "Admins can manage all notes" ON notes;
DROP POLICY IF EXISTS "Users can create notes in their tenant" ON notes;
DROP POLICY IF EXISTS "Users can delete notes in their tenant" ON notes;
DROP POLICY IF EXISTS "Users can update notes in their tenant" ON notes;
DROP POLICY IF EXISTS "Users can view notes in their tenant" ON notes;

DROP POLICY IF EXISTS "Admins can manage all reminders" ON reminders;
DROP POLICY IF EXISTS "Users can create reminders in their tenant" ON reminders;
DROP POLICY IF EXISTS "Users can delete reminders in their tenant" ON reminders;
DROP POLICY IF EXISTS "Users can update reminders in their tenant" ON reminders;
DROP POLICY IF EXISTS "Users can view reminders in their tenant" ON reminders;

-- ============================================================================
-- PART 2: CREATE CONSOLIDATED POLICIES (1 per table)
-- ============================================================================

-- Guest Management Tables
CREATE POLICY "couples_manage_own_guests"
  ON guest_list
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_guest_groups"
  ON guest_groups
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_guest_communications"
  ON guest_communications
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_guest_meal_selections"
  ON guest_meal_selections
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

-- Budget Tables
CREATE POLICY "couples_manage_own_budget_categories"
  ON budget_categories
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_expenses"
  ON expenses
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_expense_allocations"
  ON expense_budget_allocations
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_expense_line_items"
  ON expense_line_items
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_budget_settings"
  ON budget_settings
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_budget_milestones"
  ON budget_milestones
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_budget_development_items"
  ON budget_development_items
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_budget_development_scenarios"
  ON budget_development_scenarios
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

-- Affordability Tables
CREATE POLICY "couples_manage_own_affordability_inputs"
  ON affordability_inputs
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_affordability_results"
  ON affordability_results
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_affordability_scenarios"
  ON affordability_scenarios
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_gift_contributions"
  ON affordability_gifts_contributions
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_gifts_and_owed"
  ON gifts_and_owed
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_gift_received"
  ON gift_received
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_money_owed"
  ON money_owed
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

-- Vendor Tables
CREATE POLICY "couples_manage_own_vendors"
  ON vendor_information
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_vendor_contacts"
  ON vendor_contacts
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_vendor_documents"
  ON vendor_documents
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_vendor_reviews"
  ON vendor_reviews
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_vendor_contact_communications"
  ON vendor_contact_communications
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_vendor_custom_categories"
  ON vendor_custom_categories
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

-- Task and Timeline Tables
CREATE POLICY "couples_manage_own_tasks"
  ON wedding_tasks
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_subtasks"
  ON wedding_subtasks
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_timeline"
  ON wedding_timeline
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_events"
  ON wedding_events
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_milestones"
  ON wedding_milestones
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

-- Document and Communication Tables
CREATE POLICY "couples_manage_own_documents"
  ON documents
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_communication_templates"
  ON communication_templates
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

-- Seating and Meal Tables
CREATE POLICY "couples_manage_own_seating_charts"
  ON seating_charts
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_seating_tables"
  ON seating_tables
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_seat_assignments"
  ON seat_assignments
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_meal_options"
  ON meal_options
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_meal_dietary_mapping_rules"
  ON meal_dietary_mapping_rules
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_preparation_schedule"
  ON preparation_schedule
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_rsvp_workflow"
  ON rsvp_workflow
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

-- Payment and Settings Tables
CREATE POLICY "couples_manage_own_payment_plans"
  ON payment_plans
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_settings"
  ON couple_settings
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_cash_flow"
  ON monthly_cash_flow
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

-- Notes and Reminders
CREATE POLICY "couples_manage_own_notes"
  ON notes
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

CREATE POLICY "couples_manage_own_reminders"
  ON reminders
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

-- ============================================================================
-- VERIFICATION QUERY
-- ============================================================================

-- Run this to verify consolidation was successful
-- Expected: Each table should have 1 policy (or 2-4 for special cases)
DO $$
DECLARE
  policy_count_record RECORD;
  max_policies INTEGER := 0;
BEGIN
  FOR policy_count_record IN
    SELECT 
      tablename,
      COUNT(*) as policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
    GROUP BY tablename
    HAVING COUNT(*) > 4
    ORDER BY COUNT(*) DESC
  LOOP
    RAISE WARNING 'Table % still has % policies (expected ≤4)', 
      policy_count_record.tablename, 
      policy_count_record.policy_count;
    max_policies := GREATEST(max_policies, policy_count_record.policy_count);
  END LOOP;
  
  IF max_policies = 0 THEN
    RAISE NOTICE '✅ SUCCESS: All tables have ≤4 policies';
  ELSE
    RAISE WARNING '⚠️  Some tables still have excessive policies. Review needed.';
  END IF;
END $$;
