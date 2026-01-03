---
title: Beads - Git-Backed Task Tracking
type: note
permalink: ai-tools/workflow/beads-git-backed-task-tracking
tags:
- beads
- task-tracking
- git
- cli
- workflow
- ai-agents
- issue-tracker
---

# Beads - Git-Backed Task Tracking

**Repository**: https://github.com/steveyegge/beads  
**Type**: CLI Tool / Issue Tracker  
**Purpose**: Distributed, git-backed graph issue tracker designed specifically for AI agents  
**Storage**: `.beads/` directory with JSONL files  
**Command**: `bd`

---

## Overview

Beads is a revolutionary approach to issue tracking that treats **issues as code, not metadata**. Instead of storing tasks in external databases or cloud services, Beads stores them as version-controlled JSONL files in your repository's `.beads/` directory. This makes issues first-class citizens in your codebase, enabling offline work, git-based collaboration, and seamless integration with AI coding agents.

### Core Philosophy

> "Issues are code, not metadata"

Beads challenges the traditional separation between code and project management by:
- **Version controlling tasks** alongside code changes
- **Enabling offline-first workflows** with no network dependency
- **Treating task graphs as code** that can be branched, merged, and reviewed
- **Eliminating external dependencies** - no servers, no databases, no accounts

---

## Installation

### Quick Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash
```

### Manual Installation

```bash
git clone https://github.com/steveyegge/beads.git
cd beads
cargo build --release
cp target/release/bd ~/.local/bin/  # or /usr/local/bin
```

### Verify Installation

```bash
bd --version
```

---

## Core Concepts

### 1. Hash-Based IDs

Every issue gets a unique hash-based ID (e.g., `bd-a1b2c3d4`) that:
- **Prevents merge conflicts** - IDs are deterministic based on content
- **Enables distributed creation** - Multiple agents can create issues simultaneously
- **Maintains referential integrity** - Dependencies use stable IDs

### 2. Dependency Graph (DAG)

Beads models tasks as a **Directed Acyclic Graph (DAG)**:
- **Nodes** = Individual tasks/issues
- **Edges** = Dependency relationships ("X blocks Y")
- **Cycle detection** = Prevents circular dependencies
- **Graph traversal** = Powers `bd ready` to find unblocked work

### 3. JSONL Storage Format

Issues are stored as **JSON Lines** (`.jsonl`) files:
- One JSON object per line
- Append-only for git-friendly diffs
- Human-readable and greppable
- Easy to parse and manipulate

Example `.beads/issues.jsonl`:
```jsonl
{"id":"bd-a1b2","title":"Implement auth","status":"open","priority":1,"type":"feature","created":"2025-01-15T10:00:00Z"}
{"id":"bd-c3d4","title":"Add login UI","status":"in_progress","priority":1,"type":"task","created":"2025-01-15T11:00:00Z","depends_on":["bd-a1b2"]}
```

### 4. Priority Levels

```
P0 = Critical   (Blocking production, security issues)
P1 = High       (Important features, major bugs)
P2 = Medium     (Standard work, minor bugs)
P3 = Low        (Nice-to-haves, polish)
P4 = Backlog    (Future consideration)
```

**Important**: Use **numbers** (0-4), not words, in commands.

### 5. Issue Types

- `task` - Standard work item
- `bug` - Defect or error
- `feature` - New functionality
- `epic` - Large initiative (can have subtasks)
- `question` - Discussion or clarification needed
- `docs` - Documentation work

### 6. Status Lifecycle

```
open → in_progress → completed
  ↓         ↓
blocked   paused
```

---

## Essential Commands

### Initialization

```bash
# Initialize beads in current repository
bd init

# Creates:
# .beads/
# ├── issues.jsonl
# ├── config.toml
# └── .gitignore
```

### Querying Issues

```bash
# Show tasks with NO blockers (ready to work)
bd ready

# List all open issues
bd list --status=open

# List by priority
bd list --priority=0  # Critical only
bd list --priority=1  # High priority

# List by type
bd list --type=bug
bd list --type=feature

# Show full details of specific issue
bd show bd-a1b2c3d4

# Show with dependency tree
bd show bd-a1b2c3d4 --deps
```

### Creating Issues

```bash
# Create task (default type)
bd create "Implement user authentication" --priority=1

# Create with specific type
bd create "Fix login bug" --type=bug --priority=0
bd create "Add dark mode" --type=feature --priority=2
bd create "Q1 Roadmap" --type=epic --priority=1

# Create with description
bd create "Refactor database layer" \
  --priority=1 \
  --description="Split monolithic DB module into repositories"

# Create with assignee
bd create "Write API docs" --assignee="@alice" --priority=2
```

### Updating Issues

```bash
# Claim a task (mark as in progress)
bd update bd-a1b2 --status=in_progress

# Change priority
bd update bd-a1b2 --priority=0

# Mark as blocked
bd update bd-a1b2 --status=blocked

