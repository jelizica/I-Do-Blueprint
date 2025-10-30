-- Migration: Create Collaboration Tables
-- Description: Creates tables for real-time collaboration features
-- Date: 2025-10-28
-- Reference: JES-168 - Real-time Collaboration Features

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. COLLABORATION ROLES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS collaboration_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Role definition
    name TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    description TEXT,
    
    -- Permissions
    can_edit BOOLEAN NOT NULL DEFAULT false,
    can_delete BOOLEAN NOT NULL DEFAULT false,
    can_invite BOOLEAN NOT NULL DEFAULT false,
    can_manage_roles BOOLEAN NOT NULL DEFAULT false,
    
    -- Metadata
    is_system_role BOOLEAN NOT NULL DEFAULT true,
    sort_order INTEGER NOT NULL DEFAULT 0
);

-- Insert default roles
INSERT INTO collaboration_roles (name, display_name, description, can_edit, can_delete, can_invite, can_manage_roles, sort_order)
VALUES 
    ('owner', 'Owner', 'Full access to all features', true, true, true, true, 1),
    ('partner', 'Partner', 'Full access to planning features', true, true, true, false, 2),
    ('planner', 'Planner', 'Can edit most planning features', true, false, false, false, 3),
    ('viewer', 'Viewer', 'Can view all planning details', false, false, false, false, 4)
ON CONFLICT (name) DO NOTHING;

-- =====================================================
-- 2. COLLABORATORS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS collaborators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Relationships
    couple_id UUID NOT NULL,
    user_id UUID NOT NULL,
    role_id UUID NOT NULL REFERENCES collaboration_roles(id),
    
    -- Invitation tracking
    invited_by UUID NOT NULL,
    invited_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    accepted_at TIMESTAMPTZ,
    
    -- Status
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'inactive', 'revoked')),
    
    -- User info (for pending invitations)
    email TEXT NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    
    -- Activity tracking
    last_seen_at TIMESTAMPTZ,
    
    -- Constraints
    UNIQUE(couple_id, user_id)
);

-- Indexes for collaborators
CREATE INDEX IF NOT EXISTS idx_collaborators_couple_id ON collaborators(couple_id);
CREATE INDEX IF NOT EXISTS idx_collaborators_user_id ON collaborators(user_id);
CREATE INDEX IF NOT EXISTS idx_collaborators_role_id ON collaborators(role_id);
CREATE INDEX IF NOT EXISTS idx_collaborators_status ON collaborators(couple_id, status);
CREATE INDEX IF NOT EXISTS idx_collaborators_invited_by ON collaborators(invited_by);

-- =====================================================
-- 3. PRESENCE TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS presence (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Relationships
    couple_id UUID NOT NULL,
    user_id UUID NOT NULL,
    session_id TEXT NOT NULL,
    
    -- Status
    status TEXT NOT NULL DEFAULT 'online' CHECK (status IN ('online', 'away', 'offline')),
    
    -- Current activity
    current_view TEXT,
    current_resource_type TEXT,
    current_resource_id UUID,
    
    -- Editing state
    is_editing BOOLEAN NOT NULL DEFAULT false,
    editing_resource_type TEXT,
    editing_resource_id UUID,
    
    -- Heartbeat
    last_heartbeat TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Constraints
    UNIQUE(couple_id, user_id, session_id)
);

-- Indexes for presence
CREATE INDEX IF NOT EXISTS idx_presence_couple_id ON presence(couple_id);
CREATE INDEX IF NOT EXISTS idx_presence_user_id ON presence(user_id);
CREATE INDEX IF NOT EXISTS idx_presence_session_id ON presence(session_id);
CREATE INDEX IF NOT EXISTS idx_presence_status ON presence(couple_id, status);
CREATE INDEX IF NOT EXISTS idx_presence_heartbeat ON presence(last_heartbeat) WHERE status = 'online';
CREATE INDEX IF NOT EXISTS idx_presence_editing ON presence(couple_id, editing_resource_type, editing_resource_id) WHERE is_editing = true;

-- =====================================================
-- 4. ACTIVITY EVENTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS activity_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Relationships
    couple_id UUID NOT NULL,
    actor_id UUID NOT NULL,
    actor_name TEXT NOT NULL,
    
    -- Action details
    action_type TEXT NOT NULL CHECK (action_type IN ('created', 'updated', 'deleted', 'viewed', 'commented', 'invited', 'joined', 'left')),
    resource_type TEXT NOT NULL CHECK (resource_type IN ('guest', 'budgetCategory', 'expense', 'vendor', 'task', 'timeline', 'document', 'note', 'moodBoard', 'seatingChart', 'collaborator')),
    resource_id UUID,
    resource_name TEXT NOT NULL,
    
    -- Additional context
    description TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Read status
    is_read BOOLEAN NOT NULL DEFAULT false
);

-- Indexes for activity_events
CREATE INDEX IF NOT EXISTS idx_activity_events_couple_id ON activity_events(couple_id);
CREATE INDEX IF NOT EXISTS idx_activity_events_actor_id ON activity_events(actor_id);
CREATE INDEX IF NOT EXISTS idx_activity_events_action_type ON activity_events(couple_id, action_type);
CREATE INDEX IF NOT EXISTS idx_activity_events_resource_type ON activity_events(couple_id, resource_type);
CREATE INDEX IF NOT EXISTS idx_activity_events_created_at ON activity_events(couple_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_events_unread ON activity_events(couple_id, is_read) WHERE is_read = false;

-- =====================================================
-- 5. UPDATE TRIGGERS
-- =====================================================

-- Apply update triggers
DROP TRIGGER IF EXISTS update_collaboration_roles_updated_at ON collaboration_roles;
CREATE TRIGGER update_collaboration_roles_updated_at
    BEFORE UPDATE ON collaboration_roles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_collaborators_updated_at ON collaborators;
CREATE TRIGGER update_collaborators_updated_at
    BEFORE UPDATE ON collaborators
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_presence_updated_at ON presence;
CREATE TRIGGER update_presence_updated_at
    BEFORE UPDATE ON presence
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 6. ENABLE REALTIME
-- =====================================================

-- Enable realtime for collaboration tables
ALTER PUBLICATION supabase_realtime ADD TABLE collaborators;
ALTER PUBLICATION supabase_realtime ADD TABLE presence;
ALTER PUBLICATION supabase_realtime ADD TABLE activity_events;

-- Comments
COMMENT ON TABLE collaboration_roles IS 'Defines roles and permissions for collaboration';
COMMENT ON TABLE collaborators IS 'Tracks collaborators for each couple with invitation workflow';
COMMENT ON TABLE presence IS 'Real-time presence tracking with heartbeat mechanism';
COMMENT ON TABLE activity_events IS 'Activity feed for all resource changes';
