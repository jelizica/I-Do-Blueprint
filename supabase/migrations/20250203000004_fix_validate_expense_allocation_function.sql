-- Fix validate_expense_allocation function to use schema-qualified table names
-- This function has SET search_path TO '' for security, so it needs explicit schema qualification

CREATE OR REPLACE FUNCTION public.validate_expense_allocation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO ''
AS $function$
DECLARE
    budget_item_scenario_id UUID;
    expense_couple_id UUID;
    v_is_valid BOOLEAN;
    v_message TEXT;
    v_scenario_name TEXT;
    original_errcode TEXT;
    original_errmsg TEXT;
BEGIN
    -- Auto-populate scenario_id from budget item if not provided
    IF NEW.scenario_id IS NULL AND NEW.budget_item_id IS NOT NULL THEN
        SELECT scenario_id INTO NEW.scenario_id
        FROM public.budget_development_items  -- ✅ Schema-qualified
        WHERE id = NEW.budget_item_id;
        
        IF NEW.scenario_id IS NULL THEN
            RAISE EXCEPTION 'Cannot determine scenario_id: budget item % not found', NEW.budget_item_id
                USING ERRCODE = 'P0001',
                      HINT = 'Verify that the budget item exists and has a valid scenario_id';
        END IF;
    END IF;

    -- Get budget item's scenario_id for validation
    SELECT scenario_id INTO budget_item_scenario_id
    FROM public.budget_development_items  -- ✅ Schema-qualified
    WHERE id = NEW.budget_item_id;
    
    IF budget_item_scenario_id IS NULL THEN
        RAISE EXCEPTION 'Budget item % not found', NEW.budget_item_id
            USING ERRCODE = 'P0002',
                  HINT = 'Verify that the budget item ID exists in the database';
    END IF;
    
    -- Ensure scenario consistency
    IF NEW.scenario_id != budget_item_scenario_id THEN
        -- Get scenario name with explicit column qualification
        SELECT bds.scenario_name INTO v_scenario_name
        FROM public.budget_development_scenarios bds  -- ✅ Schema-qualified
        WHERE bds.id = NEW.scenario_id;
        
        RAISE EXCEPTION 'Allocation scenario mismatch: allocation belongs to scenario "%"(%) but budget item belongs to scenario %', 
            COALESCE(v_scenario_name, 'Unknown'), NEW.scenario_id, budget_item_scenario_id
            USING ERRCODE = 'P0003',
                  HINT = 'Ensure the allocation scenario_id matches the budget item scenario_id';
    END IF;
    
    -- Get expense couple_id for tenant validation
    SELECT couple_id INTO expense_couple_id
    FROM public.expenses  -- ✅ Schema-qualified
    WHERE id = NEW.expense_id;
    
    IF expense_couple_id IS NULL THEN
        RAISE EXCEPTION 'Expense % not found', NEW.expense_id
            USING ERRCODE = 'P0004',
                  HINT = 'Verify that the expense ID exists in the database';
    END IF;
    
    -- Ensure couple_id consistency
    IF NEW.couple_id != expense_couple_id THEN
        RAISE EXCEPTION 'Tenant mismatch: allocation couple_id (%) does not match expense couple_id (%)', 
            NEW.couple_id, expense_couple_id
            USING ERRCODE = 'P0005',
                  HINT = 'Ensure the allocation belongs to the same couple as the expense';
    END IF;

    -- Use the scenario-aware validation function
    SELECT * INTO v_is_valid, v_message
    FROM public.validate_expense_allocation_by_scenario_detailed(  -- ✅ Schema-qualified
        NEW.expense_id,
        NEW.budget_item_id,
        NEW.allocated_amount,
        NEW.scenario_id
    );
    
    IF NOT v_is_valid THEN
        -- Get scenario name with explicit column qualification
        SELECT bds.scenario_name INTO v_scenario_name
        FROM public.budget_development_scenarios bds  -- ✅ Schema-qualified
        WHERE bds.id = NEW.scenario_id;
        
        RAISE EXCEPTION 'Scenario allocation validation failed in scenario "%"(%): %', 
            COALESCE(v_scenario_name, 'Unknown'), 
            NEW.scenario_id,
            COALESCE(v_message, 'Invalid allocation amount or scenario constraints violated')
            USING ERRCODE = 'P0006',
                  HINT = 'Check allocation amount against budget limits and existing allocations within this scenario';
    END IF;
    
    -- Optional debug logging
    IF current_setting('app.debug_allocation_validation', true) = 'true' THEN
        RAISE NOTICE 'Cross-scenario allocation validated successfully: expense=%, budget_item=%, amount=%, scenario=% (%)', 
            NEW.expense_id, NEW.budget_item_id, NEW.allocated_amount, NEW.scenario_id, COALESCE(v_scenario_name, 'Unknown');
    END IF;

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS 
            original_errcode = RETURNED_SQLSTATE,
            original_errmsg = MESSAGE_TEXT;
        
        RAISE EXCEPTION USING 
            ERRCODE = original_errcode,
            MESSAGE = format('Allocation validation failed for expense %s -> budget item %s (amount %s, scenario %s): %s', 
                NEW.expense_id, NEW.budget_item_id, NEW.allocated_amount, NEW.scenario_id, original_errmsg),
            HINT = format('Original error: %s (%s)', original_errmsg, original_errcode);
END;
$function$;

-- Add comment explaining the fix
COMMENT ON FUNCTION public.validate_expense_allocation() IS 
'Validates expense allocations to budget items with scenario awareness.
Uses SET search_path TO '''' for security, so all table references are schema-qualified.
Fixed in migration 20250203000004 to properly qualify all table names.';
