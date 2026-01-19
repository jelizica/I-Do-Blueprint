-- Migration: Create gift_budget_allocations table
-- Purpose: Support proportional allocation of gifts to multiple budget items
-- Pattern: Mirrors expense_budget_allocations table structure

-- Create gift_budget_allocations table
CREATE TABLE IF NOT EXISTS gift_budget_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gift_id UUID NOT NULL REFERENCES gifts_and_owed(id) ON DELETE CASCADE,
    budget_item_id UUID NOT NULL,
    allocated_amount NUMERIC NOT NULL DEFAULT 0,
    percentage NUMERIC,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    couple_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
    scenario_id UUID NOT NULL,
    is_test_data BOOLEAN DEFAULT false,

    -- Ensure unique allocation per gift/budget item/scenario combination
    CONSTRAINT unique_gift_budget_allocation UNIQUE (gift_id, budget_item_id, scenario_id)
);

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_gift_allocations_gift_id
    ON gift_budget_allocations(gift_id);

CREATE INDEX IF NOT EXISTS idx_gift_allocations_budget_item_id
    ON gift_budget_allocations(budget_item_id);

CREATE INDEX IF NOT EXISTS idx_gift_allocations_scenario_id
    ON gift_budget_allocations(scenario_id);

CREATE INDEX IF NOT EXISTS idx_gift_allocations_couple_id
    ON gift_budget_allocations(couple_id);

-- Composite index for common query patterns
CREATE INDEX IF NOT EXISTS idx_gift_allocations_scenario_budget_item
    ON gift_budget_allocations(scenario_id, budget_item_id);

-- Enable Row Level Security
ALTER TABLE gift_budget_allocations ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Couples can only access their own gift allocations
CREATE POLICY "couples_manage_own_gift_allocations"
    ON gift_budget_allocations
    FOR ALL
    USING (couple_id = (SELECT get_user_couple_id()))
    WITH CHECK (couple_id = (SELECT get_user_couple_id()));

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_gift_allocations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER gift_allocations_updated_at
    BEFORE UPDATE ON gift_budget_allocations
    FOR EACH ROW
    EXECUTE FUNCTION update_gift_allocations_updated_at();

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON gift_budget_allocations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON gift_budget_allocations TO service_role;

COMMENT ON TABLE gift_budget_allocations IS 'Proportional allocation of gifts to budget items, mirrors expense_budget_allocations pattern';
COMMENT ON COLUMN gift_budget_allocations.gift_id IS 'Reference to the gift being allocated';
COMMENT ON COLUMN gift_budget_allocations.budget_item_id IS 'Reference to the budget development item receiving allocation';
COMMENT ON COLUMN gift_budget_allocations.allocated_amount IS 'Dollar amount allocated to this budget item';
COMMENT ON COLUMN gift_budget_allocations.percentage IS 'Optional percentage for reference (calculated from budgeted amounts)';
COMMENT ON COLUMN gift_budget_allocations.scenario_id IS 'Budget development scenario this allocation belongs to';
