-- Create a view that aggregates payment plans for easy querying
-- This provides a "full payment plan" view showing plan-level details

CREATE OR REPLACE VIEW payment_plan_summaries AS
WITH plan_aggregates AS (
  SELECT 
    expense_id,
    couple_id,
    vendor,
    vendor_id,
    vendor_type,
    payment_type,
    payment_plan_type,
    
    -- Plan metadata
    MAX(total_payment_count) as total_payments,
    MIN(payment_date) as first_payment_date,
    MAX(payment_date) as last_payment_date,
    MIN(CASE WHEN is_deposit THEN payment_date END) as deposit_date,
    
    -- Financial aggregates
    SUM(payment_amount) as total_amount,
    SUM(CASE WHEN paid THEN payment_amount ELSE 0 END) as amount_paid,
    SUM(CASE WHEN NOT paid THEN payment_amount ELSE 0 END) as amount_remaining,
    SUM(CASE WHEN is_deposit THEN payment_amount ELSE 0 END) as deposit_amount,
    
    -- Payment counts
    COUNT(*) as actual_payment_count,
    COUNT(CASE WHEN paid THEN 1 END) as payments_completed,
    COUNT(CASE WHEN NOT paid THEN 1 END) as payments_remaining,
    COUNT(CASE WHEN is_deposit THEN 1 END) as deposit_count,
    
    -- Status indicators
    BOOL_AND(paid) as all_paid,
    BOOL_OR(paid) as any_paid,
    BOOL_OR(is_deposit) as has_deposit,
    BOOL_OR(is_retainer) as has_retainer,
    
    -- Next payment info
    MIN(CASE WHEN NOT paid AND payment_date >= CURRENT_DATE THEN payment_date END) as next_payment_date,
    MIN(CASE WHEN NOT paid AND payment_date >= CURRENT_DATE THEN payment_amount END) as next_payment_amount,
    
    -- Overdue info
    COUNT(CASE WHEN NOT paid AND payment_date < CURRENT_DATE THEN 1 END) as overdue_count,
    SUM(CASE WHEN NOT paid AND payment_date < CURRENT_DATE THEN payment_amount ELSE 0 END) as overdue_amount,
    
    -- Timestamps
    MIN(created_at) as plan_created_at,
    MAX(updated_at) as plan_updated_at,
    
    -- Notes (concatenate unique notes)
    STRING_AGG(DISTINCT notes, ' | ') FILTER (WHERE notes IS NOT NULL AND notes != '') as combined_notes
    
  FROM payment_plans
  GROUP BY expense_id, couple_id, vendor, vendor_id, vendor_type, payment_type, payment_plan_type
)
SELECT 
  *,
  -- Calculated fields
  ROUND((amount_paid / NULLIF(total_amount, 0) * 100), 2) as percent_paid,
  
  -- Plan status
  CASE 
    WHEN all_paid THEN 'completed'
    WHEN overdue_count > 0 THEN 'overdue'
    WHEN any_paid THEN 'in_progress'
    ELSE 'pending'
  END as plan_status,
  
  -- Plan type display name
  CASE payment_plan_type
    WHEN 'simple-recurring' THEN 'Monthly Recurring'
    WHEN 'interval-recurring' THEN 'Custom Interval'
    WHEN 'cyclical-recurring' THEN 'Cyclical Payments'
    WHEN 'installment' THEN 'Installment Plan'
    WHEN 'retainer-based' THEN 'Retainer'
    WHEN 'deposit-based' THEN 'Deposit'
    WHEN 'one-time' THEN 'One-Time Payment'
    ELSE 'Payment Plan'
  END as plan_type_display,
  
  -- Days until next payment
  CASE 
    WHEN next_payment_date IS NOT NULL 
    THEN next_payment_date - CURRENT_DATE
    ELSE NULL
  END as days_until_next_payment
  
FROM plan_aggregates;

-- Add helpful comment
COMMENT ON VIEW payment_plan_summaries IS 
'Aggregated view of payment plans showing plan-level summaries.
Use this view to display "full payment plan" information instead of individual payments.
Includes financial totals, payment progress, status, and next payment information.';

-- Create index on the underlying table to speed up the view
CREATE INDEX IF NOT EXISTS idx_payment_plans_expense_id ON payment_plans(expense_id);
CREATE INDEX IF NOT EXISTS idx_payment_plans_couple_expense ON payment_plans(couple_id, expense_id);
CREATE INDEX IF NOT EXISTS idx_payment_plans_vendor_expense ON payment_plans(vendor_id, expense_id);

-- Grant access to authenticated users
GRANT SELECT ON payment_plan_summaries TO authenticated;
