---
title: Comprehensive Automation Orchestration Plan
type: note
permalink: architecture/automation/comprehensive-automation-orchestration-plan
tags:
- automation
- orchestration
- workflows
- security
- session-management
- productivity
---

# Comprehensive Automation Orchestration Plan for I Do Blueprint

## Executive Summary

This document outlines a comprehensive automation orchestration strategy for the I Do Blueprint project, leveraging existing tools (bd, bv, basic-memory, swiftscan, mcp-shield, TruffleHog) and shell integration to create seamless "start session" and "end session" workflows, plus on-demand security scanning.

---

## Current Tool Inventory

### Task & Knowledge Management
- **bd (Beads)**: Git-backed task tracking with dependency graph
- **bv (Beads Viewer)**: Graph-aware triage and analysis (`bv --robot-triage`)
- **basic-memory**: Knowledge management MCP server (project: `i-do-blueprint`)

### Security Tools
- **swiftscan**: Swift-specific security scanning (Semgrep wrapper)
- **mcp-shield**: MCP server vulnerability scanning
- **TruffleHog**: Secret scanning in git history and filesystems

### Development Tools
- **direnv**: Environment variable management
- **claude**: Claude Code CLI
- **git**: Version control

### Existing Scripts
- `scripts/security-check.sh`: Pre-commit security checks
- `scripts/verify-tooling.sh`: Tool verification

### Existing Aliases (from ~/.zshrc)
- Git shortcuts: `gs`, `ga`, `gaa`, `gc`, `gp`, `gl`
- Directory navigation: `dev`, `projects`, `myapp`
- Profile management: `profile`, `reload`, `aliases`

---

## Proposed Orchestration Architecture

### 1. Session Workflow Commands

Create high-level commands that orchestrate multiple tools:

```bash
# Session Start (Morning Workflow)
alias session-start='_session_start'
_session_start() {
    echo "🌅 Starting Development Session for I Do Blueprint"
    echo ""
    
    # 1. Navigate to project
    cd ~/Development/nextjs-projects/I\ Do\ Blueprint
    
    # 2. Git status check
    echo "📊 Git Status:"
    git status --short
    echo ""
    
    # 3. Restore context from Basic Memory
    echo "🧠 Loading Recent Context (Basic Memory)..."
    # This would be done in Claude Code via MCP
    echo "   → Run: mcp__basic-memory__recent_activity(timeframe='7d', project='i-do-blueprint')"
    echo "   → Run: mcp__basic-memory__build_context(url='projects/i-do-blueprint')"
    echo ""
    
    # 4. Check active work (Beads)
    echo "📋 Active Work Items (Beads):"
    bd list --status=in_progress
    echo ""
    
    echo "🎯 Ready Tasks (Beads):"
    bd ready --limit=5
    echo ""
    
    # 5. Unified Triage (Beads Viewer - THE MEGA-COMMAND)
    echo "🔍 Unified Triage Analysis (Beads Viewer):"
    bv --robot-triage
    echo ""
    
    # 6. Check MCP server health
    echo "🔌 MCP Server Health:"
    claude mcp list
    echo ""
    
    echo "✅ Session initialized! Use 'session-plan' to see execution plan."
}

# Get execution plan
alias session-plan='bv --robot-plan'

# Get next task recommendation
alias session-next='bv --robot-next'

# Session End (Evening Workflow)
alias session-end='_session_end'
_session_end() {
    echo "🌙 Ending Development Session for I Do Blueprint"
    echo ""
    
    # 1. Show what's been done
    echo "✅ Completed Work:"
    git log --oneline --since="8 hours ago" --author="$(git config user.email)"
    echo ""
    
    # 2. Check for uncommitted changes
    echo "📝 Uncommitted Changes:"
    git status --short
    echo ""
    
    # 3. Sync Beads
    echo "🔄 Syncing Beads to Git..."
    bd sync
    echo ""
    
    # 4. Check for alerts
    echo "⚠️  Health Alerts (Beads Viewer):"
    bv --robot-alerts
    echo ""
    
    # 5. Prompt to document knowledge
    echo "💡 Document New Knowledge:"
    echo "   → Run: mcp__basic-memory__write_note() for new patterns/decisions"
    echo ""
    
    # 6. Project stats
    echo "📊 Project Statistics:"
    bd stats
    echo ""
    
    echo "🎉 Session complete! Don't forget to push your work."
}
```

