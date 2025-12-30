A comprehensive guide to the Model Context Protocol (MCP) tools currently open in this browser session.

## Table of Contents

1. [Owlex](#owlex)
2. [Sync MCP Config](#sync-mcp-config)
3. [Agent Deck](#agent-deck)
4. [Beads](#beads)
5. [Beads Viewer](#beads-viewer)

---

## Owlex

**Repository:** agentic-mcp-tools/owlex

**Purpose:** Multi-agent orchestration MCP server for coordinating multiple AI models

**Key Features:**
- Council deliberation - Query all agents in parallel with optional revision round
- Session management - Start fresh or resume with full context preserved
- Async execution - Tasks run in background with timeout control
- Critique mode - Agents find bugs and flaws in each other's answers

**Installation:**
```bash
uv tool install git+https://github.com/agentic-mcp-tools/owlex.git
```

**Configuration (.mcp.json):**
```json
{
  "mcpServers": {
    "owlex": {
      "command": "owlex-server"
    }
  }
}
```

**Main Tools:**
- **council_ask**: Query all agents and collect answers with optional deliberation
  - Parameters: prompt (required), claude_opinion, deliberate (default: true), critique (default: false), timeout (default: 300s)
  - Returns: round_1 with initial answers, round_2 with revisions (if enabled)
- **Agent Sessions**: start_codex_session, resume_codex_session, start_gemini_session, resume_gemini_session
- **Task Management**: wait_for_task, get_task_result, list_tasks, cancel_task

**Best Use Cases by Agent:**
- **Codex**: Code review, bug finding, PRD discussion
- **Gemini**: Large codebase analysis (1M context), multimodal
- **OpenCode**: Alternative perspective, plan mode
- **Claude**: Complex multi-step implementation

---

## Sync MCP Config

**Repository:** jgrichardson/sync-mcp-cfg

**Purpose:** Manage and synchronize Model Context Protocol server configurations across multiple AI clients

**Key Features:**
- Multi-client support: Claude Code, Claude Desktop, Cursor, VS Code, Gemini CLI, OpenCode
- Easy synchronization with automatic conflict resolution
- Backup and restore capability
- Interactive CLI with rich output and progress indicators
- Optional text-based UI (TUI)
- Cross-platform support (Windows, macOS, Linux)
- Plugin-based extensible architecture
- Protected against accidental exposure of sensitive data

**Installation:**
```bash
git clone https://github.com/jgrichardson/sync-mcp-cfg.git
cd sync-mcp-cfg
pip install -e .
```

**Supported Clients & Config Locations:**
- Claude Code CLI: ~/.claude.json
- Claude Desktop: ~/Library/Application Support/Claude/claude_desktop_config.json (macOS)
- Cursor: ~/.cursor/mcp.json
- VS Code Copilot: ~/Library/Application Support/Code/User/settings.json (macOS)
- Gemini CLI: ~/.gemini/settings.json (global) or .gemini/settings.json (local)
- OpenCode: ~/.config/opencode/config.json (global) or ./opencode.json (project)

**Core Commands:**
- `sync-mcp-cfg init` - Initialize configuration
- `sync-mcp-cfg status` - Check client status
- `sync-mcp-cfg add <name> <command>` - Add MCP server
- `sync-mcp-cfg list [--detailed]` - List configured servers
- `sync-mcp-cfg sync --from <client> --to <client>` - Sync between clients
- `sync-mcp-cfg remove <name> [--clients]` - Remove server
- `sync-mcp-cfg tui` - Launch interactive UI
- `sync-mcp-cfg backup` - Manual backup
- `sync-mcp-cfg restore` - Restore from backup

**Special Features:**
- Gemini CLI: Support for trust field and timeout configuration
- OpenCode: Unique local/remote server format with environment variables
- All clients: Automatic backup creation before changes

---

## Agent Deck

**Repository:** asheshgoplani/agent-deck

**Purpose:** Terminal-based session manager and command center for AI coding agents. Built with Go + Bubble Tea.

**Key Features:**
- Unified control center - Manage multiple AI agent sessions from one terminal
- Session forking - Duplicate conversations with full context inheritance
- On-demand MCP attachment - Toggle MCPs without editing config files
- MCP Socket Pool - Share MCP processes across sessions (85-90% memory savings)
- Fuzzy search - Find sessions, issues, and conversations instantly
- Smart status detection - Know if agents are Running, Waiting, Idle, or Error
- Hierarchical organization - Group sessions by project, client, or experiment
- Built on tmux - Sessions persist through disconnects and reboots
- Claude Code skill available - AI-assisted session management

**Installation:**
```bash
curl -fsSL https://raw.githubusercontent.com/asheshgoplani/agent-deck/main/install.sh | bash
```

**Core Commands:**
- `agent-deck` - Launch interactive TUI
- `agent-deck add <path> [-c <tool>]` - Add session
- `agent-deck list [--json]` - List all sessions
- `agent-deck session attach <id>` - Attach to session
- `agent-deck session fork <id> [-t "name"]` - Fork Claude session
- `agent-deck session restart <id>` - Restart and reload MCPs
- `agent-deck mcp list` - List available MCPs
- `agent-deck mcp attach <id> <mcp> [--global] [--restart]` - Attach MCP
- `agent-deck mcp detach <id> <mcp>` - Detach MCP
- `agent-deck group create <name> [--parent <parent>]` - Create groups
- `agent-deck status [-v]` - Quick status check

**TUI Keyboard Shortcuts:**
- `j/k` or arrows - Navigate
- `Enter` - Attach to session
- `n` - New session
- `g` - New group
- `r` - Rename
- `d` - Delete
- `f` - Fork Claude session
- `M` - MCP Manager
- `/` - Search
- `Ctrl+Q` - Detach
- `?` - Help

**MCP Manager Features:**
- Toggle MCPs per project (LOCAL scope)
- Toggle MCPs globally (GLOBAL scope)
- Auto-restart sessions with new capabilities
- Supports stdio MCPs and HTTP/SSE endpoints
- Supports all major MCP packages (filesystem, GitHub, sequential-thinking, etc.)

**Special Features:**
- Session auto-detection after restarts
- Parallel forking for exploring multiple solutions
- CLI support for automation and scripting (--json output)
- MCP Socket Pool for resource-constrained setups

---

## Beads

**Repository:** steveyegge/beads

**Purpose:** Distributed, git-backed graph issue tracker for AI agents. Provides persistent, structured memory for coding agents.

**Key Features:**
- Persistent memory - Replaces messy markdown plans with dependency-aware graph
- Git as database - Issues stored as JSONL in .beads/ (versioned, branched, merged like code)
- Agent-optimized - JSON output, dependency tracking, auto-ready task detection
- Zero conflict - Hash-based IDs (bd-a1b2) prevent merge collisions in multi-agent workflows
- Invisible infrastructure - SQLite local cache for speed, background daemon for auto-sync
- Semantic compaction - "Memory decay" summarizes old closed tasks to save context window
- Hierarchical IDs - Support for epics, tasks, and subtasks (bd-a3f8.1.1)
- Stealth mode - Use locally without committing to main repo

**Installation:**
```bash
npm install -g @beads/bd
# or
brew install steveyegge/beads/bd
# or
go install github.com/steveyegge/beads/cmd/bd@latest
```

**Core Commands:**
- `bd init` - Initialize (humans run once)
- `bd init --stealth` - Stealth mode (local-only)
- `bd ready` - List tasks with no open blockers
- `bd create "Title" -p 0` - Create P0 task
- `bd dep add <child> <parent>` - Link tasks (blocks relationship)
- `bd show <id>` - View task details and audit trail
- `bd list` - List all tasks
- `bd close <id>` - Mark task completed
- `bd reopen <id>` - Reopen task

**Data Format:**
- Issues stored as JSONL in .beads/beads.jsonl
- Each issue is a JSON object with full history
- Git-native (branches, merges, conflicts handled)
- Hash-based IDs prevent collisions during merge conflicts
- Full audit trail for each task

**Task Hierarchy Example:**
```
bd-a3f8        (Epic: Login system)
bd-a3f8.1      (Task: Database setup)
bd-a3f8.1.1    (Subtask: Schema design)
```

---

## Beads Viewer

**Repository:** Dicklesworthstone/beads_viewer

**Purpose:** Elegant, keyboard-driven terminal interface for browsing, managing, and analyzing Beads task tracking data. Provides graph-aware insights with AI agent integration.

**Key Features:**
- Fast terminal UI - Zero network latency, Vim-style navigation (j/k)
- Split view - List on left, rich details on right (responsive to terminal width)
- Kanban board - Visualize workflow (Open, In Progress, Blocked, Closed)
- Dependency graph - Interactive visualization with D3.js and custom ASCII rendering
- Graph metrics - PageRank, Betweenness, HITS, Critical Path, Cycles detection
- Insights dashboard - 6-panel interactive analysis
- Time-travel - Compare project state across any git revision
- AI agent integration - Robot JSON protocol for deterministic outputs
- Semantic search - Full-text fuzzy search with semantic capabilities
- Sprint tracking - Burndown charts, progress tracking, at-risk detection
- Label health - Domain-centric health monitoring
- Interactive graph export - Self-contained HTML with force-directed visualization
- Markdown export - Reports with embedded Mermaid diagrams
- Cass integration - Optional AI session correlation

**Installation:**
```bash
curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/beads_viewer/main/install.sh?$(date +%s)" | bash
```

**Core Commands:**
- `bv` - Launch interactive TUI
- `bv --robot-triage` - THE MEGA-COMMAND: unified triage with all analysis
- `bv --robot-next` - Single top recommendation + claim command
- `bv --robot-plan` - Parallel execution tracks with unblocks analysis
- `bv --robot-insights` - Full graph metrics and analysis
- `bv --robot-priority` - Priority recommendations with confidence scores
- `bv --robot-history` - Bead-to-commit correlations
- `bv --robot-alerts` - Proactive health monitoring and drift detection
- `bv --robot-label-health` - Per-label health metrics
- `bv --robot-forecast` - ETA predictions with dependency-aware scheduling
- `bv --export-pages` - Generate self-contained static HTML dashboard
- `bv --export-md` - Export Markdown report with Mermaid diagrams
- `bv --as-of <ref>` - Time-travel to historical state

**Graph Metrics Computed:**
1. **PageRank** (30% weight) - Foundational dependency importance; bedrock blocker identification
2. **Betweenness** (30% weight) - Bottleneck/bridge position; gatekeeper nodes
3. **HITS** - Hub/Authority: Epics (hubs) vs Infrastructure (authorities)
4. **Critical Path** - Longest dependency chain; zero-slack keystones
5. **Eigenvector** (10% weight) - Influence via important neighbors
6. **Degree Centrality** - Direct blockers/blocked counts
7. **Density** - Project coupling health (0.0 isolated, 1.0 fully coupled)
8. **Cycles** - Circular dependency detection (logical impossibilities)
9. **Topological Sort** - Valid execution order

**TUI Navigation (j/k to move, Enter to open, ? for help):**

**List View:**
- `b` - Toggle Kanban board
- `g` - Toggle graph visualizer
- `i` - Toggle insights dashboard
- `h` - Toggle history view
- `f` - Toggle file-centric drill-down
- `l` - Label picker
- `s` - Cycle sort mode (Priority, Created, Updated, etc.)
- `/` - Search (fuzzy or semantic)
- `t` - Time-travel mode
- `T` - Quick time-travel (HEAD~5)
- `p` - Toggle priority hints overlay
- `!` - Toggle alerts panel
- `C` - Copy issue to clipboard
- `y` - Copy issue ID

**Kanban Board:**
- `h/l` - Move between columns
- `j/k` - Move within column
- `s` - Cycle swimlane mode (Status, Priority, Type)
- `d` - Expand/collapse card details
- `Tab` - Toggle side detail panel
- `o/c/r` - Filter: Open, Closed, Ready

**Graph View:**
- `H/L` - Scroll left/right
- `Ctrl+D/U` - Page down/up
- `z` - Zoom in/out

**Insights Dashboard:**
- `Tab/Shift+Tab` - Move between panels
- `e` - Toggle explanations
- `x` - Toggle calculation proofs

**History View (bead-to-commit correlation):**
- `v` - Toggle Bead Mode ↔ Git Mode
- `f` - Toggle file-centric drill-down
- `t` - Toggle timeline panel
- `c` - Cycle confidence threshold
- `y` - Copy commit SHA
- `o` - Open in browser

**Static Site Export:**
- Generates self-contained HTML dashboards
- Pre-computed graph layout (instant rendering, no force simulation)
- SQLite FTS5 for instant full-text search
- Interactive dependency graph with pan/zoom
- Responsive design (mobile, tablet, desktop)
- Suitable for stakeholder sharing

**Robot Commands (AI-friendly JSON output):**
- `--robot-triage` - Best entry point; complete analysis in one call
- `--robot-plan` - Execution plan with parallel tracks and unblock counts
- `--robot-insights` - All 9 graph metrics with per-metric status
- `--robot-priority` - Priority recommendations with reasoning
- `--robot-label-health` - Per-label health and velocity
- `--robot-label-flow` - Cross-label dependency matrix
- `--robot-history` - Commit-to-bead correlations
- `--robot-alerts` - Stale issues, blocking cascades, priority misalignment
- `--robot-forecast` - ETA and completion predictions
- `--robot-suggest` - Hygiene suggestions (duplicates, cycles, deps)

**Time-Travel & Diffs:**
- `bv --as-of HEAD~30` - View state 30 commits ago
- `bv --as-of v1.0.0` - View state at release tag
- `bv --diff-since HEAD~5` - Show changes in last 5 commits
- `bv --robot-diff --diff-since HEAD~5` - JSON diff output

**Performance:**
- Instant startup (<50ms for typical repos)
- 60 FPS UI updates
- Handles 10,000+ issues without lag
- Two-phase analyzer: Phase 1 (instant), Phase 2 (async, 500ms timeout)
- Caching by data hash
- Size-aware timeouts prevent hanging

---

## Integration Scenarios

### For Multi-Agent Coordination:
1. Use **Agent Deck** as the session hub (manage Claude, Gemini, OpenCode, Codex)
2. Use **Beads** for persistent task tracking (bd create, bd dep)
3. Use **Beads Viewer** with robot commands for triage and planning
4. Use **Owlex** for agent council meetings and cross-agent critique

### For MCP Management:
1. Define all MCPs in **Agent Deck** config (~/.agent-deck/config.toml)
2. Use **Sync MCP Config** to propagate configurations to other clients
3. Toggle MCPs per project in **Agent Deck** MCP Manager (press M)
4. Sessions auto-restart and reload new capabilities

### For Task Management:
1. Create and manage tasks with **Beads** (bd create, bd dep, bd ready)
2. View and analyze with **Beads Viewer** TUI or robot commands
3. Export dashboards for stakeholders using `--export-pages`
4. Track correlations between code commits and work items with history view

### For AI Agent Workflows:
1. Run `bv --robot-triage` to get unified overview
2. Extract highest-impact task from recommendations
3. Agent works on task while tracking with Beads
4. Run `bv --robot-plan` to find next unblocked work
5. Use `bv --robot-insights` for impact analysis before changes

---

## Summary Table

| Tool | Type | Primary Purpose | Best For |
|------|------|-----------------|----------|
| **Owlex** | MCP Server | Multi-agent orchestration | Agent councils, cross-agent critique, debate |
| **Sync MCP Config** | CLI Tool | Configuration management | Managing MCPs across 6 client types |
| **Agent Deck** | Terminal UI | Session management | Running multiple agents, dynamic MCP toggling |
| **Beads** | Git-backed DB | Task tracking | Persistent task memory, dependency graphs |
| **Beads Viewer** | Terminal UI + API | Task visualization & analysis | Triage, planning, graph-aware metrics |

---

## Quick Start for Agents
```bash
# 1. Initialize task tracking
bd init

# 2. Create a task
bd create "Implement feature X" -p 0

# 3. View execution plan
bv --robot-plan

# 4. Get full triage (use this!)
bv --robot-triage

# 5. Manage sessions across tools
agent-deck  # Launch session hub

# 6. Coordinate multiple agents
owlex council_ask "Code review this PR" --deliberate
```