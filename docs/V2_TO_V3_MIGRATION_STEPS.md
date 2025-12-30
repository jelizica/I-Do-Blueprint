# V2 to V3 Migration Steps

## Current Status

- ✅ All V3 files created
- ⚠️ V2 files still present in codebase
- ⚠️ VendorManagementViewV3 still references V2

## Migration Strategy

### Option A: Safe Migration (Recommended)

1. **Keep V2 as backup** - Don't delete anything yet
2. **Build project** - See if V2 and V3 can coexist
3. **Update VendorManagementViewV3** - Switch to V3
4. **Test thoroughly** - Verify all functionality
5. **Delete V2** - Only after V3 is confirmed working

### Option B: Clean Slate (Riskier)

1. **Rename V2 files** - Add `.backup` extension
2. **Update VendorManagementViewV3** - Switch to V3
3. **Build and test**
4. **Delete backups** - After confirmation

## Step-by-Step Instructions

### Step 1: Update VendorManagementViewV3

Change line 62 in `VendorManagementViewV3.swift`:

```swift
// FROM:
.sheet(item: $selectedVendor) { vendor in
    VendorDetailViewV2(
        vendor: vendor,
        vendorStore: vendorStore
    )
}

// TO:
.sheet(item: $selectedVendor) { vendor in
    VendorDetailViewV3(
        vendor: vendor,
        vendorStore: vendorStore
    )
}
```

### Step 2: Build the Project

Press `Cmd+B` in Xcode to build.

**Expected Issues:**
- Missing imports
- Type mismatches
- Undefined symbols

### Step 3: Fix Compilation Errors

Common fixes needed:
- Add missing `import` statements
- Fix any type mismatches
- Ensure all dependencies are available

### Step 4: Test Functionality

Test checklist:
- [ ] Open vendor detail view
- [ ] All 4 tabs display correctly
- [ ] Logo upload works
- [ ] Quick actions (Call, Email, Website) work
- [ ] Export toggle persists
- [ ] Financial data loads
- [ ] Documents load
- [ ] Notes display
- [ ] Edit vendor works
- [ ] Delete vendor works

### Step 5: Clean Up V2 Files (After Confirmation)

Files to delete (only after V3 is working):

```
Views/Vendors/
├── VendorDetailViewV2.swift
└── Components/
    ├── VendorHeroHeaderView.swift
    ├── VendorQuickInfoSection.swift
    ├── VendorContactSection.swift
    ├── VendorBusinessDetailsSection.swift
    ├── VendorExportFlagSection.swift
    ├── VendorNotesSection.swift
    ├── VendorExpensesSection.swift
    ├── VendorPaymentsSection.swift
    ├── VendorDocumentsSection.swift
    ├── VendorFinancialSection.swift
    ├── VendorFinancialCard.swift
    └── VendorBusinessDetailCard.swift
```

**Keep these files** (used elsewhere):
- `EditVendorSheetV2.swift` - Used in Dashboard and AppCoordinator
- `VendorSupportingViews.swift` - Contains `SectionHeaderV2` used in Dashboard
- `ModernVendorCard.swift` - Used in other vendor list views

## Rollback Plan

If V3 doesn't work:

1. Revert `VendorManagementViewV3.swift` to use V2
2. Keep V2 files
3. Debug V3 issues
4. Try again

## Notes

- V3 uses same dependencies as V2 (VendorStoreV2, repositories)
- V3 has same public interface as V2
- V3 should be a drop-in replacement
- All V3 components are prefixed with `V3` to avoid naming conflicts
