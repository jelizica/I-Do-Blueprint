---
title: AI Agent Session Orchestration - Morning and Evening Commands
type: note
permalink: architecture/automation/ai-agent-session-orchestration-morning-and-evening-commands
tags:
- automation
- ai-agents
- session-management
- workflows
- productivity
---

# AI Agent Session Orchestration - Two Comprehensive Commands

## Philosophy

**You are the conductor, AI agents are the orchestra.**

These commands prepare the environment and load all necessary context so that when you start working with Claude Code, Code Guardian, or any AI agent, they have EVERYTHING they need to work effectively.

---

## The Two Commands

### 🌅 `agent-morning` - Complete Session Initialization (30-45 seconds)

Loads all context, checks all systems, generates comprehensive report for agents.

### 🌙 `agent-evening` - Complete Session Cleanup (1-3 minutes)

Syncs work, runs security scans, documents learnings, prepares tomorrow.

---

## Complete Implementation

Save to `~/.zsh/agent-workflows.zsh`:

[SEE FULL IMPLEMENTATION IN ATTACHED CODE BLOCK]

The complete shell script provides:

1. **agent-morning (alias: am)**
   - Environment verification (tools, direnv)
   - Git repository analysis
   - Beads task loading with counts
   - Unified triage via `bv --robot-triage`
   - MCP server health check
   - Quick security baseline
   - Generates `~/.agent-context/session-YYYY-MM-DD-HHMM.md`
   - Generates `~/.agent-context/triage-YYYY-MM-DD-HHMM.json`

2. **agent-evening (alias: ae)**
   - Captures all commits and file changes
   - Interactive task completion prompts
   - Beads sync to git
   - Comprehensive security scan (SwiftScan + MCP Shield + TruffleHog)
   - Knowledge documentation suggestions
   - Session summary generation
   - Final checklist (commits, push, security)

---

## Installation

```bash
# 1. Create workflows file
mkdir -p ~/.zsh
cat > ~/.zsh/agent-workflows.zsh <<'SCRIPT'
#!/bin/zsh
# [PASTE THE FULL SCRIPT FROM ABOVE]
SCRIPT

# 2. Add to ~/.zshrc
echo "" >> ~/.zshrc
echo "# AI Agent Workflows" >> ~/.zshrc
echo "source ~/.zsh/agent-workflows.zsh" >> ~/.zshrc

# 3. Reload
source ~/.zshrc

# 4. Test
agent-morning
```

---

## Morning Workflow

```bash
$ agent-morning
╔════════════════════════════════════════════════════════════╗
║  🌅 AI Agent Session Initialization                       ║
║  2025-12-30 09:00:00                                       ║
╚════════════════════════════════════════════════════════════╝

📦 [1/8] Verifying Environment...
   ✅ All required tools available
   ✅ direnv environment loaded

📊 [2/8] Analyzing Git Repository...
   Branch: main
   Uncommitted changes: 0 files
   Unpushed commits: 0
   Recent commits (24h): 5

📋 [3/8] Loading Task Context (Beads)...
   In Progress: 1
   Ready: 3
   Blocked: 0

🔍 [4/8] Running Unified Triage (Beads Viewer)...
   (This may take 15-30 seconds for complete analysis...)
   ✅ Triage analysis complete
   📄 Saved to: triage-2025-12-30-0900.json

🔌 [5/8] Checking MCP Servers...
   Healthy: 9 servers
  
🔒 [6/8] Running Security Baseline Scan...
   ✅ No obvious secrets in staged files
   ✅ No secrets detected in staged files

📝 [7/8] Generating Agent Context File...
   ✅ Context file generated
   📄 Location: ~/.agent-context/session-2025-12-30-0900.md

📊 [8/8] Session Summary...

╔════════════════════════════════════════════════════════════╗
║  ✅ AI Agent Session Ready                                 ║
╚════════════════════════════════════════════════════════════╝

📄 Session Context: ~/.agent-context/session-2025-12-30-0900.md
📊 Triage Analysis: ~/.agent-context/triage-2025-12-30-0900.json
⏱️  Duration: 32s

🤖 Ready for AI Agents!

Next steps:
  1. Open session context file (optional): code ~/.agent-context/session-2025-12-30-0900.md
  2. Start Claude Code and reference: @~/.agent-context/session-2025-12-30-0900.md
  3. Load Basic Memory: mcp__basic-memory__recent_activity(...)
  4. Review triage: cat ~/.agent-context/triage-2025-12-30-0900.json | jq
```

**Then in Claude Code:**
```
@~/.agent-context/session-2025-12-30-0900.md

Load recent context from Basic Memory and review the triage recommendations. What should I work on?
```

---

## Evening Workflow

