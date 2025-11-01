-- Migration: Create Collaboration RLS Policies
-- Description: Row Level Security policies for collaboration tables
-- Date: 2025-10-28
-- Reference: JES-168 - Real-time Collaboration Features

-- =====================================================
-- HELPER FUNCTION: Get User's Couple ID
-- =====================================================
CREATE OR REPLACE FUNCTION get_user_couple_id()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_couple_id UUID;
BEGIN
    -- Get couple_id from collaborators table for the authenticated user
    SELECT couple_id INTO v_couple_id
    FROM collaborators
    WHERE user_id = (SELECT auth.uid())
      AND status = 'active'
    LIMIT 1;
    
    RETURN v_couple_id;
END;
$$;

-- =====================================================
-- HELPER FUNCTION: Check User Permission
-- =====================================================
CREATE OR REPLACE FUNCTION user_has_permission(
    p_couple_id UUID,
    p_permission TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_has_permission BOOLEAN;
BEGIN
    -- Check if user has the specified permission through their role
    SELECT CASE p_permission
        WHEN 'can_edit' THEN r.can_edit
        WHEN 'can_delete' THEN r.can_delete
        WHEN 'can_invite' THEN r.can_invite
        WHEN 'can_manage_roles' THEN r.can_manage_roles
        ELSE false
    END INTO v_has_permission
    FROM collaborators c
    JOIN collaboration_roles r ON c.role_id = r.id
    WHERE c.couple_id = p_couple_id
      AND c.user_id = (SELECT auth.uid())
      AND c.status = 'active';
    
    RETURN COALESCE(v_has_permission, false);
END;
$$;

-- =====================================================
-- HELPER FUNCTION: Get User's Role
-- =====================================================
CREATE OR REPLACE FUNCTION get_user_role(p_couple_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_role_name TEXT;
BEGIN
    SELECT r.name INTO v_role_name
    FROM collaborators c
    JOIN collaboration_roles r ON c.role_id = r.id
    WHERE c.couple_id = p_couple_id
      AND c.user_id = (SELECT auth.uid())
      AND c.status = 'active';
    
    RETURN v_role_name;
END;
$$;

-- =====================================================
-- RLS POLICIES: collaboration_roles
-- =====================================================

-- Enable RLS
ALTER TABLE collaboration_roles ENABLE ROW LEVEL SECURITY;

-- Everyone can read roles (needed for role selection)
CREATE POLICY "Anyone can view collaboration roles"
    ON collaboration_roles
    FOR SELECT
    USING (true);

-- =====================================================
-- RLS POLICIES: collaborators
-- =====================================================

-- Enable RLS
ALTER TABLE collaborators ENABLE ROW LEVEL SECURITY;

-- Users can view collaborators for their couple
CREATE POLICY "Users can view collaborators for their couple"
    ON collaborators
    FOR SELECT
    USING (
        couple_id IN (
            SELECT couple_id 
            FROM collaborators 
            WHERE user_id = (SELECT auth.uid()) 
              AND status = 'active'
        )
    );

-- Users with can_invite permission can insert collaborators
CREATE POLICY "Users with can_invite can add collaborators"
    ON collaborators
    FOR INSERT
    WITH CHECK (
        user_has_permission(couple_id, 'can_invite')
    );

-- Users with can_manage_roles can update collaborators
CREATE POLICY "Users with can_manage_roles can update collaborators"
    ON collaborators
    FOR UPDATE
    USING (
        user_has_permission(couple_id, 'can_manage_roles')
    )
    WITH CHECK (
        user_has_permission(couple_id, 'can_manage_roles')
    );

-- Users with can_manage_roles can delete collaborators
CREATE POLICY "Users with can_manage_roles can delete collaborators"
    ON collaborators
    FOR DELETE
    USING (
        user_has_permission(couple_id, 'can_manage_roles')
    );

-- =====================================================
-- RLS POLICIES: presence
-- =====================================================

-- Enable RLS
ALTER TABLE presence ENABLE ROW LEVEL SECURITY;

-- Users can view presence for their couple
CREATE POLICY "Users can view presence for their couple"
    ON presence
    FOR SELECT
    USING (
        couple_id IN (
            SELECT couple_id 
            FROM collaborators 
            WHERE user_id = (SELECT auth.uid()) 
              AND status = 'active'
        )
    );

-- Users can insert their own presence
CREATE POLICY "Users can insert their own presence"
    ON presence
    FOR INSERT
    WITH CHECK (
        user_id = (SELECT auth.uid())
        AND couple_id IN (
            SELECT couple_id 
            FROM collaborators 
            WHERE user_id = (SELECT auth.uid()) 
              AND status = 'active'
        )
    );

-- Users can update their own presence
CREATE POLICY "Users can update their own presence"
    ON presence
    FOR UPDATE
    USING (
        user_id = (SELECT auth.uid())
    )
    WITH CHECK (
        user_id = (SELECT auth.uid())
    );

-- Users can delete their own presence
CREATE POLICY "Users can delete their own presence"
    ON presence
    FOR DELETE
    USING (
        user_id = (SELECT auth.uid())
    );

-- =====================================================
-- RLS POLICIES: activity_events
-- =====================================================

-- Enable RLS
ALTER TABLE activity_events ENABLE ROW LEVEL SECURITY;

-- Users can view activity events for their couple
CREATE POLICY "Users can view activity events for their couple"
    ON activity_events
    FOR SELECT
    USING (
        couple_id IN (
            SELECT couple_id 
            FROM collaborators 
            WHERE user_id = (SELECT auth.uid()) 
              AND status = 'active'
        )
    );

-- System can insert activity events (for triggers)
CREATE POLICY "System can insert activity events"
    ON activity_events
    FOR INSERT
    WITH CHECK (true);

-- Users can update their own activity events (mark as read)
CREATE POLICY "Users can update activity events for their couple"
    ON activity_events
    FOR UPDATE
    USING (
        couple_id IN (
            SELECT couple_id 
            FROM collaborators 
            WHERE user_id = (SELECT auth.uid()) 
              AND status = 'active'
        )
    )
    WITH CHECK (
        couple_id IN (
            SELECT couple_id 
            FROM collaborators 
            WHERE user_id = (SELECT auth.uid()) 
              AND status = 'active'
        )
    );

-- Comments
COMMENT ON FUNCTION get_user_couple_id() IS 'Returns the couple_id for the authenticated user';
COMMENT ON FUNCTION user_has_permission(UUID, TEXT) IS 'Checks if user has a specific permission for a couple';
COMMENT ON FUNCTION get_user_role(UUID) IS 'Returns the role name for the authenticated user in a couple';
