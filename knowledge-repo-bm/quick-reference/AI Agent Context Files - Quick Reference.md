---
title: AI Agent Context Files - Quick Reference
type: note
permalink: quick-reference/ai-agent-context-files-quick-reference
tags:
- quick-reference
- ai-agents
- context-files
- claude-code
- qodo-gen
- maintenance
---

# AI Agent Context Files - Quick Reference

## Overview

This project uses two primary AI agents with dedicated context files:

| Agent | Context File | Purpose |
|-------|--------------|---------|
| **Qodo Gen** | `best_practices.md` | Primary AI agent for development |
| **Claude Code** | `CLAUDE.md` | Backup AI agent |

Both files implement the **Cold Start Protocol** with the Van Halen M&M comprehension gate.

## File Locations

```
/
├── best_practices.md      # Qodo Gen context (1500+ lines)
├── CLAUDE.md              # Claude Code context (800+ lines)
├── AGENTS.md              # Repository guidelines (shared)
└── .claude/
    └── skills/            # Modular skill files for Claude Code
        ├── base.md
        ├── security.md
        ├── project-tooling.md
        ├── session-management.md
        ├── swift-macos.md
        ├── supabase.md
        └── beads-viewer.md
```

## Key Sections in Both Files

### Cold Start Protocol
- Step-by-step checklist for new sessions
- Dotfiles to read
- Source files to examine
- Session state to check
- Comprehension proof requirements
- M&M confirmation gate

### Stack Stability
- Project is mature/approaching production
- No new dependencies without approval
- Locked stack definition
- "When in doubt, ASK"

### Architecture Overview
- Layered architecture diagram
- Data flow explanation
- Key patterns (Repository, Domain Services, Cache Strategies)

### Critical Patterns
- UUID handling (never convert to string for queries)
- Error handling with `handleError` extension
- Loading state pattern
- Store access patterns (never create instances in views)

### Do's and Don'ts
- Comprehensive lists of best practices
- Common pitfalls to avoid

## Updating These Files

### When to Update

1. **New architectural patterns** - Add to Common Patterns section
2. **New dependencies** - Update Stack Stability and Tools sections
3. **New stores/repositories** - Update directory structure and counts
4. **New cache strategies** - Add to Caching section
5. **New pitfalls discovered** - Add to Common Pitfalls
6. **New MCP tools** - Update MCP Tools Reference section

### Update Checklist

- [ ] Update both `best_practices.md` AND `CLAUDE.md` for shared changes
- [ ] Keep Cold Start Protocol comprehension requirements in sync
- [ ] Update "Last Updated" date at bottom of files
- [ ] Test that comprehension proof requirements are still accurate
- [ ] Verify dotfile list is current

## Reference Resources

### Official Documentation
- **Anthropic Claude Code Best Practices**: https://www.anthropic.com/engineering/claude-code-best-practices

### Community Resources
- **Van Halen Cold Start Protocol**: https://www.reddit.com/r/ClaudeAI/comments/1q0qje8/van_halen_show_rider_inspired_claudemd_cold_start/

### Related Basic Memory Notes
- [[Cold Start Protocol - Van Halen M&M Pattern]] - Full protocol explanation
- [[Anthropic Claude Code Best Practices]] - Official Anthropic guidance
- [[MCP Tools Overview]] - Available MCP servers

## Comprehension Proof Template

When an agent completes the Cold Start Protocol, they should report:

```
## Comprehension Report

### Dotfiles Found
- `.envrc` - [summary]
- `.swiftlint.yml` - [summary]
- `.chunkhound.json` - [summary]
- `.mcp.json.example` - [summary]
- `.trufflehogignore` - [summary]

### Architecture Counts
- **V2 Stores**: [count] in Services/Stores/
- **Live Repositories**: [count] in Domain/Repositories/Live/
- **Cache Strategies**: [list] in Domain/Repositories/Caching/

### Session State
- **Current work**: [from _project_specs/session/current-state.md]
- **Open issues**: [from bd list --status=in_progress]
- **Blockers**: [any blocking issues]

### Confirmation
"I have removed all the red M&Ms."
```

## Tags

- quick-reference
- ai-agents
- context-files
- claude-code
- qodo-gen