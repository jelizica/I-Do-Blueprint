-- Migration: Fix RLS Policies Using auth.uid() Without SELECT Wrapper
-- Issue: JES-149
-- Description: Replace all instances of auth.uid() with (SELECT auth.uid()) to prevent
--              per-row function evaluation and improve query performance dramatically.
-- 
-- Performance Impact:
-- - Before: auth.uid() called once per row (1000 rows = 1000 calls)
-- - After: auth.uid() called once per query (1000 rows = 1 call)
-- - Expected improvement: 50-90% faster queries depending on dataset size

-- =============================================================================
-- ADMIN TABLES
-- =============================================================================

-- admin_audit_log
DROP POLICY IF EXISTS "admins_read_audit_log" ON admin_audit_log;
CREATE POLICY "admins_read_audit_log" ON admin_audit_log
FOR SELECT USING (
    EXISTS (
        SELECT 1
        FROM admin_roles ar
        WHERE ar.user_id = (SELECT auth.uid())
            AND ar.is_active = true
            AND (ar.expires_at IS NULL OR ar.expires_at > CURRENT_TIMESTAMP)
    )
);

-- admin_roles
DROP POLICY IF EXISTS "super_admins_manage_admin_roles" ON admin_roles;
CREATE POLICY "super_admins_manage_admin_roles" ON admin_roles
FOR ALL USING (
    EXISTS (
        SELECT 1
        FROM admin_roles ar
        WHERE ar.user_id = (SELECT auth.uid())
            AND ar.role_name = 'super_admin'
            AND ar.is_active = true
            AND (ar.expires_at IS NULL OR ar.expires_at > CURRENT_TIMESTAMP)
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM admin_roles ar
        WHERE ar.user_id = (SELECT auth.uid())
            AND ar.role_name = 'super_admin'
            AND ar.is_active = true
            AND (ar.expires_at IS NULL OR ar.expires_at > CURRENT_TIMESTAMP)
    )
);

-- =============================================================================
-- COUPLE & MEMBERSHIP TABLES
-- =============================================================================

-- couple_profiles
DROP POLICY IF EXISTS "Admin can do everything" ON couple_profiles;
CREATE POLICY "Admin can do everything" ON couple_profiles
FOR ALL USING (
    EXISTS (
        SELECT 1
        FROM memberships
        WHERE memberships.user_id = (SELECT auth.uid())
            AND memberships.role = 'admin'
    )
);

DROP POLICY IF EXISTS "Users can insert their own couple profile" ON couple_profiles;
CREATE POLICY "Users can insert their own couple profile" ON couple_profiles
FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1
        FROM memberships
        WHERE memberships.user_id = (SELECT auth.uid())
            AND memberships.couple_id = couple_profiles.id
    )
);

DROP POLICY IF EXISTS "Users can update their own couple profile" ON couple_profiles;
CREATE POLICY "Users can update their own couple profile" ON couple_profiles
FOR UPDATE USING (
    EXISTS (
        SELECT 1
        FROM memberships
        WHERE memberships.user_id = (SELECT auth.uid())
            AND memberships.couple_id = couple_profiles.id
    )
);

DROP POLICY IF EXISTS "Users can view their own couple profile" ON couple_profiles;
CREATE POLICY "Users can view their own couple profile" ON couple_profiles
FOR SELECT USING (
    EXISTS (
        SELECT 1
        FROM memberships
        WHERE memberships.user_id = (SELECT auth.uid())
            AND memberships.couple_id = couple_profiles.id
    )
);

-- memberships
DROP POLICY IF EXISTS "Users can view their own memberships" ON memberships;
CREATE POLICY "Users can view their own memberships" ON memberships
FOR SELECT USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "debug_insert_memberships" ON memberships;
CREATE POLICY "debug_insert_memberships" ON memberships
FOR INSERT WITH CHECK (
    (get_user_role_in_tenant(couple_id) = ANY (ARRAY['owner'::text, 'admin'::text]))
    OR (
        (user_id = (SELECT auth.uid()))
        AND ((SELECT auth.uid()) IS NOT NULL)
        AND (
            EXISTS (
                SELECT 1
                FROM invitations i
                WHERE i.couple_id = i.couple_id
                    AND i.status = 'pending'
                    AND i.expires_at > now()
            )
        )
    )
);

