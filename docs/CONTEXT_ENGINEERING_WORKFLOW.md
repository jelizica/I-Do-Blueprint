# Context Engineering Workflow Diagram

This document visualizes how context engineering integrates with our existing tools (Basic Memory, Beads, Claude Code, Qodo Gen).

---

## Complete Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                     SESSION START                                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  1. LOAD LONG-TERM KNOWLEDGE (Basic Memory)                     │
│                                                                   │
│  mcp__basic-memory__search_notes("cache strategy")              │
│  mcp__basic-memory__build_context(url: "projects/i-do-blueprint")│
│                                                                   │
│  Returns: Architectural patterns, common pitfalls, decisions     │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  2. GET CURRENT TASK (Beads)                                    │
│                                                                   │
│  bd ready                    # Find available work               │
│  bd show beads-123          # Get task details                  │
│  bd update beads-123 --status=in_progress                       │
│                                                                   │
│  Returns: Task goal, priority, dependencies                      │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  3. CREATE SESSION CONTEXT (Intent-Based Template)              │
│                                                                   │
│  ./Scripts/update-session-context.sh coding-session             │
│                                                                   │
│  Creates: .claude-context.md with structure:                    │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ ## Current Goal                                            │ │
│  │ [From Beads task]                                          │ │
│  │                                                             │ │
│  │ ## Architecture Context                                    │ │
│  │ [From Basic Memory patterns]                               │ │
│  │                                                             │ │
│  │ ## Key Decisions                                           │ │
���  │ [Track decisions as you go]                                │ │
│  │                                                             │ │
│  │ ## Failed Approaches (Don't Retry)                         │ │
│  │ [Critical for avoiding loops]                              │ │
│  │                                                             │ │
│  │ ## Next Steps                                              │ │
│  │ [Specific, actionable tasks]                               │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    WORK LOOP (10 turns)                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  4. WORK WITH AI AGENTS                                          │
│                                                                   │
│  ┌──────────────────┐         ┌──────────────────┐             │
│  │  Claude Code     │         │  Qodo Gen        │             │
│  │                  │         │                  │             │
│  │  "See .claude-   │         │  "Use test-      │             │
│  │   context.md"    │         │   generation-    │             │
│  │                  │         │   template.md"   │             │
│  └──────────────────┘         └──────────────────┘             │
│           ↓                            ↓                         │
│  ┌────────────────────────────────────────────────┐            │
│  │  Intent-Based Context (Deterministic)          │            │
│  │  • Maintains task fidelity                     │            │
│  │  • Tracks failed approaches                    │            │
│  │  • Documents decisions                         │            │
│  │  • Provides architecture context               │            │
│  └────────────────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  5. UPDATE CONTEXT (Every 10 turns)                             │
│                                                                   │
│  ./Scripts/update-session-context.sh update                     │
│                                                                   │
│  Updates:                                                        │
│  • Completed milestones                                          │
│  • New decisions made                                            │
│  • Failed approaches discovered                                  │
│  • Next steps refined                                            │
│  • Session metrics (turns, files, tests)                         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                    [Repeat Work Loop]
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                     SESSION END                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────���──────────────────────┐
│  6. PERSIST NEW KNOWLEDGE (Basic Memory)                        │
│                                                                   │
│  mcp__basic-memory__write_note(                                 │
│    title: "Pattern: Guest Cache Invalidation",                  │
│    folder: "architecture/caching",                              │
│    content: "Discovered pattern...",                            │
│    project: "i-do-blueprint"                                    │
│  )                                                               │
│                                                                   │
│  Stores: New patterns, decisions, pitfalls for future sessions  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  7. COMPLETE TASK (Beads)                                       │
│                                                                   │
│  bd close beads-123                                             │
│  bd sync                                                         │
│                                                                   │
│  Updates: Task status, commits changes to git                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  8. ARCHIVE CONTEXT                                              │
│                                                                   │
│  ./Scripts/update-session-context.sh archive                    │
│                                                                   │
│  Moves: .claude-context.md → .context-archive/context-DATE.md  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌────────────────────────────────────────��────────────────────────┐
│  9. PUSH CODE                                                    │
│                                                                   │
│  git push                                                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## Context Engineering Approaches Comparison

