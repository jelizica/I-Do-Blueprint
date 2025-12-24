# Budget Scenario Save - Schema Mismatch Fix

## Problem Summary

The RPC function `save_budget_scenario_with_items` was failing with:
```
column "category_id" of relation "budget_development_items" does not exist
```

This was a **schema mismatch** - the RPC function was trying to insert into columns that don't exist in the actual database table.

## Root Cause Analysis

### Actual Database Schema (budget_development_items)
```sql
id                              uuid
scenario_id                     uuid
item_name                       varchar
category                        varchar        -- NOT category_id
subcategory                     varchar
vendor_estimate_without_tax     numeric
tax_rate                        numeric
vendor_estimate_with_tax        numeric
person_responsible              text
notes                           text
linked_gift_owed_id             uuid
couple_id                       uuid
created_at                      timestamp
updated_at                      timestamp
event_id                        uuid
event_ids                       ARRAY
linked_expense_id               uuid
is_test_data                    boolean
```

### What the RPC Was Trying to Insert
```sql
-- WRONG - These columns don't exist:
category_id                     -- Should be: category (varchar)
vendor_id                       -- Doesn't exist
estimated_cost                  -- Should be: vendor_estimate_without_tax
final_cost                      -- Should be: vendor_estimate_with_tax
priority                        -- Doesn't exist
```

## Solution

Updated both migration files to use the correct column names:

### File 1: `20250224000000_create_save_budget_scenario_with_items_rpc.sql`
- Changed `category_id` → `category`
- Changed `vendor_id` → removed (not in schema)
- Changed `estimated_cost` → `vendor_estimate_without_tax`
- Changed `final_cost` → `vendor_estimate_with_tax`
- Changed `priority` → removed (not in schema)
- Added `tax_rate` (required field)
- Added `person_responsible` (optional field)

### File 2: `20250224000001_fix_save_budget_scenario_function_overload.sql`
- Applied same fixes as File 1
- Ensures both function versions use correct schema

## Client Code Status

✅ **No changes needed to client code**

The Swift models are already correct:

### SavedScenario (Domain/Models/Budget/Budget.swift)
```swift
struct SavedScenario: Identifiable, Codable {
    let id: String
    var scenarioName: String
    var createdAt: Date
    var updatedAt: Date
    var totalWithoutTax: Double?
    var totalTax: Double?
    var totalWithTax: Double?
    var isPrimary: Bool
    var coupleId: String
    var isTestData: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case scenarioName = "scenario_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case totalWithoutTax = "total_without_tax"
        case totalTax = "total_tax"
        case totalWithTax = "total_with_tax"
        case isPrimary = "is_primary"
        case coupleId = "couple_id"
        case isTestData = "is_test_data"
    }
}
```

### BudgetItem (Domain/Models/Budget/Budget.swift)
```swift
struct BudgetItem: Identifiable, Codable {
    let id: String
    var scenarioId: String?
    var itemName: String
    var category: String                    // ✅ Correct
    var subcategory: String?                // ✅ Correct
    var vendorEstimateWithoutTax: Double    // ✅ Correct
    var taxRate: Double                     // ✅ Correct
    var vendorEstimateWithTax: Double       // ✅ Correct
    var personResponsible: String?          // ✅ Correct
    var notes: String?                      // ✅ Correct
    var createdAt: Date?
    var updatedAt: Date?
    var eventId: String?
    var eventIds: [String]?
    var linkedExpenseId: String?
    var linkedGiftOwedId: String?
    var coupleId: String
    var isTestData: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case scenarioId = "scenario_id"
        case itemName = "item_name"
        case category = "category"
        case subcategory = "subcategory"
        case vendorEstimateWithoutTax = "vendor_estimate_without_tax"
        case taxRate = "tax_rate"
        case vendorEstimateWithTax = "vendor_estimate_with_tax"
        case personResponsible = "person_responsible"
        case notes = "notes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case eventId = "event_id"
        case eventIds = "event_ids"
        case linkedExpenseId = "linked_expense_id"
        case linkedGiftOwedId = "linked_gift_owed_id"
        case coupleId = "couple_id"
        case isTestData = "is_test_data"
    }
}
```

## Repository Code Status

✅ **No changes needed to repository code**

The `LiveBudgetRepository.saveBudgetScenarioWithItems()` method correctly encodes the models:

```swift
func saveBudgetScenarioWithItems(_ scenario: SavedScenario, items: [BudgetItem]) async throws -> (scenarioId: String, insertedItems: Int) {
    struct Params: Encodable {
        let p_scenario: SavedScenario
        let p_items: [BudgetItem]
    }
    
    let params = Params(p_scenario: scenario, p_items: items)
    
    let result: [[String: AnyCodable]] = try await client
        .rpc("save_budget_scenario_with_items", body: params)
        .execute()
        .value
    
    // Parse response...
}
```

The client code was correct all along - the RPC function definition was wrong.

## Testing the Fix

After applying the migrations, the save operation should:

1. ✅ Accept `SavedScenario` with correct fields
2. ✅ Accept `[BudgetItem]` with correct fields
3. ✅ Insert into `budget_development_scenarios` table
4. ✅ Insert into `budget_development_items` table with correct column mappings
5. ✅ Return success response with scenario_id and inserted_items count

## Migration Deployment Order

1. Apply `20250224000000_create_save_budget_scenario_with_items_rpc.sql`
2. Apply `20250224000001_fix_save_budget_scenario_function_overload.sql`

Both migrations drop and recreate the function, so order matters.

## Summary of Changes

| Component | Status | Changes |
|-----------|--------|---------|
| Database Schema | ✅ No changes | Already correct |
| RPC Function | ✅ Fixed | Updated column names to match schema |
| SavedScenario Model | ✅ No changes | Already correct |
| BudgetItem Model | ✅ No changes | Already correct |
| Repository Code | ✅ No changes | Already correct |
| Client Code | ✅ No changes | Already correct |

The issue was purely in the RPC function definition - it was trying to insert into columns that don't exist in the actual database table.
