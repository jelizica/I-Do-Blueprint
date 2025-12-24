# Guest Refresh Fix - Testing Guide

## Quick Test Checklist

### ✅ Basic Add Guest Test
1. Open the app and navigate to Guest Management
2. Click "Add Guest" button
3. Fill in basic info (First Name, Last Name required)
4. Click "Save"
5. **Expected**: Guest appears in list immediately, success toast shows
6. **Verify**: Guest count increases, stats update

### ✅ Add Guest with Filters Active
1. Apply a search filter (e.g., search for "John")
2. Click "Add Guest"
3. Add a guest named "John Smith"
4. **Expected**: Guest appears in filtered list immediately
5. Click "Add Guest" again
6. Add a guest named "Jane Doe"
7. **Expected**: Guest does NOT appear in filtered list (doesn't match filter)
8. **Verify**: Total count increases but filtered count doesn't

### ✅ Add Guest with Status Filter
1. Filter by RSVP Status = "Pending"
2. Click "Add Guest"
3. Add a guest with RSVP Status = "Pending"
4. **Expected**: Guest appears in list immediately
5. Click "Add Guest" again
6. Add a guest with RSVP Status = "Attending"
7. **Expected**: Guest does NOT appear in filtered list
8. **Verify**: Total count increases but filtered count doesn't

### ✅ Add Multiple Guests
1. Add 3 guests in succession
2. **Expected**: Each guest appears immediately after save
3. **Verify**: Stats accumulate correctly (total count = 3)
4. **Verify**: No duplicate entries

### ✅ Add Guest and Import
1. Add a guest manually
2. **Expected**: Guest appears in list
3. Import a CSV file
4. **Expected**: Import completes successfully
5. **Verify**: Both manual and imported guests are in list
6. **Verify**: No state conflicts or duplicates

### ✅ Error Handling
1. Try to add a guest with empty first name
2. **Expected**: Save button is disabled
3. Fill in first name but leave last name empty
4. **Expected**: Save button is disabled
5. Fill in both names
6. **Expected**: Save button is enabled
7. Click Save
8. **Expected**: Guest is added successfully

### ✅ Modal Dismissal
1. Add a guest
2. **Expected**: Modal dismisses after save completes
3. **Verify**: Guest appears in list before modal closes
4. **Verify**: No "Publishing changes from within view updates" warnings in console

### ✅ Console Logging
1. Add a guest
2. **Expected**: Console shows:
   ```
   Guest created successfully: [name]. Performing complete data reload...
   ```
3. **Verify**: This indicates the fix is working

## Performance Expectations

- **Add Guest**: ~500-1000ms total (create + reload)
- **Modal Dismissal**: Immediate after reload completes
- **View Update**: Instant (no lag)
- **Stats Update**: Immediate

## What to Look For

### ✅ Good Signs
- Guest appears immediately after save
- Success toast shows
- Stats update correctly
- No console warnings
- Modal dismisses smoothly
- Filtered list respects filters

### ❌ Bad Signs
- Guest doesn't appear in list
- Stats don't update
- Modal stays open
- Console shows "Publishing changes from within view updates"
- Duplicate entries appear
- Filtered list shows guests that don't match filters

## Regression Testing

### Test Other Guest Operations
1. **Update Guest**: Edit a guest and verify changes appear
2. **Delete Guest**: Delete a guest and verify it's removed
3. **Search**: Search for guests and verify results
4. **Filter**: Filter by status/invited by and verify results

### Test Other Views
1. **Dashboard**: Verify guest count updates on dashboard
2. **Guest Stats**: Verify stats card updates correctly
3. **Detail View**: Verify guest detail view shows new guest

## Edge Cases

### Test Edge Cases
1. **Add guest with special characters**: Name with apostrophe, accent marks
2. **Add guest with very long name**: 100+ character name
3. **Add guest with empty optional fields**: Only first/last name
4. **Add guest with all fields**: Complete profile
5. **Add guest while loading**: Click add while data is loading
6. **Add guest with network delay**: Simulate slow network

## Debugging

### If Tests Fail

1. **Check Console Logs**
   ```
   Guest created successfully: [name]. Performing complete data reload...
   ```
   - If missing: Fix not applied correctly

2. **Check Network Tab**
   - Should see POST to create guest
   - Should see GET to fetch guests (reload)
   - Should see GET to fetch stats

3. **Check Store State**
   - `guestStore.guests.count` should increase
   - `guestStore.filteredGuests` should update
   - `guestStore.totalGuestsCount` should increase

4. **Check View Hierarchy**
   - List should update without recreation
   - Stats should update
   - Detail panel should update if guest selected

## Performance Profiling

### Using Instruments
1. Open Xcode Instruments
2. Select "System Trace"
3. Add guest
4. Look for:
   - Network request (create)
   - Network request (fetch)
   - Main thread work
   - View updates

### Expected Timeline
```
0ms:    User clicks Save
50ms:   Create request sent
200ms:  Create response received
210ms:  Cache invalidated
220ms:  Fetch request sent
400ms:  Fetch response received
410ms:  State updated
420ms:  View refreshed
430ms:  Modal dismisses
```

## Comparison: Add Guest vs Import

### Add Guest Flow
1. Create guest (POST)
2. Invalidate cache
3. Reload all guests (GET)
4. Update state
5. Show success
6. Dismiss modal

### Import Flow
1. Create multiple guests (POST)
2. Reload all guests (GET)
3. Update state
4. Show success
5. Dismiss modal

**Both flows now use the same reload pattern** ✅

## Sign-Off Checklist

- [ ] Basic add guest works
- [ ] Add with filters works
- [ ] Multiple adds work
- [ ] Add + import works
- [ ] Error handling works
- [ ] Modal dismisses correctly
- [ ] Console logs show correct messages
- [ ] No console warnings
- [ ] Stats update correctly
- [ ] Filtered list respects filters
- [ ] Other operations still work
- [ ] Performance is acceptable

## Questions?

If tests fail or behavior is unexpected:
1. Check the console logs
2. Verify the fix was applied (check GuestStoreV2.addGuest)
3. Check network requests in browser dev tools
4. Review the GUEST_REFRESH_FIX_SUMMARY.md for details

---

**Last Updated**: December 16, 2025  
**Fix Status**: ✅ Complete  
**Testing Status**: Ready for QA
