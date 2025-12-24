-- Migration: Fix save_budget_scenario_with_items function overload
-- Purpose: Remove duplicate function signatures and create single correct version
-- Date: 2025-02-24
-- FIXED: Uses correct column names from budget_development_items schema

-- Drop ALL existing versions of the function (both signatures)
DROP FUNCTION IF EXISTS public.save_budget_scenario_with_items(jsonb, jsonb);
DROP FUNCTION IF EXISTS public.save_budget_scenario_with_items(jsonb, jsonb[]);

-- Create the ONLY correct version with jsonb[] for items array
CREATE FUNCTION public.save_budget_scenario_with_items(
    p_scenario jsonb,
    p_items jsonb[]
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_scenario_id uuid;
    v_couple_id uuid;
    v_item jsonb;
    v_item_id uuid;
    v_inserted_count int := 0;
    v_result jsonb;
BEGIN
    -- Extract couple_id and scenario_id from scenario JSON
    v_couple_id := (p_scenario->>'couple_id')::uuid;
    v_scenario_id := COALESCE((p_scenario->>'id')::uuid, gen_random_uuid());

    -- Validate couple_id is provided
    IF v_couple_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'couple_id is required in scenario'
        );
    END IF;

    -- Upsert the scenario row
    INSERT INTO public.budget_development_scenarios (
        id,
        couple_id,
        scenario_name,
        total_without_tax,
        total_tax,
        total_with_tax,
        is_primary,
        created_at,
        updated_at
    )
    VALUES (
        v_scenario_id,
        v_couple_id,
        p_scenario->>'scenario_name',
        (p_scenario->>'total_without_tax')::numeric,
        (p_scenario->>'total_tax')::numeric,
        (p_scenario->>'total_with_tax')::numeric,
        COALESCE((p_scenario->>'is_primary')::boolean, false),
        COALESCE((p_scenario->>'created_at')::timestamp, now()),
        now()
    )
    ON CONFLICT (id) DO UPDATE SET
        scenario_name = EXCLUDED.scenario_name,
        total_without_tax = EXCLUDED.total_without_tax,
        total_tax = EXCLUDED.total_tax,
        total_with_tax = EXCLUDED.total_with_tax,
        is_primary = EXCLUDED.is_primary,
        updated_at = now();

    -- Process each item
    IF p_items IS NOT NULL AND array_length(p_items, 1) > 0 THEN
        FOR v_item IN SELECT unnest(p_items)
        LOOP
            -- Generate UUID for new items, use provided id for existing items
            v_item_id := COALESCE((v_item->>'id')::uuid, gen_random_uuid());

            -- Upsert the item by primary key id
            -- Using correct column names from budget_development_items schema
            INSERT INTO public.budget_development_items (
                id,
                couple_id,
                scenario_id,
                item_name,
                category,
                subcategory,
                vendor_estimate_without_tax,
                tax_rate,
                vendor_estimate_with_tax,
                person_responsible,
                notes,
                linked_gift_owed_id,
                created_at,
                updated_at
            )
            VALUES (
                v_item_id,
                v_couple_id,
                v_scenario_id,
                v_item->>'item_name',
                v_item->>'category',
                v_item->>'subcategory',
                (v_item->>'vendor_estimate_without_tax')::numeric,
                (v_item->>'tax_rate')::numeric,
                (v_item->>'vendor_estimate_with_tax')::numeric,
                v_item->>'person_responsible',
                v_item->>'notes',
                (v_item->>'linked_gift_owed_id')::uuid,
                COALESCE((v_item->>'created_at')::timestamp, now()),
                now()
            )
            ON CONFLICT (id) DO UPDATE SET
                item_name = EXCLUDED.item_name,
                category = EXCLUDED.category,
                subcategory = EXCLUDED.subcategory,
                vendor_estimate_without_tax = EXCLUDED.vendor_estimate_without_tax,
                tax_rate = EXCLUDED.tax_rate,
                vendor_estimate_with_tax = EXCLUDED.vendor_estimate_with_tax,
                person_responsible = EXCLUDED.person_responsible,
                notes = EXCLUDED.notes,
                linked_gift_owed_id = EXCLUDED.linked_gift_owed_id,
                updated_at = now();

            v_inserted_count := v_inserted_count + 1;
        END LOOP;
    END IF;

    -- Return success response with scenario_id and item count
    v_result := jsonb_build_object(
        'scenario_id', v_scenario_id::text,
        'inserted_items', v_inserted_count,
        'success', true
    );

    RETURN jsonb_build_array(v_result);
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.save_budget_scenario_with_items(jsonb, jsonb[]) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION public.save_budget_scenario_with_items(jsonb, jsonb[]) IS
'Idempotent upsert of budget scenario and its items. Handles both creates and updates without PK conflicts.
Parameters:
  - p_scenario: JSON object with scenario data (id, couple_id, scenario_name, total_without_tax, total_tax, total_with_tax, is_primary)
  - p_items: Array of JSON objects with item data (id, couple_id, scenario_id, item_name, category, subcategory, vendor_estimate_without_tax, tax_rate, vendor_estimate_with_tax, person_responsible, notes, linked_gift_owed_id)
Returns: JSON array with single object containing scenario_id, inserted_items count, and success flag';
