-- Fix validate_expense_allocation_by_scenario_detailed function to use schema-qualified table names
-- This function has SET search_path TO '' for security, so it needs explicit schema qualification

CREATE OR REPLACE FUNCTION public.validate_expense_allocation_by_scenario_detailed(
    p_expense_id uuid, 
    p_budget_item_id uuid, 
    p_allocated_amount numeric, 
    p_scenario_id uuid, 
    p_allocation_id uuid DEFAULT NULL::uuid, 
    OUT is_valid boolean, 
    OUT message text
)
RETURNS record
LANGUAGE plpgsql
SET search_path TO ''
AS $function$
DECLARE
    expense_total DECIMAL(10,2);
    allocated_total DECIMAL(10,2);
    budget_item_scenario_id UUID;
BEGIN
    -- Initialize output parameters
    is_valid := FALSE;
    message := '';
    
    -- Validate that allocated amount is not negative
    IF p_allocated_amount < 0 THEN
        message := 'Allocated amount cannot be negative: ' || p_allocated_amount;
        RETURN;
    END IF;
    
    -- Validate that expense exists
    SELECT amount INTO expense_total
    FROM public.expenses  -- ✅ Schema-qualified
    WHERE id = p_expense_id;
    
    IF expense_total IS NULL THEN
        message := 'Expense with ID ' || p_expense_id || ' not found';
        RETURN;
    END IF;
    
    -- Validate that scenario exists
    IF NOT EXISTS (SELECT 1 FROM public.budget_development_scenarios WHERE id = p_scenario_id) THEN  -- ✅ Schema-qualified
        message := 'Scenario with ID ' || p_scenario_id || ' not found';
        RETURN;
    END IF;
    
    -- Get the budget item's scenario_id
    SELECT scenario_id INTO budget_item_scenario_id
    FROM public.budget_development_items  -- ✅ Schema-qualified
    WHERE id = p_budget_item_id;
    
    -- Validate that budget item exists and belongs to specified scenario
    IF budget_item_scenario_id IS NULL THEN
        message := 'Budget item with ID ' || p_budget_item_id || ' not found';
        RETURN;
    END IF;
    
    IF budget_item_scenario_id != p_scenario_id THEN
        message := 'Budget item ' || p_budget_item_id || ' belongs to scenario ' || budget_item_scenario_id || ' but expected scenario ' || p_scenario_id;
        RETURN;
    END IF;
    
    -- REMOVED: Cross-scenario allocation check
    -- We now allow the same expense to be allocated to multiple scenarios
    -- This enables users to assign expenses to different budget scenarios simultaneously
    
    -- Calculate total allocated amount for this expense WITHIN THIS SCENARIO ONLY (excluding current allocation if updating)
    SELECT COALESCE(SUM(allocated_amount), 0) INTO allocated_total
    FROM public.expense_budget_allocations  -- ✅ Schema-qualified
    WHERE expense_id = p_expense_id 
      AND scenario_id = p_scenario_id
      AND (p_allocation_id IS NULL OR id != p_allocation_id);
    
    -- Check if adding this allocation would exceed the expense total WITHIN THIS SCENARIO
    IF (allocated_total + p_allocated_amount) > expense_total THEN
        message := 'Total allocated amount (' || (allocated_total + p_allocated_amount) || ') would exceed expense total (' || expense_total || ') for expense ' || p_expense_id || ' in scenario ' || p_scenario_id;
        RETURN;
    END IF;
    
    -- All validations passed
    is_valid := TRUE;
    message := 'Validation successful';
    RETURN;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Reserve exceptions for truly unexpected states (system errors, etc.)
        is_valid := FALSE;
        message := 'Unexpected error during validation: ' || SQLERRM;
        RETURN;
END;
$function$;

-- Add comment explaining the fix
COMMENT ON FUNCTION public.validate_expense_allocation_by_scenario_detailed(uuid, uuid, numeric, uuid, uuid) IS 
'Validates expense allocations with scenario awareness and detailed error messages.
Uses SET search_path TO '''' for security, so all table references are schema-qualified.
Fixed in migration 20250203000005 to properly qualify all table names.';
