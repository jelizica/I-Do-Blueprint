-- Final fix for activity_events trigger - disable RLS for trigger inserts
-- Issue: Even with SECURITY DEFINER and updated RLS policies, the trigger still
-- couldn't insert into activity_events because RLS was blocking it.
--
-- Solution: Create a separate function that inserts into activity_events with
-- RLS explicitly disabled, and call that from the trigger.

-- Create a helper function that inserts activity events with RLS disabled
CREATE OR REPLACE FUNCTION public.insert_activity_event(
    p_couple_id UUID,
    p_actor_id UUID,
    p_action_type TEXT,
    p_resource_type TEXT,
    p_resource_id UUID,
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
        p_resource_name,
        p_changes,
        false
    );
END;
$function$;

-- Update the log_activity_event trigger to use the helper function
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
        v_resource_id := OLD.id;
        
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
        v_resource_id := NEW.id;
        
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
        v_resource_name,
        v_changes
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$function$;

-- Add comments
COMMENT ON FUNCTION public.insert_activity_event IS 
'Helper function to insert activity events with RLS disabled. 
Used by log_activity_event trigger to bypass RLS restrictions.';

COMMENT ON FUNCTION public.log_activity_event() IS 
'Activity logging trigger function. 
Uses IF-ELSIF to prevent field access errors and calls insert_activity_event 
helper to bypass RLS restrictions.';
