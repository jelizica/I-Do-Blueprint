---
title: Phone Number Formatting Research - Swift Solutions
type: note
permalink: architecture/phone-formatting/phone-number-formatting-research-swift-solutions
tags:
- phone-formatting
- validation
- phonenumberkit
- libphonenumber
- research
- decision
---

# Phone Number Formatting Research - Swift Solutions

## Research Date
January 2025

## Problem Statement
Need to implement automatic phone number formatting throughout the I Do Blueprint app that:
- Standardizes phone numbers upon save to format: `+X (XXX) XXX-XXXX`
- Supports international country codes
- Allows country/country code selection
- Formats automatically regardless of how numbers are entered
- Currently only has manual formatting in Settings > Vendors tab

## Recommended Solution: PhoneNumberKit

### Overview
**PhoneNumberKit** is the leading Swift library for phone number handling, inspired by Google's libphonenumber.

- **Repository**: https://github.com/marmelroy/PhoneNumberKit
- **Stars**: 5.3k
- **License**: MIT
- **Platform**: iOS/macOS
- **Swift Version**: 5.3+
- **Latest Release**: 4.2.2 (Dec 18, 2025)

### Key Features
1. ✅ **Parsing & Validation**: Parse and validate phone numbers for all countries
2. ✅ **Formatting**: Multiple format options (E.164, International, National)
3. ✅ **Country Detection**: Automatically detects country from phone number
4. ✅ **As-You-Type Formatting**: Real-time formatting as user types
5. ✅ **Country Picker**: Built-in country code picker UI
6. ✅ **Metadata**: Uses Google's libphonenumber metadata (best-in-class)
7. ✅ **Performance**: Fast - 1000 parses in ~0.4 seconds
8. ✅ **SwiftUI Support**: Works seamlessly with SwiftUI

### Installation (Swift Package Manager)
```swift
dependencies: [
    .package(url: "https://github.com/marmelroy/PhoneNumberKit", from: "4.0.0")
]
```

### Basic Usage Examples

#### 1. Parsing Phone Numbers
```swift
import PhoneNumberKit

let phoneNumberKit = PhoneNumberKit()

do {
    let phoneNumber = try phoneNumberKit.parse("+33 6 89 017383")
    let phoneNumberCustomRegion = try phoneNumberKit.parse("+44 20 7031 3000", withRegion: "GB")
} catch {
    print("Parse error: \(error)")
}
```

#### 2. Formatting Phone Numbers
```swift
// E.164 format: +61236618300
phoneNumberKit.format(phoneNumber, toType: .e164)

// International format: +61 2 3661 8300
phoneNumberKit.format(phoneNumber, toType: .international)

// National format: (02) 3661 8300
phoneNumberKit.format(phoneNumber, toType: .national)
```

#### 3. As-You-Type Formatting (TextField)
```swift
// Replace UITextField with PhoneNumberTextField
let textField = PhoneNumberTextField()

// Customize appearance
textField.withFlag = true  // Show country flag
textField.withExamplePlaceholder = true  // Show example number
textField.withPrefix = true  // Auto-insert country code prefix

// Set default region
class MyTextField: PhoneNumberTextField {
    override var defaultRegion: String {
        get { return "US" }
        set {}
    }
}
```

#### 4. Validation
```swift
let isValid = phoneNumberKit.isValidNumber(phoneNumber)  // true/false
```

#### 5. Country Code Utilities
```swift
// Get countries for a dialing code
phoneNumberKit.countries(withCode: 33)  // ["FR"]

// Get dialing code for a country
phoneNumberKit.countryCode(for: "FR")  // 33
```

### PhoneNumber Object Properties
```swift
phoneNumber.numberString       // Full number string
phoneNumber.countryCode        // Country calling code (e.g., 1 for US)
phoneNumber.nationalNumber     // Number without country code
phoneNumber.numberExtension    // Extension if present
phoneNumber.type              // .mobile, .fixedLine, etc.
```

### Country Picker Customization
```swift
let headerOptions = CountryCodePickerOptions.CountryCodePickerHeaderOptions(
    textLabelColor: .blue,
    textLabelFont: .boldSystemFont(ofSize: 18),
    backgroundColor: nil,
    cellType: .cellNib(headerNib, identifier: CustomHeaderView.reuseIdentifier),
    height: CustomHeaderView.defaultHeight
)

let cellOptions = CountryCodePickerOptions.CountryCodePickerCellOptions(
    textLabelColor: nil,
    textLabelFont: nil,
    detailTextLabelColor: nil,
    detailTextLabelFont: nil,
    backgroundColor: nil,
    backgroundColorSelection: nil,
    cellType: .cellNib(cellNib, identifier: CustomCell.reuseIdentifier),
    height: CustomCell.defaultHeight
)

let options = CountryCodePickerOptions(
    backgroundColor: .systemGroupedBackground,
    separatorColor: .opaqueSeparator,
    tintColor: UIView().tintColor,
    cellOptions: cellOptions,
    headerOptions: headerOptions
)

textField.withDefaultPickerUIOptions = options
```

