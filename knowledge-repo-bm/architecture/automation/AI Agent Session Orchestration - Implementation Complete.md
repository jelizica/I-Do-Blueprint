---
title: AI Agent Session Orchestration - Implementation Complete
type: note
permalink: architecture/automation/ai-agent-session-orchestration-implementation-complete
tags:
- automation
- ai-agents
- workflows
- implementation
- shell
- orchestration
- completed
---

# AI Agent Session Orchestration - Implementation Complete

**Status**: ✅ Fully Implemented and Tested
**Date**: 2025-12-30
**Approach**: Manual Route (file-based context, not Claude Code skills)

## Overview

Implemented comprehensive session orchestration for multi-agent workflows (Claude Code, Qodo Gen, Cursor, etc.). Uses shell functions to generate context files that AI agents can read.

## Files Created

### 1. `~/.zsh/agent-workflows.zsh` (12KB)
Complete shell function library with 5 main commands:
- `agent-morning` - 8-step morning preparation
- `agent-evening` - 7-step evening wrap-up  
- `agent-prompt` - Copy morning prompt to clipboard
- `agent-end-prompt` - Copy evening prompt to clipboard
- `agent-help` - Display usage instructions

### 2. `~/snippets/agent-start.txt`
Template prompt for beginning coding session:
- Loads session context file
- Makes Basic Memory MCP calls
- Loads triage analysis
- Presents summary with top 3 tasks
- Interactive task selection

### 3. `~/snippets/agent-end.txt`
Template prompt for ending coding session:
- Loads session summary
- Reviews security scan results
- Analyzes completed work
- Suggests knowledge documentation
- Guides through final checklist
- Suggests tomorrow's tasks

### 4. Updated `~/.zshrc`
- Sources workflow file
- Defines `agent-welcome()` with visual session instructions
- Auto-displays welcome message on new terminal

## Workflow

### Morning (Session Begin)

```bash
# Terminal
agent-morning      # Runs 8-step prep, generates context files
agent-prompt       # Copies prompt to clipboard

# In AI agent (Claude Code, Qodo Gen, etc.)
[Paste prompt]     # Agent loads context and presents summary
```

**Generated Files**:
- `~/.agent-context/session-YYYY-MM-DD-HHMM.md` - Full session context
- `~/.agent-context/triage-YYYY-MM-DD-HHMM.json` - bv --robot-triage output
- `~/.agent-context/tooling-check.log` - Tool verification results

### Evening (Session End)

```bash
# Terminal
agent-evening      # Runs 7-step wrap-up, security scans
agent-end-prompt   # Copies prompt to clipboard

# In AI agent
[Paste prompt]     # Agent reviews work, suggests documentation
```

**Generated Files**:
- `~/.agent-context/summary-YYYY-MM-DD-HHMM.md` - Session summary
- `~/.agent-context/security-YYYY-MM-DD-HHMM.log` - Security scan results

## Morning Workflow Details

### [1/8] Environment Verification
- Runs `scripts/verify-tooling.sh`
- Checks: GitHub CLI, Xcode, Supabase CLI, Swift
- Logs to: `~/.agent-context/tooling-check.log`

### [2/8] Git Repository Status
- Current branch
- Short status (`git status --short`)
- Last 5 commits

### [3/8] Beads Task Analysis
- `bd stats` - Overall statistics
- `bd ready --brief` - Ready-to-work tasks
- `bd list --status=in_progress --brief` - Active work

### [4/8] Unified Triage
- Runs `bv --robot-triage`
- Outputs to JSON file for agent consumption
- Graph-aware task analysis and recommendations

### [5/8] MCP Server Health
- `claude mcp list` - Check all MCP servers

### [6/8] Quick Security Scan
- Runs `scripts/security-check.sh`
- Pre-commit style checks (.env, Config.plist, hardcoded secrets)

### [7/8] Generate Agent Context File
- Comprehensive markdown file with all above data
- Structured for AI agent consumption
- Includes next steps and MCP calls to make

### [8/8] Session Summary
- Displays file paths
- Shows next step instructions

## Evening Workflow Details

### [1/7] Work Capture & Analysis
- Git log since midnight
- Files changed in last 5 commits

### [2/7] Git Status & Uncommitted Work
- Warns if uncommitted changes exist
- Prompts to commit before ending session

