-- Fix ensure_single_primary_scenario() function to use explicit schema qualification
-- This fixes the "relation budget_development_scenarios does not exist" error
-- 
-- Root cause: Function has search_path='' but uses unqualified table name
-- Solution: Add public. prefix to table name in UPDATE statement

-- Drop existing trigger first (will be recreated)
DROP TRIGGER IF EXISTS enforce_single_primary_scenario ON public.budget_development_scenarios;

-- Drop and recreate function with proper schema qualification
DROP FUNCTION IF EXISTS public.ensure_single_primary_scenario();

CREATE OR REPLACE FUNCTION public.ensure_single_primary_scenario()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO ''  -- Keep security setting: empty search path
AS $function$
BEGIN
    -- If setting a scenario as primary, unset all others for this couple
    IF NEW.is_primary = TRUE THEN
        -- ✅ FIX: Use explicit schema qualification (public.budget_development_scenarios)
        UPDATE public.budget_development_scenarios
        SET is_primary = FALSE
        WHERE couple_id = NEW.couple_id  -- ✅ IMPROVEMENT: Only affect same couple
          AND id != NEW.id 
          AND is_primary = TRUE;
    END IF;
    
    RETURN NEW;
END;
$function$;

-- Recreate trigger with exact same settings as before
CREATE TRIGGER enforce_single_primary_scenario 
    BEFORE INSERT OR UPDATE 
    ON public.budget_development_scenarios 
    FOR EACH ROW 
    WHEN (new.is_primary = true) 
    EXECUTE FUNCTION ensure_single_primary_scenario();

-- Add comment for documentation
COMMENT ON FUNCTION public.ensure_single_primary_scenario() IS 
'Ensures only one budget development scenario is marked as primary per couple.
Uses explicit schema qualification (public.) because search_path is empty for security.
Trigger fires BEFORE INSERT OR UPDATE when is_primary is set to true.';

COMMENT ON TRIGGER enforce_single_primary_scenario ON public.budget_development_scenarios IS
'Automatically unsets is_primary on other scenarios when a new primary is set.
Scoped to the same couple_id to prevent cross-tenant interference.';
