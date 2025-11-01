-- Migration: Create invitations table for pending collaborator invites
-- Purpose: Separate pending invitations from active collaborators to avoid FK constraint violations
-- Date: 2025-10-29

-- Create invitations table
CREATE TABLE IF NOT EXISTS public.invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Multi-tenant isolation
    couple_id UUID NOT NULL REFERENCES public.couple_profiles(id) ON DELETE CASCADE,

    -- Invitation details
    email TEXT NOT NULL,
    role_id UUID NOT NULL REFERENCES public.collaboration_roles(id),
    invited_by UUID NOT NULL REFERENCES auth.users(id),
    invited_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),

    -- Status tracking
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired', 'cancelled', 'declined')),

    -- Security
    token TEXT UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(32), 'hex'),

    -- Optional metadata
    display_name TEXT,
    message TEXT, -- Optional invitation message
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Constraints
    UNIQUE(couple_id, email), -- One invitation per email per couple
    CHECK (expires_at > invited_at)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_invitations_couple_id ON public.invitations(couple_id);
CREATE INDEX IF NOT EXISTS idx_invitations_email ON public.invitations(email);
CREATE INDEX IF NOT EXISTS idx_invitations_token ON public.invitations(token);
CREATE INDEX IF NOT EXISTS idx_invitations_status ON public.invitations(status);
CREATE INDEX IF NOT EXISTS idx_invitations_expires_at ON public.invitations(expires_at) WHERE status = 'pending';

-- Enable Row Level Security
ALTER TABLE public.invitations ENABLE ROW LEVEL SECURITY;

-- RLS Policies for invitations
-- Users can view invitations for their couple
CREATE POLICY "Users can view invitations for their couple"
    ON public.invitations
    FOR SELECT
    USING (
        couple_id IN (SELECT unnest(get_user_couple_ids()))
    );

-- Users with can_invite permission can create invitations
CREATE POLICY "Users with can_invite can create invitations"
    ON public.invitations
    FOR INSERT
    WITH CHECK (
        couple_id IN (SELECT unnest(get_user_couple_ids()))
        AND EXISTS (
            SELECT 1 FROM public.collaborators c
            JOIN public.collaboration_roles r ON c.role_id = r.id
            WHERE c.couple_id = invitations.couple_id
                AND c.user_id = auth.uid()
                AND c.status = 'active'
                AND r.can_invite = true
        )
    );

-- Users with can_invite permission can update invitations (e.g., cancel)
CREATE POLICY "Users with can_invite can update invitations"
    ON public.invitations
    FOR UPDATE
    USING (
        couple_id IN (SELECT unnest(get_user_couple_ids()))
        AND EXISTS (
            SELECT 1 FROM public.collaborators c
            JOIN public.collaboration_roles r ON c.role_id = r.id
            WHERE c.couple_id = invitations.couple_id
                AND c.user_id = auth.uid()
                AND c.status = 'active'
                AND r.can_invite = true
        )
    );

-- Users with can_invite permission can delete invitations
CREATE POLICY "Users with can_invite can delete invitations"
    ON public.invitations
    FOR DELETE
    USING (
        couple_id IN (SELECT unnest(get_user_couple_ids()))
        AND EXISTS (
            SELECT 1 FROM public.collaborators c
            JOIN public.collaboration_roles r ON c.role_id = r.id
            WHERE c.couple_id = invitations.couple_id
                AND c.user_id = auth.uid()
                AND c.status = 'active'
                AND r.can_invite = true
        )
    );

-- Invited users can view their own invitations by email
CREATE POLICY "Invited users can view their invitations"
    ON public.invitations
    FOR SELECT
    USING (
        email = (SELECT email FROM auth.users WHERE id = auth.uid())
        AND status = 'pending'
    );

-- Function to automatically expire old invitations
CREATE OR REPLACE FUNCTION public.expire_old_invitations()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    UPDATE public.invitations
    SET status = 'expired',
        updated_at = NOW()
    WHERE status = 'pending'
        AND expires_at < NOW();
END;
$$;

-- Trigger to update updated_at timestamp
CREATE TRIGGER update_invitations_updated_at
    BEFORE UPDATE ON public.invitations
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.invitations TO authenticated;
GRANT SELECT ON public.invitations TO anon;

-- Add helpful comments
COMMENT ON TABLE public.invitations IS 'Pending collaboration invitations before users are active collaborators';
COMMENT ON COLUMN public.invitations.token IS 'Secure token for invitation links';
COMMENT ON COLUMN public.invitations.expires_at IS 'Invitation expires 7 days after creation';
COMMENT ON FUNCTION public.expire_old_invitations() IS 'Automatically marks expired invitations';
