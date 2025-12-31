# Coding Session Context Template

**Last Updated**: [Auto-update timestamp]

---

## Current Goal
[One-sentence description of what we're trying to achieve]

**Beads Task**: [Task ID and title]
**Priority**: [P0-P4]
**Estimated Completion**: [Time estimate]

---

## Session Progress

### Completed Milestones
- [x] Milestone 1: [Brief outcome and key files changed]
- [x] Milestone 2: [Brief outcome and key files changed]
- [ ] Milestone 3: [In progress]

### Active Context
- **Current file**: [path/to/file.swift]
- **Current task**: [Specific action being performed]
- **Working on**: [Function/class/feature name]
- **Blockers**: [Any blockers or dependencies]

---

## Key Decisions Made

| Decision | Rationale | Impact | Files Affected |
|----------|-----------|--------|----------------|
| Use V2 store pattern | Consistency with existing architecture | All new stores | `Services/Stores/` |
| Implement cache strategy | Reduce database calls | Performance improvement | `Domain/Repositories/Caching/` |
| [Add more as needed] | | | |

---

## Failed Approaches (Don't Retry)

1. **Approach**: [What was tried]
   - **Why it failed**: [Root cause]
   - **Error**: [Error message if applicable]
   - **Alternative**: [What to try instead]

2. **Approach**: [What was tried]
   - **Why it failed**: [Root cause]
   - **Error**: [Error message if applicable]
   - **Alternative**: [What to try instead]

---

## Architecture Context

### Relevant Patterns
- Repository Pattern: [How it applies to current work]
- Domain Services: [If business logic is complex]
- Cache Strategies: [Which strategy to use]

### Key Files
```
Domain/Models/[Feature]/
Domain/Repositories/Protocols/[Feature]RepositoryProtocol.swift
Domain/Repositories/Live/Live[Feature]Repository.swift
Services/Stores/[Feature]StoreV2.swift
Views/[Feature]/
```

### Dependencies
- Repositories: [List relevant repositories]
- Services: [List relevant domain services]
- Stores: [List dependent stores]

---

## Code Quality Checklist

- [ ] Follows V2 naming convention
- [ ] Uses `@MainActor` for UI-related classes
- [ ] Implements `LoadingState<T>` pattern
- [ ] Uses `handleError` extension for error handling
- [ ] Passes UUIDs directly to Supabase (not `.uuidString`)
- [ ] Uses `DateFormatting` for timezone-aware dates
- [ ] Implements cache invalidation strategy
- [ ] Adds `AppLogger` logging
- [ ] Includes Sentry error tracking
- [ ] Has accessibility labels
- [ ] Uses design system constants (AppColors, Typography, Spacing)
- [ ] Includes unit tests with mock repositories

---

## Next Steps

### Immediate (Next 1-3 turns)
1. [Specific action with file path]
2. [Specific action with file path]
3. [Specific action with file path]

### Following (Next 4-10 turns)
1. [Broader task]
2. [Broader task]
3. [Broader task]

### Before Session End
- [ ] Run tests: `xcodebuild test -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint"`
- [ ] Run SwiftLint: `swiftlint`
- [ ] Update Beads task status
- [ ] Document patterns in Basic Memory
- [ ] Commit and push changes

---

## Memory Integration

### Relevant Basic Memory Notes
- [Note title 1]: [Why it's relevant]
- [Note title 2]: [Why it's relevant]

### Patterns to Document After Session
- [ ] [New pattern discovered]
- [ ] [Architectural decision made]
- [ ] [Common pitfall avoided]

---

## Session Metrics

- **Turns so far**: [Count]
- **Files modified**: [Count]
- **Tests added**: [Count]
- **Context resets**: [Count]

---

## Notes & Observations

[Free-form notes about anything important that doesn't fit above]

---

**Update Frequency**: Every 10 turns or after major milestone
**Template Version**: 1.0
