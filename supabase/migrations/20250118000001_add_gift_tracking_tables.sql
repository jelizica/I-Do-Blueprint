-- Migration: Add gift_received and money_owed tables
-- Created: 2025-01-18
-- Purpose: Implement database persistence for GiftReceived and MoneyOwed tracking

-- Create gift_received table
CREATE TABLE IF NOT EXISTS gift_received (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    couple_id UUID NOT NULL REFERENCES couple_profiles(id) ON DELETE CASCADE,
    from_person TEXT NOT NULL,
    amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    date_received DATE NOT NULL,
    gift_type TEXT NOT NULL CHECK (gift_type IN ('Cash', 'Check', 'Gift', 'Gift Card', 'Other')),
    notes TEXT,
    is_thank_you_sent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create money_owed table
CREATE TABLE IF NOT EXISTS money_owed (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    couple_id UUID NOT NULL REFERENCES couple_profiles(id) ON DELETE CASCADE,
    to_person TEXT NOT NULL,
    amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    reason TEXT NOT NULL,
    due_date DATE,
    priority TEXT NOT NULL DEFAULT 'Medium' CHECK (priority IN ('Low', 'Medium', 'High')),
    notes TEXT,
    is_paid BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_gift_received_couple_id ON gift_received(couple_id);
CREATE INDEX IF NOT EXISTS idx_gift_received_date_received ON gift_received(date_received DESC);
CREATE INDEX IF NOT EXISTS idx_money_owed_couple_id ON money_owed(couple_id);
CREATE INDEX IF NOT EXISTS idx_money_owed_due_date ON money_owed(due_date);
CREATE INDEX IF NOT EXISTS idx_money_owed_is_paid ON money_owed(is_paid);

-- Enable Row Level Security
ALTER TABLE gift_received ENABLE ROW LEVEL SECURITY;
ALTER TABLE money_owed ENABLE ROW LEVEL SECURITY;

-- RLS Policies for gift_received
CREATE POLICY "Enable read access for authenticated users"
    ON gift_received FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert for authenticated users"
    ON gift_received FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update for authenticated users"
    ON gift_received FOR UPDATE
    USING (auth.role() = 'authenticated');

CREATE POLICY "Enable delete for authenticated users"
    ON gift_received FOR DELETE
    USING (auth.role() = 'authenticated');

-- RLS Policies for money_owed
CREATE POLICY "Enable read access for authenticated users"
    ON money_owed FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert for authenticated users"
    ON money_owed FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update for authenticated users"
    ON money_owed FOR UPDATE
    USING (auth.role() = 'authenticated');

CREATE POLICY "Enable delete for authenticated users"
    ON money_owed FOR DELETE
    USING (auth.role() = 'authenticated');

-- Create function for updating updated_at timestamp if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_gift_received_updated_at
    BEFORE UPDATE ON gift_received
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_money_owed_updated_at
    BEFORE UPDATE ON money_owed
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add comments for documentation
COMMENT ON TABLE gift_received IS 'Tracks gifts received from guests and family members';
COMMENT ON TABLE money_owed IS 'Tracks money owed to vendors, family, or other parties';
COMMENT ON COLUMN gift_received.gift_type IS 'Type of gift: Cash, Check, Gift, Gift Card, or Other';
COMMENT ON COLUMN money_owed.priority IS 'Payment priority: Low, Medium, or High';
