# Using Basic Memory & Beads in Tandem

A comprehensive guide to combining Basic Memory (knowledge management) and Beads (issue tracking) for optimal AI-assisted development workflows.

---

## Table of Contents

1. [Overview](#overview)
2. [Core Differences](#core-differences)
3. [When to Use Each Tool](#when-to-use-each-tool)
4. [Integrated Workflow Patterns](#integrated-workflow-patterns)
5. [Setup & Configuration](#setup--configuration)
6. [Command Reference](#command-reference)
7. [Best Practices](#best-practices)
8. [Real-World Examples](#real-world-examples)

---

## Overview

### What is Basic Memory?

**Basic Memory** is a knowledge management platform that creates a persistent, semantic knowledge base enabling bidirectional collaboration between humans and AI assistants.

**Key Characteristics:**
- 📚 **Long-term knowledge repository** - Architectural decisions, research, documentation
- 🧠 **Semantic graph structure** - Automatically connects related concepts
- ✍️ **Markdown files** - Human-readable, version-controllable
- 🤝 **Bidirectional collaboration** - Both humans and AI read/write
- 🔌 **MCP integration** - Available across Claude Desktop, Claude Code, Cursor, VS Code

**Purpose**: Stores the **WHY** and **WHAT** of your project.

### What is Beads?

**Beads** is a distributed, git-backed graph issue tracker optimized for AI agents, replacing unorganized markdown task lists with a dependency-aware task graph.

**Key Characteristics:**
- 📋 **Task & issue tracking** - Structured work management
- 🔗 **Dependency graph** - Track blocking relationships
- 📦 **Git-native storage** - JSONL files in `.beads/` directory
- 🤖 **Agent-optimized** - JSON output, hash-based IDs prevent conflicts
- ⚡ **Performance-focused** - SQLite cache, background sync daemon

**Purpose**: Tracks the **HOW** and **WHEN** of your work.

---

## Core Differences

| Aspect | Basic Memory | Beads |
|--------|-------------|-------|
| **Primary Focus** | Knowledge & documentation | Task execution & tracking |
| **Time Horizon** | Long-term (months/years) | Short-term (hours/days/weeks) |
| **Content Type** | WHY & WHAT | HOW & WHEN |
| **Storage Format** | Markdown files (.md) | JSONL files (.jsonl) |
| **Data Structure** | Semantic knowledge graph | Dependency task graph |
| **Access Method** | MCP tools (read_note, write_note) | CLI commands (bd create, bd update) |
| **Typical Size** | 2000+ word documents | Short task descriptions |
| **Versioning** | Optional git integration | Git-native (required) |
| **Search** | Semantic search across knowledge | Query by status, dependencies |
| **Collaboration** | Human ↔ AI bidirectional | Primarily AI agent workflow |
| **Context** | Persistent across all sessions | Session continuity & handoff |
| **Organization** | Folder hierarchy by domain | Priority, status, dependencies |

---

## When to Use Each Tool

### Use Basic Memory For:

#### 1. **Architectural Decisions**
```
Why did we choose the Repository pattern?
Why do we use actor-based caching?
What's our stance on multi-tenancy security?
```

#### 2. **Technical Documentation**
```
How does timezone-aware date handling work?
What's the cache invalidation strategy?
How do we structure multi-tenant queries?
```

#### 3. **Domain Knowledge**
```
Wedding planning business rules
Guest management workflows
Budget calculation formulas
```

#### 4. **Research & Solutions**
```
Investigation into Swift concurrency patterns
Supabase Row Level Security best practices
SwiftUI performance optimization techniques
```

#### 5. **Code Patterns & Standards**
```
Error handling patterns
Naming conventions
Testing strategies
Design system guidelines
```

#### 6. **Project Context**
```
Technology stack overview
System architecture diagrams
Integration patterns
Third-party service configurations
```

### Use Beads For:

#### 1. **Feature Development**
```
Implement RSVP embeddable widget
Add export to Google Sheets functionality
Build seating chart drag-and-drop interface
```

#### 2. **Bug Fixes**
```
Fix UUID case mismatch in guest queries
Resolve cache invalidation race condition
Address timezone display inconsistency
```

#### 3. **Technical Tasks**
```
Migrate to Supabase Edge Functions
Update Swift Package dependencies
Refactor BudgetStoreV2 composition
```

#### 4. **Dependency Management**
```
Task A depends on Task B
Feature requires infrastructure setup first
Testing blocked until implementation complete
```

#### 5. **Work Prioritization**
```
P0 (Critical): Production bugs
P1 (High): Customer-requested features
P2 (Medium): Technical debt
P3-P4 (Low/Backlog): Nice-to-haves
```

#### 6. **Session Continuity**
```
What was I working on?
What's next in the queue?
What's blocked and why?
```

---

## Integrated Workflow Patterns

### Pattern 1: Research → Plan → Execute → Document

This is the most common workflow combining both tools:

```
┌─────────────────────────────────────────────────────────────┐
│ 1. RESEARCH (Basic Memory)                                  │
│    Query existing knowledge, read architecture docs         │
│    mcp__basic-memory__search_notes("repository pattern")    │
│    mcp__basic-memory__read_note("Cache Strategy")           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. PLAN (Beads)                                             │
│    Create work items, establish dependencies                │
│    bd create "Implement guest import feature" -p 1          │
│    bd create "Add CSV validation" -p 1                      │
│    bd dep add beads-xxx beads-yyy                           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. EXECUTE (Beads)                                          │
│    Track active work, update status                         │
│    bd ready                                                 │
│    bd update beads-xxx --status=in_progress                 │
│    [Write code, run tests]                                  │
│    bd close beads-xxx                                       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. DOCUMENT (Basic Memory)                                  │
│    Capture decisions, update patterns                       │
│    mcp__basic-memory__write_note(                           │
│      title: "CSV Import Pattern",                           │
│      folder: "architecture/data-import"                     │
│    )                                                        │
└─────────────────────────────────────────────────────────────┘
```

### Pattern 2: Problem → Investigate → Fix → Learn

For debugging and issue resolution:

```
┌─────────────────────────────────────────────────────────────┐
│ 1. PROBLEM REPORTED (Beads)                                 │
│    bd create "UUID case mismatch bug" -t bug -p 0           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. INVESTIGATE (Basic Memory)                               │
│    Search for similar issues, check architecture            │
│    mcp__basic-memory__search_notes("UUID handling")         │
│    mcp__basic-memory__read_note("Supabase Query Patterns")  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. FIX (Beads)                                              │
│    bd update beads-xxx --status=in_progress                 │
│    [Apply fix, test, commit]                                │
│    bd close beads-xxx                                       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. LEARN (Basic Memory)                                     │
│    Document the pitfall for future reference                │
│    mcp__basic-memory__write_note(                           │
│      title: "Common Pitfall - UUID String Conversion",      │
│      folder: "troubleshooting"                              │
│    )                                                        │
└─────────────────────────────────────────────────────────────┘
```

### Pattern 3: Session Start Protocol

Beginning a new work session:

```bash
# 1. Restore context (Basic Memory)
mcp__basic-memory__recent_activity(timeframe: "7d", project: "i-do-blueprint")
mcp__basic-memory__build_context(url: "projects/i-do-blueprint")

# 2. Check active work (Beads)
bd ready                    # What's ready to work?
bd list --status=in_progress # What was I working on?
bd blocked                  # What's blocked?

# 3. Select next task (Beads)
bd show beads-xxx          # Review details
bd update beads-xxx --status=in_progress

# 4. Load relevant knowledge (Basic Memory)
mcp__basic-memory__search_notes("relevant topic")
mcp__basic-memory__read_note("Architecture Doc")
```

### Pattern 4: Session End Protocol

Closing a work session:

```bash
# 1. Complete work items (Beads)
bd close beads-xxx beads-yyy beads-zzz  # Close all completed tasks
bd update beads-aaa --status=blocked    # Mark blocked items

# 2. Document new knowledge (Basic Memory)
mcp__basic-memory__write_note(
  title: "New Pattern Discovered",
  content: "...",
  folder: "architecture/patterns",
  tags: ["swift", "async", "patterns"]
)

# 3. Update architectural notes (Basic Memory)
mcp__basic-memory__edit_note(
  identifier: "Repository Patterns",
  operation: "append",
  content: "\n## Lessons Learned\n..."
)

# 4. Sync to git (Beads)
bd sync
```

### Pattern 5: Cross-Reference Pattern

Linking task work to knowledge:

```
┌─────────────────────────────────────────────────────────────┐
│ Basic Memory Note                                           │
│ ────────────────────────────────────────────────────────────│
│ # Repository Pattern - Cache Invalidation Strategy          │
│                                                             │
│ ## Implementation                                           │
│ See beads-a1b2 for implementation tracking                  │
│                                                             │
│ ## Related Work                                             │
│ - beads-c3d4: Performance optimization                      │
│ - beads-e5f6: Testing improvements                          │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Beads Task                                                  │
│ ────────────────────────────────────────────────────────────│
│ bd show beads-a1b2                                          │
│                                                             │
│ Title: Implement cache invalidation strategy               │
│ Status: in_progress                                         │
│ Notes: Architecture doc at                                  │
│        memory://architecture/caching/cache-strategy         │
│                                                             │
│ Dependencies:                                               │
│ - Blocks: beads-e5f6 (testing)                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Setup & Configuration

### Initial Setup

#### 1. Install Both Tools

```bash
# Install Basic Memory (follow docs.basicmemory.com)
# Configure MCP integration in Claude Desktop/Code

# Install Beads
npm install -g @beads/bd
# or
brew install steveyegge/beads/bd
```

#### 2. Initialize Beads in Your Project

```bash
cd /path/to/your/project
bd init
```

This creates:
- `.beads/` directory (git-tracked)
- `.beads/issues/` for JSONL issue files
- `.beads/config.json` for configuration
- `.beads/cache.db` for local SQLite cache (gitignored)

#### 3. Configure Basic Memory Project

Set up your Basic Memory project structure:

```bash
# Create project in Basic Memory
# Configure folders matching your needs:
# - architecture/
# - database/
# - security/
# - testing/
# - projects/
# - quick-reference/
```

#### 4. Update Project Documentation

Create `AGENTS.md` (for AI agents):

```markdown
# Agent Guidelines

## Task Tracking
This project uses Beads for task management. Use `bd` commands for:
- Creating tasks: `bd create "Task title" -p <priority>`
- Checking ready work: `bd ready`
- Managing dependencies: `bd dep add <child> <parent>`

## Knowledge Base
This project uses Basic Memory for architectural knowledge. Use MCP tools:
- Reading docs: `mcp__basic-memory__read_note(identifier, project)`
- Searching: `mcp__basic-memory__search_notes(query, project)`
- Writing: `mcp__basic-memory__write_note(title, content, folder, project)`
```

---

## Command Reference

### Basic Memory MCP Tools

#### Reading
```javascript
// Read a specific note
mcp__basic-memory__read_note({
  identifier: "Note Title or Permalink",
  project: "i-do-blueprint"
})

// Search notes
mcp__basic-memory__search_notes({
  query: "search terms",
  project: "i-do-blueprint",
  types: ["note"],
  page_size: 20
})

// Build context from path
mcp__basic-memory__build_context({
  url: "architecture/repositories",
  depth: 2,
  project: "i-do-blueprint"
})

// View formatted note
mcp__basic-memory__view_note({
  identifier: "Note Title",
  project: "i-do-blueprint"
})
```

#### Writing
```javascript
// Create new note
mcp__basic-memory__write_note({
  title: "Note Title",
  content: "# Heading\n\nContent...",
  folder: "architecture/patterns",
  tags: ["tag1", "tag2"],
  project: "i-do-blueprint"
})

// Edit existing note
mcp__basic-memory__edit_note({
  identifier: "Note Title",
  operation: "append",  // or "prepend", "find_replace", "replace_section"
  content: "\n## New Section\n...",
  project: "i-do-blueprint"
})
```

#### Navigation
```javascript
// List directory
mcp__basic-memory__list_directory({
  dir_name: "architecture",
  depth: 2,
  project: "i-do-blueprint"
})

// Recent activity
mcp__basic-memory__recent_activity({
  timeframe: "7d",
  project: "i-do-blueprint"
})
```

### Beads CLI Commands

#### Creating & Managing
```bash
# Create tasks
bd create "Task title" -p 0             # Priority 0 (critical)
bd create "Feature title" -t feature -p 1
bd create "Bug title" -t bug -p 0

# Update tasks
bd update beads-xxx --status=in_progress
bd update beads-xxx --assignee=username
bd update beads-xxx --priority=2

# Close tasks
bd close beads-xxx
bd close beads-xxx beads-yyy beads-zzz  # Bulk close
bd close beads-xxx --reason="Completed after testing"
```

#### Querying
```bash
# Find work
bd ready                               # Tasks ready to work (no blockers)
bd list --status=open                  # All open tasks
bd list --status=in_progress           # Active work
bd blocked                             # All blocked tasks

# View details
bd show beads-xxx                      # Full task details
bd show beads-xxx --format=json        # JSON output for agents
```

#### Dependencies
```bash
# Add dependencies (child depends on parent)
bd dep add beads-child beads-parent    # child DEPENDS ON parent (parent BLOCKS child)

# The task that IS DEPENDED UPON is the blocker
# The task that DEPENDS ON another is the blocked

# Example: Testing depends on Implementation
bd dep add beads-test beads-impl       # impl blocks test
```

#### Sync & Maintenance
```bash
# Sync with git
bd sync                                # Commit and push .beads/ changes
bd sync --status                       # Check sync status

# Project health
bd stats                               # Statistics
bd doctor                              # Check for issues
```

---

## Best Practices

### 1. Separation of Concerns

**Basic Memory = Knowledge**
- Architectural decisions that outlive individual tasks
- Reusable patterns and solutions
- Research and investigation results
- "Why we do things this way"

**Beads = Execution**
- Current sprint/week work
- Bugs that need fixing
- Features in development
- "What we're doing right now"

### 2. Cross-Referencing

**Link Beads tasks to Basic Memory docs:**

```bash
# In Beads task
bd create "Implement cache invalidation" -p 1
bd update beads-xxx --notes="See memory://architecture/caching/strategy"
```

**Reference Beads tasks in Basic Memory:**

```markdown
# Cache Invalidation Strategy

## Current Implementation
Implementation tracked in beads-a1b2

## Related Work
- beads-c3d4: Performance testing
- beads-e5f6: Integration tests
```

### 3. Documentation Timing

**Document AFTER completing work, not before:**

```
❌ WRONG:
1. Write architecture doc in Basic Memory
2. Create Beads task
3. Implement
4. Close task

✅ CORRECT:
1. Create Beads task
2. Research in Basic Memory
3. Implement
4. Close task
5. Document new patterns in Basic Memory
```

### 4. Task Granularity

**Beads tasks should be:**
- Completable in < 1 day ideally
- Have clear success criteria
- Be independently testable

**Basic Memory notes should be:**
- Comprehensive (1000-3000 words)
- Answer "why" and "what", not just "how"
- Connect to related concepts

### 5. Search Strategies

**Basic Memory - Semantic Search:**
```javascript
// Good: Conceptual queries
mcp__basic-memory__search_notes({
  query: "cache invalidation patterns",
  project: "i-do-blueprint"
})

// Bad: Specific task names
mcp__basic-memory__search_notes({
  query: "beads-a1b2"  // Use Beads for this
})
```

**Beads - Structured Queries:**
```bash
# Good: Status/priority filters
bd list --status=in_progress --priority=0

# Bad: Conceptual searches
bd search "why do we use repositories?"  # Use Basic Memory
```

### 6. Priority Alignment

**Map Beads priorities to Basic Memory importance:**

| Beads Priority | Basic Memory Action |
|----------------|---------------------|
| P0 (Critical) | Document immediately after fix |
| P1 (High) | Document patterns if novel |
| P2 (Medium) | Document if creates reusable pattern |
| P3-P4 (Low) | Document only if architecturally significant |

### 7. AI Agent Workflows

**Teach agents the distinction:**

```markdown
# In AGENTS.md or CLAUDE.md

## Knowledge vs. Execution

**Before starting ANY task:**
1. Search Basic Memory for relevant architecture/patterns
2. Check Beads for related or blocking work
3. Read necessary documentation
4. Create/update Beads task for tracking

**After completing ANY task:**
1. Close Beads task
2. If pattern is reusable → Document in Basic Memory
3. If decision was made → Record in Basic Memory
4. Sync Beads to git
```

---

## Real-World Examples

### Example 1: Adding a New Feature

**Scenario**: Add CSV import for guest list

```bash
# ═══════════════════════════════════════════════════════════
# PHASE 1: RESEARCH (Basic Memory)
# ═══════════════════════════════════════════════════════════

mcp__basic-memory__search_notes({
  query: "file import patterns CSV validation",
  project: "i-do-blueprint"
})

mcp__basic-memory__read_note({
  identifier: "Repository Pattern - File Operations",
  project: "i-do-blueprint"
})

# ═══════════════════════════════════════════════════════════
# PHASE 2: PLANNING (Beads)
# ═══════════════════════════════════════════════════════════

bd create "Implement CSV guest import feature" -t feature -p 1
# → Creates beads-a1b2

bd create "Add CSV validation service" -t task -p 1
# → Creates beads-c3d4

bd create "Create FileImportService tests" -t task -p 2
# → Creates beads-e5f6

# Establish dependencies
bd dep add beads-a1b2 beads-c3d4  # Feature depends on validation
bd dep add beads-e5f6 beads-a1b2  # Tests depend on feature

# ═══════════════════════════════════════════════════════════
# PHASE 3: EXECUTION (Beads + Coding)
# ═══════════════════════════════════════════════════════════

bd ready
# Shows: beads-c3d4 (no blockers)

bd update beads-c3d4 --status=in_progress

# [Write code for CSV validation]
# [Run tests]
# [Commit code]

bd close beads-c3d4

bd ready
# Now shows: beads-a1b2 (validation complete)

bd update beads-a1b2 --status=in_progress

# [Implement CSV import feature]
# [Integrate validation]
# [Commit code]

bd close beads-a1b2

bd ready
# Now shows: beads-e5f6 (feature complete)

bd update beads-e5f6 --status=in_progress

# [Write comprehensive tests]
# [All tests pass]
# [Commit code]

bd close beads-e5f6

# ═══════════════════════════════════════════════════════════
# PHASE 4: DOCUMENTATION (Basic Memory)
# ═══════════════════════════════════════════════════════════

mcp__basic-memory__write_note({
  title: "CSV Import Pattern - Guest List",
  content: `# CSV Import Pattern

## Overview
Reusable pattern for importing CSV files with validation and error handling.

## Implementation
- FileImportService for parsing
- Validation pipeline with clear error messages
- Preview before bulk import
- Rollback on partial failures

## Code Reference
- Services/Import/FileImportService.swift
- Domain/Services/GuestImportService.swift

## Related Work
- beads-a1b2: Initial implementation
- beads-c3d4: Validation service

## Best Practices
1. Always validate before import
2. Show preview to user
3. Handle encoding issues (UTF-8, UTF-16)
4. Provide detailed error messages with line numbers

## Common Pitfalls
- Don't assume UTF-8 encoding
- Validate column mappings before processing
- Handle duplicate detection gracefully
`,
  folder: "architecture/data-import",
  tags: ["csv", "import", "validation", "patterns"],
  project: "i-do-blueprint"
})

# Update related architecture docs
mcp__basic-memory__edit_note({
  identifier: "Repository Pattern - File Operations",
  operation: "append",
  content: `

## CSV Import Example
See "CSV Import Pattern - Guest List" for a complete implementation example.
Reference: beads-a1b2 for implementation history.
`,
  project: "i-do-blueprint"
})

# ═══════════════════════════════════════════════════════════
# PHASE 5: SYNC (Beads)
# ═══════════════════════════════════════════════════════════

bd sync
```

### Example 2: Debugging Production Issue

**Scenario**: UUID case mismatch causing query failures

```bash
# ═══════════════════════════════════════════════════════════
# PHASE 1: REPORT BUG (Beads)
# ═══════════════════════════════════════════════════════════

bd create "Guest query returns empty - UUID mismatch" -t bug -p 0
# → Creates beads-bug1

bd update beads-bug1 --status=in_progress

# ═══════════════════════════════════════════════════════════
# PHASE 2: INVESTIGATE (Basic Memory + Code)
# ═══════════════════════════════════════════════════════════

mcp__basic-memory__search_notes({
  query: "UUID Supabase query patterns",
  project: "i-do-blueprint"
})

# Found: "Security Architecture - Multi-Tenancy and RLS"
mcp__basic-memory__read_note({
  identifier: "Security Architecture - Multi-Tenancy and RLS",
  project: "i-do-blueprint"
})

# Discovers the issue:
# Swift UUIDs uppercase → .uuidString → "ABC-123"
# Postgres UUIDs lowercase → expects "abc-123"
# Solution: Pass UUID directly, not .uuidString

# ═══════════════════════════════════════════════════════════
# PHASE 3: FIX (Coding)
# ═══════════════════════════════════════════════════════════

# [Update GuestRepository.swift]
# Before:
# .eq("couple_id", value: tenantId.uuidString)
#
# After:
# .eq("couple_id", value: tenantId)

# [Test the fix]
# [Commit changes]

bd close beads-bug1

# ═══════════════════════════════════════════════════════════
# PHASE 4: DOCUMENT PITFALL (Basic Memory)
# ═══════════════════════════════════════════════════════════

mcp__basic-memory__write_note({
  title: "Common Pitfall - UUID String Conversion in Queries",
  content: `# UUID String Conversion Pitfall

## The Problem
Converting UUIDs to strings before passing to Supabase queries causes case mismatch errors.

**Root Cause:**
- Swift UUID.uuidString produces uppercase: "550E8400-E29B-41D4-A716-446655440000"
- PostgreSQL stores UUIDs lowercase: "550e8400-e29b-41d4-a716-446655440000"
- Case mismatch = no results returned

## The Solution

### ❌ WRONG
\`\`\`swift
.eq("couple_id", value: tenantId.uuidString)
.eq("guest_id", value: guestId.uuidString)
\`\`\`

### ✅ CORRECT
\`\`\`swift
.eq("couple_id", value: tenantId)
.eq("guest_id", value: guestId)
\`\`\`

## When to Use .uuidString
Only convert to string for:
- Cache keys: \`"guests_\\(tenantId.uuidString)"\`
- Logging: \`logger.info("Fetching for \\(id.uuidString)")\`
- Display to users

## Related Bug
Fixed in beads-bug1 (2025-12-29)

## Code Locations Affected
- All Repository implementations
- Any Supabase query filters
`,
  folder: "troubleshooting",
  tags: ["uuid", "supabase", "queries", "pitfall", "debugging"],
  project: "i-do-blueprint"
})

# Update security architecture doc
mcp__basic-memory__edit_note({
  identifier: "Security Architecture - Multi-Tenancy and RLS",
  operation: "append",
  content: `

## Critical: UUID Query Pattern

**ALWAYS pass UUID directly to Supabase queries:**

\`\`\`swift
// ✅ CORRECT
.eq("couple_id", value: tenantId)

// ❌ WRONG - causes case mismatch
.eq("couple_id", value: tenantId.uuidString)
\`\`\`

See "Common Pitfall - UUID String Conversion" for details.
`,
  project: "i-do-blueprint"
})

bd sync
```

### Example 3: Refactoring Project

**Scenario**: Refactor BudgetStoreV2 to use sub-store composition

```bash
# ═══════════════════════════════════════════════════════════
# PHASE 1: ARCHITECTURAL DECISION (Basic Memory)
# ═══════════════════════════════════════════════════════════

mcp__basic-memory__write_note({
  title: "ADR-001 - Budget Store Composition Pattern",
  content: `# ADR-001: Budget Store Composition Over Delegation

## Status
Accepted (2025-12-29)

## Context
BudgetStoreV2 is becoming a "god object" with 2000+ lines, handling:
- Category management
- Expense tracking
- Payment schedules
- Gift registry
- Affordability calculations
- Budget development scenarios

## Decision
Refactor into composition of specialized sub-stores:
- CategoryStoreV2
- ExpenseStoreV2
- PaymentScheduleStore
- GiftsStore
- AffordabilityStore
- BudgetDevelopmentStoreV2

## Consequences

### Positive
- Single responsibility per store
- Easier testing (mock individual stores)
- Better code organization
- Parallel development possible

### Negative
- More files to maintain
- Need to update views to access sub-stores
- Migration effort required

## Implementation Notes
- Views access sub-stores directly (no delegation)
- Example: \`budgetStore.categoryStore.addCategory()\`
- Each sub-store owns its @Published properties

## Related Work
Implementation tracked in beads-epic-001
`,
  folder: "architecture/decisions",
  tags: ["adr", "architecture", "stores", "composition", "refactoring"],
  project: "i-do-blueprint"
})

# ═══════════════════════════════════════════════════════════
# PHASE 2: PLANNING (Beads)
# ═══════════════════════════════════════════════════════════

# Create epic
bd create "Refactor BudgetStoreV2 to composition pattern" -t epic -p 1
# → Creates beads-epic-001

# Create subtasks
bd create "beads-epic-001.1: Extract CategoryStoreV2" -t task -p 1
bd create "beads-epic-001.2: Extract ExpenseStoreV2" -t task -p 1
bd create "beads-epic-001.3: Extract PaymentScheduleStore" -t task -p 1
bd create "beads-epic-001.4: Extract GiftsStore" -t task -p 1
bd create "beads-epic-001.5: Extract AffordabilityStore" -t task -p 1
bd create "beads-epic-001.6: Extract BudgetDevelopmentStoreV2" -t task -p 1
bd create "beads-epic-001.7: Update views to use sub-stores" -t task -p 2
bd create "beads-epic-001.8: Update tests" -t task -p 2
bd create "beads-epic-001.9: Remove old delegation methods" -t task -p 3

# Establish dependencies (each extraction must complete before view updates)
bd dep add beads-epic-001.7 beads-epic-001.1
bd dep add beads-epic-001.7 beads-epic-001.2
bd dep add beads-epic-001.7 beads-epic-001.3
bd dep add beads-epic-001.7 beads-epic-001.4
bd dep add beads-epic-001.7 beads-epic-001.5
bd dep add beads-epic-001.7 beads-epic-001.6

bd dep add beads-epic-001.8 beads-epic-001.7  # Tests after views
bd dep add beads-epic-001.9 beads-epic-001.8  # Cleanup after tests

# ═══════════════════════════════════════════════════════════
# PHASE 3: EXECUTION (Iterative)
# ═══════════════════════════════════════════════════════════

bd ready
# Shows: beads-epic-001.1 through beads-epic-001.6 (parallel work possible)

# Work on first subtask
bd update beads-epic-001.1 --status=in_progress
# [Extract CategoryStoreV2 code]
# [Create tests]
# [Commit]
bd close beads-epic-001.1

# Continue with others...
# (Repeat for each subtask)

# Eventually all extractions done
bd ready
# Shows: beads-epic-001.7 (update views)

bd update beads-epic-001.7 --status=in_progress
# [Update all view files to use sub-stores]
# [Build and test]
# [Commit]
bd close beads-epic-001.7

# Continue through testing and cleanup...

bd close beads-epic-001  # Close the epic

# ═══════════════════════════════════════════════════════════
# PHASE 4: DOCUMENTATION (Basic Memory)
# ═══════════════════════════════════════════════════════════

mcp__basic-memory__write_note({
  title: "Store Composition Pattern - Implementation Guide",
  content: `# Store Composition Pattern

## Overview
Pattern for breaking large stores into specialized sub-stores while maintaining a single composition root.

## When to Use
- Store exceeds 500 lines
- Multiple distinct domains in one store
- Testing becomes difficult due to complexity

## Implementation

### 1. Create Sub-Stores
\`\`\`swift
@MainActor
final class CategoryStoreV2: ObservableObject {
    @Published var categories: [Category] = []
    @Dependency(\\.categoryRepository) private var repository

    func loadCategories() async { ... }
    func addCategory(_ category: Category) async { ... }
}
\`\`\`

### 2. Compose in Parent Store
\`\`\`swift
@MainActor
final class BudgetStoreV2: ObservableObject {
    let categoryStore = CategoryStoreV2()
    let expenseStore = ExpenseStoreV2()
    let payments = PaymentScheduleStore()
    // ... other sub-stores
}
\`\`\`

### 3. Access in Views
\`\`\`swift
struct BudgetView: View {
    @Environment(\\.budgetStore) private var store

    var body: some View {
        Button("Add Category") {
            await store.categoryStore.addCategory(category)
        }
    }
}
\`\`\`

## Best Practices
- ✅ Access sub-stores directly (no delegation)
- ✅ Each sub-store owns its @Published state
- ✅ Sub-stores can share repositories
- ❌ Don't create delegation methods in parent
- ❌ Don't expose sub-store internals through parent

## Case Study
- **Epic**: beads-epic-001
- **Result**: Reduced BudgetStoreV2 from 2000 lines to 200 lines
- **Files**: 6 new sub-stores created
- **Tests**: Improved test isolation, 40% faster test suite

## Related Patterns
- Repository Pattern
- Dependency Injection
- MVVM Architecture
`,
  folder: "architecture/patterns",
  tags: ["stores", "composition", "architecture", "patterns", "refactoring"],
  project: "i-do-blueprint"
})

# Update main store architecture doc
mcp__basic-memory__edit_note({
  identifier: "Store Layer Architecture - V2 Pattern",
  operation: "append",
  content: `

## Store Composition Pattern

For complex domains, use composition of specialized sub-stores.

**Example**: BudgetStoreV2 composes 6 sub-stores:
- budgetStore.categoryStore
- budgetStore.expenseStore
- budgetStore.payments
- budgetStore.gifts
- budgetStore.affordability
- budgetStore.development

See "Store Composition Pattern - Implementation Guide" for details.

**Implementation**: beads-epic-001
`,
  project: "i-do-blueprint"
})

bd sync
```

---

## Summary

### The Golden Rule

```
Basic Memory = WHY & WHAT (Knowledge)
Beads = HOW & WHEN (Execution)
```

### Quick Decision Tree

```
Is this information needed in 6 months?
├─ YES → Basic Memory
│  └─ Examples: Architecture decisions, patterns, pitfalls
│
└─ NO → Beads
   └─ Examples: "Fix bug X", "Add feature Y", "Refactor Z"

Will this help understand future code?
├─ YES → Basic Memory
│  └─ Examples: Why we chose X, How pattern Y works
│
└─ NO → Beads
   └─ Examples: Task status, blocking relationships

Is this actionable work?
├─ YES → Beads
│  └─ Create task, track progress, mark complete
│
└─ NO → Basic Memory
   └─ Document context, record decision
```

### Integration Checklist

- [ ] Basic Memory configured with appropriate folders
- [ ] Beads initialized (`bd init`)
- [ ] `AGENTS.md` updated with both tool usage
- [ ] `.beads/` committed to git
- [ ] MCP configured for Basic Memory access
- [ ] AI agents instructed on when to use each tool
- [ ] Cross-referencing pattern established
- [ ] Session start/end protocols defined

---

**Last Updated**: 2025-12-29
**Maintainer**: Project Team
**Tools**: Basic Memory (docs.basicmemory.com) + Beads (github.com/steveyegge/beads)
