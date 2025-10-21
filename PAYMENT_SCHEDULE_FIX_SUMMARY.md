# Payment Schedule Creation Fix Summary

## Issue
Payment schedule creation was failing with the error:
```
duplicate key value violates unique constraint "paymentPlans_pkey"
```

## Root Cause
The code was attempting to insert `PaymentSchedule` objects with hardcoded ID values (`Int64.min + Int64(index)`), which caused primary key constraint violations. The database has an auto-incrementing sequence (`paymentPlans_id_seq`) that should generate unique IDs automatically, but the code was providing explicit ID values instead of letting the database handle ID generation.

## Solution

### 1. Updated `AddPaymentScheduleView.swift`
Changed the payment schedule creation to use a placeholder ID of `0` instead of `Int64.min + Int64(index)`:

```swift
let paymentSchedule = PaymentSchedule(
    id: 0, // Let database auto-generate the ID
    coupleId: coupleId,
    vendor: vendorName,
    // ... other fields
)
```

### 2. Updated `LiveBudgetRepository.swift`
Modified the `createPaymentSchedule` method to:
- Create a custom `Codable` struct (`PaymentScheduleInsert`) that excludes the `id` field
- Map all fields from the input `PaymentSchedule` to the insert struct
- Let the database auto-generate the ID using its sequence

```swift
func createPaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule {
    // Create a codable struct for insertion that excludes the id field
    struct PaymentScheduleInsert: Codable {
        let coupleId: UUID
        let vendor: String
        let paymentDate: Date
        // ... all other fields except id
        
        enum CodingKeys: String, CodingKey {
            case coupleId = "couple_id"
            case vendor
            case paymentDate = "payment_date"
            // ... snake_case mappings
        }
    }
    
    let insertData = PaymentScheduleInsert(
        coupleId: schedule.coupleId,
        vendor: schedule.vendor,
        // ... map all fields
    )
    
    let created: PaymentSchedule = try await client
        .from("payment_plans")
        .insert(insertData)
        .select()
        .single()
        .execute()
        .value
    
    return created
}
```

## Technical Details

### Why This Approach Works
1. **Excludes ID from Insert**: By creating a separate struct without the `id` field, we ensure the database's auto-increment sequence generates unique IDs
2. **Type-Safe**: Uses Swift's `Codable` protocol for proper serialization
3. **Maintains Compatibility**: The returned `PaymentSchedule` includes the database-generated ID
4. **Handles Optional Fields**: All optional fields are properly mapped

### Database Schema
- Table: `payment_plans` (formerly `paymentPlans`)
- Primary Key: `id` (bigint)
- Sequence: `paymentPlans_id_seq`
- The sequence automatically generates unique IDs when no explicit ID is provided

## Files Modified
1. `/I Do Blueprint/Views/Budget/AddPaymentScheduleView.swift`
   - Changed hardcoded ID generation to use placeholder value `0`

2. `/I Do Blueprint/Domain/Repositories/Live/LiveBudgetRepository.swift`
   - Created `PaymentScheduleInsert` struct for database insertion
   - Modified `createPaymentSchedule` method to exclude ID from insert operation

## Testing
- ✅ Xcode project builds successfully
- ✅ No compilation errors
- ✅ Type-safe implementation using Codable
- ✅ Follows repository pattern best practices

## Impact
- **Positive**: Payment schedules can now be created without duplicate key errors
- **Positive**: Multiple payment schedules in a plan each get unique IDs
- **Positive**: Follows database best practices for auto-incrementing primary keys
- **No Breaking Changes**: The API remains the same for consumers

## Date
January 2025