### 2. Security Orchestration Commands

Create unified security scanning workflows:

```bash
# Quick Security Scan (pre-commit)
alias security-quick='_security_quick'
_security_quick() {
    echo "🔒 Quick Security Scan"
    echo ""
    
    # 1. Run existing security-check.sh
    echo "1️⃣ Running git staging checks..."
    ./scripts/security-check.sh
    echo ""
    
    # 2. TruffleHog scan on staged files
    echo "2️⃣ Scanning staged files for secrets (TruffleHog)..."
    git diff --cached --name-only | xargs trufflehog filesystem --no-update --fail
    echo ""
    
    echo "✅ Quick security scan complete!"
}

# Comprehensive Security Audit
alias security-full='_security_full'
_security_full() {
    echo "🛡️  Comprehensive Security Audit"
    echo ""
    
    # 1. Swift code security scan
    echo "1️⃣ Swift Code Security (SwiftScan/Semgrep)..."
    swiftscan . --json > /tmp/swiftscan-results.json
    echo "   Results saved to: /tmp/swiftscan-results.json"
    cat /tmp/swiftscan-results.json | jq '.results | length' | xargs echo "   Findings:"
    echo ""
    
    # 2. MCP server vulnerability scan
    echo "2️⃣ MCP Server Security (MCP Shield)..."
    mcpscan-all
    echo ""
    
    # 3. TruffleHog full repository scan
    echo "3️⃣ Secret Scanning (TruffleHog)..."
    trufflehog git file://. --since-commit HEAD~10 --fail --no-update
    echo ""
    
    # 4. Check for hardcoded secrets in Swift
    echo "4️⃣ Hardcoded Secret Patterns (grep)..."
    grep -r -n -E '(apiKey|secretKey|password|token)\s*=\s*"[A-Za-z0-9]{20,}"' \
        --include="*.swift" \
        "I Do Blueprint/" || echo "   ✓ No obvious hardcoded secrets found"
    echo ""
    
    # 5. Create Beads issues for findings
    echo "5️⃣ Processing Security Findings..."
    echo "   → Review /tmp/swiftscan-results.json"
    echo "   → Create Beads issues: bd create 'Fix: <finding>' -t bug -p 0"
    echo ""
    
    echo "✅ Comprehensive security audit complete!"
}

# Continuous Security (pre-commit hook integration)
alias security-precommit='_security_precommit'
_security_precommit() {
    # Run quick checks before every commit
    ./scripts/security-check.sh && \
    git diff --cached --name-only | xargs trufflehog filesystem --no-update --fail
}

# MCP Security Only
alias security-mcp='mcpscan-all'

# Swift Security Only  
alias security-swift='swiftscan . --json | jq'

# Secrets Scan Only
alias security-secrets='trufflehog git file://. --since-commit HEAD~10 --fail'
```

### 3. Integrated Workflow Commands

Combine multiple tools into single commands:

```bash
# Create task and track with Beads
alias task-create='_task_create'
_task_create() {
    local title="$1"
    local type="${2:-task}"  # task, bug, feature, epic
    local priority="${3:-2}" # 0-4
    
    bd create "$title" -t "$type" -p "$priority"
    
    echo ""
    echo "💡 Tip: Run 'bv --robot-plan' to see updated execution plan"
}

# Close task and document knowledge
alias task-complete='_task_complete'
_task_complete() {
    local task_id="$1"
    local knowledge_title="$2"
    
    # Close the task
    bd close "$task_id"
    
    # Prompt for knowledge documentation
    if [ -n "$knowledge_title" ]; then
        echo ""
        echo "📚 Document this in Basic Memory:"
        echo "   mcp__basic-memory__write_note("
        echo "     title='$knowledge_title',"
        echo "     folder='architecture/patterns',"  
        echo "     project='i-do-blueprint'"
        echo "   )"
    fi
    
    # Sync to git
    bd sync
}

# Comprehensive project health check
alias health-check='_health_check'
_health_check() {
    echo "🏥 I Do Blueprint Health Check"
    echo ""
    
    # 1. Beads statistics
    echo "📊 Task Health (Beads):"
    bd stats
    echo ""
    
    # 2. Git status
    echo "📝 Git Status:"
    git status --short
    echo ""
    
    # 3. MCP servers
    echo "🔌 MCP Servers:"
    claude mcp list
    echo ""
    
    # 4. Build status
    echo "🔨 Build Check:"
    xcodebuild build -project "I Do Blueprint.xcodeproj" \
        -scheme "I Do Blueprint" \
        -destination 'platform=macOS' \
        -quiet && echo "   ✅ Build successful" || echo "   ❌ Build failed"
    echo ""
    
    # 5. Test status (quick smoke test)
    echo "🧪 Test Status:"
    xcodebuild test -project "I Do Blueprint.xcodeproj" \
        -scheme "I Do Blueprint" \
        -destination 'platform=macOS' \
        -only-testing:"I Do BlueprintTests" \
        -quiet 2>&1 | grep -E "(Test Suite|Executed|PASSED|FAILED)" | head -5
    echo ""
}
```