```
┌─────────────────────────────────────────────────────────────────┐
│                    RAW APPROACH (Append-Only)                    │
└─────────────────────────────────────────────────────────────────┘

Turn 1:  [System] [User] [Assistant]
Turn 2:  [System] [User] [Assistant] [User] [Assistant]
Turn 3:  [System] [User] [Assistant] [User] [Assistant] [User] [Assistant]
Turn 10: [System] [User] [Assistant] ... [30+ messages] ... [Assistant]
                                    ↓
                        EXPONENTIAL GROWTH
                        Needle in haystack problem
                        Success rate: ~90%


┌─────────────────────────────────────────────────────────────────┐
│              SUMMARIZATION APPROACH (Auto-Compress)              │
└─────────────────────────────────────────────────────────────────┘

Turn 1:  [System] [User] [Assistant]
Turn 2:  [System] [User] [Assistant] [User] [Assistant]
Turn 5:  [System] [Summary of turns 1-4] [User] [Assistant]
Turn 10: [System] [Summary of turns 1-9] [User] [Assistant]
                                    ↓
                        PLATEAU GROWTH
                        Information loss ("broken telephone")
                        Success rate: ~60-70%


┌─────────────────────────────────────────────────────────────────┐
│           INTENT APPROACH (Deterministic Template)               │
└─────────────────────────────────────────────────────────────────┘

Turn 1:  [Intent Template] [User] [Assistant]
Turn 2:  [Intent Template + Updates] [User] [Assistant]
Turn 10: [Intent Template + Updates] [User] [Assistant]
                                    ↓
                        LINEAR GROWTH
                        No information loss
                        Success rate: 100% ✅
```

---

## Template Selection Decision Tree

```
                    Start New Work
                          ↓
                    What type of work?
                          ↓
        ┌─────────────────┼─────────────────┐
        ↓                 ↓                  ↓
   Feature Dev       Bug Fix          Architecture
   Refactoring       Investigation    Decision
        ↓                 ↓                  ↓
   coding-session-   debugging-       architecture-
   template.md       session-         decision-
                     template.md      template.md
        ↓                 ↓                  ↓
   Writing Tests?    Need ADR?        Need Tests?
        ↓                 ↓                  ↓
   test-generation-  architecture-    test-generation-
   template.md       decision-        template.md
                     template.md
```

---

## Context Update Frequency

```
Session Timeline:
├─ Turn 1-10:   Initial context created
│               [Update at turn 10]
│
├─ Turn 11-20:  Context updated with progress
│               [Update at turn 20]
│
├─ Turn 21-30:  Context updated with decisions
│               [Update at turn 30]
│
└─ Turn 31+:    Context compressed if needed
                [Archive when done]

Update Triggers:
• Every 10 turns (automatic)
• After major milestone (manual)
• When changing focus area (manual)
• When discovering failed approach (immediate)
• When making key decision (immediate)
```

---

## Information Flow

```
┌──────────────────────────────────────────────────────────────┐
│                    LONG-TERM MEMORY                           │
│                    (Basic Memory)                             │
│                                                                │
│  • Architectural patterns                                     │
│  • Common pitfalls                                            │
│  • Design decisions                                           │
│  • Code conventions                                           │
│                                                                │
│  Lifetime: Permanent                                          │
│  Scope: Project-wide                                          │
└──────────────────────────────────────────────────────────────┘
                          ↓ Load at session start
                          ↓ Persist at session end
┌──────────────────────────────────────────────────────────────┐
│                    SESSION CONTEXT                            │
│                    (.claude-context.md)                       │
│                                                                │
│  • Current goal                                               │
│  • Progress tracking                                          │
│  • Key decisions                                              │
│  • Failed approaches                                          │
│  • Next steps                                                 │
│                                                                │
│  Lifetime: Single session                                     │
│  Scope: Current task                                          │
└──────────────────────────────────────────────────────────────┘
                          ↓ Referenced in every prompt
                          ↓ Updated every 10 turns
┌──────────────────────────────────────────────────────────────┐
│                    AI AGENT CONTEXT                           │
│                    (Claude Code / Qodo Gen)                   │
│                                                                │
│  • Immediate conversation                                     │
│  • Tool outputs                                               │
│  • Code snippets                                              │
│  • Error messages                                             │
│                                                                │
│  Lifetime: Current turn                                       │
│  Scope: Immediate action                                      │
└──────────────────────────────────────────────────────────────┘
```

---

## Success Metrics Dashboard

