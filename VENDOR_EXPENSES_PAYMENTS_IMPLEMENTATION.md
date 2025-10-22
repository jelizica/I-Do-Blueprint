# Vendor Expenses and Payments Implementation Summary

## Overview
This document summarizes the implementation of displaying linked expenses and payments for vendors in the vendor detail views.

## Database Structure

### Existing Relationships
- **expenses** table has `vendor_id` (Int64) linking to `vendor_information.id`
- **payment_plans** table has `vendor_id` (Int64) linking to `vendor_information.id`

Both tables properly link to vendors through foreign key constraints.

## Implementation Details

### 1. Repository Protocol Updates

#### BudgetRepositoryProtocol.swift
Added two new methods to fetch expenses and payments by vendor:

```swift
/// Fetches expenses for a specific vendor
/// - Parameter vendorId: The ID of the vendor
/// - Returns: Array of expenses linked to the vendor
/// - Throws: Repository errors if fetch fails
func fetchExpensesByVendor(vendorId: Int64) async throws -> [Expense]

/// Fetches payment schedules for a specific vendor
/// - Parameter vendorId: The ID of the vendor
/// - Returns: Array of payment schedules linked to the vendor
/// - Throws: Repository errors if fetch fails
func fetchPaymentSchedulesByVendor(vendorId: Int64) async throws -> [PaymentSchedule]
```

### 2. Live Repository Implementation

#### LiveBudgetRepository.swift
Implemented the two new methods with:
- Proper caching (30 sec TTL for expenses, 60 sec for payments)
- Error handling with retry logic
- Performance logging
- Cache invalidation on mutations

```swift
func fetchExpensesByVendor(vendorId: Int64) async throws -> [Expense] {
    let cacheKey = "expenses_vendor_\(vendorId)"
    
    // Check cache first (30 sec TTL for very fresh data)
    if let cached: [Expense] = await RepositoryCache.shared.get(cacheKey, maxAge: 30) {
        return cached
    }
    
    let client = try getClient()
    let startTime = Date()
    
    do {
        let expenses: [Expense] = try await RepositoryNetwork.withRetry {
            try await client
                .from("expenses")
                .select()
                .eq("vendor_id", value: String(vendorId))
                .order("expense_date", ascending: false)
                .execute()
                .value
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Only log if slow
        if duration > 1.0 {
            logger.info("Slow vendor expenses fetch: \(String(format: "%.2f", duration))s for \(expenses.count) items")
        }
        
        await RepositoryCache.shared.set(cacheKey, value: expenses)
        
        return expenses
    } catch {
        let duration = Date().timeIntervalSince(startTime)
        logger.error("Vendor expenses fetch failed after \(String(format: "%.2f", duration))s", error: error)
        throw error
    }
}

func fetchPaymentSchedulesByVendor(vendorId: Int64) async throws -> [PaymentSchedule] {
    let cacheKey = "payment_schedules_vendor_\(vendorId)"
    
    if let cached: [PaymentSchedule] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
        return cached
    }
    
    let client = try getClient()
    let startTime = Date()
    
    do {
        let schedules: [PaymentSchedule] = try await RepositoryNetwork.withRetry {
            try await client
                .from("payment_plans")
                .select()
                .eq("vendor_id", value: String(vendorId))
                .order("payment_date", ascending: true)
                .execute()
                .value
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Only log if slow
        if duration > 1.0 {
            logger.info("Slow vendor payment schedules fetch: \(String(format: "%.2f", duration))s for \(schedules.count) items")
        }
        
        await RepositoryCache.shared.set(cacheKey, value: schedules)
        
        return schedules
    } catch {
        let duration = Date().timeIntervalSince(startTime)
        logger.error("Vendor payment schedules fetch failed after \(String(format: "%.2f", duration))s", error: error)
        throw error
    }
}
```

### 3. Mock Repository Implementation

#### MockBudgetRepository.swift (both locations)
Updated both mock repository files:
- `/I Do BlueprintTests/Helpers/MockRepositories.swift`
- `/I Do Blueprint/Domain/Repositories/Mock/MockBudgetRepository.swift`

Both now include:

```swift
func fetchExpensesByVendor(vendorId: Int64) async throws -> [Expense] {
    if shouldThrowError { throw errorToThrow }
    return expenses.filter { $0.vendorId == vendorId }
}

func fetchPaymentSchedulesByVendor(vendorId: Int64) async throws -> [PaymentSchedule] {
    if shouldThrowError { throw errorToThrow }
    return paymentSchedules.filter { $0.vendorId == vendorId }
}
```

