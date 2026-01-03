---
title: README - Basic Memory Knowledge Repository
type: note
permalink: knowledge-repo-bm/readme-basic-memory-knowledge-repository
tags:
- documentation
- workflow
- basic-memory
- beads
---

# Basic Memory Knowledge Repository

This directory contains the persistent knowledge base for the I Do Blueprint project using Basic Memory.

## Folder Structure

```
knowledge-repo-bm/ (Basic Memory project: i-do-blueprint)
├── projects/
│   └── i-do-blueprint/          # Project-wide overview and context
│       └── I Do Blueprint - Project Overview.md
├── architecture/
│   ├── caching/                 # Cache infrastructure and patterns
│   │   └── Caching Infrastructure - Strategy Pattern and Actor-Based Cache.md
│   ├── models/                  # Domain model structures
│   │   └── Domain Models - Data Structures by Feature.md
│   ├── repositories/            # Repository layer patterns
│   │   └── Repository Layer Architecture - Protocol-Based Data Access.md
│   ├── services/                # Domain service patterns
│   │   └── Domain Services Layer - Business Logic Separation.md
│   └── stores/                  # Store layer patterns
│       └── Store Layer Architecture - V2 Pattern.md
├── database/
│   └── Supabase Database Schema Overview.md
├── security/
│   └── Security Architecture - Multi-Tenancy and RLS.md
├── testing/
│   └── Testing Infrastructure and Patterns.md
├── project-management/
│   └── Beads Issues - Active Work and Technical Debt.md
└── quick-reference/
    └── I Do Blueprint - Quick Reference Guide.md
```

## What Goes in Basic Memory vs Beads

### Basic Memory stores the WHY and WHAT

**Purpose**: Persistent architectural knowledge, decisions, and context that survives across sessions.

**Access via MCP tools**:
```
# Read architecture decisions
mcp__basic-memory__read_note(
  identifier: "Store Layer Architecture - V2 Pattern",
  project: "i-do-blueprint"
)

# Search for topics
mcp__basic-memory__search_notes(
  query: "cache invalidation",
  project: "i-do-blueprint"
)

# Create new architectural documentation
mcp__basic-memory__write_note(
  title: "New Pattern Documentation",
  content: "...",
  folder: "architecture/patterns",
  project: "i-do-blueprint"
)
```

### Beads tracks the HOW and WHEN

**Purpose**: Active work items, dependencies, and task tracking with git-based persistence.

**Access via CLI**:
```bash
# Feature work
bd create "Implement RSVP embeddable widget" -t feature -p 1

# Technical tasks
bd create "Migrate to Supabase Edge Functions" -t task -p 2

# Bug fixes
bd create "Fix UUID case mismatch in guest queries" -t bug -p 0

# Dependencies
bd dep add beads-123 beads-122  # Task depends on another

# Track progress
bd update beads-123 --status=in_progress
bd close beads-123
bd sync
```

## Basic Memory MCP Tool Usage

### Reading Notes

```
# By identifier (title or permalink)
mcp__basic-memory__read_note(
  identifier: "I Do Blueprint - Project Overview",
  project: "i-do-blueprint"
)

# Search and read
mcp__basic-memory__search_notes(
  query: "repository pattern",
  project: "i-do-blueprint"
)

# View formatted (for better readability)
mcp__basic-memory__view_note(
  identifier: "I Do Blueprint - Quick Reference Guide",
  project: "i-do-blueprint"
)
```

### Writing Notes

```
# Create new note
mcp__basic-memory__write_note(
  title: "Cache Invalidation Strategy Pattern",
  content: "## Overview\n\n...",
  folder: "architecture/caching",
  tags: ["architecture", "caching", "patterns"],
  project: "i-do-blueprint"
)

# Update existing note
mcp__basic-memory__edit_note(
  identifier: "Repository Layer Architecture - Protocol-Based Data Access",
  operation: "append",
  content: "\n## New Section\n...",
  project: "i-do-blueprint"
)

# Replace section
mcp__basic-memory__edit_note(
  identifier: "Store Layer Architecture - V2 Pattern",
  operation: "replace_section",
  section: "Best Practices",
  content: "Updated best practices...",
  project: "i-do-blueprint"
)
```

