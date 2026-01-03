---
title: Agent Deck - Agent Session Management
type: note
permalink: ai-tools/orchestration/agent-deck-agent-session-management
tags:
- cli
- orchestration
- session-management
- tmux
- multi-agent
- claude-code
- opencode
- tui
---

# Agent Deck - Agent Session Management

## Overview

**Category**: Orchestration  
**Status**: ✅ Active - Session Management Tool  
**Installation**: `curl -fsSL https://raw.githubusercontent.com/asheshgoplani/agent-deck/main/install.sh | bash`  
**CLI Command**: `agent-deck`  
**Repository**: https://github.com/asheshgoplani/agent-deck  
**License**: MIT  
**Built With**: Go + Bubble Tea (TUI framework)  
**Agent Attachment**: CLI/Shell (agent-agnostic, works with all terminal-based AI agents)

---

## What It Does

Agent Deck is a **terminal session manager** for AI coding agents (Claude Code, OpenCode, Aider). It provides mission control for managing multiple AI agent sessions in one terminal, with complete visibility, instant switching, hierarchical organization, and zero-config session persistence through tmux.

### The Problem

Managing multiple AI coding sessions gets messy:
- **Too many terminal tabs**: Hard to track which agent is where
- **Lost context**: Switching between projects means hunting through windows
- **No visibility**: Can't see what's running, waiting, or idle at a glance
- **Manual management**: Creating, organizing, and tracking sessions is tedious

### The Solution

Agent Deck provides:
- 🎯 **See everything at a glance**: Running, waiting, or idle - know status instantly
- ⚡ **Switch in milliseconds**: Jump between sessions with a single keystroke
- 🔍 **Never lose track**: Search across conversations, filter by status
- 🌳 **Stay organized**: Group sessions by project, client, or experiment with collapsible hierarchies
- 🔌 **Zero config switching**: Built on tmux - sessions persist through disconnects and reboots
- 🍴 **Fork conversations**: Try different approaches without losing context (Claude Code only)

---

## Key Features

### 1. Terminal UI (TUI)

**Interactive Dashboard**:
- List all sessions with status indicators
- Group sessions hierarchically (projects, clients, experiments)
- Search and filter sessions by name, status, agent type
- Attach to sessions with single keystroke
- Real-time status updates

**Status Indicators**:
- 🟢 **Running**: Agent actively processing
- 🟡 **Idle**: Session active, waiting for input
- 🔴 **Stopped**: Session stopped/exited
- ⏸️ **Paused**: Session paused, can be resumed

### 2. Session Management

**Create Sessions**:
```bash
# Add current directory as session
agent-deck add .

# Add with specific agent (Claude Code)
agent-deck add . -c claude

# Add with custom name
agent-deck add /path/to/project -n "my-project"

# Add with group
agent-deck add . -g "client-work"
```

**Lifecycle Management**:
```bash
# Start session's tmux process
agent-deck session start <id>

# Stop/kill session process
agent-deck session stop <id>

# Restart (Claude: reloads MCPs)
agent-deck session restart <id>
```

**Attach/Detach**:
```bash
# Attach interactively
agent-deck session attach <id>

# Auto-detect current session (in tmux)
agent-deck session show

# Show session details
agent-deck session show <id>
```

### 3. MCP Server Integration (Claude Code Only)

**List Available MCPs**:
```bash
# From config.toml
agent-deck mcp list
agent-deck mcp list --json
```

**Attach/Detach MCPs**:
```bash
# Attach to LOCAL scope (session-specific)
agent-deck mcp attach <id> github

# Attach to GLOBAL scope (all sessions)
agent-deck mcp attach <id> exa --global

# Attach and restart session
agent-deck mcp attach <id> memory --restart

# Detach from LOCAL
agent-deck mcp detach <id> github

# Detach from GLOBAL
agent-deck mcp detach <id> exa --global
```

**Show Attached MCPs**:
```bash
# For specific session
agent-deck mcp attached <id>

# Auto-detect current session
agent-deck mcp attached
```

### 4. Conversation Forking (Claude Code Only)