## Alternative: Google's libphonenumber

### Overview
- **Repository**: https://github.com/google/libphonenumber
- **Stars**: 17.7k
- **Languages**: Java, C++, JavaScript (no native Swift)
- **License**: Apache 2.0

### Why Not Use Directly?
- No native Swift implementation
- PhoneNumberKit is a Swift port that's optimized for iOS/macOS
- PhoneNumberKit uses the same metadata as libphonenumber
- Better Swift/SwiftUI integration

## Implementation Plan for I Do Blueprint

### Phase 1: Add PhoneNumberKit Dependency
1. Add PhoneNumberKit via Swift Package Manager
2. Import in relevant files

### Phase 2: Create Utility Service
```swift
// Services/PhoneNumberService.swift
import PhoneNumberKit

actor PhoneNumberService {
    private let phoneNumberKit = PhoneNumberKit()
    
    /// Format phone number to standard format: +X (XXX) XXX-XXXX
    func formatPhoneNumber(_ input: String, defaultRegion: String = "US") -> String? {
        do {
            let phoneNumber = try phoneNumberKit.parse(input, withRegion: defaultRegion)
            return phoneNumberKit.format(phoneNumber, toType: .international)
        } catch {
            AppLogger.validation.error("Failed to format phone number", error: error)
            return nil
        }
    }
    
    /// Validate phone number
    func isValid(_ input: String, region: String = "US") -> Bool {
        do {
            let phoneNumber = try phoneNumberKit.parse(input, withRegion: region)
            return phoneNumberKit.isValidNumber(phoneNumber)
        } catch {
            return false
        }
    }
    
    /// Get phone number type (mobile, landline, etc.)
    func getType(_ input: String, region: String = "US") -> PhoneNumberType? {
        do {
            let phoneNumber = try phoneNumberKit.parse(input, withRegion: region)
            return phoneNumber.type
        } catch {
            return nil
        }
    }
}
```

### Phase 3: Update Models
```swift
// Domain/Models/Guest/Guest.swift
extension Guest {
    var formattedPhone: String? {
        guard let phone, !phone.isEmpty else { return nil }
        return Task {
            await PhoneNumberService().formatPhoneNumber(phone)
        }.value
    }
}

// Domain/Models/Vendor/Vendor.swift
extension Vendor {
    var formattedPhoneNumber: String? {
        guard let phoneNumber, !phoneNumber.isEmpty else { return nil }
        return Task {
            await PhoneNumberService().formatPhoneNumber(phoneNumber)
        }.value
    }
}
```

### Phase 4: Update Repositories
Add formatting on save in repositories:

```swift
// LiveGuestRepository.swift
func createGuest(_ guest: Guest) async throws -> Guest {
    var guestToSave = guest
    
    // Format phone number before saving
    if let phone = guest.phone {
        guestToSave.phone = await PhoneNumberService().formatPhoneNumber(phone)
    }
    
    // ... rest of save logic
}

// LiveVendorRepository.swift
func createVendor(_ vendor: Vendor) async throws -> Vendor {
    var vendorToSave = vendor
    
    // Format phone number before saving
    if let phoneNumber = vendor.phoneNumber {
        vendorToSave.phoneNumber = await PhoneNumberService().formatPhoneNumber(phoneNumber)
    }
    
    // ... rest of save logic
}
```

### Phase 5: Update UI Components
Replace TextField with PhoneNumberTextField:

```swift
// Views/Guests/AddGuestView.swift
import PhoneNumberKit

struct AddGuestView: View {
    @State private var phoneNumberField = PhoneNumberTextField()
    
    var body: some View {
        VStack {
            // Replace TextField with PhoneNumberTextField
            PhoneNumberTextFieldWrapper(
                phoneNumber: $phone,
                defaultRegion: "US"
            )
        }
    }
}

// Create SwiftUI wrapper
struct PhoneNumberTextFieldWrapper: NSViewRepresentable {
    @Binding var phoneNumber: String
    let defaultRegion: String
    
    func makeNSView(context: Context) -> PhoneNumberTextField {
        let textField = PhoneNumberTextField()
        textField.withFlag = true
        textField.withExamplePlaceholder = true
        textField.withPrefix = true
        textField.defaultRegion = defaultRegion
        return textField
    }
    
    func updateNSView(_ nsView: PhoneNumberTextField, context: Context) {
        nsView.text = phoneNumber
    }
}
```

