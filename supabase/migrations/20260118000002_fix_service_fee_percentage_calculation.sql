-- =============================================================================
-- Migration: fix_service_fee_percentage_calculation
-- Purpose: Fix service fee calculation in calculate_bill_calculator_subtotal
--
-- BUG: Service fees were being added as flat dollar amounts ($25) instead of
--      being calculated as percentages (25% of per-person subtotal = $985.50)
--
-- The Swift model correctly calculates: serviceFeeSubtotal * (amount / 100.0)
-- where serviceFeeSubtotal = perPersonTotal (the sum of all per-person items)
--
-- This migration fixes the database function to match Swift's calculation.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.calculate_bill_calculator_subtotal(p_calculator_id UUID)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_subtotal NUMERIC := 0;
    v_per_person_total NUMERIC := 0;
    v_service_fee_total NUMERIC := 0;
    v_flat_fee_total NUMERIC := 0;
    v_guest_count INTEGER;
    v_guest_count_mode TEXT;
    v_item RECORD;
BEGIN
    -- Get the guest count and mode for this calculator
    SELECT guest_count, guest_count_mode
    INTO v_guest_count, v_guest_count_mode
    FROM bill_calculators
    WHERE id = p_calculator_id;

    IF v_guest_count IS NULL THEN
        RETURN 0;
    END IF;

    -- =========================================================================
    -- STEP 1: Calculate per-person total first (needed for service fee base)
    -- =========================================================================
    FOR v_item IN
        SELECT type, amount, item_quantity, quantity_multiplier
        FROM bill_calculator_items
        WHERE calculator_id = p_calculator_id
        AND type = 'per_person'
    LOOP
        IF v_guest_count_mode = 'variable' THEN
            -- Variable mode: each item uses its own quantity or dynamic calculation
            IF v_item.quantity_multiplier IS NOT NULL THEN
                v_per_person_total := v_per_person_total + (v_item.amount * GREATEST(1, CEIL(v_guest_count * v_item.quantity_multiplier)));
            ELSE
                v_per_person_total := v_per_person_total + (v_item.amount * COALESCE(v_item.item_quantity, 1));
            END IF;
        ELSE
            -- Auto/Manual mode: all items multiply by guest count
            v_per_person_total := v_per_person_total + (v_item.amount * v_guest_count);
        END IF;
    END LOOP;

    -- =========================================================================
    -- STEP 2: Calculate service fee total (percentage of per-person total)
    -- Service fees are stored as percentages (e.g., 25 = 25%)
    -- =========================================================================
    FOR v_item IN
        SELECT amount
        FROM bill_calculator_items
        WHERE calculator_id = p_calculator_id
        AND type = 'service_fee'
    LOOP
        -- Service fee = per_person_total * (percentage / 100)
        v_service_fee_total := v_service_fee_total + (v_per_person_total * (v_item.amount / 100.0));
    END LOOP;

    -- =========================================================================
    -- STEP 3: Calculate flat fee and variable item totals
    -- =========================================================================
    FOR v_item IN
        SELECT type, amount, item_quantity
        FROM bill_calculator_items
        WHERE calculator_id = p_calculator_id
        AND type IN ('flat_fee', 'variable')
    LOOP
        CASE v_item.type
            WHEN 'flat_fee' THEN
                -- Flat fee items are added as-is
                v_flat_fee_total := v_flat_fee_total + v_item.amount;
            WHEN 'variable' THEN
                -- Variable items multiply by their quantity
                v_flat_fee_total := v_flat_fee_total + (v_item.amount * COALESCE(v_item.item_quantity, 1));
        END CASE;
    END LOOP;

    -- =========================================================================
    -- STEP 4: Return combined subtotal (matches Swift's subtotal calculation)
    -- subtotal = perPersonTotal + serviceFeeTotal + flatFeeTotal
    -- =========================================================================
    v_subtotal := v_per_person_total + v_service_fee_total + v_flat_fee_total;

    RETURN v_subtotal;
END;
$$;

COMMENT ON FUNCTION public.calculate_bill_calculator_subtotal(UUID) IS
'Calculates the subtotal for a bill calculator, matching Swift model calculation.
Service fees are calculated as percentages of the per-person subtotal (e.g., 25% = amount * 0.25).
Used by sync_bill_to_linked_budget_items trigger to update budget development items.';

-- =============================================================================
-- STEP 5: Recalculate all existing budget items linked to bill calculators
-- This ensures all historical data is corrected with the new calculation logic
-- =============================================================================

-- Part A: Update budget items linked via 1:1 relationship (linked_bill_calculator_id)
UPDATE budget_development_items bdi
SET
    vendor_estimate_without_tax = calculate_bill_calculator_subtotal(bdi.linked_bill_calculator_id),
    vendor_estimate_with_tax = calculate_bill_calculator_subtotal(bdi.linked_bill_calculator_id) * (1 + COALESCE(bdi.tax_rate, 0) / 100),
    updated_at = NOW()
WHERE bdi.linked_bill_calculator_id IS NOT NULL;

-- Part B: Update budget items linked via many-to-many junction table
-- For each budget item with linked calculators, sum up all linked calculator subtotals
WITH linked_totals AS (
    SELECT
        bibl.budget_item_id,
        SUM(calculate_bill_calculator_subtotal(bibl.bill_calculator_id)) AS combined_subtotal
    FROM budget_item_bill_calculator_links bibl
    GROUP BY bibl.budget_item_id
)
UPDATE budget_development_items bdi
SET
    vendor_estimate_without_tax = lt.combined_subtotal,
    vendor_estimate_with_tax = lt.combined_subtotal * (1 + COALESCE(bdi.tax_rate, 0) / 100),
    updated_at = NOW()
FROM linked_totals lt
WHERE bdi.id = lt.budget_item_id;