### [3/7] Task Synchronization
- `bd sync` - Sync Beads to git remote

### [4/7] Comprehensive Security Scan
Three-layer security analysis:

**[4a] SwiftScan** (Semgrep wrapper):
```bash
swiftscan .
```
- Swift-specific security patterns
- OWASP vulnerabilities

**[4b] MCP Shield**:
```bash
npx mcp-shield
```
- MCP server vulnerability scanning

**[4c] TruffleHog**:
```bash
trufflehog filesystem . --no-update
```
- Secret detection in git history
- Filesystem scanning for exposed credentials

All results logged to: `~/.agent-context/security-YYYY-MM-DD-HHMM.log`

### [5/7] Knowledge Documentation Prompts
Reminds to document:
- New patterns discovered
- Architectural decisions
- Pitfalls and solutions
- Important code locations

### [6/7] Generate Session Summary
- Markdown summary of work completed
- Security scan status
- Final checklist
- Knowledge documentation suggestions

### [7/7] Final Checklist
Interactive checklist:
- [ ] All work committed and pushed
- [ ] Beads tasks updated
- [ ] Security scan reviewed
- [ ] Knowledge documented
- [ ] Tomorrow's tasks identified

## Agent Prompt Templates

### Start Prompt Structure
1. Load session context file (latest `session-*.md`)
2. Make Basic Memory MCP calls (`recent_activity`, `build_context`)
3. Load triage analysis (latest `triage-*.json`)
4. Present summary (git, tasks, top 3 recommendations)
5. Interactive task selection

### End Prompt Structure
1. Load session summary (latest `summary-*.md`)
2. Review security scan (latest `security-*.log`)
3. Analyze work accomplished
4. Suggest knowledge documentation
5. Guide through final checklist
6. Suggest tomorrow's tasks

## Design Decisions

### Why Manual Route (vs Claude Code Skills)?

**Compatibility**:
- ✅ Works in: Claude Code, Qodo Gen, Cursor, any AI agent
- ❌ Skills only work in: Claude Code CLI

**User Context**:
- User uses multiple agents
- Needs consistent workflow across all tools

**Simplicity**:
- File references are explicit and transparent
- Easy to debug and modify
- No hidden skill mechanics

**Trade-offs**:
- Manual route: Copy-paste prompt, universal compatibility
- Skills route: Type `/session-start`, but Claude Code only

### Why Shell Functions (vs Many Commands)?

**Original Plan**: Many discrete commands
- `session-start`, `security-quick`, `security-full`, `task-create`, etc.

**Revised Plan**: Two comprehensive commands
- `agent-morning`, `agent-evening`

**Rationale**:
- User is conductor, AI agents are orchestra
- Commands PREPARE environment FOR agents
- Commands generate CONTEXT FILES for agent consumption
- Okay if commands take time (comprehensive is better)

### Why Clipboard Prompts?

**Pattern**:
```bash
agent-prompt      # Copies to clipboard
[Paste in agent]  # Universal across all agents
```

**Benefits**:
- Works with Qodo Gen, Claude Code, Cursor, etc.
- User maintains control (sees prompt before pasting)
- Transparent (can edit before pasting)
- No API integration needed

## Testing Results

All components tested and verified:
- ✅ `~/.zsh/agent-workflows.zsh` created (12KB)
- ✅ `~/snippets/agent-start.txt` created
- ✅ `~/snippets/agent-end.txt` created
- ✅ `~/.zshrc` updated with source and welcome message
- ✅ `~/.agent-context/` directory created
- ✅ `~/snippets/` directory created
- ✅ Shell syntax validated (`zsh -n`)
- ✅ Functions load in fresh shell
- ✅ `agent-help` displays correctly
- ✅ Welcome message displays on new terminal

## Environment Variables

```bash
export IDB_PROJECT="$HOME/Development/nextjs-projects/I Do Blueprint"
export AGENT_CONTEXT_DIR="$HOME/.agent-context"
export AGENT_SNIPPETS_DIR="$HOME/snippets"
```

## Generated File Patterns

All files timestamped: `YYYY-MM-DD-HHMM`

**Morning**:
- `session-2025-12-30-0900.md` - Context file
- `triage-2025-12-30-0900.json` - Triage analysis
- `tooling-check.log` - Tool verification (reused)