**Fork Sessions**:
```bash
# Fork with inherited context
agent-deck session fork <id>

# Custom title
agent-deck session fork <id> -t "exploration"

# Into specific group
agent-deck session fork <id> -g "experiments"
```

**Use Case**: Try different implementation approaches without losing original conversation context.

### 5. Hierarchical Groups

**Organize Sessions**:
```bash
# Create group
agent-deck group create "client-work"

# Add session to group
agent-deck group add <id> "client-work"

# Remove from group
agent-deck group remove <id> "client-work"

# List groups
agent-deck group list

# Collapse/expand in TUI
# (handled interactively)
```

**Hierarchy Example**:
```
📁 client-work/
  📁 project-a/
    🟢 feature-auth
    🟡 bugfix-login
  📁 project-b/
    🟢 refactor-api
📁 personal/
  🟡 learning-rust
  🔴 experiment-wasm
```

### 6. Agent Support

**Supported Agents**:
- **Claude Code** (primary, full feature support including MCP and forking)
- **OpenCode** (open-source alternative, replaced Aider in v1.3.0)
- **Custom Tools** (define in `~/.agent-deck/config.toml`)

**Example Custom Tool** (`~/.agent-deck/config.toml`):
```toml
[tools.aider]
command = "aider"
icon = "🔧"
busy_patterns = ["processing..."]
```

---

## Installation & Configuration

### Prerequisites

**tmux** (required):
```bash
# macOS
brew install tmux

# Linux (Ubuntu/Debian)
sudo apt-get install tmux

# Verify installation
tmux -V
```

### Installation Methods

#### 1. Quick Install (Homebrew)

```bash
# Tap repository
brew tap asheshgoplani/tap

# Install Agent Deck
brew install agent-deck
```

#### 2. Shell Script

```bash
# Run installer
curl -fsSL https://raw.githubusercontent.com/asheshgoplani/agent-deck/main/install.sh | bash

# Verify installation
agent-deck --version
```

#### 3. From Source

```bash
# Clone repository
git clone https://github.com/asheshgoplani/agent-deck.git
cd agent-deck

# Build
make build

# Install
sudo mv build/agent-deck /usr/local/bin/
```

### Configuration

**tmux Configuration** (automatic):

Agent Deck installer adds necessary configuration to `~/.tmux.conf`. If not present, add manually:

```bash
# agent-deck configuration
set -g mouse on
set -g base-index 1
set -g pane-base-index 1
set -g renumber-windows on
```

**Agent Deck Configuration** (`~/.agent-deck/config.toml`):

Created automatically on first run. Example:

```toml
# Default agent
default_agent = "claude"

# MCP servers (for Claude Code)
[mcp_servers.github]
enabled = true
scope = "local"  # or "global"

[mcp_servers.memory]
enabled = true
scope = "global"

# Custom tools
[tools.aider]
command = "aider"
icon = "🔧"
busy_patterns = ["processing..."]
```

---

## CLI Reference

### Global Commands

```bash
# Launch TUI
agent-deck

# Quick status overview
agent-deck status

# List all sessions
agent-deck list

# List as JSON
agent-deck list --json
```

**Note**: Flags must come BEFORE positional arguments (Go flag package standard).

### Session Commands

**Identification**: Sessions can be identified by:
- Session ID (e.g., `my-project`)
- Auto-detection (if in tmux session)

#### Lifecycle

```bash
# Start session
agent-deck session start <id>

# Stop session
agent-deck session stop <id>

# Restart session (reloads MCPs for Claude)
agent-deck session restart <id>
```

#### Fork (Claude Only)

```bash
# Fork with inherited context
agent-deck session fork <id>

# Custom title
agent-deck session fork <id> -t "exploration"

# Into specific group
agent-deck session fork <id> -g "experiments"
```

#### Attach/Show

```bash
# Attach interactively
agent-deck session attach <id>

# Show session details
agent-deck session show <id>

# Auto-detect current session
agent-deck session show

# Current session info
agent-deck session current

# Just session name (for scripting)
agent-deck session current -q

# JSON output (for automation)
agent-deck session current --json
```

### MCP Commands (Claude Code Only)

