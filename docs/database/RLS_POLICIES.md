# RLS Policy Documentation

**Last Updated**: February 4, 2025  
**Version**: 2.0 (Post-Consolidation)

---

## Overview

This document describes the Row Level Security (RLS) policy structure for the I Do Blueprint database. All policies follow a consistent, secure pattern to ensure proper multi-tenant isolation.

---

## Standard Policy Structure

### Multi-Tenant Tables (with couple_id)

**Pattern**: 1 policy per table using `FOR ALL` operations

```sql
CREATE POLICY "couples_manage_own_{resource}"
  ON {table_name}
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());
```

**Components**:
- **Policy Name**: `couples_manage_own_{resource}` (e.g., `couples_manage_own_guests`)
- **Command**: `FOR ALL` (covers SELECT, INSERT, UPDATE, DELETE)
- **USING Clause**: `couple_id = get_user_couple_id()` (read access)
- **WITH CHECK Clause**: `couple_id = get_user_couple_id()` (write validation)

**Security**:
- ✅ Users can only access their own couple's data
- ✅ Tenant isolation enforced at database level
- ✅ No cross-tenant data leakage possible

---

## Policy Naming Convention

### Format
```
{role}_{action}_{scope}
```

### Examples
- `couples_manage_own_guests` - Couples manage their own guest data
- `couples_manage_own_vendors` - Couples manage their own vendor data
- `couples_manage_own_budget_categories` - Couples manage their own budget categories

### Components
- **Role**: `couples` (authenticated users managing their wedding)
- **Action**: `manage` (all CRUD operations: create, read, update, delete)
- **Scope**: `own_{resource}` (tenant-scoped to their couple_id)

---

## Policy Inventory

### Guest Management (4 tables)

| Table | Policy Name | Scoping |
|-------|-------------|---------|
| `guest_list` | `couples_manage_own_guests` | `couple_id = get_user_couple_id()` |
| `guest_groups` | `couples_manage_own_guest_groups` | `couple_id = get_user_couple_id()` |
| `guest_communications` | `couples_manage_own_guest_communications` | `couple_id = get_user_couple_id()` |
| `guest_meal_selections` | `couples_manage_own_guest_meal_selections` | `couple_id = get_user_couple_id()` |

### Budget (8 tables)

| Table | Policy Name | Scoping |
|-------|-------------|---------|
| `budget_categories` | `couples_manage_own_budget_categories` | `couple_id = get_user_couple_id()` |
| `expenses` | `couples_manage_own_expenses` | `couple_id = get_user_couple_id()` |
| `expense_budget_allocations` | `couples_manage_own_expense_allocations` | `couple_id = get_user_couple_id()` |
| `expense_line_items` | `couples_manage_own_expense_line_items` | `couple_id = get_user_couple_id()` |
| `budget_settings` | `couples_manage_own_budget_settings` | `couple_id = get_user_couple_id()` |
| `budget_milestones` | `couples_manage_own_budget_milestones` | `couple_id = get_user_couple_id()` |
| `budget_development_items` | `couples_manage_own_budget_development_items` | `couple_id = get_user_couple_id()` |
| `budget_development_scenarios` | `couples_manage_own_budget_development_scenarios` | `couple_id = get_user_couple_id()` |

### Affordability (7 tables)

| Table | Policy Name | Scoping |
|-------|-------------|---------|
| `affordability_inputs` | `couples_manage_own_affordability_inputs` | `couple_id = get_user_couple_id()` |
| `affordability_results` | `couples_manage_own_affordability_results` | `couple_id = get_user_couple_id()` |
| `affordability_scenarios` | `couples_manage_own_affordability_scenarios` | `couple_id = get_user_couple_id()` |
| `affordability_gifts_contributions` | `couples_manage_own_gift_contributions` | `couple_id = get_user_couple_id()` |
| `gifts_and_owed` | `couples_manage_own_gifts_and_owed` | `couple_id = get_user_couple_id()` |
| `gift_received` | `couples_manage_own_gift_received` | `couple_id = get_user_couple_id()` |
| `money_owed` | `couples_manage_own_money_owed` | `couple_id = get_user_couple_id()` |

### Vendors (6 tables)

| Table | Policy Name | Scoping |
|-------|-------------|---------|
| `vendor_information` | `couples_manage_own_vendors` | `couple_id = get_user_couple_id()` |
| `vendor_contacts` | `couples_manage_own_vendor_contacts` | `couple_id = get_user_couple_id()` |
| `vendor_documents` | `couples_manage_own_vendor_documents` | `couple_id = get_user_couple_id()` |
| `vendor_reviews` | `couples_manage_own_vendor_reviews` | `couple_id = get_user_couple_id()` |
| `vendor_contact_communications` | `couples_manage_own_vendor_contact_communications` | `couple_id = get_user_couple_id()` |
| `vendor_custom_categories` | `couples_manage_own_vendor_custom_categories` | `couple_id = get_user_couple_id()` |