```
┌─────────────────────────────────────────────────────────────┐
│                   SESSION METRICS                            │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Turns to Completion:  [████████░░] 23/50                   │
│  Success Rate:         [██████████] 100%                    │
│  Context Resets:       [░░░░░░░░░░] 0                       │
│  Pattern Reuse:        [████████░░] 8/10                    │
│                                                               │
│  Files Modified:       5                                     │
│  Tests Added:          12                                    │
│  Decisions Made:       3                                     │
│  Failed Approaches:    2 (documented)                        │
│                                                               │
├─────────────────────────────────────────────────────────────┤
│                   QUALITY METRICS                            │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  First-Try Success:    [████████░░] 80%                     │
│  Test Pass Rate:       [██████████] 100%                    │
│  Code Review Score:    [█████████░] 9/10                    │
│                                                               │
├───────────────────────────────────��─────────────────────────┤
│                   EFFICIENCY METRICS                         │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Time to Context:      2 minutes                             │
│  Time to Decision:     5 minutes                             │
│  Time to Fix:          15 minutes                            │
│  Total Session:        45 minutes                            │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Tool Integration Matrix

```
┌──────────────┬─────────────┬──────────────┬─────────────────┐
│ Tool         │ Purpose     │ When to Use  │ Context Source  │
├──────────────┼─────────────┼──────────────┼─────────────────┤
│ Basic Memory │ Long-term   │ Session      │ Permanent       │
│              │ knowledge   │ start/end    │ knowledge base  │
├──────────────┼─────────────┼──────────────┼─────────────────┤
│ Beads        │ Task        │ Throughout   │ Current sprint  │
│              │ tracking    │ session      │ work items      │
├──────────────┼─────────────┼──────────────┼─────────────────┤
│ Context      │ Session     │ Every 10     │ Intent-based    │
│ Template     │ state       │ turns        │ template        │
├──────────────┼─────────────┼──────────────┼─────────────────┤
│ Claude Code  │ Coding      │ Active       │ Session context │
│              │ agent       │ development  │ + conversation  │
├──────────────┼─────────────┼────────��─────┼─────────────────┤
│ Qodo Gen     │ Test        │ Test         │ Test template   │
│              │ generation  │ writing      │ + patterns      │
└──────────────┴─────────────┴──────────────┴─────────────────┘
```

---

## Before vs After Context Engineering

```
BEFORE (Raw Approach):
┌────────────────────────────────────────────────────────────┐
│ Session: Implement guest import feature                    │
├────────────────────────────────────────────────────────────┤
│ Turn 1:  Start implementation                              │
│ Turn 5:  Try approach A (fails)                            │
│ Turn 10: Try approach A again (fails again)                │
│ Turn 15: Try approach B (fails)                            │
│ Turn 20: Forget original goal                              │
│ Turn 25: Ask user for clarification                        │
│ Turn 30: Try approach A third time (fails)                 │
│ Turn 35: Finally try approach C (works)                    │
│ Turn 40: Complete task                                     │
├────────────────────────────────────────────────────────────┤
│ Result: 40 turns, 3 failed retries, 1 context reset       │
│ Success Rate: 70%                                          │
└────────────────────────────────────────────────────────────┘

AFTER (Intent Approach):
┌────────────────────────────────────────────────────────────┐
│ Session: Implement guest import feature                    │
├────────────────────────────────────────────────────────────┤
│ Turn 1:  Load context (goal, patterns, constraints)        │
│ Turn 2:  Try approach A (fails)                            │
│ Turn 3:  Document failure, try approach B (fails)          │
│ Turn 4:  Document failure, try approach C (works)          │
│ Turn 10: Update context with progress                      │
│ Turn 15: Complete implementation                           │
│ Turn 20: Add tests                                         │
│ Turn 23: Complete task                                     │
├────────────────────────────────────────────────────────────┤
│ Result: 23 turns, 0 failed retries, 0 context resets      │
│ Success Rate: 100%                                         │
└────────────────────────────────────────────────────────────┘

Improvement: 42% fewer turns, 100% success rate
```

---

## Quick Reference Commands

```bash
# Session Start
./Scripts/update-session-context.sh coding-session
mcp__basic-memory__search_notes("topic", project: "i-do-blueprint")
bd show <task-id>

# During Session
./Scripts/update-session-context.sh update      # Every 10 turns
./Scripts/update-session-context.sh summary     # Check progress

# Session End
bd close <task-id>
./Scripts/update-session-context.sh archive
mcp__basic-memory__write_note(...)
bd sync && git push
```

---

**For more details, see**:
- Full Analysis: `docs/CONTEXT_ENGINEERING_ANALYSIS.md`
- Quick Start: `docs/CONTEXT_ENGINEERING_QUICK_START.md`
- Templates: `docs/context-templates/`
