-- Fix activity_events to handle non-UUID resource IDs (like vendor bigint IDs)
-- Issue: vendor_information.id is bigint, but activity_events.resource_id is UUID
-- This causes "invalid input syntax for type uuid" errors when logging vendor activities
--
-- Solution: Make resource_id nullable and add a resource_id_text column for non-UUID IDs

-- Add a text column for non-UUID resource IDs
ALTER TABLE activity_events 
ADD COLUMN IF NOT EXISTS resource_id_text TEXT;

-- Make resource_id nullable (it was probably already nullable, but let's be explicit)
ALTER TABLE activity_events 
ALTER COLUMN resource_id DROP NOT NULL;

-- Drop the old function first
DROP FUNCTION IF EXISTS public.insert_activity_event(UUID, UUID, TEXT, TEXT, UUID, TEXT, JSONB);

-- Create the new function with updated signature
CREATE OR REPLACE FUNCTION public.insert_activity_event(
    p_couple_id UUID,
    p_actor_id UUID,
    p_action_type TEXT,
    p_resource_type TEXT,
    p_resource_id UUID,
    p_resource_id_text TEXT,
    p_resource_name TEXT,
    p_changes JSONB
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
BEGIN
    -- Disable RLS for this insert
    SET LOCAL row_security = off;
    
    INSERT INTO public.activity_events (
        id,
        created_at,
        couple_id,
        actor_id,
        action_type,
        resource_type,
        resource_id,
        resource_id_text,
        resource_name,
        changes,
        is_read
    ) VALUES (
        gen_random_uuid(),
        NOW(),
        p_couple_id,
        p_actor_id,
        p_action_type,
        p_resource_type,
        p_resource_id,
        p_resource_id_text,
        p_resource_name,
        p_changes,
        false
    );
END;
$function$;

-- Update the log_activity_event trigger to use resource_id_text for vendors
CREATE OR REPLACE FUNCTION public.log_activity_event()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
    v_couple_id UUID;
    v_actor_id UUID;
    v_action_type TEXT;
    v_resource_type TEXT;
    v_resource_id UUID;
    v_resource_id_text TEXT;
    v_resource_name TEXT;
    v_changes JSONB;
BEGIN
    -- Determine action type
    v_action_type := CASE TG_OP
        WHEN 'INSERT' THEN 'created'
        WHEN 'UPDATE' THEN 'updated'
        WHEN 'DELETE' THEN 'deleted'
    END;
    
    -- Get couple_id and resource details based on table
    IF TG_OP = 'DELETE' THEN
        v_couple_id := OLD.couple_id;
        
        -- Handle resource ID based on table type
        IF TG_TABLE_NAME = 'vendor_information' THEN
            v_resource_id := NULL;
            v_resource_id_text := OLD.id::TEXT;
        ELSE
            v_resource_id := OLD.id;
            v_resource_id_text := NULL;
        END IF;
        
        -- Get resource name from OLD record
        IF TG_TABLE_NAME = 'guest_list' THEN
            v_resource_name := OLD.first_name || ' ' || OLD.last_name;
        ELSIF TG_TABLE_NAME = 'budget_categories' THEN
            v_resource_name := OLD.category_name;
        ELSIF TG_TABLE_NAME = 'expenses' THEN
            v_resource_name := OLD.expense_name;
        ELSIF TG_TABLE_NAME = 'vendor_information' THEN
            v_resource_name := OLD.vendor_name;
        ELSIF TG_TABLE_NAME = 'wedding_tasks' THEN
            v_resource_name := OLD.task_name;
        ELSIF TG_TABLE_NAME = 'collaborators' THEN
            v_resource_name := COALESCE(OLD.display_name, OLD.email);
        ELSE
            v_resource_name := 'Unknown';
        END IF;
    ELSE
        v_couple_id := NEW.couple_id;
        
        -- Handle resource ID based on table type
        IF TG_TABLE_NAME = 'vendor_information' THEN
            v_resource_id := NULL;
            v_resource_id_text := NEW.id::TEXT;
        ELSE
            v_resource_id := NEW.id;
            v_resource_id_text := NULL;
        END IF;
        
        -- Get resource name from NEW record
        IF TG_TABLE_NAME = 'guest_list' THEN
            v_resource_name := NEW.first_name || ' ' || NEW.last_name;
        ELSIF TG_TABLE_NAME = 'budget_categories' THEN
            v_resource_name := NEW.category_name;
        ELSIF TG_TABLE_NAME = 'expenses' THEN
            v_resource_name := NEW.expense_name;
        ELSIF TG_TABLE_NAME = 'vendor_information' THEN
            v_resource_name := NEW.vendor_name;
        ELSIF TG_TABLE_NAME = 'wedding_tasks' THEN
            v_resource_name := NEW.task_name;
        ELSIF TG_TABLE_NAME = 'collaborators' THEN
            v_resource_name := COALESCE(NEW.display_name, NEW.email);
        ELSE
            v_resource_name := 'Unknown';
        END IF;
    END IF;
    
    -- Get actor_id (current user)
    v_actor_id := (SELECT auth.uid());
    
    -- Determine resource type
    v_resource_type := CASE TG_TABLE_NAME
        WHEN 'guest_list' THEN 'guest'
        WHEN 'budget_categories' THEN 'budget_category'
        WHEN 'expenses' THEN 'expense'
        WHEN 'vendor_information' THEN 'vendor'
        WHEN 'wedding_tasks' THEN 'task'
        WHEN 'collaborators' THEN 'collaborator'
        ELSE TG_TABLE_NAME
    END;
    
    -- Build changes JSON for updates
    IF TG_OP = 'UPDATE' THEN
        v_changes := jsonb_build_object(
            'before', to_jsonb(OLD),
            'after', to_jsonb(NEW)
        );
    ELSE
        v_changes := NULL;
    END IF;
    
    -- Insert activity event using helper function (bypasses RLS)
    PERFORM public.insert_activity_event(
        v_couple_id,
        v_actor_id,
        v_action_type,
        v_resource_type,
        v_resource_id,
        v_resource_id_text,
        v_resource_name,
        v_changes
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$function$;

-- Add comments
COMMENT ON COLUMN activity_events.resource_id_text IS 
'Text representation of resource ID for tables with non-UUID primary keys (e.g., vendor_information uses bigint).';

COMMENT ON FUNCTION public.insert_activity_event IS 
'Helper function to insert activity events with RLS disabled. 
Handles both UUID and non-UUID resource IDs.
Used by log_activity_event trigger to bypass RLS restrictions.';

COMMENT ON FUNCTION public.log_activity_event() IS 
'Activity logging trigger function. 
Uses IF-ELSIF to prevent field access errors.
Handles both UUID and non-UUID resource IDs (vendors use bigint).
Calls insert_activity_event helper to bypass RLS restrictions.';