### Tasks & Timeline (5 tables)

| Table | Policy Name | Scoping |
|-------|-------------|---------|
| `wedding_tasks` | `couples_manage_own_tasks` | `couple_id = get_user_couple_id()` |
| `wedding_subtasks` | `couples_manage_own_subtasks` | `couple_id = get_user_couple_id()` |
| `wedding_timeline` | `couples_manage_own_timeline` | `couple_id = get_user_couple_id()` |
| `wedding_events` | `couples_manage_own_events` | `couple_id = get_user_couple_id()` |
| `wedding_milestones` | `couples_manage_own_milestones` | `couple_id = get_user_couple_id()` |

### Documents (2 tables)

| Table | Policy Name | Scoping |
|-------|-------------|---------|
| `documents` | `couples_manage_own_documents` | `couple_id = get_user_couple_id()` |
| `communication_templates` | `couples_manage_own_communication_templates` | `couple_id = get_user_couple_id()` |

### Seating & Meals (7 tables)

| Table | Policy Name | Scoping |
|-------|-------------|---------|
| `seating_charts` | `couples_manage_own_seating_charts` | `couple_id = get_user_couple_id()` |
| `seating_tables` | `couples_manage_own_seating_tables` | `couple_id = get_user_couple_id()` |
| `seat_assignments` | `couples_manage_own_seat_assignments` | `couple_id = get_user_couple_id()` |
| `meal_options` | `couples_manage_own_meal_options` | `couple_id = get_user_couple_id()` |
| `meal_dietary_mapping_rules` | `couples_manage_own_meal_dietary_mapping_rules` | `couple_id = get_user_couple_id()` |
| `preparation_schedule` | `couples_manage_own_preparation_schedule` | `couple_id = get_user_couple_id()` |
| `rsvp_workflow` | `couples_manage_own_rsvp_workflow` | `couple_id = get_user_couple_id()` |

### Payments & Settings (3 tables)

| Table | Policy Name | Scoping |
|-------|-------------|---------|
| `payment_plans` | `couples_manage_own_payment_plans` | `couple_id = get_user_couple_id()` |
| `couple_settings` | `couples_manage_own_settings` | `couple_id = get_user_couple_id()` |
| `monthly_cash_flow` | `couples_manage_own_cash_flow` | `couple_id = get_user_couple_id()` |

### Notes (2 tables)

| Table | Policy Name | Scoping |
|-------|-------------|---------|
| `notes` | `couples_manage_own_notes` | `couple_id = get_user_couple_id()` |
| `reminders` | `couples_manage_own_reminders` | `couple_id = get_user_couple_id()` |

---

## Shared/Reference Tables

### Tables Without couple_id

Some tables are shared across all users or are reference data:

| Table | Policy Pattern | Notes |
|-------|----------------|-------|
| `vendor_types` | Read-only for authenticated users | System reference data |
| `subscription_plans` | Read-only for authenticated users | System reference data |
| `feature_flags` | Read-only for all users | System configuration |
| `roles` | Service role only | RBAC configuration |
| `users_roles` | Service role only | RBAC assignments |

**Pattern for Reference Tables**:
```sql
CREATE POLICY "authenticated_users_read_only"
  ON {table_name}
  FOR SELECT
  USING (auth.role() = 'authenticated');
```

---

## Helper Functions

### get_user_couple_id()

Returns the couple_id for the currently authenticated user.

```sql
CREATE OR REPLACE FUNCTION get_user_couple_id()
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
  SELECT couple_id 
  FROM couple_profiles 
  WHERE id = auth.uid()
  LIMIT 1;
$$;
```

**Usage**: Used in all RLS policies to scope data to the current user's couple.

### can_user_access_tenant(tenant_id uuid)

Checks if the current user can access a specific tenant.

```sql
CREATE OR REPLACE FUNCTION can_user_access_tenant(tenant_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 
    FROM couple_profiles 
    WHERE id = auth.uid() 
      AND couple_id = tenant_id
  );
$$;
```

**Usage**: Used for additional validation in complex scenarios.

---

## Adding New Tables

### Checklist for New Multi-Tenant Tables

When adding a new table with `couple_id`:

1. **Enable RLS**:
   ```sql
   ALTER TABLE {table_name} ENABLE ROW LEVEL SECURITY;
   ```

