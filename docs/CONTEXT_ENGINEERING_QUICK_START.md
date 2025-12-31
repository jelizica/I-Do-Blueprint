# Context Engineering Quick Start Guide

**TL;DR**: Use intent-based context templates to achieve 100% task success rate vs 60-90% with raw approaches.

---

## 5-Minute Setup

### 1. Start a New Session

```bash
# Choose your template
./Scripts/update-session-context.sh coding-session
# or
./Scripts/update-session-context.sh debugging-session
# or
./Scripts/update-session-context.sh test-generation
# or
./Scripts/update-session-context.sh architecture-decision
```

This creates `.claude-context.md` in your project root.

### 2. Fill in the Template

Open `.claude-context.md` and complete:
- **Current Goal**: What you're trying to achieve (from Beads task)
- **Architecture Context**: Relevant patterns from Basic Memory
- **Next Steps**: Immediate actions (1-3 specific tasks)

### 3. Reference in Prompts

When working with Claude Code or Qodo Gen:
```
"See .claude-context.md for current session state"
```

### 4. Update Every 10 Turns

```bash
./Scripts/update-session-context.sh update
```

Or manually update key sections:
- Completed milestones
- Failed approaches
- Next steps

### 5. Archive When Done

```bash
./Scripts/update-session-context.sh archive
```

---

## Why This Works

### The Problem
Without context engineering, AI agents:
- Forget earlier decisions (needle in haystack)
- Retry failed approaches (wasted time)
- Lose track of the original goal (hallucination)
- Require more turns to complete tasks (inefficiency)

### The Solution
Intent-based context engineering:
- ✅ **100% success rate** (vs 60-90% for other approaches)
- ✅ **Fewer steps** (<25 vs 30-45 turns)
- ✅ **Maintains task fidelity** (no broken telephone effect)
- ✅ **Linear context growth** (predictable and controllable)

