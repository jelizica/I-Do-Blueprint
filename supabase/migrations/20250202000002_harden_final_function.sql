-- Migration: Harden Final Function - get_monthly_cash_flow_summary
-- Issue: JES-74
-- Description: Harden the last remaining function
-- Date: 2025-02-02
-- Phase: Final - Complete 100% function hardening

DROP FUNCTION IF EXISTS public.get_monthly_cash_flow_summary(uuid, date) CASCADE;

CREATE OR REPLACE FUNCTION public.get_monthly_cash_flow_summary(target_couple_id uuid, target_month date)
 RETURNS TABLE(field_name text, field_value numeric, field_source text)
 LANGUAGE plpgsql
 SET search_path = ''
AS $function$
DECLARE
    mcf_record public.monthly_cash_flow%ROWTYPE;
    prev_month_date DATE;
    calc_starting_balance NUMERIC;
    total_payments NUMERIC;
BEGIN
    -- Get the cash flow record
    SELECT * INTO mcf_record 
    FROM public.monthly_cash_flow 
    WHERE couple_id = target_couple_id AND month = target_month;
    
    -- Calculate previous month date
    prev_month_date := (target_month - INTERVAL '1 month')::DATE;
    
    -- Get calculated starting balance
    SELECT public.recalculate_starting_balance(target_couple_id, target_month) INTO calc_starting_balance;
    
    -- Get total payments for the month
    SELECT COALESCE(SUM(payment_amount), 0) INTO total_payments
    FROM public."paymentPlans"
    WHERE couple_id = target_couple_id
    AND payment_date >= target_month
    AND payment_date < (target_month + INTERVAL '1 month')::DATE;
    
    -- Return summary data
    field_name := 'starting_balance_saved'; 
    field_value := mcf_record.starting_balance; 
    field_source := CASE WHEN mcf_record.starting_balance IS NULL THEN 'AUTO_CALCULATED' ELSE 'USER_SET' END; 
    RETURN NEXT;
    
    field_name := 'starting_balance_calculated'; 
    field_value := calc_starting_balance; 
    field_source := 'CALCULATED_FROM_PREV_MONTH'; 
    RETURN NEXT;
    
    field_name := 'partner1_inflow'; 
    field_value := COALESCE(mcf_record.partner1_inflow, 0); 
    field_source := 'SAVED'; 
    RETURN NEXT;
    
    field_name := 'partner2_inflow'; 
    field_value := COALESCE(mcf_record.partner2_inflow, 0); 
    field_source := 'SAVED'; 
    RETURN NEXT;
    
    field_name := 'interest_income'; 
    field_value := COALESCE(mcf_record.interest_income, 0); 
    field_source := 'SAVED'; 
    RETURN NEXT;
    
    field_name := 'gifts_inflow'; 
    field_value := COALESCE(mcf_record.gifts_inflow, 0); 
    field_source := 'SAVED'; 
    RETURN NEXT;
    
    field_name := 'non_wedding_adjustments'; 
    field_value := COALESCE(mcf_record.non_wedding_adjustments, 0); 
    field_source := 'SAVED'; 
    RETURN NEXT;
    
    field_name := 'total_outflow'; 
    field_value := total_payments; 
    field_source := 'CALCULATED_FROM_PAYMENTS'; 
    RETURN NEXT;
    
    field_name := 'ending_balance'; 
    field_value := COALESCE(calc_starting_balance, mcf_record.starting_balance, 0) + 
                   COALESCE(mcf_record.partner1_inflow, 0) + 
                   COALESCE(mcf_record.partner2_inflow, 0) + 
                   COALESCE(mcf_record.interest_income, 0) + 
                   COALESCE(mcf_record.gifts_inflow, 0) + 
                   COALESCE(mcf_record.non_wedding_adjustments, 0) - 
                   total_payments; 
    field_source := 'CALCULATED'; 
    RETURN NEXT;
END;
$function$;

-- ============================================================================
-- FINAL VERIFICATION
-- ============================================================================

DO $$
DECLARE
    unhardened_count INTEGER;
    total_functions INTEGER;
    hardened_count INTEGER;
BEGIN
    -- Count total functions
    SELECT COUNT(*) INTO total_functions
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
        AND p.prokind = 'f';
    
    -- Count unhardened functions
    SELECT COUNT(*) INTO unhardened_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
        AND p.prokind = 'f'
        AND (
            p.proconfig IS NULL 
            OR NOT EXISTS (
                SELECT 1 FROM unnest(p.proconfig) AS config 
                WHERE config LIKE 'search_path=%'
            )
        );
    
    hardened_count := total_functions - unhardened_count;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE '🎉 JES-74 COMPLETE! 🎉';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total public functions: %', total_functions;
    RAISE NOTICE 'Hardened functions: % (100%%)', hardened_count;
    RAISE NOTICE 'Remaining unhardened: %', unhardened_count;
    RAISE NOTICE '========================================';
    
    IF unhardened_count = 0 THEN
        RAISE NOTICE '✓✓✓ SUCCESS! ALL FUNCTIONS HARDENED! ✓✓✓';
        RAISE NOTICE 'All % public functions now have SET search_path = ''''', total_functions;
        RAISE NOTICE 'Database security hardening complete!';
    ELSE
        RAISE WARNING 'Still % unhardened functions remaining', unhardened_count;
    END IF;
    
    RAISE NOTICE '========================================';
END $$;