2. **Create Policy**:
   ```sql
   CREATE POLICY "couples_manage_own_{resource}"
     ON {table_name}
     FOR ALL
     USING (couple_id = get_user_couple_id())
     WITH CHECK (couple_id = get_user_couple_id());
   ```

3. **Test Policy**:
   ```sql
   -- Test read own data (should succeed)
   SELECT * FROM {table_name} WHERE couple_id = get_user_couple_id();
   
   -- Test write own data (should succeed)
   INSERT INTO {table_name} (couple_id, ...) VALUES (get_user_couple_id(), ...);
   
   -- Test read other couple's data (should return 0 rows)
   SELECT * FROM {table_name} WHERE couple_id != get_user_couple_id();
   ```

4. **Document Policy**:
   - Add to this document
   - Update migration file
   - Add to test suite

---

## Policy Management Best Practices

### DO ✅

1. **Use consistent naming**: Follow `couples_manage_own_{resource}` pattern
2. **Use FOR ALL**: Simplifies policy management (covers all operations)
3. **Use helper functions**: `get_user_couple_id()` for consistent scoping
4. **Test thoroughly**: Verify tenant isolation before deploying
5. **Document changes**: Update this file when adding/modifying policies
6. **Review regularly**: Quarterly audit of policy counts and effectiveness

### DON'T ❌

1. **Don't create duplicate policies**: One policy per table is sufficient
2. **Don't use overly permissive policies**: Avoid `USING (true)` or `USING (auth.role() = 'authenticated')` on multi-tenant tables
3. **Don't hardcode UUIDs**: Use helper functions instead
4. **Don't skip testing**: Always test tenant isolation
5. **Don't bypass RLS**: Never disable RLS on multi-tenant tables
6. **Don't create policies manually**: Use migrations for all policy changes

---

## Troubleshooting

### Common Issues

#### Issue: "Permission denied for table {table_name}"

**Cause**: RLS is enabled but no policy grants access

**Solution**: Verify policy exists and uses correct scoping:
```sql
SELECT * FROM pg_policies WHERE tablename = '{table_name}';
```

#### Issue: "User can see other couple's data"

**Cause**: Overly permissive policy or missing couple_id check

**Solution**: Verify policy uses `get_user_couple_id()`:
```sql
SELECT policyname, qual, with_check 
FROM pg_policies 
WHERE tablename = '{table_name}';
```

#### Issue: "User cannot insert data"

**Cause**: Missing WITH CHECK clause or incorrect scoping

**Solution**: Ensure policy has WITH CHECK clause:
```sql
CREATE POLICY "couples_manage_own_{resource}"
  ON {table_name}
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());  -- Required for INSERT/UPDATE
```

---

## Testing RLS Policies

### Manual Testing

```sql
-- 1. Set up test user context
SET LOCAL "request.jwt.claims" = '{"sub": "test-user-uuid"}';

-- 2. Test read own data (should succeed)
SELECT * FROM guest_list WHERE couple_id = get_user_couple_id();

-- 3. Test write own data (should succeed)
INSERT INTO guest_list (couple_id, first_name, last_name) 
VALUES (get_user_couple_id(), 'Test', 'Guest');

-- 4. Test read other couple's data (should return 0 rows)
SELECT * FROM guest_list WHERE couple_id != get_user_couple_id();

-- 5. Test write other couple's data (should fail)
INSERT INTO guest_list (couple_id, first_name, last_name) 
VALUES ('00000000-0000-0000-0000-000000000001', 'Malicious', 'Insert');
-- Expected: ERROR: new row violates row-level security policy
```

### Automated Testing

See `I Do BlueprintTests/Integration/RLSPolicyTests.swift` for automated test suite.

---

## Monitoring

### Policy Count Check

Run this query quarterly to ensure no policy proliferation:

```sql
SELECT 
  tablename,
  COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename
HAVING COUNT(*) > 4
ORDER BY COUNT(*) DESC;
```

**Expected**: No results (all tables should have ≤4 policies)

### Policy Audit

```sql
SELECT 
  tablename,
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

---

## References

- **PostgreSQL RLS Documentation**: https://www.postgresql.org/docs/current/ddl-rowsecurity.html
- **Supabase RLS Guide**: https://supabase.com/docs/guides/auth/row-level-security
- **Migration File**: `supabase/migrations/20250204000000_consolidate_duplicate_rls_policies.sql`
- **Consolidation Summary**: `RLS_POLICY_CONSOLIDATION_SUMMARY.md`

---

**Maintained by**: Database Team  
**Review Frequency**: Quarterly  
**Last Audit**: February 4, 2025  
**Next Audit**: May 4, 2025