### Searching

```
# Text search
mcp__basic-memory__search_notes(
  query: "UUID handling",
  project: "i-do-blueprint"
)

# Search with filters
mcp__basic-memory__search_notes(
  query: "testing",
  types: ["note"],
  page_size: 20,
  project: "i-do-blueprint"
)

# Advanced search syntax
mcp__basic-memory__search_notes(
  query: "tag:architecture cache",
  project: "i-do-blueprint"
)
```

### Building Context

```
# Get related context from a memory path
mcp__basic-memory__build_context(
  url: "architecture/repositories",
  depth: 2,
  max_related: 10,
  project: "i-do-blueprint"
)

# Pattern matching
mcp__basic-memory__build_context(
  url: "architecture/*",
  timeframe: "30d",
  project: "i-do-blueprint"
)
```

### Directory Operations

```
# List directory contents
mcp__basic-memory__list_directory(
  dir_name: "architecture",
  depth: 2,
  project: "i-do-blueprint"
)

# List with filtering
mcp__basic-memory__list_directory(
  dir_name: "/",
  file_name_glob: "*.md",
  depth: 3,
  project: "i-do-blueprint"
)
```

## When to use Basic Memory

1. **Documenting architectural decisions**
   - Why we chose the Repository pattern
   - Why we use actor-based caching
   - Why we have Domain Services layer

2. **Recording technical solutions**
   - How to handle timezone-aware dates
   - How to implement cache invalidation
   - How to structure multi-tenant queries

3. **Building institutional knowledge**
   - Common pitfalls and solutions
   - Best practices for the codebase
   - Design patterns we follow

4. **Project context for AI assistants**
   - Codebase structure
   - Key architectural patterns
   - Technology stack overview

## When to use Beads

1. **Tracking active work**
   - Features in development
   - Bugs to fix
   - Technical debt items

2. **Managing dependencies**
   - What blocks what
   - What must be done first
   - Ready-to-work items

3. **Session-to-session continuity**
   - What was being worked on
   - What's next in the queue
   - What's blocked

4. **Team coordination**
   - Who's working on what
   - What's completed
   - What needs review

## Workflow Example

```bash
# 1. Check what work is ready (Beads)
bd ready

# 2. Review architectural context (Basic Memory MCP)
mcp__basic-memory__read_note(
  identifier: "Store Layer Architecture - V2 Pattern",
  project: "i-do-blueprint"
)

mcp__basic-memory__search_notes(
  query: "repository pattern data access",
  project: "i-do-blueprint"
)

# 3. Start work (Beads)
bd update beads-456 --status=in_progress

# 4. Implement following architectural patterns (Basic Memory guides)
mcp__basic-memory__read_note(
  identifier: "Repository Layer Architecture - Protocol-Based Data Access",
  project: "i-do-blueprint"
)

mcp__basic-memory__read_note(
  identifier: "Security Architecture - Multi-Tenancy and RLS",
  project: "i-do-blueprint"
)

# 5. Document new architectural decision (Basic Memory)
mcp__basic-memory__write_note(
  title: "New Pattern - Async Stream Repository",
  content: "## Decision\n\n...",
  folder: "architecture/repositories",
  tags: ["architecture", "async", "repositories"],
  project: "i-do-blueprint"
)

# 6. Complete work (Beads)
bd close beads-456

# 7. Sync work (Beads)
bd sync
```

## Integration with Claude Code

Basic Memory MCP tools are automatically available in Claude Code sessions. Use them to:

- **Read context**: Before implementing, read relevant architecture notes
- **Search patterns**: Find similar solutions in the knowledge base
- **Document decisions**: Capture new patterns and decisions
- **Build context**: Get related notes for comprehensive understanding

## Project Configuration

This knowledge base uses the **i-do-blueprint** project in Basic Memory. Always specify:

```
project: "i-do-blueprint"
```

in all MCP tool calls to ensure notes are read from and written to the correct knowledge base.

---

**Key Principle**: Basic Memory = long-term knowledge (via MCP tools), Beads = short-term execution (via CLI).
