-- Migration: Add is_tax_exempt column to bill_calculator_items table
-- Purpose: Allow individual items to be marked as exempt from tax calculations
-- Default: false (items are taxed by default)

-- Add the is_tax_exempt column with default value of false
ALTER TABLE bill_calculator_items
ADD COLUMN IF NOT EXISTS is_tax_exempt BOOLEAN DEFAULT FALSE NOT NULL;

-- Add comment explaining the column's purpose
COMMENT ON COLUMN bill_calculator_items.is_tax_exempt IS 'When true, this item is excluded from tax calculations. Default is false (item is taxed).';