---

## Implementation Plan

### Phase 1: Create Shell Function Library

**File: `~/.zsh/workflows.zsh`**

```bash
# I Do Blueprint Development Workflows
# Source this in ~/.zshrc: source ~/.zsh/workflows.zsh

# Project directory
export IDB_PROJECT="$HOME/Development/nextjs-projects/I Do Blueprint"

# Helper function to ensure we're in project directory
_ensure_project_dir() {
    if [ "$PWD" != "$IDB_PROJECT" ]; then
        cd "$IDB_PROJECT" || {
            echo "❌ Failed to navigate to project directory"
            return 1
        }
    fi
}

# === SESSION MANAGEMENT ===

session-start() {
    _ensure_project_dir || return 1
    
    echo "🌅 Starting Development Session for I Do Blueprint"
    echo ""
    
    # Git status
    echo "📊 Git Status:"
    git status --short
    echo ""
    
    # Active work
    echo "📋 Active Work (In Progress):"
    bd list --status=in_progress
    echo ""
    
    # Ready tasks
    echo "🎯 Ready Tasks:"
    bd ready --limit=5
    echo ""
    
    # Unified triage
    echo "🔍 Unified Triage (Beads Viewer):"
    bv --robot-triage
    echo ""
    
    # MCP health
    echo "🔌 MCP Server Health:"
    claude mcp list | grep -E "✓|✗"
    echo ""
    
    echo "✅ Session initialized!"
    echo ""
    echo "Next steps:"
    echo "  • session-plan    - View execution plan"
    echo "  • session-next    - Get next task recommendation"
    echo "  • health-check    - Full project health check"
    echo "  • security-full   - Comprehensive security audit"
}

session-end() {
    _ensure_project_dir || return 1
    
    echo "🌙 Ending Development Session"
    echo ""
    
    # Recent work
    echo "✅ Recent Commits (last 8 hours):"
    git log --oneline --since="8 hours ago" --author="$(git config user.email)"
    echo ""
    
    # Uncommitted changes
    echo "📝 Uncommitted Changes:"
    git status --short
    echo ""
    
    # Sync beads
    echo "🔄 Syncing Beads..."
    bd sync
    echo ""
    
    # Alerts
    echo "⚠️  Health Alerts:"
    bv --robot-alerts
    echo ""
    
    # Stats
    echo "📊 Project Statistics:"
    bd stats
    echo ""
    
    echo "💡 Don't forget to:"
    echo "  • Document new knowledge in Basic Memory"
    echo "  • Push your work: git push"
    echo "  • Close completed tasks: bd close <id>"
}

session-plan() {
    _ensure_project_dir || return 1
    bv --robot-plan
}

session-next() {
    _ensure_project_dir || return 1
    bv --robot-next
}

# === SECURITY ORCHESTRATION ===

security-quick() {
    _ensure_project_dir || return 1
    
    echo "🔒 Quick Security Scan"
    echo ""
    
    # Git staging checks
    echo "1️⃣ Git Staging Checks..."
    ./scripts/security-check.sh || return 1
    echo ""
    
    # TruffleHog on staged files
    echo "2️⃣ Secret Scanning (TruffleHog)..."
    git diff --cached --name-only | xargs -r trufflehog filesystem --no-update --fail || {
        echo "❌ Secrets detected in staged files!"
        return 1
    }
    echo ""
    
    echo "✅ Quick security scan passed!"
}

security-full() {
    _ensure_project_dir || return 1
    
    echo "🛡️  Comprehensive Security Audit"
    echo ""
    
    # SwiftScan
    echo "1️⃣ Swift Code Security (SwiftScan)..."
    swiftscan . --json > /tmp/swiftscan-results.json
    local findings=$(cat /tmp/swiftscan-results.json | jq '.results | length')
    echo "   Findings: $findings"
    if [ "$findings" -gt 0 ]; then
        echo "   ⚠️  Review: /tmp/swiftscan-results.json"
    fi
    echo ""
    
    # MCP Shield
    echo "2️⃣ MCP Server Security (MCP Shield)..."
    mcpscan-all
    echo ""
    
    # TruffleHog
    echo "3️⃣ Secret Scanning (TruffleHog)..."
    trufflehog git file://. --since-commit HEAD~10 --fail --no-update || {
        echo "   ⚠️  Secrets found in git history!"
    }
    echo ""
    
    # Hardcoded secrets grep
    echo "4️⃣ Hardcoded Secret Patterns..."
    grep -r -n -E '(apiKey|secretKey|password|token)\s*=\s*"[A-Za-z0-9]{20,}"' \
        --include="*.swift" "I Do Blueprint/" 2>/dev/null || {
        echo "   ✓ No obvious hardcoded secrets"
    }
    echo ""
    
    echo "✅ Security audit complete!"
    echo ""
    echo "Next steps:"
    echo "  • Review findings in /tmp/swiftscan-results.json"
    echo "  • Create Beads issues: bd create 'Fix: <finding>' -t bug -p 0"
}

security-mcp() {
    mcpscan-all
}

security-swift() {
    _ensure_project_dir || return 1
    swiftscan . --json | jq
}

security-secrets() {
    _ensure_project_dir || return 1
    trufflehog git file://. --since-commit HEAD~10 --fail --no-update
}

# === TASK MANAGEMENT ===

task-create() {
    _ensure_project_dir || return 1
    
    local title="$1"
    local type="${2:-task}"
    local priority="${3:-2}"
    
    if [ -z "$title" ]; then
        echo "Usage: task-create 'Task title' [type] [priority]"
        echo "  type: task, bug, feature, epic (default: task)"
        echo "  priority: 0-4 (default: 2)"
        return 1
    fi
    
    bd create "$title" -t "$type" -p "$priority"
    
    echo ""
    echo "💡 Tip: Run 'session-plan' to see updated execution plan"
}

task-complete() {
    _ensure_project_dir || return 1
    
    local task_id="$1"
    
    if [ -z "$task_id" ]; then
        echo "Usage: task-complete <task-id> [knowledge-title]"
        return 1
    fi
    
    bd close "$task_id"
    bd sync
    
    echo ""
    echo "✅ Task closed and synced to git"
}

# === HEALTH MONITORING ===

health-check() {
    _ensure_project_dir || return 1
    
    echo "🏥 I Do Blueprint Health Check"
    echo ""
    
    # Beads stats
    echo "📊 Task Health:"
    bd stats
    echo ""
    
    # Git status
    echo "📝 Git Status:"
    git status --short
    echo ""
    
    # MCP servers
    echo "🔌 MCP Servers:"
    claude mcp list | grep -E "✓|✗"
    echo ""
    
    # Build check
    echo "🔨 Build Check:"
    xcodebuild build -project "I Do Blueprint.xcodeproj" \
        -scheme "I Do Blueprint" \
        -destination 'platform=macOS' \
        -quiet &>/dev/null && \
        echo "   ✅ Build successful" || \
        echo "   ❌ Build failed"
    echo ""
}

# === ALIASES FOR CONVENIENCE ===

alias ss='session-start'
alias se='session-end'
alias sp='session-plan'
alias sn='session-next'
alias hc='health-check'
alias sq='security-quick'
alias sf='security-full'
alias tc='task-create'
alias td='task-complete'

echo "✅ I Do Blueprint workflows loaded!"
echo "   Type 'session-start' or 'ss' to begin"
```