## Next Steps

### UI Implementation Required

To complete this feature, you need to update the vendor detail views to display the linked expenses and payments:

1. **Update VendorDetailViewV2.swift**
   - Add `@Dependency(\.budgetRepository) var budgetRepository` to access the repository
   - Create state variables for expenses and payments:
     ```swift
     @State private var expenses: [Expense] = []
     @State private var payments: [PaymentSchedule] = []
     @State private var isLoadingFinancials = false
     ```
   
   - Load data when view appears:
     ```swift
     .task {
         await loadFinancialData()
     }
     
     private func loadFinancialData() async {
         isLoadingFinancials = true
         do {
             async let expensesTask = budgetRepository.fetchExpensesByVendor(vendorId: vendor.id)
             async let paymentsTask = budgetRepository.fetchPaymentSchedulesByVendor(vendorId: vendor.id)
             
             expenses = try await expensesTask
             payments = try await paymentsTask
         } catch {
             // Handle error
         }
         isLoadingFinancials = false
     }
     ```

2. **Update the Financial Tab**
   - Replace the current `financialTab` content with sections for:
     - Quoted Amount (existing)
     - Linked Expenses (new)
     - Payment Schedule (new)
   
   Example structure:
   ```swift
   private var financialTab: some View {
       VStack(spacing: Spacing.xxxl) {
           // Quoted Amount Section
           if let quotedAmount = vendor.quotedAmount {
               VendorQuotedAmountCard(amount: quotedAmount)
           }
           
           // Expenses Section
           if !expenses.isEmpty {
               VendorExpensesSection(expenses: expenses)
           }
           
           // Payments Section
           if !payments.isEmpty {
               VendorPaymentsSection(payments: payments)
           }
           
           // Empty State
           if expenses.isEmpty && payments.isEmpty && vendor.quotedAmount == nil {
               EmptyFinancialStateView()
           }
       }
   }
   ```

3. **Create UI Components**
   - `VendorExpensesSection.swift` - Display list of expenses with:
     - Expense name
     - Amount
     - Date
     - Payment status
     - Total expenses amount
   
   - `VendorPaymentsSection.swift` - Display payment schedule with:
     - Payment date
     - Amount
     - Paid status
     - Total paid vs remaining
     - Progress indicator

4. **Add Real-time Updates**
   - When expenses or payments are created/updated elsewhere in the app, the vendor view should refresh
   - Consider using Combine or observation to watch for changes

## Testing

### Unit Tests
The mock repositories are ready for testing. Create tests for:
- Fetching expenses by vendor
- Fetching payments by vendor
- Empty state handling
- Error handling

### Integration Tests
Test the complete flow:
1. Create a vendor
2. Create expenses linked to that vendor
3. Create payments linked to that vendor
4. View vendor details and verify expenses/payments are displayed
5. Update/delete expenses/payments and verify UI updates

## Build Status

✅ **Build Successful** - The Xcode project builds successfully with all changes.

## Files Modified

1. `/I Do Blueprint/Domain/Repositories/Protocols/BudgetRepositoryProtocol.swift`
2. `/I Do Blueprint/Domain/Repositories/Live/LiveBudgetRepository.swift`
3. `/I Do Blueprint/Domain/Repositories/Mock/MockBudgetRepository.swift`
4. `/I Do BlueprintTests/Helpers/MockRepositories.swift`

## Architecture Compliance

✅ Follows repository pattern
✅ Proper error handling
✅ Caching implemented
✅ Performance logging
✅ Mock implementations for testing
✅ Follows project best practices

## Questions to Answer Before UI Implementation

1. **Display Format**: How should expenses and payments be displayed?
   - List view?
   - Card view?
   - Table view?

2. **Sorting**: How should items be sorted?
   - By date (newest first)?
   - By amount?
   - By status?

3. **Filtering**: Should there be filters?
   - Show only unpaid?
   - Show only overdue?
   - Date range filter?

4. **Actions**: What actions should be available?
   - View expense details?
   - Mark payment as paid?
   - Edit expense/payment?
   - Delete expense/payment?

5. **Summary**: Should there be a summary section?
   - Total expenses
   - Total paid
   - Total remaining
   - Payment progress bar

6. **Empty State**: What should be shown when there are no expenses/payments?
   - Call to action to create?
   - Informational message?

Please provide answers to these questions so I can implement the UI components accordingly.
