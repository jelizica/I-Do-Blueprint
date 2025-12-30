A comprehensive guide to the Model Context Protocol (MCP) tools.

## Table of Contents

### Claude Code Active Servers
1. [ADR Analysis Server](#adr-analysis-server)
2. [Code Guardian Studio](#code-guardian-studio)
3. [Grep MCP](#grep-mcp)
4. [Supabase MCP](#supabase-mcp)
5. [Swiftzilla](#swiftzilla)

### Claude Desktop Servers
6. [Owlex](#owlex)
7. [Sync MCP Config](#sync-mcp-config)
8. [Agent Deck](#agent-deck)
9. [Beads](#beads)
10. [Beads Viewer](#beads-viewer)

---

# Claude Code Active Servers

The following MCP servers are configured and active in Claude Code CLI.

## ADR Analysis Server

**Repository:** tosin2013/mcp-adr-analysis-server

**Purpose:** Architectural Decision Records (ADR) analysis and management with AI-powered insights

**Key Features:**
- Automated ADR generation from PRDs and code analysis
- ADR compliance validation and progress tracking
- Deployment readiness assessment with bootstrap validation
- Research-driven architectural recommendations
- Environment analysis and optimization
- Smart git push with security scanning
- Integration with TODO.md for task tracking
- Memory-centric architecture with conversation history

**Installation:**
```bash
# Clone and install
git clone https://github.com/tosin2013/mcp-adr-analysis-server
cd mcp-adr-analysis-server
npm install
npm run build
```

**Main Tools:**
- **analyze_project_ecosystem**: Comprehensive recursive project analysis with advanced prompting
- **get_architectural_context**: Get detailed architectural context with ADR infrastructure setup
- **generate_adrs_from_prd**: Generate ADRs from Product Requirements Documents
- **compare_adr_progress**: Validate TODO.md progress against ADRs and environment
- **suggest_adrs**: Suggest architectural decisions with knowledge generation
- **deployment_readiness**: Comprehensive deployment validation with test tracking
- **smart_git_push**: AI-driven security-focused git push with credential detection
- **bootstrap_validation_loop**: Guided deployment validation workflow

**Best Use Cases:**
- Documenting architectural decisions systematically
- Validating implementation progress against architectural plans
- Security scanning before deployments
- Generating deployment scripts and validation
- ADR-driven development workflows

---

## Code Guardian Studio

**Repository/Article:** Building Code Guardian Studio - An MCP Server for AI-Powered Code Refactoring

**URL:** https://dev.to/phuongrealmax/building-code-guardian-studio-an-mcp-server-for-ai-powered-code-refactoring-1ice

**Purpose:** AI-powered code refactoring and quality analysis MCP server

**Key Features:**
- Intelligent code quality analysis
- Automated refactoring suggestions
- Pattern detection and code smell identification
- Integration with AI coding workflows
- Session-based memory for context preservation
- Guard module for code validation
- Automated fix loops with learning from memory

**Main Tools:**
- **guard_validate**: Validate code for common issues (fake tests, disabled features, empty catch blocks)
- **guard_check_test**: Analyze test files for fake tests without assertions
- **auto_fix_loop**: Automatic error fixing with retry logic and memory learning
- **memory_store**: Store information in persistent memory
- **memory_recall**: Search and retrieve stored memories
- **session_init**: Initialize session and load memory
- **workflow_task_create**: Create new workflow tasks

**Best Use Cases:**
- Code quality enforcement during development
- Automated refactoring recommendations
- Test quality validation
- Learning from past errors and fixes
- Multi-session context preservation

---

## Grep MCP

**Repository:** galprz/grep-mcp
**Blog Post:** https://vercel.com/blog/grep-a-million-github-repositories-via-mcp

**Purpose:** High-performance semantic code search across massive codebases and GitHub repositories

**Key Features:**
- Search millions of GitHub repositories via MCP
- AI-powered semantic code search with natural language queries
- Intelligent keyword extraction for precise pattern matching
- File pattern filtering and intent-based search
- Optimized for large-scale code exploration
- Integration with greb-mcp for enhanced search capabilities

**Installation:**
```bash
npm install -g grep-mcp
```

**Main Tools:**
- **code_search**: Natural language code search with AI-powered keyword extraction
  - Parameters: query (natural language), keywords (extracted terms, code patterns, file patterns, intent)
  - Returns: Ranked search results with relevance scores

**Best Use Cases:**
- Finding code patterns across large codebases
- Exploring unfamiliar repositories
- Locating specific implementations or APIs
- Understanding codebase structure through semantic search
- Research-driven development workflows

**Integration Notes:**
- Works with greb-mcp for enhanced search capabilities
- Requires FULL ABSOLUTE PATH to workspace directory (not relative paths)
- Supports file pattern filtering (*.py, *.js, etc.)
- Provides primary terms and code patterns for intent understanding

---

## Supabase MCP

**Repository:** supabase-community/supabase-mcp
**Documentation:** https://supabase.com/docs/guides/getting-started/mcp

**Purpose:** Official Supabase Model Context Protocol server for database operations and API management

**Key Features:**
- Direct PostgreSQL database access and management
- Migration creation and execution
- Edge Functions deployment and management
- Development branch workflows
- Real-time logs and advisory monitoring
- TypeScript type generation
- Automatic security best practices enforcement

**Installation:**
```bash
npx supabase mcp install
```

**Main Tools:**
- **list_tables**: List all tables in schema(s)
- **execute_sql**: Execute raw SQL queries
- **apply_migration**: Create and apply database migrations (DDL operations)
- **list_migrations**: List all applied migrations
- **deploy_edge_function**: Deploy Edge Functions with JWT verification
- **get_edge_function**: Retrieve Edge Function source code
- **list_edge_functions**: List all Edge Functions
- **get_advisors**: Get security and performance advisories
- **get_logs**: Retrieve logs by service (api, postgres, auth, storage, etc.)
- **create_branch**: Create development branches
- **merge_branch**: Merge branch migrations to production

**Best Use Cases:**
- Database schema development and migrations
- Edge Functions deployment and management
- Security and performance monitoring
- Branch-based development workflows
- PostgreSQL-backed applications

**Security Notes:**
- Uses project-specific service role keys
- Enforces JWT verification on Edge Functions by default
- Provides security advisories and RLS policy recommendations
- Safe for use with AI agents (proper key scoping)

---

## Swiftzilla

**Website:** https://swiftzilla.dev/

**Purpose:** Comprehensive Swift documentation search across Evolution proposals, API Guidelines, and Apple Developer Documentation

**Key Features:**
- Unified search across all official Swift documentation sources
- Swift Evolution Proposals (language features, syntax, SE proposals)
- Swift API Design Guidelines (naming conventions, best practices)
- Apple Developer Documentation (frameworks, APIs, SDK)
- Swift Community Blogs (tutorials, articles from top Swift developers)
- Relevance-ranked results with content excerpts

**Main Tools:**
- **search**: Search Swift documentation with natural language queries
  - Parameters: query (search terms)
  - Returns: Up to 5 most relevant results from all sources with relevance scores

**Query Tips:**
- Be specific: "URLSession dataTask" works better than "networking"
- Include framework names: "SwiftUI List" vs just "List"
- Use technical terms: "async throws" vs "asynchronous error handling"

**Best Use Cases:**
- Finding language feature documentation and Evolution proposals
- Understanding Swift API design conventions
- Looking up Apple framework APIs and methods
- Learning Swift best practices and idioms
- Quick reference during Swift development

---

# Claude Desktop Servers

The following MCP servers are configured for Claude Desktop application.

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