### Phase 2: Update ~/.zshrc

```bash
# Add to end of ~/.zshrc

# I Do Blueprint Development Workflows
if [ -f ~/.zsh/workflows.zsh ]; then
    source ~/.zsh/workflows.zsh
fi
```

### Phase 3: Setup Git Hooks

**File: `.git/hooks/pre-commit`**

```bash
#!/bin/bash

# I Do Blueprint Pre-Commit Security Hook

echo "🔒 Running pre-commit security checks..."

# Run quick security scan
cd "$(git rev-parse --show-toplevel)"
security-quick

exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo ""
    echo "❌ Pre-commit checks failed!"
    echo "   Fix security issues before committing"
    echo "   Or use: git commit --no-verify (NOT RECOMMENDED)"
    exit 1
fi

echo "✅ Pre-commit checks passed!"
exit 0
```

**Make it executable:**
```bash
chmod +x .git/hooks/pre-commit
```

---

## Usage Examples

### Morning Startup
```bash
# Simple command
session-start
# or
ss

# Output:
# 🌅 Starting Development Session for I Do Blueprint
# 📊 Git Status: ...
# 📋 Active Work: ...
# 🎯 Ready Tasks: ...
# 🔍 Unified Triage: ...
# ✅ Session initialized!
```

### Creating a Task
```bash
# Create a bug with high priority
task-create "Fix UUID case mismatch" bug 1

# Create a feature
task-create "Add CSV import" feature 1

# Create a task (default)
task-create "Update documentation"
```

