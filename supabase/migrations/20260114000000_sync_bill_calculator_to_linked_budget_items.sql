-- =============================================================================
-- Migration: sync_bill_calculator_to_linked_budget_items
-- Purpose: Automatically update linked budget items when bill calculator totals change
--
-- This trigger ensures that when a bill calculator's items or guest count change,
-- all budget development items linked to that calculator are automatically updated
-- with the new subtotal and recalculated tax amounts.
-- =============================================================================

-- Function to calculate bill calculator subtotal from its items
CREATE OR REPLACE FUNCTION public.calculate_bill_calculator_subtotal(p_calculator_id UUID)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_subtotal NUMERIC := 0;
    v_guest_count INTEGER;
    v_item RECORD;
BEGIN
    -- Get the guest count for this calculator
    SELECT guest_count INTO v_guest_count
    FROM bill_calculators
    WHERE id = p_calculator_id;

    IF v_guest_count IS NULL THEN
        RETURN 0;
    END IF;

    -- Calculate subtotal based on item types
    FOR v_item IN
        SELECT type, amount, item_quantity
        FROM bill_calculator_items
        WHERE calculator_id = p_calculator_id
    LOOP
        CASE v_item.type
            WHEN 'perPerson' THEN
                -- Per person items multiply by guest count
                v_subtotal := v_subtotal + (v_item.amount * v_guest_count);
            WHEN 'flatFee' THEN
                -- Flat fee items are added as-is
                v_subtotal := v_subtotal + v_item.amount;
            WHEN 'serviceFee' THEN
                -- Service fee items are added as-is (percentage applied at display)
                v_subtotal := v_subtotal + v_item.amount;
            WHEN 'variable' THEN
                -- Variable items multiply by their quantity
                v_subtotal := v_subtotal + (v_item.amount * COALESCE(v_item.item_quantity, 1));
            ELSE
                -- Unknown type, add as flat
                v_subtotal := v_subtotal + v_item.amount;
        END CASE;
    END LOOP;

    RETURN v_subtotal;
END;
$$;

COMMENT ON FUNCTION public.calculate_bill_calculator_subtotal(UUID) IS
'Calculates the pre-tax subtotal for a bill calculator based on its items and guest count.';

-- Function to sync bill calculator changes to linked budget items
CREATE OR REPLACE FUNCTION public.sync_bill_to_linked_budget_items()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_calculator_id UUID;
    v_subtotal NUMERIC;
    v_budget_item RECORD;
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

    -- Calculate the new subtotal
    v_subtotal := calculate_bill_calculator_subtotal(v_calculator_id);

    -- Update all budget items linked to this calculator
    FOR v_budget_item IN
        SELECT id, tax_rate
        FROM budget_development_items
        WHERE linked_bill_calculator_id = v_calculator_id
    LOOP
        UPDATE budget_development_items
        SET
            vendor_estimate_without_tax = v_subtotal,
            vendor_estimate_with_tax = v_subtotal * (1 + tax_rate / 100),
            updated_at = NOW()
        WHERE id = v_budget_item.id;
    END LOOP;

    RETURN COALESCE(NEW, OLD);
END;
$$;

COMMENT ON FUNCTION public.sync_bill_to_linked_budget_items() IS
'Trigger function that automatically updates linked budget items when bill calculator items or guest count changes.';

-- Create trigger on bill_calculator_items table
DROP TRIGGER IF EXISTS sync_bill_items_to_budget ON bill_calculator_items;
CREATE TRIGGER sync_bill_items_to_budget
    AFTER INSERT OR UPDATE OR DELETE ON bill_calculator_items
    FOR EACH ROW
    EXECUTE FUNCTION sync_bill_to_linked_budget_items();

-- Create trigger on bill_calculators table (for guest count changes)
DROP TRIGGER IF EXISTS sync_bill_guest_count_to_budget ON bill_calculators;
CREATE TRIGGER sync_bill_guest_count_to_budget
    AFTER UPDATE ON bill_calculators
    FOR EACH ROW
    EXECUTE FUNCTION sync_bill_to_linked_budget_items();

-- Add comments
COMMENT ON TRIGGER sync_bill_items_to_budget ON bill_calculator_items IS
'Syncs bill calculator item changes to linked budget development items.';

COMMENT ON TRIGGER sync_bill_guest_count_to_budget ON bill_calculators IS
'Syncs bill calculator guest count changes to linked budget development items.';
