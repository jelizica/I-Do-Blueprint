# Build Fix Required - Duplicate FeatureFlags Reference

## Issue
The build is failing with this error:
```
error: Multiple commands produce '.../FeatureFlags.stringsdata'
```

## Cause
There was a duplicate `FeatureFlags.swift` file created at:
- `I Do Blueprint/Core/Configuration/FeatureFlags.swift` (DELETED)

The file has been deleted from the filesystem, but Xcode still has a reference to it in the project.

## Fix (2 minutes in Xcode)

### Option 1: Remove the Reference in Xcode
1. Open Xcode
2. In the Project Navigator (left sidebar), look for **two** `FeatureFlags.swift` files
3. Find the one under `Core/Configuration/` (it will be red/missing)
4. Right-click it → **Delete** → Choose "Remove Reference"
5. Build again (`Cmd + B`)

### Option 2: Clean Build Folder
1. Open Xcode
2. Press `Cmd + Shift + K` (Clean Build Folder)
3. Press `Cmd + B` (Build)

### Option 3: Remove Derived Data
1. Close Xcode
2. Run: `rm -rf ~/Library/Developer/Xcode/DerivedData/I_Do_Blueprint-*`
3. Open Xcode
4. Build (`Cmd + B`)

## Correct File Location
The **correct** FeatureFlags file is at:
```
I Do Blueprint/Core/Common/Common/FeatureFlags.swift
```

This file now includes the `budgetFoldersEnabled` flag.

## After Fix
Once the build succeeds, you can test the folder feature!

---

**Quick Fix**: Option 1 is fastest - just remove the red/missing file reference in Xcode.
