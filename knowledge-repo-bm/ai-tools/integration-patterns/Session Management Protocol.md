---
title: Session Management Protocol
type: note
permalink: ai-tools/integration-patterns/session-protocol
---

# Session Management Protocol

This document outlines the protocol for managing work sessions, ensuring that context is maintained and work is not lost.

## Session Start

1.  **Restore Context**: Use Basic Memory to restore the context from your previous session.
    *   `mcp__basic-memory__recent_activity(timeframe: "7d", project: "i-do-blueprint")`
    *   `mcp__basic-memory__build_context(url: "projects/i-do-blueprint")`
2.  **Check Active Work**: Use Beads to see what tasks are ready, in progress, or blocked.
    *   `bd ready`
    *   `bd list --status=in_progress`
    *   `bd blocked`
3.  **Select Next Task**: Choose a task to work on and update its status.
    *   `bd show <id>`
    *   `bd update <id> --status=in_progress`
4.  **Load Relevant Knowledge**: Use Basic Memory to load any relevant documentation for the task.
    *   `mcp__basic-memory__search_notes(query: "relevant topic", project: "i-do-blueprint")`

## Session End

1.  **Complete Work Items**: Mark your completed tasks in Beads.
    *   `bd close <id>`
2.  **Document New Knowledge**: If you have learned anything new, document it in Basic Memory.
    *   `mcp__basic-memory__write_note(...)`
3.  **Sync to Git**: Commit and push your changes.
    *   `bd sync`
    *   `git push`