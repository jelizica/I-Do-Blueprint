---
title: Daily Workflow Patterns
type: note
permalink: ai-tools/integration-patterns/daily-workflow
---

# Daily Workflow Patterns

This document outlines the recommended daily workflow for using the AI tools in the "I Do Blueprint" project. Following these patterns will help ensure a smooth and efficient development process.

## Morning Routine

1.  **Check for ready tasks**: Use `bd ready` to see what tasks are unblocked and ready to be worked on.
2.  **Review in-progress tasks**: Use `bd list --status=in_progress` to see what you were working on previously.
3.  **Check for blockers**: Use `bd blocked` to see if any of your tasks are blocked by others.

## During Work

*   Use the appropriate MCP servers for your current task (e.g., Swiftzilla for Swift documentation, Supabase for database operations).
*   Run `swiftscan .` before committing to check for security vulnerabilities.

## Evening Routine

1.  **Complete work items**: Use `bd close <id>` to mark your completed tasks.
2.  **Sync your work**: Use `bd sync` to commit and push your changes.
3.  **Check for alerts**: Use `bv --robot-alerts` to see if there are any issues that need your attention.