### The Research
Based on [Taras Yarema's benchmark](https://www.tarasyarema.com/blog/agent-context-engineering):
- Tested 3 approaches (raw, summarization, intent)
- Across 4 models (Claude, GPT-4, Gemini)
- On complex analytical tasks
- Intent approach won on all metrics that matter

---

## Templates Overview

### Coding Session Template
**Use for**: Feature development, refactoring, general coding

**Key sections**:
- Current goal and Beads task
- Completed milestones
- Key decisions made
- Failed approaches (critical!)
- Next steps

**Update frequency**: Every 10 turns or major milestone

### Test Generation Template
**Use for**: Writing tests with Qodo Gen

**Key sections**:
- Target component details
- Test scenarios required
- Mock setup requirements
- Recent similar tests (for consistency)

**Update frequency**: Before each test generation

### Debugging Session Template
**Use for**: Bug investigation, troubleshooting

**Key sections**:
- Bug description and reproduction
- Hypotheses tested
- Attempted fixes
- Common pitfalls checklist
- Solution and prevention

**Update frequency**: After each hypothesis or fix attempt

### Architecture Decision Template
**Use for**: ADR creation, design decisions

**Key sections**:
- Problem statement
- Options considered
- Decision matrix
- Implementation plan
- Impact analysis

**Update frequency**: Throughout decision process

---

## Integration with Existing Tools

### With Basic Memory

```bash
# 1. Load long-term knowledge
mcp__basic-memory__search_notes("cache strategy", project: "i-do-blueprint")

# 2. Create session context
./Scripts/update-session-context.sh coding-session

# 3. Fill in relevant patterns from Basic Memory
# [Edit .claude-context.md]

# 4. After session, persist new patterns
mcp__basic-memory__write_note(
  title: "Pattern: Guest Cache Invalidation",
  folder: "architecture/caching",
  project: "i-do-blueprint"
)
```

### With Beads

```bash
# 1. Get current task
bd show beads-123

# 2. Create context
./Scripts/update-session-context.sh coding-session

# 3. Fill in goal from Beads
# [Edit .claude-context.md with task details]

# 4. Update as you work
bd update beads-123 --status=in_progress

# 5. Complete and sync
bd close beads-123
bd sync
```

### Complete Workflow

```bash
# Morning: Start session
bd ready                                    # Find work
./Scripts/update-session-context.sh coding-session
# Fill in context from Beads + Basic Memory

# During: Update context
./Scripts/update-session-context.sh update # Every 10 turns

# Evening: Complete session
bd close beads-123                          # Close task
./Scripts/update-session-context.sh archive # Archive context
bd sync                                     # Sync Beads
git push                                    # Push code
```

---

## Common Patterns

### Pattern 1: Failed Approach Tracking

**Problem**: AI retries the same failed approach multiple times

**Solution**: Document in "Failed Approaches" section

```markdown
## Failed Approaches (Don't Retry)

1. **Approach**: Insert guests one-by-one in loop
   - **Why it failed**: Too slow for large files (>1000 rows)
   - **Error**: Timeout after 500 rows
   - **Alternative**: Use batch insert with transaction
```

**Result**: AI won't retry this approach

### Pattern 2: Decision Documentation

**Problem**: Forgetting why you chose approach A over B

**Solution**: Document in "Key Decisions" table

```markdown
## Key Decisions Made

| Decision | Rationale | Impact | Files Affected |
|----------|-----------|--------|----------------|
| Use V2 store pattern | Consistency with existing architecture | All new stores | Services/Stores/ |
| Implement cache strategy | Reduce database calls | Performance | Domain/Repositories/Caching/ |
```

**Result**: Clear audit trail of decisions

### Pattern 3: Architecture Context

**Problem**: AI suggests patterns inconsistent with project architecture

**Solution**: Pre-load architecture context

```markdown
## Architecture Context

### Relevant Patterns
- Repository Pattern: All data access through protocols
- Domain Services: Complex business logic in actors
- Cache Strategies: Per-domain invalidation strategies

### Key Files
Domain/Repositories/Protocols/GuestRepositoryProtocol.swift
Domain/Repositories/Live/LiveGuestRepository.swift
Services/Stores/GuestStoreV2.swift
```

**Result**: AI follows project conventions

---

## Measuring Success

Track these metrics to validate effectiveness:

### Before Context Engineering
- Success rate: ~70%
- Average turns: 35-40
- Context resets: 2-3 per session
- Pattern reuse: Low

### After Context Engineering
- Success rate: ~95%+
- Average turns: 20-25
- Context resets: 0-1 per session
- Pattern reuse: High

### How to Measure

Add to `.claude-context.md`:

```markdown
## Session Metrics

- **Turns so far**: [Count]
- **Files modified**: [Count]
- **Tests added**: [Count]
- **Context resets**: [Count]
```

Update after each major milestone.

---

## Troubleshooting

### "Context file is getting too long"

**Solution**: You're updating too infrequently or including too much detail.

**Fix**:
1. Update every 10 turns (not 50)
2. Keep "Completed Milestones" to last 5 items
3. Archive old contexts: `./Scripts/update-session-context.sh archive`

### "AI still forgetting things"

**Solution**: Critical information not in context.

**Fix**:
1. Check "Failed Approaches" section is filled
2. Verify "Key Decisions" are documented
3. Ensure "Next Steps" are specific (not vague)

### "Too much manual work"

**Solution**: Use automation script.

**Fix**:
```bash
# Auto-update timestamp and git info
./Scripts/update-session-context.sh update

# Show summary without opening file
./Scripts/update-session-context.sh summary
```

---

## Advanced Tips

### Tip 1: Context Compression

When context grows large, compress completed work:

```markdown
## Completed Milestones
- [x] Phase 1: Guest import (5 files, 3 tests) ✓
- [x] Phase 2: Validation (2 files, 4 tests) ✓
- [ ] Phase 3: Error handling (in progress)
```

Instead of listing every single file change.

### Tip 2: Cross-Reference

Link to external resources:

```markdown
## Related Resources
- Basic Memory: "Cache Strategy Pattern"
- ADR: docs/adrs/ADR-015-cache-invalidation.md
- Beads: beads-123 (parent task)
```

### Tip 3: Template Customization

Create project-specific templates:

```bash
cp docs/context-templates/coding-session-template.md \
   docs/context-templates/swiftui-view-template.md

# Customize for SwiftUI-specific patterns
```

### Tip 4: Pre-Session Checklist

Before starting work:

- [ ] Loaded Beads task
- [ ] Searched Basic Memory for relevant patterns
- [ ] Created context from template
- [ ] Filled in current goal
- [ ] Listed next 3 steps

### Tip 5: Post-Session Checklist

After completing work:

- [ ] Updated context with final state
- [ ] Documented new patterns in Basic Memory
- [ ] Closed Beads task
- [ ] Archived context
- [ ] Pushed code

---

## Next Steps

1. **Try it now**: Start a session with `./Scripts/update-session-context.sh coding-session`
2. **Read full analysis**: See `docs/CONTEXT_ENGINEERING_ANALYSIS.md`
3. **Explore templates**: Browse `docs/context-templates/`
4. **Integrate workflow**: Update `BASIC-MEMORY-AND-BEADS-GUIDE.md`

---

## Resources

- **Original Research**: https://www.tarasyarema.com/blog/agent-context-engineering
- **GitHub Repo**: https://github.com/desplega-ai/context-engineering
- **Anthropic Guide**: https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
- **Full Link List**: See `docs/CONTEXT_ENGINEERING_ANALYSIS.md`

---

**Questions?** Check the full analysis document or create a Basic Memory note with your findings!