-- invitations
DROP POLICY IF EXISTS "insert_invitations" ON invitations;
CREATE POLICY "insert_invitations" ON invitations
FOR INSERT WITH CHECK (
    (get_user_role_in_tenant(couple_id) = ANY (ARRAY['owner'::text, 'admin'::text]))
    AND (invited_by = (SELECT auth.uid()))
);

DROP POLICY IF EXISTS "update_invitations" ON invitations;
CREATE POLICY "update_invitations" ON invitations
FOR UPDATE USING (
    (get_user_role_in_tenant(couple_id) = ANY (ARRAY['owner'::text, 'admin'::text]))
    OR (
        (email IS NOT NULL)
        AND (email = (auth.jwt() ->> 'email'::text))
        AND (status = 'pending')
    )
    OR (
        (email IS NULL)
        AND (status = 'pending')
        AND ((SELECT auth.uid()) IS NOT NULL)
    )
);

-- =============================================================================
-- BILLING TABLES
-- =============================================================================

-- billing_events (already uses SELECT wrapper, but included for completeness)
-- No changes needed - already optimized

-- =============================================================================
-- BUDGET TABLES
-- =============================================================================

-- my_estimated_budget
DROP POLICY IF EXISTS "Couples can manage their estimated budget" ON my_estimated_budget;
CREATE POLICY "Couples can manage their estimated budget" ON my_estimated_budget
FOR ALL USING (couple_id = (SELECT auth.uid()))
WITH CHECK (couple_id = (SELECT auth.uid()));

-- =============================================================================
-- VISUAL PLANNING TABLES
-- =============================================================================

