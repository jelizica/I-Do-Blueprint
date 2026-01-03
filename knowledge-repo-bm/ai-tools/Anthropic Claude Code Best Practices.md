---
title: Anthropic Claude Code Best Practices
type: note
permalink: ai-tools/anthropic-claude-code-best-practices
tags:
- claude-code
- anthropic
- best-practices
- ai-agents
- agentic-coding
- official-docs
---

# Anthropic Claude Code Best Practices

## Source

**Official Anthropic Engineering Blog**: https://www.anthropic.com/engineering/claude-code-best-practices

Published: April 18, 2025

## Overview

Claude Code is a command line tool for agentic coding. This document summarizes the official best practices from Anthropic for using Claude Code effectively.

## 1. Customize Your Setup

### CLAUDE.md Files

`CLAUDE.md` is a special file that Claude automatically pulls into context when starting a conversation. Ideal for documenting:

- Common bash commands
- Core files and utility functions
- Code style guidelines
- Testing instructions
- Repository etiquette (branch naming, merge vs. rebase)
- Developer environment setup
- Unexpected behaviors or warnings
- Other information you want Claude to remember

**Placement options:**
- Repo root (most common) - check into git to share with team
- Parent directories (for monorepos)
- Child directories (pulled in on demand)
- Home folder (`~/.claude/CLAUDE.md`) - applies to all sessions

**Pro tip**: Use `/init` command to auto-generate a CLAUDE.md

### Tuning CLAUDE.md

- Refine like any frequently used prompt
- Use `#` key to add instructions Claude incorporates automatically
- Run through prompt improver occasionally
- Add emphasis with "IMPORTANT" or "YOU MUST" for critical instructions

### Tool Allowlist

Customize allowed tools via:
- "Always allow" when prompted
- `/permissions` command
- Edit `.claude/settings.json` or `~/.claude.json`
- `--allowedTools` CLI flag

## 2. Give Claude More Tools

### Bash Tools
Claude inherits your bash environment. Tell Claude about custom tools:
1. Provide tool name with usage examples
2. Tell Claude to run `--help`
3. Document in CLAUDE.md

### MCP (Model Context Protocol)
Claude Code can connect to MCP servers:
- Project config (directory-specific)
- Global config (all projects)
- Checked-in `.mcp.json` file (team-wide)

Use `--mcp-debug` flag for troubleshooting.

### Custom Slash Commands
Store prompt templates in `.claude/commands/` folder:
- Available via slash menu when typing `/`
- Use `$ARGUMENTS` for parameters
- Check into git for team sharing

## 3. Common Workflows

### Explore, Plan, Code, Commit
1. Ask Claude to read relevant files (tell it NOT to code yet)
2. Ask Claude to make a plan - use "think" for extended thinking
   - "think" < "think hard" < "think harder" < "ultrathink"
3. Ask Claude to implement the solution
4. Ask Claude to commit and create PR

### Test-Driven Development
1. Ask Claude to write tests based on expected I/O
2. Tell Claude to run tests and confirm they fail
3. Ask Claude to commit the tests
4. Ask Claude to write code that passes tests
5. Ask Claude to commit the code

### Visual Development
1. Give Claude screenshot capability (Puppeteer MCP, iOS simulator MCP)
2. Give Claude a visual mock
3. Ask Claude to implement, screenshot, and iterate
4. Ask Claude to commit when satisfied

### Safe YOLO Mode
Use `claude --dangerously-skip-permissions` in containers without internet access.

### Codebase Q&A
Use Claude for onboarding and learning:
- "How does logging work?"
- "How do I make a new API endpoint?"
- "What does this code do?"

### Git Operations
Claude handles 90%+ of git interactions:
- Searching git history
- Writing commit messages
- Complex operations (revert, rebase, patches)

### GitHub Integration
- Creating pull requests
- Fixing code review comments
- Fixing failing builds
- Triaging issues

## 4. Optimize Your Workflow

### Be Specific
Poor: "add tests for foo.py"
Good: "write a new test case for foo.py, covering the edge case where the user is logged out. avoid mocks"

### Give Claude Images
- Paste screenshots (cmd+ctrl+shift+4 on macOS)
- Drag and drop images
- Provide file paths

### Mention Files
Use tab-completion to reference files/folders

### Give Claude URLs
Paste URLs for Claude to fetch and read

### Course Correct Early
- Ask Claude to make a plan before coding
- Press Escape to interrupt
- Double-tap Escape to go back in history
- Ask Claude to undo changes

### Use `/clear` Frequently
Reset context between tasks to avoid irrelevant content

### Use Checklists for Complex Tasks
Have Claude use a Markdown file as a checklist and scratchpad

### Pass Data to Claude
- Copy and paste
- Pipe into Claude (`cat foo.txt | claude`)
- Tell Claude to pull data via tools
- Ask Claude to read files or fetch URLs

## 5. Headless Mode

Use `-p` flag for non-interactive contexts (CI, pre-commit hooks, automation):
- `--output-format stream-json` for streaming JSON
- Does not persist between sessions

Use cases:
- Issue triage
- Subjective code reviews (linting)

## 6. Multi-Claude Workflows

### One Writes, Another Verifies
1. Have one Claude write code
2. Use `/clear` or start second Claude
3. Have second Claude review
4. Start third Claude to edit based on feedback

### Multiple Checkouts
1. Create 3-4 git checkouts in separate folders
2. Open each in separate terminal tabs
3. Start Claude in each with different tasks
4. Cycle through to check progress

### Git Worktrees
Lighter-weight alternative to multiple checkouts:
```bash
git worktree add ../project-feature-a feature-a
cd ../project-feature-a && claude
```

### Headless Mode with Custom Harness
**Fanning out**: Handle large migrations by looping through tasks
**Pipelining**: Integrate Claude into data/processing pipelines

## Key Takeaways for I Do Blueprint

1. **CLAUDE.md is essential** - We have comprehensive CLAUDE.md and best_practices.md
2. **Skills files** - We use `.claude/skills/` for modular guidance
3. **MCP integration** - We use multiple MCP servers (Supabase, Swiftzilla, etc.)
4. **Beads integration** - We use Beads for issue tracking (documented in CLAUDE.md)
5. **Session management** - We have `_project_specs/session/` for context tracking
6. **Cold Start Protocol** - We added Van Halen-inspired comprehension gate

## Related Notes

- [[Cold Start Protocol - Van Halen M&M Pattern]]
- [[MCP Tools Overview]]

## Tags

- claude-code
- anthropic
- best-practices
- ai-agents
- agentic-coding