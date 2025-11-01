-- Migration: Create Collaboration Triggers and Functions
-- Description: Triggers for activity logging and realtime broadcasting
-- Date: 2025-10-28
-- Reference: JES-168 - Real-time Collaboration Features

-- =====================================================
-- FUNCTION: Log Activity Event
-- =====================================================
CREATE OR REPLACE FUNCTION log_activity_event()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = ''
LANGUAGE plpgsql
AS $$
DECLARE
    v_actor_id UUID;
    v_actor_name TEXT;
    v_action_type TEXT;
    v_resource_type TEXT;
    v_resource_id UUID;
    v_resource_name TEXT;
    v_description TEXT;
    v_couple_id UUID;
BEGIN
    -- Get actor information
    v_actor_id := (SELECT auth.uid());
    
    -- Get actor name from collaborators
    SELECT display_name INTO v_actor_name
    FROM collaborators
    WHERE user_id = v_actor_id
    LIMIT 1;
    
    -- Default to email if no display name
    IF v_actor_name IS NULL THEN
        v_actor_name := (SELECT email FROM auth.users WHERE id = v_actor_id);
    END IF;
    
    -- Determine action type
    IF TG_OP = 'INSERT' THEN
        v_action_type := 'created';
    ELSIF TG_OP = 'UPDATE' THEN
        v_action_type := 'updated';
    ELSIF TG_OP = 'DELETE' THEN
        v_action_type := 'deleted';
    END IF;
    
    -- Determine resource type and get details based on table
    CASE TG_TABLE_NAME
        WHEN 'guest_list' THEN
            v_resource_type := 'guest';
            IF TG_OP = 'DELETE' THEN
                v_resource_id := OLD.id;
                v_resource_name := OLD.full_name;
                v_couple_id := OLD.couple_id;
            ELSE
                v_resource_id := NEW.id;
                v_resource_name := NEW.full_name;
                v_couple_id := NEW.couple_id;
            END IF;
        WHEN 'budget_categories' THEN
            v_resource_type := 'budgetCategory';
            IF TG_OP = 'DELETE' THEN
                v_resource_id := OLD.id;
                v_resource_name := OLD.category_name;
                v_couple_id := OLD.couple_id;
            ELSE
                v_resource_id := NEW.id;
                v_resource_name := NEW.category_name;
                v_couple_id := NEW.couple_id;
            END IF;
        WHEN 'expenses' THEN
            v_resource_type := 'expense';
            IF TG_OP = 'DELETE' THEN
                v_resource_id := OLD.id;
                v_resource_name := OLD.expense_name;
                v_couple_id := OLD.couple_id;
            ELSE
                v_resource_id := NEW.id;
                v_resource_name := NEW.expense_name;
                v_couple_id := NEW.couple_id;
            END IF;
        WHEN 'vendor_information' THEN
            v_resource_type := 'vendor';
            IF TG_OP = 'DELETE' THEN
                v_resource_id := OLD.id;
                v_resource_name := OLD.vendor_name;
                v_couple_id := OLD.couple_id;
            ELSE
                v_resource_id := NEW.id;
                v_resource_name := NEW.vendor_name;
                v_couple_id := NEW.couple_id;
            END IF;
        WHEN 'wedding_tasks' THEN
            v_resource_type := 'task';
            IF TG_OP = 'DELETE' THEN
                v_resource_id := OLD.id;
                v_resource_name := OLD.task_name;
                v_couple_id := OLD.couple_id;
            ELSE
                v_resource_id := NEW.id;
                v_resource_name := NEW.task_name;
                v_couple_id := NEW.couple_id;
            END IF;
        WHEN 'collaborators' THEN
            v_resource_type := 'collaborator';
            IF TG_OP = 'DELETE' THEN
                v_resource_id := OLD.id;
                v_resource_name := COALESCE(OLD.display_name, OLD.email);
                v_couple_id := OLD.couple_id;
            ELSE
                v_resource_id := NEW.id;
                v_resource_name := COALESCE(NEW.display_name, NEW.email);
                v_couple_id := NEW.couple_id;
            END IF;
        ELSE
            RETURN COALESCE(NEW, OLD);
    END CASE;
    
    -- Create description
    v_description := v_actor_name || ' ' || v_action_type || ' ' || v_resource_type || ': ' || v_resource_name;
    
    -- Insert activity event
    INSERT INTO activity_events (
        couple_id,
        actor_id,
        actor_name,
        action_type,
        resource_type,
        resource_id,
        resource_name,
        description
    ) VALUES (
        v_couple_id,
        v_actor_id,
        v_actor_name,
        v_action_type,
        v_resource_type,
        v_resource_id,
        v_resource_name,
        v_description
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$$;

-- =====================================================
-- FUNCTION: Broadcast Change via pg_notify
-- =====================================================
CREATE OR REPLACE FUNCTION broadcast_change()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = ''
LANGUAGE plpgsql
AS $$
DECLARE
    v_payload JSON;
    v_couple_id UUID;
BEGIN
    -- Get couple_id from the record
    IF TG_OP = 'DELETE' THEN
        v_couple_id := OLD.couple_id;
    ELSE
        v_couple_id := NEW.couple_id;
    END IF;
    
    -- Create payload
    v_payload := json_build_object(
        'table', TG_TABLE_NAME,
        'operation', TG_OP,
        'couple_id', v_couple_id,
        'timestamp', NOW()
    );
    
    -- Broadcast via pg_notify
    PERFORM pg_notify('collaboration_changes', v_payload::text);
    
    RETURN COALESCE(NEW, OLD);
END;
$$;

-- =====================================================
-- FUNCTION: Cleanup Stale Presence
-- =====================================================
CREATE OR REPLACE FUNCTION cleanup_stale_presence()
RETURNS INTEGER
SECURITY DEFINER
SET search_path = ''
LANGUAGE plpgsql
AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    -- Delete presence records with heartbeat older than 5 minutes
    DELETE FROM presence
    WHERE last_heartbeat < NOW() - INTERVAL '5 minutes';
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RETURN v_deleted_count;
END;
$$;

-- =====================================================
-- TRIGGERS: Activity Logging
-- =====================================================

-- Guest list
DROP TRIGGER IF EXISTS log_guest_activity ON guest_list;
CREATE TRIGGER log_guest_activity
    AFTER INSERT OR UPDATE OR DELETE ON guest_list
    FOR EACH ROW
    EXECUTE FUNCTION log_activity_event();

-- Budget categories
DROP TRIGGER IF EXISTS log_budget_category_activity ON budget_categories;
CREATE TRIGGER log_budget_category_activity
    AFTER INSERT OR UPDATE OR DELETE ON budget_categories
    FOR EACH ROW
    EXECUTE FUNCTION log_activity_event();

-- Expenses
DROP TRIGGER IF EXISTS log_expense_activity ON expenses;
CREATE TRIGGER log_expense_activity
    AFTER INSERT OR UPDATE OR DELETE ON expenses
    FOR EACH ROW
    EXECUTE FUNCTION log_activity_event();

-- Vendors
DROP TRIGGER IF EXISTS log_vendor_activity ON vendor_information;
CREATE TRIGGER log_vendor_activity
    AFTER INSERT OR UPDATE OR DELETE ON vendor_information
    FOR EACH ROW
    EXECUTE FUNCTION log_activity_event();

-- Tasks
DROP TRIGGER IF EXISTS log_task_activity ON wedding_tasks;
CREATE TRIGGER log_task_activity
    AFTER INSERT OR UPDATE OR DELETE ON wedding_tasks
    FOR EACH ROW
    EXECUTE FUNCTION log_activity_event();

-- Collaborators
DROP TRIGGER IF EXISTS log_collaborator_activity ON collaborators;
CREATE TRIGGER log_collaborator_activity
    AFTER INSERT OR UPDATE OR DELETE ON collaborators
    FOR EACH ROW
    EXECUTE FUNCTION log_activity_event();

-- =====================================================
-- TRIGGERS: Realtime Broadcasting
-- =====================================================

-- Collaborators
DROP TRIGGER IF EXISTS broadcast_collaborator_change ON collaborators;
CREATE TRIGGER broadcast_collaborator_change
    AFTER INSERT OR UPDATE OR DELETE ON collaborators
    FOR EACH ROW
    EXECUTE FUNCTION broadcast_change();

-- Presence
DROP TRIGGER IF EXISTS broadcast_presence_change ON presence;
CREATE TRIGGER broadcast_presence_change
    AFTER INSERT OR UPDATE OR DELETE ON presence
    FOR EACH ROW
    EXECUTE FUNCTION broadcast_change();

-- Activity events
DROP TRIGGER IF EXISTS broadcast_activity_change ON activity_events;
CREATE TRIGGER broadcast_activity_change
    AFTER INSERT ON activity_events
    FOR EACH ROW
    EXECUTE FUNCTION broadcast_change();

-- Comments
COMMENT ON FUNCTION log_activity_event() IS 'Logs changes to activity_events table for audit trail';
COMMENT ON FUNCTION broadcast_change() IS 'Broadcasts changes via pg_notify for Supabase Realtime';
COMMENT ON FUNCTION cleanup_stale_presence() IS 'Removes stale presence records (>5 minutes old)';