#### List

```bash
# List available MCPs (from config.toml)
agent-deck mcp list

# JSON output
agent-deck mcp list --json
```

#### Attached

```bash
# Show attached MCPs for session
agent-deck mcp attached <id>

# Auto-detect current session
agent-deck mcp attached
```

#### Attach/Detach

```bash
# Attach to LOCAL scope
agent-deck mcp attach <id> github

# Attach to GLOBAL scope
agent-deck mcp attach <id> exa --global

# Attach and restart session
agent-deck mcp attach <id> memory --restart

# Detach from LOCAL
agent-deck mcp detach <id> github

# Detach from GLOBAL
agent-deck mcp detach <id> exa --global
```

**Scopes**:
- **LOCAL**: MCP server attached to specific session only
- **GLOBAL**: MCP server attached to all sessions

### Group Commands

```bash
# Create group
agent-deck group create <name>

# Add session to group
agent-deck group add <id> <group>

# Remove from group
agent-deck group remove <id> <group>

# List groups
agent-deck group list

# Delete group (doesn't delete sessions)
agent-deck group delete <name>
```

---

## Workflow Patterns

### Pattern 1: Project-Based Organization

**Use Case**: Organize sessions by client project.

```bash
# Create groups
agent-deck group create "client-a"
agent-deck group create "client-b"

# Add sessions to groups
agent-deck add /path/to/client-a -g "client-a" -n "feature-auth"
agent-deck add /path/to/client-a -g "client-a" -n "bugfix-api"
agent-deck add /path/to/client-b -g "client-b" -n "refactor-db"

# Launch TUI to navigate
agent-deck
```

**Result**: Hierarchical organization in TUI, easy switching between client projects.

### Pattern 2: Experimental Forks

**Use Case**: Try different implementation approaches without losing original context.

```bash
# Start with original approach
agent-deck add . -n "auth-implementation"

# Work on auth implementation in Claude Code
# ...

# Fork to try alternative approach
agent-deck session fork auth-implementation -t "auth-jwt" -g "experiments"
agent-deck session fork auth-implementation -t "auth-oauth" -g "experiments"

# Compare approaches in parallel
agent-deck  # TUI shows all three sessions
```

**Result**: Multiple parallel explorations, easy comparison, preserved context.

### Pattern 3: MCP Server Experimentation

**Use Case**: Test different MCP servers for a specific task.

```bash
# Create session
agent-deck add . -n "feature-search"

# Attach GitHub MCP (code search)
agent-deck mcp attach feature-search github

# Work with GitHub MCP
# ...

# Detach GitHub, attach memory MCP
agent-deck mcp detach feature-search github
agent-deck mcp attach feature-search memory --restart

# Compare effectiveness
```

**Result**: Quick A/B testing of MCP servers without recreating sessions.

### Pattern 4: Multi-Agent Research

**Use Case**: Use Claude Code and OpenCode in parallel for diverse perspectives.

```bash
# Create Claude Code session
agent-deck add . -c claude -n "research-claude"

# Create OpenCode session
agent-deck add . -c opencode -n "research-opencode"

# Launch TUI to switch between agents
agent-deck

# Compare responses, synthesize insights
```

**Result**: Diverse AI perspectives on the same problem.

### Pattern 5: Session Persistence Across Disconnects

**Use Case**: Work on project, disconnect, resume later without losing context.

```bash
# Day 1: Create session
agent-deck add . -n "my-project"
agent-deck session attach my-project

# Work in Claude Code
# ...

# Disconnect (close laptop, etc.)
# tmux session persists in background

# Day 2: Resume
agent-deck session attach my-project

# Full context preserved!
```

**Result**: Zero-friction resume, no context loss.

---

## I Do Blueprint Use Cases

### 1. Feature Development Workflow

**Scenario**: Develop RSVP feature with Claude Code, test alternatives with forking.

