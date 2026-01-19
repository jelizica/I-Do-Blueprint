-- =============================================================================
-- Migration: sync_bill_to_junction_linked_budget_items
-- Purpose: Extend bill calculator sync to support many-to-many linking via junction table
--
-- The existing trigger (sync_bill_to_linked_budget_items) only updates budget items
-- linked via the 1:1 linked_bill_calculator_id column. This migration extends support
-- to budget items linked via the budget_item_bill_calculator_links junction table.
--
-- When a bill calculator's items or guest count change, ALL budget items linked
-- to that calculator (via either method) will be updated with recalculated totals.
-- =============================================================================

-- Replace the sync function to also check the junction table
CREATE OR REPLACE FUNCTION public.sync_bill_to_linked_budget_items()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_calculator_id UUID;
    v_budget_item RECORD;
    v_link RECORD;
    v_combined_subtotal NUMERIC;
    v_linked_calculator_ids UUID[];
BEGIN
    -- Determine the calculator ID based on trigger context
    IF TG_TABLE_NAME = 'bill_calculator_items' THEN
        -- Item was inserted, updated, or deleted
        v_calculator_id := COALESCE(NEW.calculator_id, OLD.calculator_id);
    ELSIF TG_TABLE_NAME = 'bill_calculators' THEN
        -- Calculator itself was updated (e.g., guest count change)
        v_calculator_id := COALESCE(NEW.id, OLD.id);

        -- Only process if guest_count changed (affects per-person calculations)
        IF TG_OP = 'UPDATE' AND OLD.guest_count = NEW.guest_count THEN
            RETURN COALESCE(NEW, OLD);
        END IF;
    END IF;

    -- Skip if no calculator ID (shouldn't happen)
    IF v_calculator_id IS NULL THEN
        RETURN COALESCE(NEW, OLD);
    END IF;

    -- Calculate the new subtotal for this calculator
    -- (reuses the existing calculate_bill_calculator_subtotal function)

    -- =========================================================================
    -- PART 1: Update budget items linked via 1:1 linked_bill_calculator_id column
    -- =========================================================================
    UPDATE budget_development_items
    SET
        vendor_estimate_without_tax = calculate_bill_calculator_subtotal(v_calculator_id),
        vendor_estimate_with_tax = calculate_bill_calculator_subtotal(v_calculator_id) * (1 + tax_rate / 100),
        updated_at = NOW()
    WHERE linked_bill_calculator_id = v_calculator_id;

    -- =========================================================================
    -- PART 2: Update budget items linked via many-to-many junction table
    -- For each budget item that has this calculator in its links, recalculate
    -- the combined subtotal from ALL linked calculators
    -- =========================================================================
    FOR v_budget_item IN
        SELECT DISTINCT bdi.id, bdi.tax_rate
        FROM budget_development_items bdi
        INNER JOIN budget_item_bill_calculator_links bibl ON bibl.budget_item_id = bdi.id
        WHERE bibl.bill_calculator_id = v_calculator_id
    LOOP
        -- Get all calculator IDs linked to this budget item
        SELECT ARRAY_AGG(bill_calculator_id)
        INTO v_linked_calculator_ids
        FROM budget_item_bill_calculator_links
        WHERE budget_item_id = v_budget_item.id;

        -- Calculate combined subtotal from all linked calculators
        SELECT COALESCE(SUM(calculate_bill_calculator_subtotal(unnest)), 0)
        INTO v_combined_subtotal
        FROM unnest(v_linked_calculator_ids);

        -- Update the budget item with combined total (both without and with tax)
        UPDATE budget_development_items
        SET
            vendor_estimate_without_tax = v_combined_subtotal,
            vendor_estimate_with_tax = v_combined_subtotal * (1 + v_budget_item.tax_rate / 100),
            updated_at = NOW()
        WHERE id = v_budget_item.id;
    END LOOP;

    RETURN COALESCE(NEW, OLD);
END;
$$;

COMMENT ON FUNCTION public.sync_bill_to_linked_budget_items() IS
'Trigger function that automatically updates linked budget items when bill calculator items or guest count changes. Supports both 1:1 linking (linked_bill_calculator_id) and many-to-many linking (budget_item_bill_calculator_links junction table).';

-- The existing triggers on bill_calculator_items and bill_calculators tables
-- will now use the updated function automatically (no need to recreate them)