### Running Security Scans
```bash
# Quick scan (before commit)
security-quick

# Full comprehensive audit
security-full

# Just MCP servers
security-mcp

# Just Swift code
security-swift

# Just secrets
security-secrets
```

### Evening Shutdown
```bash
# Complete session
session-end
# or
se

# Output:
# 🌙 Ending Development Session
# ✅ Recent Commits: ...
# 📝 Uncommitted Changes: ...
# 🔄 Syncing Beads: ...
# ⚠️  Health Alerts: ...
# 💡 Don't forget to...
```

---

## Advanced Orchestration Patterns

### 1. Daily Standup Report
```bash
daily-standup() {
    echo "📅 Daily Standup Report - $(date +%Y-%m-%d)"
    echo ""
    
    echo "✅ Yesterday's Commits:"
    git log --oneline --since="24 hours ago" --author="$(git config user.email)"
    echo ""
    
    echo "📋 Closed Issues (last 24 hours):"
    # Query beads for recently closed
    bd list --status=closed | grep -A 1 "$(date -v-1d +%Y-%m-%d)" || echo "None"
    echo ""
    
    echo "🎯 Today's Plan:"
    bv --robot-next
    echo ""
    
    echo "⚠️  Blockers:"
    bd blocked
}
```

### 2. CI/CD Simulation
```bash
ci-check() {
    echo "🤖 Simulating CI/CD Pipeline"
    echo ""
    
    # 1. Security
    echo "1️⃣ Security Checks..."
    security-full || return 1
    echo ""
    
    # 2. Build
    echo "2️⃣ Building..."
    xcodebuild build -project "I Do Blueprint.xcodeproj" \
        -scheme "I Do Blueprint" \
        -destination 'platform=macOS' || return 1
    echo ""
    
    # 3. Tests
    echo "3️⃣ Running Tests..."
    xcodebuild test -project "I Do Blueprint.xcodeproj" \
        -scheme "I Do Blueprint" \
        -destination 'platform=macOS' || return 1
    echo ""
    
    echo "✅ CI/CD simulation passed!"
}
```

### 3. Context Restoration (for Claude Code)
```bash
# This would be a skill for Claude Code to call
restore-context() {
    echo "🧠 Restoring Development Context"
    echo ""
    
    echo "Run these in Claude Code:"
    echo ""
    echo "mcp__basic-memory__recent_activity("
    echo "  timeframe='7d',"
    echo "  project='i-do-blueprint'"
    echo ")"
    echo ""
    echo "mcp__basic-memory__build_context("
    echo "  url='projects/i-do-blueprint',"
    echo "  depth=2"
    echo ")"
    echo ""
    echo "Then check: bd list --status=in_progress"
}
```

---

## Integration with Claude Code

### Recommended Claude Code Skill

Create `.claude/skills/session-orchestration.md`:

