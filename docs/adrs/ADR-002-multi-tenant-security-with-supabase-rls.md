# ADR-002: Multi-tenant Security with Supabase RLS

## Status
Accepted

## Context
I Do Blueprint is a multi-tenant application where multiple couples use the same database but must never see each other's data. Security requirements:
- Each couple's data must be completely isolated
- No couple should be able to access another couple's data, even through API manipulation
- Security must be enforced at the database level, not just application level
- Performance must remain acceptable with security checks

## Decision
We implemented multi-tenant security using Supabase Row Level Security (RLS):

1. **Tenant Identification**:
   - Each couple has a unique `couple_id` (UUID)
   - All multi-tenant tables include a `couple_id` column
   - User authentication provides the current couple context

2. **RLS Policy Pattern**:
   - Single `FOR ALL` policy per table for simplicity
   - Policy uses `get_user_couple_id()` helper function
   - Pattern:
     ```sql
     CREATE POLICY "couples_manage_own_{resource}"
       ON {table_name}
       FOR ALL
       USING (couple_id = get_user_couple_id())
       WITH CHECK (couple_id = get_user_couple_id());
     ```

3. **Helper Function**:
   ```sql
   CREATE OR REPLACE FUNCTION get_user_couple_id()
   RETURNS UUID AS $$
     SELECT couple_id FROM user_profiles 
     WHERE user_id = (SELECT auth.uid())
   $$ LANGUAGE SQL STABLE;
   ```

4. **UUID Handling**:
   - Pass UUIDs directly to Supabase queries (not strings)
   - Repositories automatically filter by current couple
   - Never expose data across tenants

## Consequences

### Positive
- **Database-Level Security**: RLS enforces isolation even if application code has bugs
- **Defense in Depth**: Multiple layers of security (auth + RLS)
- **Audit Trail**: Database logs show all access attempts
- **Compliance**: Meets data privacy requirements (GDPR, etc.)
- **Simple Pattern**: Single policy per table is easy to understand and maintain
- **Performance**: Indexed `couple_id` columns ensure fast queries

### Negative
- **Performance Overhead**: RLS adds a check to every query
- **Complexity**: Developers must understand RLS when writing migrations
- **Testing Challenges**: Tests must set up proper tenant context
- **Migration Risk**: Forgetting RLS on new tables creates security holes
- **Function Stability**: Using `(SELECT auth.uid())` instead of direct `auth.uid()` for performance

## Implementation Notes
- All new tables with user data MUST have `couple_id` column
- All new tables MUST enable RLS: `ALTER TABLE {table} ENABLE ROW LEVEL SECURITY;`
- All new tables MUST have the standard policy pattern
- Indexes MUST be created on `couple_id` for foreign keys
- Never use `auth.uid()` directly in policies (use `get_user_couple_id()`)
- Test RLS policies with multiple tenant contexts

## Security Checklist
- [ ] Table has `couple_id` column
- [ ] RLS is enabled on table
- [ ] Policy uses `get_user_couple_id()`
- [ ] Index exists on `couple_id`
- [ ] Repository filters by tenant
- [ ] Tests verify tenant isolation

## Related Documents
- `best_practices.md` - Section 8: Multi-Tenancy
- `supabase/migrations/` - Database migrations with RLS policies
- `Domain/Repositories/` - Tenant-aware repository implementations
