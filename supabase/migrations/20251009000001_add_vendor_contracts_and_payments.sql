-- Add vendor contract and payment tracking fields
-- This migration adds support for contract status, dates, and payment tracking using existing tables

-- Add new columns to vendor_documents for contract expiry
ALTER TABLE vendor_documents
ADD COLUMN IF NOT EXISTS contract_expiry_date DATE,
ADD COLUMN IF NOT EXISTS contract_status TEXT CHECK (contract_status IN ('draft', 'pending', 'signed', 'expired', 'none')) DEFAULT 'none';

-- Enhance existing paymentPlans table with additional payment tracking fields
ALTER TABLE "paymentPlans"
ADD COLUMN IF NOT EXISTS payment_method TEXT CHECK (payment_method IN ('cash', 'check', 'credit_card', 'debit_card', 'bank_transfer', 'other')),
ADD COLUMN IF NOT EXISTS payment_status TEXT CHECK (payment_status IN ('pending', 'overdue', 'paid', 'cancelled', 'refunded')) DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS transaction_id TEXT,
ADD COLUMN IF NOT EXISTS receipt_url TEXT;

-- Create indexes for faster queries on paymentPlans
CREATE INDEX IF NOT EXISTS idx_paymentplans_vendor_id ON "paymentPlans"(vendor_id);
CREATE INDEX IF NOT EXISTS idx_paymentplans_payment_date ON "paymentPlans"(payment_date);
CREATE INDEX IF NOT EXISTS idx_paymentplans_paid ON "paymentPlans"(paid);

-- Add address fields directly to vendorInformation table
ALTER TABLE "vendorInformation"
ADD COLUMN IF NOT EXISTS street_address TEXT,
ADD COLUMN IF NOT EXISTS street_address_2 TEXT,
ADD COLUMN IF NOT EXISTS city TEXT,
ADD COLUMN IF NOT EXISTS state TEXT,
ADD COLUMN IF NOT EXISTS postal_code TEXT,
ADD COLUMN IF NOT EXISTS country TEXT DEFAULT 'US',
ADD COLUMN IF NOT EXISTS latitude NUMERIC(10, 8),
ADD COLUMN IF NOT EXISTS longitude NUMERIC(11, 8);

-- Create function to automatically update contract_status based on dates
CREATE OR REPLACE FUNCTION update_vendor_contract_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Update contract status based on signed state and expiry date
    IF NEW.contract_signed = true THEN
        IF NEW.contract_expiry_date IS NOT NULL AND NEW.contract_expiry_date < CURRENT_DATE THEN
            NEW.contract_status = 'expired';
        ELSE
            NEW.contract_status = 'signed';
        END IF;
    ELSIF NEW.contract_signed = false AND NEW.file_url IS NOT NULL THEN
        NEW.contract_status = 'pending';
    ELSIF NEW.is_contract = true THEN
        NEW.contract_status = 'draft';
    ELSE
        NEW.contract_status = 'none';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update contract status
DROP TRIGGER IF EXISTS trigger_update_contract_status ON vendor_documents;
CREATE TRIGGER trigger_update_contract_status
    BEFORE INSERT OR UPDATE ON vendor_documents
    FOR EACH ROW
    EXECUTE FUNCTION update_vendor_contract_status();

-- Create function to automatically update payment status based on dates
CREATE OR REPLACE FUNCTION update_payment_plan_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Update payment status based on paid state and payment date
    IF NEW.paid = true THEN
        NEW.payment_status = 'paid';
    ELSIF NEW.payment_date IS NOT NULL AND NEW.payment_date < CURRENT_DATE THEN
        NEW.payment_status = 'overdue';
    ELSE
        NEW.payment_status = 'pending';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update payment status
DROP TRIGGER IF EXISTS trigger_update_payment_plan_status ON "paymentPlans";
CREATE TRIGGER trigger_update_payment_plan_status
    BEFORE INSERT OR UPDATE ON "paymentPlans"
    FOR EACH ROW
    EXECUTE FUNCTION update_payment_plan_status();

-- Create view for vendor payment summary
CREATE OR REPLACE VIEW vendor_payment_summary AS
SELECT
    v.id as vendor_id,
    v.vendor_name,
    v.couple_id,
    COUNT(pp.id) as total_payments,
    SUM(pp.payment_amount) as total_amount,
    SUM(CASE WHEN pp.paid THEN pp.payment_amount ELSE 0 END) as paid_amount,
    SUM(CASE WHEN NOT pp.paid THEN pp.payment_amount ELSE 0 END) as remaining_amount,
    MIN(CASE WHEN NOT pp.paid THEN pp.payment_date END) as next_payment_due,
    MAX(CASE WHEN pp.payment_type = 'final' THEN pp.payment_date END) as final_payment_due
FROM "vendorInformation" v
LEFT JOIN "paymentPlans" pp ON v.id = pp.vendor_id
GROUP BY v.id, v.vendor_name, v.couple_id;

-- Create view for vendor contract summary
CREATE OR REPLACE VIEW vendor_contract_summary AS
SELECT
    v.id as vendor_id,
    v.vendor_name,
    v.couple_id,
    MAX(vd.contract_signed_date) as contract_signed_date,
    MAX(vd.contract_expiry_date) as contract_expiry_date,
    MAX(vd.contract_status) as contract_status,
    COUNT(CASE WHEN vd.is_contract THEN 1 END) as contract_count
FROM "vendorInformation" v
LEFT JOIN vendor_documents vd ON v.id = vd.vendor_id AND vd.is_contract = true
GROUP BY v.id, v.vendor_name, v.couple_id;

COMMENT ON VIEW vendor_payment_summary IS 'Summary of payment information per vendor using paymentPlans table';
COMMENT ON VIEW vendor_contract_summary IS 'Summary of contract information per vendor';