**Workflow**:
```bash
# Create session for RSVP feature
agent-deck add ~/Development/nextjs-projects/I\ Do\ Blueprint \
  -c claude \
  -n "rsvp-feature" \
  -g "i-do-blueprint"

# Attach relevant MCPs
agent-deck mcp attach rsvp-feature supabase
agent-deck mcp attach rsvp-feature basic-memory

# Work on implementation
agent-deck session attach rsvp-feature

# Fork to try server components approach
agent-deck session fork rsvp-feature -t "rsvp-server-components" -g "experiments"

# Fork to try client components approach
agent-deck session fork rsvp-feature -t "rsvp-client-components" -g "experiments"

# Compare in TUI, choose best approach
agent-deck
```

### 2. Multi-Agent Code Review

**Scenario**: Get code review from both Claude Code and OpenCode.

**Workflow**:
```bash
# Create sessions
agent-deck add . -c claude -n "review-claude" -g "code-review"
agent-deck add . -c opencode -n "review-opencode" -g "code-review"

# Launch TUI, switch between agents
agent-deck

# Send same code to both agents, compare feedback
```

### 3. MCP Server Testing

**Scenario**: Test different MCP servers for database operations.

**Workflow**:
```bash
# Create session
agent-deck add . -n "db-operations" -g "i-do-blueprint"

# Test with Supabase MCP
agent-deck mcp attach db-operations supabase --restart
# Work with Supabase MCP
# ...

# Test with alternative MCP
agent-deck mcp detach db-operations supabase
agent-deck mcp attach db-operations postgres --restart
# Compare performance
```

### 4. Project Organization

**Scenario**: Organize all I Do Blueprint work sessions.

**Workflow**:
```bash
# Create hierarchical structure
agent-deck group create "i-do-blueprint"
agent-deck group create "i-do-blueprint/frontend"
agent-deck group create "i-do-blueprint/backend"
agent-deck group create "i-do-blueprint/database"

# Add sessions to groups
agent-deck add . -n "rsvp-ui" -g "i-do-blueprint/frontend"
agent-deck add . -n "guest-list" -g "i-do-blueprint/frontend"
agent-deck add . -n "api-routes" -g "i-do-blueprint/backend"
agent-deck add . -n "edge-functions" -g "i-do-blueprint/backend"
agent-deck add . -n "schema-design" -g "i-do-blueprint/database"

# Navigate in TUI
agent-deck
```

**TUI View**:
```
📁 i-do-blueprint/
  📁 frontend/
    🟢 rsvp-ui
    🟡 guest-list
  📁 backend/
    🟢 api-routes
    🔴 edge-functions
  📁 database/
    🟡 schema-design
```

### 5. Session Persistence During Development

**Scenario**: Work across multiple days without losing context.

**Workflow**:
```bash
# Day 1: Start work
agent-deck add . -n "wedding-timeline" -g "i-do-blueprint"
agent-deck mcp attach wedding-timeline supabase
agent-deck mcp attach wedding-timeline basic-memory --global
agent-deck session attach wedding-timeline

# Work in Claude Code, make progress
# ...

# End of day: Detach (session persists)
# (Ctrl+B, D to detach from tmux)

# Day 2: Resume
agent-deck session attach wedding-timeline

# Full context preserved:
# - Conversation history
# - MCP servers attached
# - Working directory
# - Environment variables
```

---

## Best Practices

### 1. Use Hierarchical Groups

- Organize sessions by project, client, or feature area
- Collapse/expand groups in TUI for focused view
- Use descriptive group names (e.g., `client-name/project-name`)

### 2. Name Sessions Descriptively

- Use clear, specific names: `rsvp-feature`, `auth-refactor`
- Avoid generic names: `session-1`, `test`, `temp`
- Include context: `i-do-blueprint-auth` vs. just `auth`

### 3. Leverage Forking for Experimentation

- Fork before trying risky changes
- Keep original session as baseline
- Compare approaches in parallel

### 4. Attach MCPs Strategically

- Use **LOCAL** scope for session-specific MCPs
- Use **GLOBAL** scope for commonly-used MCPs (Basic Memory, GitHub)
- Restart session after attaching MCPs for clean state

### 5. Use TUI for Navigation

- Launch `agent-deck` (TUI) for quick overview
- Use keyboard shortcuts for fast switching
- Filter/search for specific sessions

