---
title: Cold Start Protocol - Van Halen M&M Pattern
type: note
permalink: ai-tools/cold-start-protocol-van-halen-m-m-pattern
tags:
- cold-start-protocol
- van-halen
- claude-code
- qodo-gen
- context-engineering
- ai-agents
- best-practices
---

# Cold Start Protocol - Van Halen M&M Pattern

## Overview

The Cold Start Protocol is a context-loading pattern for AI agents inspired by Van Halen's famous concert rider that required "no brown M&Ms" in the backstage area. This wasn't about diva behavior—it was a **comprehension test**. If the venue missed the M&M clause buried in the technical requirements, they likely missed other critical safety requirements too.

Applied to AI agents: the "I have removed all the red M&Ms" confirmation phrase serves as proof that the agent actually read and processed the entire context file, not just skimmed it.

## Source

**Reddit Post**: https://www.reddit.com/r/ClaudeAI/comments/1q0qje8/van_halen_show_rider_inspired_claudemd_cold_start/

**Key insight from comments**: The M&M confirmation is a **gate, not a greeting**. The agent should not say it until they can prove they did the work.

## The Three Protocols

### Protocol 1: Cold Start Protocol

Every new AI session starts fresh without project context. Before responding to ANY user request, complete this checklist IN ORDER:

1. **Read the main context file completely** (CLAUDE.md, best_practices.md, etc.)
2. **Find and read all dotfiles** - These are memory from previous sessions
   ```bash
   ls -a | grep '^\.'
   ```
   Read every `.`-prefixed file EXCEPT `.git/`, `.gitignore`, `.env`
3. **Read the source code** - Actually open and READ key files, not just list them
4. **Read .env correctly** - Read file contents directly, do NOT use `source .env` or `dotenv`
5. **Prove comprehension** - Report what you found:
   - Dotfiles found and what each contains
   - Component/store/repository counts
   - Data files and record counts
   - Any in-progress work or open questions
6. **Confirm completion** - Only AFTER completing steps 1-5:
   > "I have removed all the red M&Ms."

### Protocol 2: Stack Stability

For mature projects approaching production:

- Do NOT introduce new dependencies or tooling without explicit approval
- Do NOT run package commands for packages not already in the stack
- Do NOT diverge from established patterns documented in context files
- The stack is **locked** - follow documented methods exactly
- When in doubt, **ASK**

### Protocol 3: Subagent Directive

For AI tools that spawn subagents (like Claude Code's Task tool):

```
**SUBAGENT DIRECTIVE**: If you are a subagent spawned via the Task tool, STOP.
Do NOT read further. Do NOT run the Cold Start Protocol.
Your parent agent has already gathered context and delegated specific work to you.
Execute the task you were given efficiently.
This file is for parent agents only.
```

## Implementation in I Do Blueprint

### Files Updated

1. **`best_practices.md`** (for Qodo Gen)
   - Added Cold Start Protocol at the beginning
   - Added Stack Stability section
   - Comprehension proof includes: dotfiles, store count, repository count, cache strategies, in-progress work

2. **`CLAUDE.md`** (for Claude Code)
   - Added Subagent Directive at the very top
   - Added Cold Start Protocol (includes reading Skills files)
   - Added Stack Stability section

### Comprehension Proof Requirements

For this project, agents must report:
1. Dotfiles found and what each contains
2. Store count (V2 stores in `Services/Stores/`)
3. Repository count (Live repositories in `Domain/Repositories/Live/`)
4. Cache strategies (domain-specific strategies in `Domain/Repositories/Caching/`)
5. In-progress work from `_project_specs/session/current-state.md` or `bd list --status=in_progress`
6. Open questions or blockers from session files

### Key Dotfiles to Read

- `.envrc` — direnv environment configuration
- `.swiftlint.yml` — SwiftLint rules (custom rules for design tokens)
- `.chunkhound.json` — Code analysis configuration
- `.mcp.json.example` — MCP server configuration template
- `.trufflehogignore` — Security scanning exclusions

### Key Source Files to Read

**Entry Points:**
- `I Do Blueprint/App/My_Wedding_Planning_AppApp.swift`
- `I Do Blueprint/App/RootFlowView.swift`

**Configuration:**
- `I Do Blueprint/Core/Configuration/AppConfig.swift`

**Architecture Patterns:**
- `I Do Blueprint/Domain/Repositories/RepositoryCache.swift` — Actor-based caching
- `I Do Blueprint/Domain/Repositories/Caching/GuestCacheStrategy.swift` — Cache invalidation
- `I Do Blueprint/Services/Stores/Budget/BudgetStoreV2.swift` — V2 store pattern
- `I Do Blueprint/Core/Common/Common/DependencyValues.swift` — Dependency injection

## Related Resources

### Anthropic's Claude Code Best Practices
**URL**: https://www.anthropic.com/engineering/claude-code-best-practices

Key recommendations:
- Create `CLAUDE.md` files for project context
- Tune your CLAUDE.md files like prompts
- Use `/init` command to auto-generate CLAUDE.md
- Place CLAUDE.md in repo root, parent directories, or child directories
- Use `#` key to add instructions that Claude incorporates into CLAUDE.md

### Van Halen Brown M&M Story
The original inspiration: Van Halen's 1982 tour rider included a clause requiring a bowl of M&Ms with all brown ones removed. This was buried in the technical requirements section. If brown M&Ms were present, it indicated the venue hadn't read the full rider carefully, suggesting they might have missed critical safety requirements for the elaborate stage setup.

## Why This Works

1. **Forces actual reading** - Agents can't fake the comprehension proof
2. **Catches skimmers** - The M&M phrase is meaningless without context
3. **Establishes baseline** - Agent starts with full project understanding
4. **Prevents hallucination** - Agent knows what exists vs. what doesn't
5. **Enables continuity** - Session state files provide handoff context

## Tags

- ai-agents
- context-engineering
- claude-code
- qodo-gen
- session-management
- best-practices