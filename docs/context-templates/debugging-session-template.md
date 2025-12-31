# Debugging Session Context Template

**Last Updated**: [Auto-update timestamp]

---

## Bug Description

**Issue ID**: [Beads task ID]
**Priority**: [P0-P4]
**Severity**: [Critical / High / Medium / Low]

### Symptoms
[What's going wrong? What's the observable behavior?]

### Expected Behavior
[What should happen instead?]

### Reproduction Steps
1. [Step 1]
2. [Step 2]
3. [Step 3]

### Environment
- **macOS Version**: [e.g., 14.0]
- **Xcode Version**: [e.g., 15.0]
- **Build Configuration**: [Debug / Release]
- **Affected Features**: [List features]

---

## Investigation Progress

### Hypotheses Tested

#### Hypothesis 1: [Description]
- **Status**: ✅ Confirmed / ❌ Rejected / 🔄 In Progress
- **Evidence**: [What led to this hypothesis]
- **Test**: [How you tested it]
- **Result**: [What you found]
- **Next**: [What to do based on result]

#### Hypothesis 2: [Description]
- **Status**: ✅ Confirmed / ❌ Rejected / 🔄 In Progress
- **Evidence**: [What led to this hypothesis]
- **Test**: [How you tested it]
- **Result**: [What you found]
- **Next**: [What to do based on result]

### Root Cause
[Once identified, describe the root cause clearly]

---

## Error Details

### Error Message
```
[Full error message or stack trace]
```

### Error Location
- **File**: [path/to/file.swift]
- **Line**: [Line number]
- **Function**: [Function name]
- **Context**: [What was happening when error occurred]

### Related Logs
```
[Relevant AppLogger output]
```

### Sentry Event
- **Event ID**: [If captured by Sentry]
- **URL**: [Link to Sentry event]

---

## Code Context

### Affected Components
```
[List of files/classes/functions involved]
```

### Data Flow
```
[Trace the data flow that leads to the bug]
User Action → View → Store → Repository → Supabase
                ↓
            [Where it breaks]
```

### Recent Changes
```bash
# Git history of affected files
git log --oneline -10 -- path/to/affected/file.swift
```

**Relevant Commits**:
- [commit hash]: [commit message]
- [commit hash]: [commit message]

---

## Attempted Fixes

### Fix Attempt 1: [Description]
- **Approach**: [What you tried]
- **Code Changed**: [Files/lines modified]
- **Result**: ✅ Worked / ❌ Failed / 🔄 Partial
- **Why it failed**: [If failed, explain why]
- **Rollback**: [If rolled back, why]

### Fix Attempt 2: [Description]
- **Approach**: [What you tried]
- **Code Changed**: [Files/lines modified]
- **Result**: ✅ Worked / ❌ Failed / 🔄 Partial
- **Why it failed**: [If failed, explain why]
- **Rollback**: [If rolled back, why]

---

## Known Working State

### Last Known Good
- **Commit**: [commit hash]
- **Date**: [date]
- **What changed since**: [Summary of changes]

### Bisect Results
```bash
# If using git bisect
git bisect start
git bisect bad [bad commit]
git bisect good [good commit]
# Result: [First bad commit]
```

---

## Related Issues

### Similar Bugs
- [Issue ID]: [Description] - [Status]
- [Issue ID]: [Description] - [Status]

### Related ADRs
- [ADR title]: [Why it's relevant]
- [ADR title]: [Why it's relevant]

### Basic Memory References
- [Note title]: [Relevant pattern or pitfall]
- [Note title]: [Relevant pattern or pitfall]

---

## Common Pitfalls Checklist

### Multi-Tenancy Issues
- [ ] Filtering by `couple_id`?
- [ ] Using UUID directly (not `.uuidString`)?
- [ ] RLS policies correct?

### Async/Await Issues
- [ ] Using `@MainActor` where needed?
- [ ] Proper error handling with `do-catch`?
- [ ] Avoiding race conditions?
- [ ] Task cancellation handled?

### Cache Issues
- [ ] Cache invalidation strategy correct?
- [ ] Cache key format consistent?
- [ ] TTL appropriate?
- [ ] Stale data possible?

### State Management Issues
- [ ] Using `@Published` for observable state?
- [ ] LoadingState transitions correct?
- [ ] Error state properly set?
- [ ] State updates on main thread?

### Date/Time Issues
- [ ] Using `DateFormatting` utility?
- [ ] Timezone handling correct?
- [ ] UTC for database storage?
- [ ] User timezone for display?

### UUID Issues
- [ ] Case sensitivity (uppercase vs lowercase)?
- [ ] String conversion only when necessary?
- [ ] Consistent format across codebase?

### Repository Issues
- [ ] Using NetworkRetry for resilience?
- [ ] Error tracking with Sentry?
- [ ] Logging with AppLogger?
- [ ] Mock repositories in tests?

---

## Debugging Tools Used

### Xcode Debugger
- [ ] Breakpoints set at: [locations]
- [ ] Variables inspected: [list]
- [ ] LLDB commands used: [list]

### Logging
```swift
// Added debug logging
AppLogger.database.debug("Variable value: \(value)")
AppLogger.database.error("Error occurred", error: error)
```

### Instruments
- [ ] Time Profiler
- [ ] Allocations
- [ ] Leaks
- [ ] Network
- [ ] Other: [specify]

### Network Inspection
- [ ] Supabase logs checked
- [ ] Network requests inspected
- [ ] Response payloads verified

---

## Solution

### Final Fix
[Describe the solution that worked]

### Code Changes
```swift
// Before
[Old code]

// After
[New code]
```

### Files Modified
- [path/to/file1.swift]: [What changed]
- [path/to/file2.swift]: [What changed]

### Why This Works
[Explain why this solution addresses the root cause]

---

## Prevention

### Tests Added
- [ ] Unit test for bug scenario
- [ ] Integration test for data flow
- [ ] UI test for user interaction

### Documentation Updated
- [ ] Added to Common Pitfalls in best_practices.md
- [ ] Created Basic Memory note
- [ ] Updated relevant ADR
- [ ] Added to troubleshooting guide

### Code Improvements
- [ ] Added validation
- [ ] Improved error handling
- [ ] Added logging
- [ ] Added assertions

---

## Lessons Learned

### What Went Wrong
[Root cause analysis - why did this bug exist?]

### What Went Right
[What helped in debugging?]

### What to Do Differently
[How to prevent similar bugs in the future?]

### Pattern to Remember
[If this reveals a common pattern, describe it]

---

## Next Steps

### Immediate
- [ ] Verify fix in all scenarios
- [ ] Run full test suite
- [ ] Check for similar issues in codebase
- [ ] Update Beads task

### Follow-up
- [ ] Monitor Sentry for related errors
- [ ] Review with team
- [ ] Update documentation
- [ ] Create preventive measures

---

## Session Metrics

- **Time to identify root cause**: [Duration]
- **Time to fix**: [Duration]
- **Hypotheses tested**: [Count]
- **Fix attempts**: [Count]
- **Files modified**: [Count]
- **Tests added**: [Count]

---

## Notes

[Any additional observations or context]

---

**Template Version**: 1.0
**Session Start**: [Timestamp]
**Session End**: [Timestamp]
