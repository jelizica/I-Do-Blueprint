# UUID Case Sensitivity Fix - Instructions

## Issue
The app was fetching 0 vendors and 0 guests because of a UUID case sensitivity issue in the `LiveVendorRepository`.

## Root Cause
The repository was using `.uuidString` which returns **uppercase** UUIDs, but PostgreSQL stores them in **lowercase**. When comparing as text, this caused 0 results.

## Fix Applied
Changed `LiveVendorRepository.swift` to pass UUID directly instead of converting to string:

**Before:**
```swift
.eq("couple_id", value: tenantId.uuidString)  // ❌ Returns uppercase
```

**After:**
```swift
.eq("couple_id", value: tenantId)  // ✅ Pass UUID directly
```

## ⚠️ IMPORTANT: You Must Rebuild the App

The fix has been applied to the source code, but you're still running the old compiled version. 

### Steps to Apply the Fix:

1. **Clean the build** (in Xcode):
   - Product → Clean Build Folder (⇧⌘K)

2. **Rebuild the app**:
   - Product → Build (⌘B)

3. **Restart the app**:
   - Stop the current running instance
   - Product → Run (⌘R)

### Alternative: Use Terminal

```bash
cd "/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint"

# Clean build
xcodebuild clean -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint"

# Rebuild
xcodebuild -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -configuration Debug build

# Then run the app from Xcode
```

## Verification

After rebuilding and restarting, you should see in the logs:

```
Fetched 25 vendors in X.XXs    ← Should show 25, not 0
Fetched 89 guests in X.XXs      ← Should show 89, not 0
```

Then the payment schedule creation should work!

## Files Modified

1. `/I Do Blueprint/Domain/Repositories/Live/LiveVendorRepository.swift`
   - Line ~67: Changed `fetchVendors()` to use UUID directly
   - Line ~178: Changed `updateVendor()` to use UUID directly

## Database Verification

The vendors exist in the database:
- 25 vendors for couple_id `eb8e5ceb-bd2d-4f59-a4fa-b80ddbfc2d2f`
- Including vendor ID 96 "DJ Lia B"
- All properly migrated and ready to use

## Expected Behavior After Fix

1. ✅ Vendors will load (25 vendors)
2. ✅ Guests will load (89 guests)  
3. ✅ Payment schedules can be created for expenses with vendors
4. ✅ Vendor lookup will find vendor ID 96 "DJ Lia B"

## Date
January 2025

## Status
✅ **CODE FIXED** - Awaiting app rebuild and restart