**Evening**:
- `summary-2025-12-30-1700.md` - Session summary
- `security-2025-12-30-1700.log` - Security scan

## Integration Points

### Basic Memory MCP
Agent prompts include MCP calls:
```
mcp__basic-memory__recent_activity(timeframe: "7d", project: "i-do-blueprint")
mcp__basic-memory__build_context(url: "projects/i-do-blueprint")
mcp__basic-memory__search_notes("topic", project: "i-do-blueprint")
```

### Beads (bd)
Morning: `bd stats`, `bd ready`, `bd list`
Evening: `bd sync`

### Beads Viewer (bv)
Morning: `bv --robot-triage` → JSON file

### Security Tools
- SwiftScan (Semgrep)
- MCP Shield (npx)
- TruffleHog (filesystem scan)

## Welcome Message

Displays on every new terminal:
```
╔════════════════════════════════════════════════════════════╗
║          🤖 I Do Blueprint - AI Agent Orchestration         ║
╚════════════════════════════════════════════════════════════╝

📅 SESSION BEGIN (Morning):
   1. agent-morning      # Prepare environment & generate context
   2. agent-prompt       # Copy prompt to clipboard
   3. [Paste in agent]   # Start coding session

📅 SESSION END (Evening):
   1. agent-evening      # Wrap-up & security scan
   2. agent-end-prompt   # Copy end prompt to clipboard
   3. [Paste in agent]   # Review & document

⚡️ QUICK COMMANDS:
   agent-help            # Show full help
   bd ready              # Show ready tasks
   bd list --status=in_progress  # Show active work
   git status            # Check git status

🔧 TOOLS:
   bd (Beads)            # Task tracking
   bv (Beads Viewer)     # Task triage & analysis
   Basic Memory MCP      # Knowledge management (i-do-blueprint)
```

## Usage Examples

### Typical Morning
```bash
# Open terminal (welcome message appears automatically)
agent-morning          # Wait ~30s for comprehensive prep
agent-prompt           # Copies to clipboard

# Open Claude Code/Qodo Gen
[Cmd+V]                # Paste prompt
# Agent loads context, shows summary, asks what to work on
```

### Typical Evening
```bash
agent-evening          # Wait ~2min for security scans
agent-end-prompt       # Copies to clipboard

# In AI agent
[Cmd+V]                # Paste prompt
# Agent reviews work, suggests documentation, guides checklist
```

### Mid-Day Break
Welcome message serves as reminder:
- Open terminal → See session begin/end instructions
- Reminds of workflow even after break

## Future Enhancements (Optional)

1. **Git hooks**: Auto-run `agent-evening` on pre-push
2. **Scheduled reminders**: macOS notifications for session end
3. **Context cleanup**: Archive old context files after N days
4. **Metrics**: Track session duration, tasks completed
5. **Templates**: Different prompt templates for different work types

## Maintenance

### Updating Workflows
Edit: `~/.zsh/agent-workflows.zsh`
Reload: `source ~/.zshrc` or open new terminal

### Updating Prompt Templates
Edit: `~/snippets/agent-start.txt` or `~/snippets/agent-end.txt`
No reload needed (read at runtime)

### Disabling Welcome Message
Comment out in `~/.zshrc`:
```bash
# agent-welcome
```

## Troubleshooting

**Functions not found**:
- Open new terminal (existing terminals need reload)
- Or run: `source ~/.zshrc`

**agent-morning fails at step X**:
- Check error message
- Common: Missing tool (verify-tooling.sh will warn)
- Context file still generated with partial data

**Security scan too slow**:
- Expected: TruffleHog can take 1-2 minutes on large repos
- Optional: Skip TruffleHog section if needed

**Clipboard not working**:
- Requires: `pbcopy` (macOS built-in)
- Fallback: Manually read snippet files

## Success Criteria

✅ Two comprehensive commands (morning, evening)
✅ Multi-agent compatible (Claude Code, Qodo Gen, Cursor)
✅ TruffleHog integration included
✅ Welcome message displays session instructions
✅ Clipboard-based workflow (universal)
✅ All context files generated successfully
✅ Security scans comprehensive (3-layer)
✅ Basic Memory integration via MCP calls
✅ Beads integration (stats, ready, sync)
✅ Beads Viewer integration (robot-triage)

**Implementation Status**: Production Ready
