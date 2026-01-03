---
title: Security Architecture - Multi-Tenancy and RLS
type: note
permalink: security/security-architecture-multi-tenancy-and-rls
tags:
- security
- rls
- multi-tenancy
- authentication
- authorization
- rbac
---

# Security Architecture - Multi-Tenancy and Row Level Security

## Overview

I Do Blueprint implements a robust security architecture using:
- **Row Level Security (RLS)** on all database tables
- **Multi-tenant isolation** via `couple_id` column
- **Role-based access control (RBAC)** for collaboration
- **Helper functions** for authorization
- **Supabase authentication** for user management

## Multi-Tenancy Architecture

### Tenant Isolation via couple_id

**All data tables** include a `couple_id UUID` foreign key:

```sql
ALTER TABLE guest_list ADD COLUMN couple_id UUID 
    REFERENCES couple_profiles(id) ON DELETE CASCADE;

CREATE INDEX idx_guest_list_couple_id ON guest_list(couple_id);
```

**Every data table has:**
- Foreign key to `couple_profiles(id)`
- Index on `couple_id` for performance
- RLS policy filtering by `couple_id`

### Core Security Functions

#### get_user_couple_id()

Returns the couple_id for the current authenticated user:

```sql
CREATE OR REPLACE FUNCTION get_user_couple_id()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_couple_id UUID;
BEGIN
    SELECT couple_id INTO v_couple_id
    FROM tenant_memberships
    WHERE user_id = (SELECT auth.uid())
    AND is_active = true
    LIMIT 1;
    
    RETURN v_couple_id;
END;
$$;
```

**Usage in RLS policies:**
```sql
USING (couple_id = get_user_couple_id())
```

#### get_user_couple_ids()

Returns all couple_ids the user has access to (for collaboration):

```sql
CREATE OR REPLACE FUNCTION get_user_couple_ids()
RETURNS UUID[]
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN ARRAY(
        SELECT DISTINCT couple_id
        FROM collaborators
        WHERE user_id = (SELECT auth.uid())
        AND status = 'active'
    );
END;
$$;
```

**Usage in RLS policies:**
```sql
USING (couple_id IN (SELECT unnest(get_user_couple_ids())))
```

## Row Level Security (RLS) Patterns

### Standard RLS Policy Pattern

**All multi-tenant tables** use this pattern:

```sql
-- Enable RLS
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;

-- Create policy
CREATE POLICY "Couples manage their own data"
    ON table_name
    FOR ALL
    USING (couple_id = get_user_couple_id())
    WITH CHECK (couple_id = get_user_couple_id());
```

**Components:**
- `FOR ALL` - Applies to SELECT, INSERT, UPDATE, DELETE
- `USING` - Read filter (what can be read)
- `WITH CHECK` - Write filter (what can be written)

### Migration History - RLS Hardening

**October 2025 - Major Security Hardening:**

1. **20251019035005** - Fix critical RLS security issues
2. **20251019041900** - Refactor high-priority security definer views
3. **20251019183208** - Harden critical functions
4. **20251019184943** - Optimize all RLS policies phase 4
5. **20251022045454** - Fix overly permissive RLS policies
6. **20251022045634** - Remove remaining permissive policies

**February 2025 - Performance Optimization:**

**20250203000000** - Fix RLS auth.uid() performance
- **Problem:** `auth.uid()` called once per row (1000 rows = 1000 calls)
- **Solution:** Use `(SELECT auth.uid())` to call once per query
- **Impact:** 50-90% faster queries

Before (slow):
```sql
USING (user_id = auth.uid())
```

After (fast):
```sql
USING (user_id = (SELECT auth.uid()))
```

**February 2025 - Policy Consolidation:**

**20250204000000** - Consolidate duplicate RLS policies
- Reduced 13-16 policies per table down to 1 consolidated policy
- Simplified maintenance and improved performance

## Role-Based Access Control (RBAC)

### Collaboration System

**Tables:**
- `collaboration_roles` - Role definitions
- `collaborators` - User-couple-role associations
- `collaboration_invitations` - Pending invitations

**Role Types:**
1. **Owner** - Full access, can manage roles
2. **Editor** - Edit permissions, cannot manage roles
3. **Viewer** - Read-only access

### Permission Check Function

```sql
CREATE OR REPLACE FUNCTION user_has_permission(
    p_couple_id UUID,
    p_permission TEXT
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_has_permission BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1
        FROM collaborators c
        JOIN collaboration_roles r ON c.role_id = r.id
        WHERE c.couple_id = p_couple_id
        AND c.user_id = (SELECT auth.uid())
        AND c.status = 'active'
        AND p_permission = ANY(r.permissions)
    ) INTO v_has_permission;
    
    RETURN v_has_permission;
END;
$$;
```

**Usage in RLS policies:**
```sql
CREATE POLICY "Users with can_invite can create invitations"
    ON invitations
    FOR INSERT
    WITH CHECK (
        user_has_permission(couple_id, 'can_invite')
    );
```

### Available Permissions

- `can_view` - View data
- `can_edit` - Edit data
- `can_delete` - Delete data
- `can_invite` - Invite collaborators
- `can_manage_roles` - Manage user roles
- `can_manage_settings` - Manage couple settings

## RLS Policy Examples

### Guest List

```sql
ALTER TABLE guest_list ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Couples manage their guest list"
    ON guest_list
    FOR ALL
    USING (couple_id = get_user_couple_id())
    WITH CHECK (couple_id = get_user_couple_id());
```

### Vendor Information

