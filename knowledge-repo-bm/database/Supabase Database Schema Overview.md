---
title: Supabase Database Schema Overview
type: note
permalink: database/supabase-database-schema-overview
tags:
- database
- supabase
- postgresql
- schema
- migrations
- rls
---

# Supabase Database Schema Overview

## Database Platform

**PostgreSQL** via Supabase with:
- Row Level Security (RLS) enabled on all tables
- Multi-tenant architecture via `couple_id`
- Real-time subscriptions for collaboration
- RPC functions for complex operations
- Automated triggers for calculations

## Migration History

**Total Migrations:** 300+ (from 20250107000000 to 20251228004755)

### Recent Major Migrations (Last 30 Days)

1. **20251228004755** - Add default vendor image URL
2. **20251227184456** - Fix payment plan summaries total payments
3. **20251227182318** - Update payment plan summaries view to use plan_id
4. **20251227182240** - Add payment_plan_id to payment_plans
5. **20251227163210** - Create payment plan summary view
6. **20251227163122** - Backfill payment plan metadata
7. **20251226233507** - Fix update folder totals search path
8. **20251226233447** - Fix calculate folder totals search path
9. **20251226233119** - Fix trigger update folder totals search path
10. **20251226224111** - Fix activity events actor_id nullable

### Major Feature Migrations

#### Budget System (Multiple Phases)
- **20250630194415** - Enhance budget system features
- **20250705120000** - Create budget development scenarios
- **20250706135000** - Merge wedding ceremony/reception categories
- **20250708000000** - Create expense budget item allocations
- **20250710000000** - Add payment plan features
- **20251224053724** - Add budget folder support
- **20251226051353** - Add cached folder totals

#### Multi-Tenancy & Collaboration
- **20250721015153** - Add couple_id to all tables
- **20250724000003** - Create collaboration system
- **20250724000004** - Update RLS policies for collaboration
- **20251024153905** - Create collaboration tables
- **20251024153938** - Create collaboration RLS policies

#### Security Hardening (October 2025)
- **20251019035005** - Fix critical RLS security issues
- **20251019041900** - Refactor high-priority security definer views
- **20251019183208** - Harden critical functions
- **20251019184943** - Optimize all RLS policies phase 4
- **20251022045454** - Fix overly permissive RLS policies
- **20251022052332** - Create log admin action function

#### Payment & Financial Tracking
- **20250701025501** - Add single payment type
- **20250710000000** - Add payment plan features
- **20251227162204** - Fix payment types by vendor
- **20251227163122** - Backfill payment plan metadata

#### Guest Management
- **20250619030733** - Add unique constraint prevent duplicate guests
- **20250619053350** - Add invitation number to guest list
- **20250619060000** - Enhanced guest data model
- **20250125000001** - Add missing guest fields

#### Activity & Realtime
- **20251024154154** - Create collaboration triggers and functions
- **20251026170253** - Fix log activity event trigger
- **20251024154353** - Create pg_cron cleanup jobs

## Core Tables

### Multi-Tenant Tables (All have couple_id)

#### User & Couple Management
- `couple_profiles` - Couple information and wedding details
- `couple_settings` - Application settings per couple
- `tenant_memberships` - User-couple associations
- `collaborators` - Multi-user collaboration
- `collaboration_roles` - Role definitions (owner, editor, viewer)
- `collaboration_invitations` - Pending invitations

#### Guest Management
- `guest_list` - Guest directory with RSVP tracking
- `invitation_numbers` - Invitation grouping
- `meal_preferences` - Guest meal selections
- `dietary_restrictions` - Dietary requirement tracking

#### Vendor Management
- `vendor_information` - Vendor directory
- `vendor_contacts` - Vendor contact details
- `vendor_reviews` - Vendor ratings and reviews
- `vendor_documents` - Vendor-specific documents

#### Budget Management
- `budget_categories` - Budget category definitions
- `budget_development_items` - Budget line items per scenario
- `budget_development_folders` - Hierarchical budget organization
- `budget_scenarios` - Budget "what-if" scenarios
- `expenses` - Actual expense tracking
- `expense_budget_allocations` - Expense-to-budget-item links
- `expense_line_items` - Detailed expense breakdown
- `payment_plans` - Payment schedules
- `gifts_and_owed` - Gift tracking and money owed
- `monthly_cash_flow` - Cash flow projections

#### Task Management
- `tasks` - Wedding task checklist
- `subtasks` - Task breakdown
- `wedding_milestones` - Major milestones

#### Timeline Management
- `timeline` - Event timeline
- `wedding_events` - Event definitions (ceremony, reception, etc.)

#### Document Management
- `documents` - Document metadata
- `document_relationships` - Document dependencies

#### Visual Planning
- `mood_boards` - Mood board collections
- `mood_board_images` - Mood board image items
- `color_palettes` - Color scheme management
- `color_palette_colors` - Individual colors in palettes
- `seating_charts` - Seating arrangement plans
- `seating_chart_tables` - Table definitions
- `seating_chart_assignments` - Guest-to-table assignments