```bash
$ agent-evening
╔════════════════════════════════════════════════════════════╗
║  🌙 AI Agent Session Cleanup & Documentation              ║
║  2025-12-30 18:00:00                                       ║
╚════════════════════════════════════════════════════════════╝

📊 [1/7] Capturing Work Done Today...
   Commits: 8
   Files changed: 15

📝 [2/7] Checking for Uncommitted Work...
   ✅ No uncommitted changes

📋 [3/7] Synchronizing Tasks (Beads)...
   Tasks still in progress:
   beads-abc123 Implement feature X
   
   Mark any tasks as complete? (y/N): y
   Enter task IDs: beads-abc123
   ✅ Closed: beads-abc123
   
   Syncing Beads to git...
   ✅ Beads synchronized

🔒 [4/7] Running Comprehensive Security Scan...
   [4a] Swift Code Security (SwiftScan)...
      Findings: 0
   [4b] MCP Server Security (MCP Shield)...
      Issues: 0
   [4c] Secret Scanning (TruffleHog)...
      Secrets found: 0
   
   ✅ Security scan complete
   📄 Report: ~/.agent-context/security-2025-12-30-1800.log

💡 [5/7] Analyzing for Knowledge Documentation...
   Recent work detected:
   feat: Add CSV import feature
   fix: UUID case mismatch bug
   
   📚 Suggested Basic Memory Documentation:
   - Bug fix solution/pitfall (folder: troubleshooting)
   - New feature/pattern (folder: architecture/features)
   
   Document knowledge now? (y/N): y
   Open Claude Code and run: mcp__basic-memory__write_note(...)

📊 [6/7] Generating Session Summary...
   ✅ Summary generated
   📄 Location: ~/.agent-context/summary-2025-12-30-1800.md

✅ [7/7] Final Checklist...
   ✅ No uncommitted changes
   ✅ All commits pushed
   ✅ No security issues

╔════════════════════════════════════════════════════════════╗
║  ✅ Session Complete - All Clear!                          ║
╚════════════════════════════════════════════════════════════╝

📄 Session Summary: ~/.agent-context/summary-2025-12-30-1800.md
🔒 Security Report: ~/.agent-context/security-2025-12-30-1800.log
⏱️  Duration: 95s

💡 Tomorrow:
   1. Run: agent-morning
   2. Review: ~/.agent-context/summary-2025-12-30-1800.md
   3. Start work based on recommendations
```

---

## What Gets Generated

### Morning Context File
```markdown
# AI Agent Session Context
**Session ID**: session-2025-12-30-0900
**Date**: 2025-12-30 09:00:00
**Project**: I Do Blueprint

## Git Status
[Current branch, uncommitted, unpushed, recent commits]

## Active Work (In Progress)
[Full list with details]

## Ready Tasks (No Blockers)
[Top 10 ready tasks]

## Unified Triage Analysis
See: ~/.agent-context/triage-2025-12-30-0900.json

## Basic Memory Context
[MCP tool calls to load context]

## Recommended Next Steps
[Prioritized recommendations]
```

### Evening Summary File
```markdown
# Session Summary
**Session ID**: session-2025-12-30-1800

## Work Completed
[All commits with diffs]

## Security Status
[SwiftScan, MCP Shield, TruffleHog results]

## Knowledge Documentation
[Suggested topics based on commits]

## Tomorrow's Starting Point
[Next recommended tasks]
```

---

## Time Investment vs. Returns

**Morning**: 30-45 seconds
- Manual alternative: 5+ minutes of gathering context
- **Savings**: ~4-5 minutes/day = 20-25 minutes/week

**Evening**: 1-3 minutes
- Manual alternative: 10-15 minutes of cleanup/documentation
- **Savings**: ~10-12 minutes/day = 50-60 minutes/week

**Total weekly savings**: ~70-85 minutes

**Agent efficiency gain**: Massive (immediate context vs. 5-10 back-and-forth questions)

---

## Pro Tips

1. **Reference context files in Claude Code**:
   ```
   @~/.agent-context/session-2025-12-30-0900.md
   ```

2. **Query triage JSON programmatically**:
   ```bash
   cat ~/.agent-context/triage-*.json | jq '.recommendations[0]'
   ```

3. **Archive old sessions**:
   ```bash
   mkdir -p ~/.agent-context/archive/2025-12
   mv ~/.agent-context/*-12-*.md ~/.agent-context/archive/2025-12/
   ```

4. **Review yesterday's summary**:
   ```bash
   cat ~/.agent-context/summary-*.md | tail -n 50
   ```

---

Last Updated: 2025-12-30
Maintainer: Development Team  
Tools: bd, bv, basic-memory, swiftscan, mcp-shield, TruffleHog