```sql
ALTER TABLE vendor_information ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Couples manage their vendors"
    ON vendor_information
    FOR ALL
    USING (couple_id = get_user_couple_id())
    WITH CHECK (couple_id = get_user_couple_id());
```

### Budget Categories

```sql
ALTER TABLE budget_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Couples manage their budget categories"
    ON budget_categories
    FOR ALL
    USING (couple_id = get_user_couple_id())
    WITH CHECK (couple_id = get_user_couple_id());
```

### Collaborators (Permission-Based)

```sql
-- View collaborators
CREATE POLICY "Users can view collaborators for their couple"
    ON collaborators
    FOR SELECT
    USING (
        couple_id IN (SELECT unnest(get_user_couple_ids()))
    );

-- Manage collaborators (requires permission)
CREATE POLICY "Users with can_manage_roles can delete collaborators"
    ON collaborators
    FOR DELETE
    USING (
        user_has_permission(couple_id, 'can_manage_roles')
    );
```

## Admin System

### Admin Roles Table

```sql
CREATE TABLE admin_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    role_name TEXT NOT NULL CHECK (role_name IN ('super_admin', 'support_admin')),
    is_active BOOLEAN NOT NULL DEFAULT true,
    UNIQUE(user_id, role_name)
);

ALTER TABLE admin_roles ENABLE ROW LEVEL SECURITY;

-- Only super admins can manage admin roles
CREATE POLICY "super_admins_manage_admin_roles"
    ON admin_roles
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM admin_roles ar
            WHERE ar.user_id = (SELECT auth.uid())
            AND ar.role_name = 'super_admin'
            AND ar.is_active = true
        )
    );
```

### Admin Audit Log

**Migration:** 20251022052332 - Create log admin action function

Logs all administrative actions for compliance:

```sql
CREATE TABLE admin_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID NOT NULL REFERENCES auth.users(id),
    action_type TEXT NOT NULL,
    target_table TEXT,
    target_record_id UUID,
    details JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

## Security Best Practices

### ✅ Do's

1. **Always filter by couple_id** - All queries must scope by tenant
2. **Use helper functions** - `get_user_couple_id()` for consistency
3. **Enable RLS on all tables** - No exceptions for data tables
4. **Use indexes on couple_id** - Performance is critical
5. **Use (SELECT auth.uid())** - Not `auth.uid()` directly (performance)
6. **Validate permissions** - Use `user_has_permission()` for RBAC
7. **Log admin actions** - Audit trail for compliance
8. **Use security definer carefully** - Only when necessary
9. **Test RLS policies** - Verify isolation in tests
10. **Use cascading deletes** - `ON DELETE CASCADE` for referential integrity

### ❌ Don'ts

1. **Don't skip RLS** - Every table must have RLS enabled
2. **Don't use overly permissive policies** - Avoid `FOR ALL TO authenticated`
3. **Don't call auth.uid() per row** - Use `(SELECT auth.uid())`
4. **Don't expose data across tenants** - Always filter by couple_id
5. **Don't hardcode UUIDs** - Use role-based checks instead
6. **Don't bypass RLS** - Even for admin operations (use proper roles)
7. **Don't forget indexes** - All `couple_id` columns need indexes
8. **Don't skip security definer validation** - Validate inputs in functions
9. **Don't expose service_role key** - Client apps use anon key only

## Client-Side Security

### Supabase Configuration

**File:** `Core/Configuration/AppConfig.swift`

```swift
enum AppConfig {
    /// Supabase anonymous key (client-safe)
    /// Protected by Row Level Security (RLS) policies
    /// IMPORTANT: Never include service_role key in client applications
    static let supabaseAnonKey = "eyJh..."
}
```

**Security Notes:**
- ✅ Anon key is safe for client-side use
- ✅ Protected by RLS policies
- ❌ Never include service_role key
- ✅ Sentry DSN is safe for client applications

### UUID Handling - CRITICAL

**ALWAYS pass UUIDs directly to queries:**

```swift
// ✅ CORRECT
.eq("couple_id", value: tenantId) // UUID type

// ❌ WRONG - Causes case mismatch bugs
.eq("couple_id", value: tenantId.uuidString)
```

**Reason:** Swift uses uppercase UUID strings, PostgreSQL uses lowercase. Passing UUID directly avoids this mismatch.

## Scenario-Based Security

Budget system uses scenario-based isolation:

```sql
CREATE OR REPLACE FUNCTION can_user_access_scenario(
    p_scenario_id TEXT
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1
        FROM budget_development_scenarios
        WHERE id = p_scenario_id
        AND couple_id = get_user_couple_id()
    );
END;
$$;
```

**Usage in allocations:**
```sql
CREATE POLICY "Users access their scenario allocations"
    ON expense_budget_allocations
    FOR ALL
    USING (
        can_user_access_scenario(scenario_id)
    );
```

## Real-Time Security

Real-time subscriptions also respect RLS:

```swift
let channel = await supabase
    .channel("guest_changes")
    .on("postgres_changes", filter: .init(
        event: .all,
        schema: "public",
        table: "guest_list",
        filter: "couple_id=eq.\(tenantId.uuidString)"
    ))
    .subscribe()
```

**RLS policies apply** to real-time subscriptions automatically.

## References
- Migration: 20250203000000 (RLS performance optimization)
- Migration: 20251019035005 (Critical RLS security fixes)
- Migration: 20251022052332 (Admin audit logging)
- Related Issue: Security hardening (October 2025 series)
- File: `Core/Configuration/AppConfig.swift` - Configuration
- Pattern: Always filter by `couple_id` in queries