# Add notes
bd update bd-a1b2 --notes="Waiting for API key from ops team"

# Reassign
bd update bd-a1b2 --assignee="@bob"
```

### Completing Work

```bash
# Close single issue
bd close bd-a1b2 --reason="Completed"

# Close multiple issues at once
bd close bd-a1b2 bd-c3d4 bd-e5f6

# Close with custom reason
bd close bd-a1b2 --reason="Fixed in commit abc123"
```

### Managing Dependencies

```bash
# Add dependency (child depends on parent)
bd dep add bd-child bd-parent

# Example: "Add login UI" depends on "Implement auth"
bd dep add bd-c3d4 bd-a1b2

# Remove dependency
bd dep remove bd-c3d4 bd-a1b2

# Show dependency chain
bd show bd-c3d4 --deps
```

### Synchronization

```bash
# Commit and push beads changes to git
bd sync

# Equivalent to:
# git add .beads/
# git commit -m "Update beads issues"
# git push
```

---

## Workflow Patterns

### 1. Daily Standup Pattern

```bash
# Morning: Find what's ready to work
bd ready

# Claim a task
bd update bd-a1b2 --status=in_progress

# [Do the work...]

# Complete and sync
bd close bd-a1b2
bd sync
```

### 2. Feature Development Pattern

```bash
# Create epic
bd create "User Authentication System" --type=epic --priority=1

# Create subtasks with dependencies
bd create "Design auth schema" --type=task --priority=1
bd create "Implement JWT tokens" --type=task --priority=1
bd create "Add login endpoint" --type=task --priority=1
bd create "Add logout endpoint" --type=task --priority=1

# Link dependencies
bd dep add bd-jwt bd-schema      # JWT depends on schema
bd dep add bd-login bd-jwt       # Login depends on JWT
bd dep add bd-logout bd-jwt      # Logout depends on JWT

# Work through ready tasks
bd ready  # Shows only "Design auth schema" initially
```

### 3. Bug Triage Pattern

```bash
# Create critical bug
bd create "Production login failing" --type=bug --priority=0

# Investigate and add notes
bd update bd-bug1 --notes="Root cause: expired SSL cert"

# Create fix task
bd create "Renew SSL certificate" --type=task --priority=0

# Link bug to fix
bd dep add bd-fix1 bd-bug1

# Complete fix and close bug
bd close bd-fix1
bd close bd-bug1 --reason="Fixed by renewing SSL cert"
```

### 4. Sprint Planning Pattern

```bash
# List all P1 and P2 tasks
bd list --priority=1
bd list --priority=2

# Check what's ready to start
bd ready

# Assign sprint work
bd update bd-a1b2 --assignee="@alice" --status=in_progress
bd update bd-c3d4 --assignee="@bob" --status=in_progress

# Track progress
bd list --status=in_progress
```

---

## Advanced Features

### Filtering and Search

```bash
# Combine filters
bd list --status=open --priority=1 --type=bug

# Search by text (if supported)
bd list --query="authentication"

# Show only assigned to you
bd list --assignee="@me"

# Show unassigned work
bd list --unassigned
```

### Bulk Operations

```bash
# Close multiple related issues
bd close bd-a1b2 bd-a1b3 bd-a1b4 --reason="Sprint complete"

# Update priority for multiple issues
for id in bd-a1b2 bd-c3d4 bd-e5f6; do
  bd update $id --priority=0
done
```

### Git Integration

```bash
# Beads works seamlessly with git branches
git checkout -b feature/auth
bd create "Implement OAuth" --priority=1
bd sync

# Switch branches - beads state follows
git checkout main
bd list  # Shows main branch issues

git checkout feature/auth
bd list  # Shows feature branch issues
```

---

## AI Agent Integration

### Why Beads is Perfect for AI Agents

1. **No Authentication Required** - No API keys, no OAuth, no tokens
2. **Offline-First** - Works without network connectivity
3. **Deterministic** - Same input always produces same output
4. **Git-Native** - Agents already understand git workflows
5. **Structured Data** - JSONL format is easy to parse
6. **Graph-Aware** - Dependency tracking prevents wasted work

### Agent Workflow Example

```bash
# Agent starts session
bd ready  # Get list of unblocked tasks

# Agent claims task
bd update bd-a1b2 --status=in_progress

# Agent completes work
# [Code changes, tests, commits...]

# Agent closes task and syncs
bd close bd-a1b2 --reason="Implemented and tested"
bd sync
```

### Programmatic Access

Beads stores data in simple JSONL files, making it easy to parse:

```python
import json

# Read all issues
with open('.beads/issues.jsonl', 'r') as f:
    issues = [json.loads(line) for line in f]

# Find ready tasks
ready_tasks = [
    issue for issue in issues
    if issue['status'] == 'open' and not issue.get('depends_on')
]
```

---

## Best Practices

### 1. Granular Tasks

✅ **Good**: "Add login form validation"  
❌ **Bad**: "Build entire auth system"

Break large work into completable chunks (< 1 day each).

### 2. Clear Dependencies

```bash
# Explicit dependency chain
bd create "Design API schema" --priority=1
bd create "Implement API endpoints" --priority=1
bd create "Write API tests" --priority=1

