-- Migration: Format existing phone numbers to E.164 international format
-- Date: 2025-01-01
-- Description: Updates all existing phone numbers in guest_list, vendor_information, 
--              vendor_contacts, and preparation_schedule tables to use E.164 format (+1 XXX-XXX-XXXX)

-- Function to format phone numbers to E.164 format
-- Handles various input formats and normalizes to +1 XXX-XXX-XXXX
CREATE OR REPLACE FUNCTION format_phone_to_e164(phone_input TEXT)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    cleaned TEXT;
    formatted TEXT;
BEGIN
    -- Return NULL if input is NULL or empty
    IF phone_input IS NULL OR TRIM(phone_input) = '' THEN
        RETURN NULL;
    END IF;
    
    -- Remove all non-digit characters
    cleaned := REGEXP_REPLACE(phone_input, '[^0-9]', '', 'g');
    
    -- Handle different lengths
    CASE LENGTH(cleaned)
        -- 10 digits: assume US number, add +1
        WHEN 10 THEN
            formatted := '+1 ' || SUBSTRING(cleaned, 1, 3) || '-' || 
                        SUBSTRING(cleaned, 4, 3) || '-' || SUBSTRING(cleaned, 7, 4);
        
        -- 11 digits starting with 1: US number with country code
        WHEN 11 THEN
            IF SUBSTRING(cleaned, 1, 1) = '1' THEN
                formatted := '+1 ' || SUBSTRING(cleaned, 2, 3) || '-' || 
                            SUBSTRING(cleaned, 5, 3) || '-' || SUBSTRING(cleaned, 8, 4);
            ELSE
                -- Not a US number, return with + prefix
                formatted := '+' || cleaned;
            END IF;
        
        -- 7 digits: local number, cannot format without area code
        WHEN 7 THEN
            -- Return as-is with note that it needs area code
            formatted := cleaned || ' (needs area code)';
        
        -- Other lengths: return with + prefix if it looks like international
        ELSE
            IF LENGTH(cleaned) > 11 THEN
                formatted := '+' || cleaned;
            ELSE
                -- Too short or invalid, return original
                formatted := phone_input;
            END IF;
    END CASE;
    
    RETURN formatted;
END;
$$;

-- Update guest_list phone numbers
UPDATE guest_list
SET phone = format_phone_to_e164(phone)
WHERE phone IS NOT NULL 
  AND phone != ''
  AND phone NOT LIKE '+%'; -- Skip already formatted numbers

-- Update vendor_information phone numbers
UPDATE vendor_information
SET phone_number = format_phone_to_e164(phone_number)
WHERE phone_number IS NOT NULL 
  AND phone_number != ''
  AND phone_number NOT LIKE '+%'; -- Skip already formatted numbers

-- Update vendor_contacts phone numbers
UPDATE vendor_contacts
SET phone_number = format_phone_to_e164(phone_number)
WHERE phone_number IS NOT NULL 
  AND phone_number != ''
  AND phone_number NOT LIKE '+%'; -- Skip already formatted numbers

-- Update preparation_schedule contact_phone numbers
UPDATE preparation_schedule
SET contact_phone = format_phone_to_e164(contact_phone)
WHERE contact_phone IS NOT NULL 
  AND contact_phone != ''
  AND contact_phone NOT LIKE '+%'; -- Skip already formatted numbers

-- Add comment to function
COMMENT ON FUNCTION format_phone_to_e164(TEXT) IS 
'Formats phone numbers to E.164 international format (+1 XXX-XXX-XXXX for US numbers).
Handles various input formats including:
- (XXX) XXX-XXXX
- XXX-XXX-XXXX
- XXXXXXXXXX
- 1XXXXXXXXXX
Returns NULL for NULL/empty input.';

-- Log migration completion
DO $$
DECLARE
    guest_count INTEGER;
    vendor_count INTEGER;
    contact_count INTEGER;
    prep_count INTEGER;
BEGIN
    -- Count updated records
    SELECT COUNT(*) INTO guest_count 
    FROM guest_list 
    WHERE phone LIKE '+1 %';
    
    SELECT COUNT(*) INTO vendor_count 
    FROM vendor_information 
    WHERE phone_number LIKE '+1 %';
    
    SELECT COUNT(*) INTO contact_count 
    FROM vendor_contacts 
    WHERE phone_number LIKE '+1 %';
    
    SELECT COUNT(*) INTO prep_count 
    FROM preparation_schedule 
    WHERE contact_phone LIKE '+1 %';
    
    RAISE NOTICE 'Phone number migration complete:';
    RAISE NOTICE '  - guest_list: % records formatted', guest_count;
    RAISE NOTICE '  - vendor_information: % records formatted', vendor_count;
    RAISE NOTICE '  - vendor_contacts: % records formatted', contact_count;
    RAISE NOTICE '  - preparation_schedule: % records formatted', prep_count;
END $$;
