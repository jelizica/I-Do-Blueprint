-- Migration: Add 'partial' to payment_status check constraint
-- Date: 2025-01-28
-- Description: Adds 'partial' as a valid payment status value to support automatic payment status calculation

-- Drop the existing check constraint
ALTER TABLE expenses DROP CONSTRAINT IF EXISTS expenses_payment_status_check;

-- Add the new check constraint with 'partial' included
ALTER TABLE expenses ADD CONSTRAINT expenses_payment_status_check 
  CHECK (payment_status IN ('pending', 'partial', 'paid', 'overdue', 'cancelled', 'refunded'));

-- Update any existing expenses that might benefit from partial status
-- (This is optional and can be commented out if not needed)
-- UPDATE expenses 
-- SET payment_status = 'partial' 
-- WHERE payment_status = 'pending' 
--   AND id IN (
--     SELECT DISTINCT expense_id 
--     FROM payment_schedules 
--     WHERE paid = true
--   );