#### Activity & Collaboration
- `activity_events` - Activity log for collaboration
- `collaborator_presence` - Real-time presence tracking

#### Affordability Calculator
- `affordability_scenarios` - Budget affordability scenarios
- `affordability_results` - Scenario calculation results
- `affordability_contributions` - Contribution tracking

#### Notes & Reminders
- `notes` - Notes system
- `reminders` - Reminder/notification system

### Administrative Tables
- `admin_roles` - Administrative role assignments
- `admin_audit_log` - Admin action audit trail

## Key Schema Patterns

### 1. Multi-Tenancy with couple_id

**All data tables** include `couple_id UUID` column:
```sql
ALTER TABLE guest_list ADD COLUMN couple_id UUID REFERENCES couple_profiles(id);
```

**RLS Policy Pattern:**
```sql
CREATE POLICY "couples_manage_own_data"
  ON table_name
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());
```

### 2. Foreign Key Indexes

**Migration:** 20251019035152 - Add missing foreign key indexes
**Migration:** 20251031151430 - Tenant scoping FK indexes

All foreign keys have indexes for performance:
```sql
CREATE INDEX idx_guest_list_couple_id ON guest_list(couple_id);
CREATE INDEX idx_vendor_information_couple_id ON vendor_information(couple_id);
```

### 3. Timestamp Tracking

All tables have:
- `created_at TIMESTAMPTZ DEFAULT now()`
- `updated_at TIMESTAMPTZ DEFAULT now()`

With automatic update trigger:
```sql
CREATE TRIGGER update_table_updated_at
  BEFORE UPDATE ON table_name
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### 4. Soft Deletes & Archiving

Some tables support archiving:
- `vendor_information.is_archived` - Archive old vendors
- `tasks.status` - Completed/archived tasks

### 5. Scenario Isolation

Budget system uses scenario-based isolation:
- `budget_development_items.scenario_id` - Scenario grouping
- `expense_budget_allocations.scenario_id` - Scenario-specific allocations
- Unique constraints per scenario: `(expense_id, budget_item_id, scenario_id)`

## Critical RPC Functions

### Authentication & Authorization
- `get_user_couple_id()` - Get couple_id for current user
- `get_user_couple_ids()` - Get all couples user has access to
- `user_has_permission(couple_id, permission)` - Permission check
- `can_user_access_scenario(scenario_id)` - Scenario access check

### Budget Calculations
- `save_budget_scenario_with_items()` - Atomic scenario save
- `calculate_proportional_split_by_scenario()` - Allocation calculation
- `validate_expense_allocation_by_scenario()` - Allocation validation
- `update_folder_totals()` - Recalculate folder sums
- `calculate_folder_totals()` - Calculate folder totals

### Collaboration
- `accept_invitation()` - Accept collaboration invite
- `create_owner_collaborator()` - Create initial owner
- `get_members_with_profiles()` - Fetch team members

### Deletion & Cleanup
- `hierarchical_deletion()` - Cascading delete with tracking
- `atomic_unlink_expense()` - Safely unlink expenses
- `reset_couple_data()` - Reset all data for couple (testing)

### Visual Planning
- `get_wedding_events()` - Fetch event definitions
- `fetch_palettes()` - Fetch color palettes

## Views (Security Definer)

**Note:** Security definer views refactored for safety (Migration 20251019041900)

- `payment_plan_summaries` - Payment plan overview
- `budget_overview_view` - Budget summary
- `user_profiles_view` - User profile data

## Storage Buckets

- `invoices` - Invoice document storage
- `documents` - General document storage
- `mood_board_images` - Mood board image storage

## Real-time Channels

Subscriptions available for:
- `collaborators` - Collaborator changes
- `activity_events` - Activity feed
- `collaborator_presence` - Presence updates
- `guest_list` - Guest changes (optional)
- `vendor_information` - Vendor changes (optional)

## Performance Optimizations

### Indexes
- Foreign key indexes on all `couple_id` columns
- Composite indexes for common queries
- Unique constraints for data integrity

### Materialized Views
- Cached folder totals in `budget_development_folders`
- Payment plan summaries view

### Triggers for Auto-Calculation
- `update_updated_at_column()` - Timestamp updates
- `update_folder_totals_trigger()` - Budget folder totals
- `validate_expense_allocation_trigger()` - Allocation validation
- `log_activity_event()` - Activity logging

## Schema Evolution Notes

### Major Refactorings
1. **Table Naming** - Migrated from camelCase to snake_case (20251019194547)
2. **RLS Hardening** - Multiple phases of security tightening (Oct 2025)
3. **Scenario Isolation** - Added scenario_id to allocations (Aug 2025)
4. **Collaboration System** - Full RBAC implementation (Oct 2025)

### Data Migrations
- **20251021165505** - Migrate all data to current couple
- **20251022215332** - Migrate data to correct couple_id
- **20251227163122** - Backfill payment plan metadata

## References
- Migration count: 300+
- First migration: 20250107000000
- Latest migration: 20251228004755
- Related Issue: I Do Blueprint (database schema documentation)
- Security hardening: October 2025 migration series