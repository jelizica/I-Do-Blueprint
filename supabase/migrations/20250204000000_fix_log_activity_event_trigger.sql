-- Fix log_activity_event() trigger function
-- Issue: The function was evaluating all CASE branches even when they didn't match,
-- causing "record has no field" errors when accessing fields that don't exist on the current table.
--
-- Solution: The CASE statement already has the correct logic, but PostgreSQL was trying to
-- evaluate NEW.category_name even for guest_list records. This is fixed by ensuring
-- the CASE statement short-circuits properly.

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
        -- Use IF-ELSIF to ensure only one branch is evaluated
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
        -- Use IF-ELSIF to ensure only one branch is evaluated
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
    
    -- Insert activity event
    INSERT INTO activity_events (
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
        v_couple_id,
        v_actor_id,
        v_action_type,
        v_resource_type,
        v_resource_id,
        v_resource_name,
        v_changes,
        false
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$function$;

-- Add comment explaining the fix
COMMENT ON FUNCTION public.log_activity_event() IS 
'Activity logging trigger function. 
Fixed: Changed from CASE expression to IF-ELSIF to prevent PostgreSQL from evaluating 
all branches and accessing fields that don''t exist on the current table record.';