### 6. Persist Long-Running Sessions

- Don't stop sessions unnecessarily
- Let tmux handle persistence
- Detach with `Ctrl+B, D` instead of closing terminal

### 7. Combine with Other Tools

- Use Agent Deck for **session management**
- Use Owlex for **multi-agent orchestration** within sessions
- Use Basic Memory for **knowledge persistence** across sessions
- Use Beads for **task tracking** within sessions

---

## Keyboard Shortcuts (TUI)

| Key | Action |
|-----|--------|
| `↑`/`↓` | Navigate sessions |
| `Enter` | Attach to selected session |
| `/` | Search/filter sessions |
| `g` | Toggle group collapse/expand |
| `r` | Refresh status |
| `q` | Quit TUI |
| `?` | Show help |

---

## Troubleshooting

### tmux Not Installed

**Error**: `tmux: command not found`

**Solution**:
```bash
# macOS
brew install tmux

# Linux
sudo apt-get install tmux
```

### Session Not Persisting

**Issue**: Session disappears after closing terminal.

**Solution**: Detach from tmux session instead of closing terminal:
```bash
# Inside tmux session, press:
Ctrl+B, D  # Detach (session continues in background)

# Reattach later:
agent-deck session attach <id>
```

### MCP Not Loading

**Issue**: MCP server not available in Claude Code session.

**Solution**: Restart session after attaching MCP:
```bash
agent-deck mcp attach <id> <mcp-name> --restart
```

### Auto-Detection Not Working

**Issue**: `agent-deck session current` returns error.

**Solution**: Ensure you're inside a tmux session managed by Agent Deck:
```bash
# Check tmux sessions
tmux ls

# Attach to Agent Deck session
agent-deck session attach <id>

# Then auto-detection will work
agent-deck session current
```

---

## Limitations & Considerations

### 1. tmux Dependency

- Requires tmux installed and configured
- Not native to Windows (use WSL or Docker)
- Learning curve for tmux commands

### 2. Claude Code Exclusive Features

- MCP integration only works with Claude Code
- Forking only available for Claude Code sessions
- OpenCode and custom tools have limited feature support

### 3. Session Overhead

- Each session consumes system resources (tmux process)
- Many sessions (50+) may impact performance
- Monitor with `agent-deck status`

### 4. No Cloud Sync

- Sessions are local to machine
- No cross-device synchronization
- Use cloud storage for session exports if needed

---

## Resources

### Official Links

- **GitHub**: https://github.com/asheshgoplani/agent-deck
- **Releases**: https://github.com/asheshgoplani/agent-deck/releases
- **Changelog**: https://github.com/asheshgoplani/agent-deck/blob/main/CHANGELOG.md
- **Contributing**: https://github.com/asheshgoplani/agent-deck/blob/main/CONTRIBUTING.md

### Related Tools

- **tmux**: https://github.com/tmux/tmux
- **Bubble Tea** (TUI framework): https://github.com/charmbracelet/bubbletea

---

## Summary

Agent Deck is a **terminal session manager** for AI coding agents, providing mission control for managing multiple Claude Code, OpenCode, and custom agent sessions with complete visibility, instant switching, and zero-config persistence through tmux.

**Key Strengths**:
- 🎯 Complete visibility (running, idle, stopped status)
- ⚡ Instant switching (single keystroke)
- 🔍 Search and filter (find sessions fast)
- 🌳 Hierarchical organization (groups and subgroups)
- 🔌 Zero-config persistence (tmux-based, survives disconnects)
- 🍴 Conversation forking (try alternatives without losing context - Claude Code only)
- 🔧 MCP integration (attach/detach servers - Claude Code only)
- 🛠️ Custom tools support (define any agent)

**Perfect for**:
- Managing multiple I Do Blueprint feature development sessions
- Multi-agent code review workflows
- Experimental forks for trying different approaches
- MCP server testing and comparison
- Project-based session organization
- Long-running sessions with context persistence

---

**Last Updated**: December 30, 2025  
**Version**: Latest (v1.3.0+, OpenCode integration)  
**I Do Blueprint Integration**: Active