bd dep add bd-endpoints bd-schema
bd dep add bd-tests bd-endpoints
```

### 3. Meaningful Priorities

- **P0**: Production is broken, security vulnerability
- **P1**: Blocking other work, important features
- **P2**: Standard development work
- **P3**: Nice-to-haves, polish
- **P4**: Ideas for future consideration

### 4. Regular Syncing

```bash
# Sync at natural breakpoints
bd close bd-a1b2
bd sync  # ← Don't forget this!

# Sync before switching branches
bd sync
git checkout feature/new-work
```

### 5. Descriptive Titles

✅ **Good**: "Fix null pointer in user profile loader"  
❌ **Bad**: "Fix bug"

Include enough context for others (or future you) to understand.

---

## Integration with Beads Viewer

Beads provides the **data layer**, while [Beads Viewer](./beads-viewer-graph-aware-task-visualization.md) provides the **visualization and analysis layer**:

```bash
# Create and manage tasks with Beads
bd create "Implement feature X" --priority=1
bd dep add bd-child bd-parent

# Analyze and visualize with Beads Viewer
bv --robot-triage  # Get AI-powered analysis
bv --robot-next    # Get next task recommendation
```

**Workflow**:
1. Use `bd` for CRUD operations (create, update, close)
2. Use `bv` for analysis and decision-making
3. Use `bd sync` to commit changes to git

---

## Comparison with Traditional Issue Trackers

| Feature | Beads | GitHub Issues | Jira | Linear |
|---------|-------|---------------|------|--------|
| **Offline Work** | ✅ Full | ❌ No | ❌ No | ❌ No |
| **Git Integration** | ✅ Native | ⚠️ Linked | ⚠️ Linked | ⚠️ Linked |
| **Dependency Graph** | ✅ Built-in | ❌ No | ⚠️ Limited | ✅ Yes |
| **AI Agent Friendly** | ✅ Perfect | ⚠️ API | ⚠️ API | ⚠️ API |
| **No Authentication** | ✅ Yes | ❌ No | ❌ No | ❌ No |
| **Merge Conflicts** | ✅ Rare | N/A | N/A | N/A |
| **Cost** | ✅ Free | ✅ Free | 💰 Paid | 💰 Paid |

---

## Troubleshooting

### Issue: "bd: command not found"

```bash
# Check installation
which bd

# If not found, add to PATH
export PATH="$HOME/.local/bin:$PATH"

# Or reinstall
curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash
```

### Issue: Merge Conflicts in .beads/

```bash
# Beads uses hash-based IDs to minimize conflicts
# If conflicts occur, resolve manually:

git status
# Edit .beads/issues.jsonl to resolve conflicts
git add .beads/
git commit -m "Resolve beads merge conflict"
```

### Issue: Circular Dependencies

```bash
# Beads prevents circular dependencies
# If you see an error, check dependency chain:

bd show bd-a1b2 --deps
bd show bd-c3d4 --deps

# Remove problematic dependency
bd dep remove bd-a1b2 bd-c3d4
```

---

## Configuration

### `.beads/config.toml`

```toml
[beads]
# Default priority for new issues
default_priority = 2

# Default assignee
default_assignee = "@me"

# Auto-sync after close
auto_sync = true

[display]
# Show dependency tree by default
show_deps = true

# Colorize output
color = true
```

---

## Related Tools

- **[Beads Viewer](./beads-viewer-graph-aware-task-visualization.md)** - Graph visualization and AI-powered analysis
- **[direnv](./direnv-environment-variable-management.md)** - Per-project environment management
- **[sync-mcp-cfg](./sync-mcp-cfg-multi-client-mcp-configuration.md)** - MCP configuration synchronization

---

## Resources

- **Repository**: https://github.com/steveyegge/beads
- **Installation Script**: https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh
- **Issue Tracker**: https://github.com/steveyegge/beads/issues
- **Beads Viewer**: https://github.com/Dicklesworthstone/beads_viewer

---

## Quick Reference Card

```bash
# Essential Commands
bd init                          # Initialize beads
bd ready                         # Show unblocked tasks
bd create "Title" -p 1           # Create task
bd list --status=open            # List open issues
bd show <id>                     # Show details
bd update <id> --status=in_progress  # Claim task
bd close <id>                    # Complete task
bd dep add <child> <parent>      # Add dependency
bd sync                          # Commit and push

# Priority Levels
P0 = Critical, P1 = High, P2 = Medium, P3 = Low, P4 = Backlog

# Status Values
open, in_progress, blocked, paused, completed

# Types
task, bug, feature, epic, question, docs
```

---

**Last Updated**: 2025-01-15  
**Version**: Based on steveyegge/beads main branch  
**Status**: Production-ready, actively maintained