# Context Engineering Templates

This directory contains templates for implementing **Intent-Based Context Engineering** as described in [Taras Yarema's benchmark research](https://www.tarasyarema.com/blog/agent-context-engineering).

## Why Context Engineering Matters

Research shows that **how you structure context** matters more than which AI framework you use:

- **Intent approach**: 100% success rate
- **Raw append-only**: ~90% success rate  
- **Summarization**: ~60-70% success rate

The Intent approach requires fewer steps (<25 vs 30-45) and maintains task fidelity throughout long sessions.

## Available Templates

### 1. Coding Session Template
**File**: `coding-session-template.md`  
**Use for**: Claude Code sessions, feature development, refactoring

**Key sections**:
- Current goal and progress tracking
- Key decisions made
- Failed approaches (don't retry)
- Architecture context
- Next steps

**Update frequency**: Every 10 turns or after major milestone

### 2. Test Generation Template
**File**: `test-generation-template.md`  
**Use for**: Qodo Gen, writing unit/integration tests

**Key sections**:
- Project architecture context
- Target component details
- Test scenarios required
- Mock setup requirements
- Recent similar tests for consistency

**Update frequency**: Before each test generation session

### 3. Debugging Session Template
**File**: `debugging-session-template.md`  
**Use for**: Bug investigation, troubleshooting, root cause analysis

**Key sections**:
- Bug description and reproduction
- Hypotheses tested
- Attempted fixes
- Common pitfalls checklist
- Solution and prevention

**Update frequency**: After each hypothesis test or fix attempt

### 4. Architecture Decision Template
**File**: `architecture-decision-template.md`  
**Use for**: ADR creation, architectural decisions, design discussions

**Key sections**:
- Problem statement and context
- Options considered with pros/cons
- Decision matrix
- Implementation plan
- Impact analysis

**Update frequency**: Throughout decision-making process

## How to Use

### Quick Start

1. **Copy the appropriate template** to your working directory:
   ```bash
   cp docs/context-templates/coding-session-template.md .claude-context.md
   ```

2. **Fill in the template** with current context:
   - Current goal from Beads task
   - Relevant patterns from Basic Memory
   - Architecture context from project

3. **Reference in prompts**:
   ```
   "See .claude-context.md for current session state"
   ```

4. **Update regularly**:
   - Every 10 turns
   - After major milestones
   - When changing focus areas

### Integration with Existing Workflow

#### With Basic Memory
```bash
# Load long-term knowledge
mcp__basic-memory__search_notes("relevant topic", project: "i-do-blueprint")

# Create session context from template
cp docs/context-templates/coding-session-template.md .claude-context.md

# Update with Basic Memory findings
# [Edit .claude-context.md]

# After session, persist new patterns
mcp__basic-memory__write_note(
  title: "Pattern: [discovered pattern]",
  folder: "architecture/patterns",
  project: "i-do-blueprint"
)
```

#### With Beads
```bash
# Get current task
bd show <task-id>

# Create context from template
cp docs/context-templates/coding-session-template.md .claude-context.md

# Fill in goal from Beads task
# [Edit .claude-context.md]

# Update Beads as you progress
bd update <task-id> --status=in_progress

# Complete and sync
bd close <task-id>
bd sync
```

### Automation Script

Use `Scripts/update-session-context.sh` to auto-populate context:

```bash
# Update context with current state
./Scripts/update-session-context.sh

# This populates:
# - Current Beads task
# - Recent git commits
# - Modified files
# - Timestamp
```

## Template Structure

All templates follow this structure:

```markdown
# [Template Name]

**Last Updated**: [Timestamp]

---

## [Primary Section]
[Core information that changes frequently]

---

## [Context Section]
[Stable information that provides background]

---

## [Progress Section]
[What's been done, what's next]

---

## [Reference Section]
[Links to related resources]
```

## Best Practices

### DO ✅

1. **Update regularly**: Every 10 turns or major milestone
2. **Be specific**: "Implement cache invalidation for guests" not "work on caching"
3. **Document failures**: Record what didn't work to avoid retrying
4. **Link to resources**: Reference Basic Memory notes, ADRs, code files
5. **Track decisions**: Record why you chose approach A over B
6. **Use checklists**: Ensure nothing is forgotten

### DON'T ❌

1. **Don't let it grow stale**: Outdated context is worse than no context
2. **Don't be vague**: "Fix bug" doesn't help; "Fix UUID case mismatch in guest queries" does
3. **Don't skip failed approaches**: These are critical to avoid loops
4. **Don't duplicate code**: Link to files, don't paste entire implementations
5. **Don't ignore the template**: Each section serves a purpose
6. **Don't forget to clean up**: Archive old contexts after session ends

## Measuring Success

Track these metrics to validate context engineering effectiveness:

### Session Metrics
- **Turns to completion**: How many turns to finish task?
- **Context resets**: How often did you need to restart?
- **Success rate**: Did you complete the task?
- **Pattern reuse**: How often did you reference previous solutions?

### Quality Metrics
- **First-try success**: Did code work on first attempt?
- **Test pass rate**: Did tests pass without revision?
- **Review feedback**: How much revision needed in code review?

### Efficiency Metrics
- **Time to context**: How long to load relevant context?
- **Time to decision**: How long to make architectural decisions?
- **Time to fix**: How long to debug and fix issues?

## Examples

### Example 1: Coding Session Context

```markdown
# Coding Session Context

**Last Updated**: 2025-01-15 14:30 PST

---

## Current Goal
Implement guest import feature with CSV validation

**Beads Task**: beads-123 "Add CSV import for guests"
**Priority**: P1

---

## Completed Milestones
- [x] Created FileImportService with CSV parsing
- [x] Added validation for required fields
- [ ] Implement bulk insert with error handling

---

## Key Decisions Made
| Decision | Rationale | Impact |
|----------|-----------|--------|
| Use CoreXLSX library | Already in project, handles both CSV and XLSX | Services/Import/ |
| Validate before insert | Prevent partial imports | Better UX |

---

## Failed Approaches (Don't Retry)
1. **Approach**: Insert guests one-by-one
   - **Why it failed**: Too slow for large files (>1000 rows)
   - **Alternative**: Use batch insert with transaction

---

## Next Steps
1. Implement batch insert in LiveGuestRepository
2. Add progress reporting to FileImportService
3. Create unit tests with mock CSV data
```

### Example 2: Debugging Session Context

```markdown
# Debugging Session Context

**Last Updated**: 2025-01-15 16:45 PST

---

## Bug Description
**Issue ID**: beads-456
**Priority**: P0
**Severity**: Critical

### Symptoms
Guest queries return empty results in production but work in development

---

## Investigation Progress

### Hypothesis 1: UUID case mismatch
- **Status**: ✅ Confirmed
- **Evidence**: Production uses lowercase UUIDs, code uses uppercase
- **Test**: Logged UUID values from both environments
- **Result**: Confirmed mismatch
- **Next**: Normalize to lowercase in queries

---

## Solution
Use `.uuidString.lowercased()` for cache keys and dictionary lookups

---

## Prevention
- [ ] Added test for UUID case sensitivity
- [ ] Updated best_practices.md with UUID pitfall
- [ ] Created Basic Memory note on UUID handling
```

## Related Documentation

- **Main Guide**: `CONTEXT_ENGINEERING_ANALYSIS.md` - Full research analysis
- **Workflow Guide**: `BASIC-MEMORY-AND-BEADS-GUIDE.md` - Integration with existing tools
- **Best Practices**: `best_practices.md` - Project coding standards
- **Architecture**: `CLAUDE.md` - Project architecture overview

## Feedback & Improvements

These templates are living documents. If you find:
- Missing sections that would be helpful
- Sections that are never used
- Better ways to structure information
- Automation opportunities

Please update the templates and this README!

---

**Template Version**: 1.0  
**Last Updated**: January 2025  
**Maintained By**: Development Team