```markdown
# Session Orchestration Skill

## Purpose
Orchestrate session start, security scans, and session end workflows.

## When to Use
- User says "start session", "morning setup", "begin work"
- User says "security scan", "run security", "check for vulnerabilities"
- User says "end session", "wrap up", "close out"

## Workflow

### Session Start
1. Run in terminal: `session-start` or `ss`
2. Call MCP tools:
   - `mcp__basic-memory__recent_activity(timeframe="7d", project="i-do-blueprint")`
   - `mcp__basic-memory__build_context(url="projects/i-do-blueprint")`
3. Review output and summarize to user

### Security Scan
1. Ask user: "Quick scan or full audit?"
2. Run: `security-quick` or `security-full`
3. Review findings in `/tmp/swiftscan-results.json`
4. Create Beads issues for critical findings
5. Document patterns in Basic Memory

### Session End
1. Run: `session-end` or `se`
2. Prompt user to document any new knowledge
3. Remind to push if uncommitted changes

## Examples

User: "Start my session"
Assistant:
1. Runs `session-start`
2. Loads Basic Memory context
3. Summarizes ready tasks
4. Recommends next task from `bv --robot-next`

User: "Run security"
Assistant:
1. Runs `security-full`
2. Reviews findings
3. Creates Beads issues for each finding
4. Suggests fixes based on knowledge base
```

---

## TruffleHog Integration Details

### Installation
```bash
# Recommended: Homebrew
brew install trufflesecurity/trufflehog/trufflehog

# Or: Direct download
curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin
```

### Common TruffleHog Commands
```bash
# Scan git repository (last 10 commits)
trufflehog git file://. --since-commit HEAD~10 --fail

# Scan filesystem
trufflehog filesystem . --fail

# Scan with specific detectors
trufflehog git file://. --only-verified --fail

# Scan staged files only
git diff --cached --name-only | xargs trufflehog filesystem --no-update --fail

# Generate JSON report
trufflehog git file://. --json > /tmp/trufflehog-report.json
```

### TruffleHog in Workflows
```bash
# Pre-commit hook
trufflehog git file://. --since-commit HEAD --fail

# CI/CD pipeline
trufflehog git file://. --since-commit origin/main --fail

# Full repository audit
trufflehog git file://. --fail
```

---

## Summary: Command Quick Reference

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `session-start` / `ss` | Start dev session | Every morning |
| `session-end` / `se` | End dev session | Every evening |
| `session-plan` / `sp` | View execution plan | After creating tasks |
| `session-next` / `sn` | Get next task | When ready for new work |
| `security-quick` / `sq` | Quick security scan | Before every commit |
| `security-full` / `sf` | Full security audit | Weekly or before release |
| `security-mcp` | MCP server scan | After config changes |
| `security-swift` | Swift code scan | After code changes |
| `security-secrets` | Secret scan | Before pushing |
| `task-create` / `tc` | Create new task | Start new work |
| `task-complete` / `td` | Complete task | Finish work |
| `health-check` / `hc` | Project health | Before release |
| `daily-standup` | Daily report | Daily standups |
| `ci-check` | CI/CD simulation | Before merging |

---

## Next Steps

1. ✅ Create `~/.zsh/workflows.zsh` with all function definitions
2. ✅ Update `~/.zshrc` to source the workflows file
3. ✅ Reload shell: `source ~/.zshrc`
4. ✅ Install TruffleHog if not present: `brew install trufflesecurity/trufflehog/trufflehog`
5. ✅ Setup git pre-commit hook
6. ✅ Test workflows: `session-start`, `security-full`, `session-end`
7. ✅ Document in Basic Memory for future reference
8. ✅ Create Claude Code skill for session orchestration

---

## Benefits

### Time Savings
- **Morning startup**: 30 seconds vs 5+ minutes manual context loading
- **Security scans**: 1 command vs 4+ separate tool invocations
- **Session end**: Automated sync and documentation prompts

### Consistency
- Same workflow every time
- Never forget security checks
- Standardized task management

### Discoverability
- Short aliases for common operations
- Help text built into functions
- Self-documenting commands

### Integration
- Combines bd, bv, basic-memory, security tools
- Git workflow integration
- Claude Code MCP integration

### Scalability
- Easy to add new tools
- Modular function design
- Team can adopt same workflows

---

Last Updated: 2025-12-30
Maintainer: Development Team
Tools: bd, bv, basic-memory, swiftscan, mcp-shield, TruffleHog, direnv