-- color_palettes
DROP POLICY IF EXISTS "Users can only access their own color palettes" ON color_palettes;
CREATE POLICY "Users can only access their own color palettes" ON color_palettes
FOR ALL USING (tenant_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can update their own color palettes" ON color_palettes;
CREATE POLICY "Users can update their own color palettes" ON color_palettes
FOR UPDATE USING (
    (tenant_id IN (SELECT get_user_tenant_ids()))
    OR (
        EXISTS (
            SELECT 1
            FROM palette_shares
            WHERE palette_shares.palette_id = color_palettes.id
                AND palette_shares.shared_with = (SELECT auth.uid())
                AND palette_shares.permission_level = 'edit'
                AND (palette_shares.expires_at IS NULL OR palette_shares.expires_at > now())
        )
    )
)
WITH CHECK (
    (tenant_id IN (SELECT get_user_tenant_ids()))
    OR (
        EXISTS (
            SELECT 1
            FROM palette_shares
            WHERE palette_shares.palette_id = color_palettes.id
                AND palette_shares.shared_with = (SELECT auth.uid())
                AND palette_shares.permission_level = 'edit'
                AND (palette_shares.expires_at IS NULL OR palette_shares.expires_at > now())
        )
    )
);

DROP POLICY IF EXISTS "Users can view their own and shared color palettes" ON color_palettes;
CREATE POLICY "Users can view their own and shared color palettes" ON color_palettes
FOR SELECT USING (
    (tenant_id IN (SELECT get_user_tenant_ids()))
    OR (visibility = 'public')
    OR (
        EXISTS (
            SELECT 1
            FROM palette_shares
            WHERE palette_shares.palette_id = color_palettes.id
                AND (
                    palette_shares.shared_with = (SELECT auth.uid())
                    OR palette_shares.is_public = true
                )
                AND (palette_shares.expires_at IS NULL OR palette_shares.expires_at > now())
        )
    )
);

-- palette_shares
DROP POLICY IF EXISTS "Users can create shares for their palettes" ON palette_shares;
CREATE POLICY "Users can create shares for their palettes" ON palette_shares
FOR INSERT WITH CHECK (
    (shared_by = (SELECT auth.uid()))
    AND (
        EXISTS (
            SELECT 1
            FROM color_palettes
            WHERE color_palettes.id = palette_shares.palette_id
                AND color_palettes.tenant_id IN (SELECT get_user_tenant_ids())
        )
    )
);

DROP POLICY IF EXISTS "Users can delete shares they created" ON palette_shares;
CREATE POLICY "Users can delete shares they created" ON palette_shares
FOR DELETE USING (shared_by = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can update shares they created" ON palette_shares;
CREATE POLICY "Users can update shares they created" ON palette_shares
FOR UPDATE USING (shared_by = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can view shares they created or are shared with" ON palette_shares;
CREATE POLICY "Users can view shares they created or are shared with" ON palette_shares
FOR SELECT USING (
    (shared_by = (SELECT auth.uid()))
    OR (shared_with = (SELECT auth.uid()))
    OR (
        (is_public = true)
        AND (expires_at IS NULL OR expires_at > now())
    )
);

-- palette_exports
DROP POLICY IF EXISTS "Users can create exports of accessible palettes" ON palette_exports;
CREATE POLICY "Users can create exports of accessible palettes" ON palette_exports
FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1
        FROM color_palettes
        WHERE color_palettes.id = palette_exports.palette_id
            AND (
                (color_palettes.tenant_id IN (SELECT get_user_tenant_ids()))
                OR (color_palettes.visibility = 'public')
                OR (
                    EXISTS (
                        SELECT 1
                        FROM palette_shares
                        WHERE palette_shares.palette_id = color_palettes.id
                            AND palette_shares.shared_with = (SELECT auth.uid())
                            AND palette_shares.permission_level = ANY (ARRAY['view', 'copy', 'edit'])
                            AND (palette_shares.expires_at IS NULL OR palette_shares.expires_at > now())
                    )
                )
            )
    )
);

DROP POLICY IF EXISTS "Users can update export counts for accessible palettes" ON palette_exports;
CREATE POLICY "Users can update export counts for accessible palettes" ON palette_exports
FOR UPDATE USING (
    (exported_by = (SELECT auth.uid()))
    OR (
        EXISTS (
            SELECT 1
            FROM color_palettes
            WHERE color_palettes.id = palette_exports.palette_id
                AND color_palettes.tenant_id IN (SELECT get_user_tenant_ids())
        )
    )
)
WITH CHECK (
    (exported_by = (SELECT auth.uid()))
    OR (
        EXISTS (
            SELECT 1
            FROM color_palettes
            WHERE color_palettes.id = palette_exports.palette_id
                AND color_palettes.tenant_id IN (SELECT get_user_tenant_ids())
        )
    )
);

DROP POLICY IF EXISTS "Users can view exports of accessible palettes" ON palette_exports;
CREATE POLICY "Users can view exports of accessible palettes" ON palette_exports
FOR SELECT USING (
    (exported_by = (SELECT auth.uid()))
    OR (
        EXISTS (
            SELECT 1
            FROM color_palettes
            WHERE color_palettes.id = palette_exports.palette_id
                AND color_palettes.tenant_id IN (SELECT get_user_tenant_ids())
        )
    )
);

-- palette_generations
DROP POLICY IF EXISTS "Users can view generations of accessible palettes" ON palette_generations;
CREATE POLICY "Users can view generations of accessible palettes" ON palette_generations
FOR SELECT USING (
    EXISTS (
        SELECT 1
        FROM color_palettes
        WHERE color_palettes.id = palette_generations.palette_id
            AND (
                (color_palettes.tenant_id IN (SELECT get_user_tenant_ids()))
                OR (color_palettes.visibility = 'public')
                OR (
                    EXISTS (
                        SELECT 1
                        FROM palette_shares
                        WHERE palette_shares.palette_id = color_palettes.id
                            AND (
                                palette_shares.shared_with = (SELECT auth.uid())
                                OR palette_shares.is_public = true
                            )
                            AND (palette_shares.expires_at IS NULL OR palette_shares.expires_at > now())
                    )
                )
            )
    )
);

-- palette_versions
DROP POLICY IF EXISTS "Users can view versions of accessible palettes" ON palette_versions;
CREATE POLICY "Users can view versions of accessible palettes" ON palette_versions
FOR SELECT USING (
    EXISTS (
        SELECT 1
        FROM color_palettes
        WHERE color_palettes.id = palette_versions.palette_id
            AND (
                (color_palettes.tenant_id IN (SELECT get_user_tenant_ids()))
                OR (color_palettes.visibility = 'public')
                OR (
                    EXISTS (
                        SELECT 1
                        FROM palette_shares
                        WHERE palette_shares.palette_id = color_palettes.id
                            AND (
                                palette_shares.shared_with = (SELECT auth.uid())
                                OR palette_shares.is_public = true
                            )
                            AND (palette_shares.expires_at IS NULL OR palette_shares.expires_at > now())
                    )
                )
            )
    )
);

-- mood_boards
DROP POLICY IF EXISTS "users_and_admins_manage_mood_boards" ON mood_boards;
CREATE POLICY "users_and_admins_manage_mood_boards" ON mood_boards
FOR ALL USING (
    (((SELECT auth.uid()) IS NOT NULL) AND (tenant_id = (SELECT auth.uid())))
    OR is_admin()
)
WITH CHECK (
    (((SELECT auth.uid()) IS NOT NULL) AND (tenant_id = (SELECT auth.uid())))
    OR is_admin()
);

-- visual_elements
DROP POLICY IF EXISTS "users_and_admins_manage_visual_elements" ON visual_elements;
CREATE POLICY "users_and_admins_manage_visual_elements" ON visual_elements
FOR ALL USING (
    (((SELECT auth.uid()) IS NOT NULL) AND (tenant_id = (SELECT auth.uid())))
    OR is_admin()
)
WITH CHECK (
    (((SELECT auth.uid()) IS NOT NULL) AND (tenant_id = (SELECT auth.uid())))
    OR is_admin()
);

-- style_preferences
DROP POLICY IF EXISTS "Users can manage their own style preferences" ON style_preferences;
CREATE POLICY "Users can manage their own style preferences" ON style_preferences
FOR ALL USING ((SELECT auth.uid()) = tenant_id);

-- visual_planning_analytics
DROP POLICY IF EXISTS "Users can insert their own analytics" ON visual_planning_analytics;
CREATE POLICY "Users can insert their own analytics" ON visual_planning_analytics
FOR INSERT WITH CHECK ((SELECT auth.uid()) = tenant_id);

DROP POLICY IF EXISTS "Users can view their own analytics" ON visual_planning_analytics;
CREATE POLICY "Users can view their own analytics" ON visual_planning_analytics
FOR SELECT USING ((SELECT auth.uid()) = tenant_id);

-- visual_planning_shares
DROP POLICY IF EXISTS "Users can manage shares they created" ON visual_planning_shares;
CREATE POLICY "Users can manage shares they created" ON visual_planning_shares
FOR ALL USING (shared_by = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can view shares they received" ON visual_planning_shares;
CREATE POLICY "Users can view shares they received" ON visual_planning_shares
FOR SELECT USING (
    (shared_with = (SELECT auth.uid()))
    AND (is_active = true)
);

-- export_templates
DROP POLICY IF EXISTS "Users can manage their own templates" ON export_templates;
CREATE POLICY "Users can manage their own templates" ON export_templates
FOR ALL USING (created_by = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can view public templates" ON export_templates;
CREATE POLICY "Users can view public templates" ON export_templates
FOR SELECT USING (
    (is_public = true)
    OR (created_by = (SELECT auth.uid()))
);

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

-- Run these queries after migration to verify all policies are fixed:
-- 
-- 1. Check for remaining auth.uid() without SELECT wrapper:
-- SELECT 
--     schemaname,
--     tablename,
--     policyname,
--     cmd as command
-- FROM pg_policies
-- WHERE schemaname = 'public'
--     AND (
--         qual LIKE '%auth.uid()%' 
--         OR with_check LIKE '%auth.uid()%'
--     )
--     AND (
--         qual NOT LIKE '%(SELECT auth.uid())%'
--         OR with_check NOT LIKE '%(SELECT auth.uid())%'
--     )
-- ORDER BY tablename, policyname;
-- 
-- Expected result: 0 rows (all policies should now use SELECT wrapper)
--
-- 2. Verify policy count:
-- SELECT COUNT(*) as total_policies
-- FROM pg_policies
-- WHERE schemaname = 'public';
--
-- 3. Test a sample query to verify performance improvement:
-- EXPLAIN ANALYZE SELECT * FROM color_palettes WHERE tenant_id = (SELECT auth.uid());