### Phase 6: Database Migration
Create migration to format existing phone numbers:

```sql
-- supabase/migrations/YYYYMMDDHHMMSS_format_phone_numbers.sql

-- Format guest phone numbers
UPDATE guest_list
SET phone = format_phone_number(phone, 'US')
WHERE phone IS NOT NULL
AND phone != '';

-- Format vendor phone numbers
UPDATE vendors
SET phone_number = format_phone_number(phone_number, 'US')
WHERE phone_number IS NOT NULL
AND phone_number != '';

-- Create function for future formatting
CREATE OR REPLACE FUNCTION format_phone_number(
    phone_input TEXT,
    default_region TEXT DEFAULT 'US'
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    -- This would call PhoneNumberKit via Edge Function
    -- Or use a PostgreSQL phone number extension
    RETURN phone_input;
END;
$$;
```

### Phase 7: Remove Manual Formatting Button
- Remove the "Format Phone Numbers" button from Settings > Vendors
- Phone numbers will now format automatically on save
- Update documentation to reflect automatic formatting

## Benefits of This Approach

1. **Automatic Formatting**: Numbers format on save, no manual action needed
2. **International Support**: Handles all country codes and formats
3. **Validation**: Built-in validation prevents invalid numbers
4. **User Experience**: As-you-type formatting improves data entry
5. **Consistency**: All phone numbers stored in same format
6. **Type Detection**: Can distinguish mobile vs landline
7. **Country Picker**: Easy country selection for international numbers
8. **Maintained**: Active project with recent updates

## Potential Challenges

1. **Performance**: PhoneNumberKit instance is expensive to allocate
   - **Solution**: Use singleton or dependency injection
   
2. **Existing Data**: Need to format existing phone numbers
   - **Solution**: Run migration script
   
3. **User Preferences**: Some users may prefer different formats
   - **Solution**: Store in standard format, display in user's preferred format
   
4. **Edge Cases**: Invalid or partial numbers
   - **Solution**: Graceful fallback, keep original if formatting fails

## Testing Strategy

1. **Unit Tests**: Test PhoneNumberService formatting
2. **Integration Tests**: Test repository formatting on save
3. **UI Tests**: Test PhoneNumberTextField behavior
4. **Migration Tests**: Verify existing data formats correctly
5. **Edge Cases**: Test invalid numbers, partial numbers, international numbers

## Cost Analysis

- **Library**: Free (MIT License)
- **Development Time**: ~2-3 days
- **Maintenance**: Minimal (stable library)
- **Performance Impact**: Negligible (fast parsing)

## Alternatives Considered

### 1. Manual Regex Formatting
- ❌ Complex to maintain
- ❌ Doesn't handle international numbers well
- ❌ No validation
- ❌ Error-prone

### 2. Third-Party API (e.g., Twilio Lookup)
- ❌ Costs money per lookup
- ❌ Requires internet connection
- ❌ Slower (network latency)
- ❌ Privacy concerns (sending data to third party)

### 3. Build Custom Solution
- ❌ Reinventing the wheel
- ❌ Time-consuming
- ❌ Won't match libphonenumber quality
- ❌ Maintenance burden

## Decision

**Recommendation**: Implement PhoneNumberKit

**Rationale**:
- Industry-standard solution (based on Google's libphonenumber)
- Free and open-source
- Excellent Swift/SwiftUI integration
- Active maintenance
- Comprehensive feature set
- Fast performance
- Easy to implement

## Next Steps

1. ✅ Research completed
2. ⏭️ Add PhoneNumberKit dependency
3. ⏭️ Create PhoneNumberService
4. ⏭️ Update repositories to format on save
5. ⏭️ Update UI components
6. ⏭️ Create database migration
7. ⏭️ Remove manual formatting button
8. ⏭️ Write tests
9. ⏭️ Update documentation

## References

- PhoneNumberKit GitHub: https://github.com/marmelroy/PhoneNumberKit
- Google libphonenumber: https://github.com/google/libphonenumber
- libphonenumber FAQ: https://github.com/google/libphonenumber/blob/master/FAQ.md
- Phone Number Falsehoods: https://github.com/google/libphonenumber/blob/master/FALSEHOODS.md
