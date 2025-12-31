A comprehensive guide to the Model Context Protocol (MCP) tools and development workflow utilities.

## Table of Contents

### Claude Code Active MCP Servers
1. [ADR Analysis Server](#adr-analysis-server)
2. [Code Guardian Studio](#code-guardian-studio)
3. [Grep MCP](#grep-mcp)
4. [Supabase MCP](#supabase-mcp)
5. [Swiftzilla](#swiftzilla)

### Development Workflow Tools
6. [Beads](#beads) (Claude Code Plugin)
7. [Beads Viewer](#beads-viewer) (Claude Code Plugin)
8. [Semgrep](#semgrep) (CLI Tool + Optional MCP)
9. [Sync MCP Config](#sync-mcp-config) (CLI Tool)
10. [direnv](#direnv) (Environment Manager)

### Multi-Agent Orchestration
10. [Owlex](#owlex) (MCP Server)
11. [Agent Deck](#agent-deck) (Session Manager)

### Claude Desktop Tools
12. [Basic Memory](#basic-memory) (MCP Server)

### Xcode/Agnostic Tools
13. [Themis](#themis) (Swift Package)

---

# Claude Code Active MCP Servers

The following MCP servers are configured and active in Claude Code CLI.

## ADR Analysis Server

**Repository:** https://github.com/tosin2013/mcp-adr-analysis-server

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

**Repository/Article:** https://dev.to/phuongrealmax/building-code-guardian-studio-an-mcp-server-for-ai-powered-code-refactoring-1ice

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

**Repository:** https://github.com/galprz/grep-mcp
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

**Repository:** https://github.com/supabase-community/supabase-mcp
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

# Development Workflow Tools

The following tools support development workflows across different environments.

## Beads

**Repository:** https://github.com/steveyegge/beads

**Implementation:**
- **Claude Code**: Plugin (recommended)
- **Qodo Gen**: MCP Server

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

**Repository:** https://github.com/Dicklesworthstone/beads_viewer

**Implementation:**
- **Claude Code**: Plugin (recommended)
- **Qodo Gen**: MCP Server

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

**TUI Navigation:**

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

---

## Semgrep

**Repository:** https://github.com/semgrep/semgrep
**Website:** https://semgrep.dev
**Documentation:** https://semgrep.dev/docs/
**Rule Registry:** https://semgrep.dev/r
**Slack Community:** https://go.semgrep.dev/slack

**Implementation:** CLI Tool + Optional MCP Server

**Purpose:** Fast, open-source static analysis tool that searches code, finds bugs, and enforces secure guardrails and coding standards using patterns that look like source code

**Key Features:**
- Lightweight static analysis for 30+ languages including Swift
- Semantic grep for code - matches patterns semantically, not just text
- Rules look like the code you write (no ASTs, regex wrestling, or painful DSLs)
- Cross-function and cross-file analysis (Pro version)
- SAST, SCA (Software Composition Analysis), and Secrets scanning
- 5,000+ community and pro rules in the registry
- AI-powered triage with Semgrep Assistant
- Local analysis - code never uploaded by default
- Pre-commit hooks and CI/CD integration
- MCP server for AI agent integration

**Installation:**
```bash
# macOS
brew install semgrep

# Ubuntu/WSL/Linux/macOS via pip
python3 -m pip install semgrep

# Docker
docker run -it -v "${PWD}:/src" semgrep/semgrep semgrep login
docker run -e SEMGREP_APP_TOKEN=<TOKEN> --rm -v "${PWD}:/src" semgrep/semgrep semgrep ci

# Upgrade
brew upgrade semgrep
# or
python3 -m pip install --upgrade semgrep
```

**Core Commands:**
- `semgrep login` - Create account and login for Pro features
- `semgrep ci` - Scan code for vulnerabilities (recommended)
- `semgrep scan --config auto` - Auto-detect and scan with appropriate rules
- `semgrep scan --config p/default` - Scan with default ruleset
- `semgrep scan --config p/security-audit` - Security-focused scan
- `semgrep -e '$X == $X' --lang=py path/to/src` - Interactive pattern search
- `semgrep --test --config rules/ tests/` - Test custom rules

**Swift-Specific Support:**
- **Documentation:** https://semgrep.dev/docs/languages/swift
- Interprocedural analysis (cross-function) with Pro
- SwiftPM package manager support for SCA
- Reachability analysis for dependency vulnerabilities
- License detection and SBOM generation
- Framework-specific Pro rules for comprehensive coverage

**Swift Security Rules (Examples):**
- CWE-477: Use of obsolete function (`ptrace` API forbidden from iOS)
- CWE-327: Broken cryptographic algorithms (MD2, MD5, etc.)
- Certificate Pinning issues
- Biometric Authentication issues
- XXE, SQL Injection, NoSQL Injection
- WebView security issues
- Insecure Storage and Keychain Settings
- Log Injection vulnerabilities

**Community Rule Collections:**

| Repository | Focus | Languages |
|------------|-------|-----------|
| [akabe1-semgrep-rules](https://github.com/akabe1/akabe1-semgrep-rules) | iOS/Swift security, Java, COBOL | Swift, Java, COBOL |
| [OWASP Mobile Rules](https://github.com/insideapp-oss/mobile-application-security-rules) | OWASP MASTG compliance | Swift, Java, Kotlin |
| [Semgrep Registry](https://semgrep.dev/r) | 5,000+ official rules | All supported languages |

**Using Custom Rules:**
```bash
# Run rules from a folder
semgrep --config akabe1-semgrep-rules/ios/swift/

# Run single rule file
semgrep --config rules/swift-insecure-storage.yaml

# Combine with official rules
semgrep --config p/default --config ./custom-rules/
```

**MCP Server Integration (Optional):**

The Semgrep MCP server enables AI agents to scan code for security vulnerabilities.

**Note:** The standalone MCP repo (https://github.com/semgrep/mcp) has been archived and moved to the main semgrep repository.

**MCP Installation:**
```bash
# Python package
uvx semgrep-mcp

# Docker
docker run -i --rm ghcr.io/semgrep/mcp -t stdio

# Hosted server (experimental)
# URL: https://mcp.semgrep.ai/mcp
```

**MCP Configuration (Cursor/Claude Code):**
```json
{
  "mcpServers": {
    "semgrep": {
      "command": "uvx",
      "args": ["semgrep-mcp"],
      "env": {
        "SEMGREP_APP_TOKEN": "<token>"
      }
    }
  }
}
```

**MCP Tools:**
- **security_check**: Scan code for security vulnerabilities
- **semgrep_scan**: Scan code files with a given config string
- **semgrep_scan_with_custom_rule**: Scan using custom Semgrep rules
- **get_abstract_syntax_tree**: Output AST of code
- **semgrep_findings**: Fetch findings from Semgrep AppSec Platform (requires token)
- **supported_languages**: List supported languages
- **semgrep_rule_schema**: Get latest rule JSON Schema

**MCP Prompts:**
- **write_custom_semgrep_rule**: Help write a custom Semgrep rule

**MCP Resources:**
- `semgrep://rule/schema`: Rule YAML syntax specification
- `semgrep://rule/{rule_id}/yaml`: Full rule from registry

**Semgrep Ecosystem:**
- **Semgrep Community Edition (CE)**: Open-source, single-file analysis
- **Semgrep AppSec Platform**: Enterprise SAST, SCA, Secrets with orchestration
- **Semgrep Code (SAST)**: Cross-file/function analysis, Pro rules
- **Semgrep Supply Chain (SSC)**: Reachable dependency vulnerabilities
- **Semgrep Secrets**: Semantic secrets detection with validation
- **Semgrep Assistant (AI)**: Auto-triage and remediation guidance

**Best Use Cases:**
- Security vulnerability scanning (SAST)
- Dependency vulnerability detection (SCA)
- Secrets and credential detection
- Code quality enforcement
- Custom coding standards
- Pre-commit security checks
- CI/CD security gates
- AI-assisted code review with MCP

**Integration with SwiftScan:**

SwiftScan (`swiftscan`) is a wrapper/alias that runs Semgrep with iOS/Swift-specific rules, making it easier to scan Swift projects without remembering complex Semgrep configurations.

**SwiftScan Installation:**
```bash
# Install via Homebrew (recommended)
brew install AikidoSec/tap/swiftscan

# Or install via pip
pip install swiftscan
```

**SwiftScan Commands:**
```bash
# Basic scan (current directory)
swiftscan .

# JSON output (for parsing/automation)
swiftscan . --json

# Scan specific directory
swiftscan /path/to/swift/project

# Scan with verbose output
swiftscan . --verbose

# Show help
swiftscan --help
```

**SwiftScan vs Semgrep Direct:**
| Command | Purpose |
|---------|---------|
| `swiftscan .` | Quick iOS/Swift security scan with curated rules |
| `swiftscan . --json` | Machine-readable output for CI/CD or analysis |
| `semgrep scan --config p/swift` | Direct Semgrep with Swift ruleset |
| `semgrep scan --config auto` | Auto-detect language and apply rules |

**Typical Workflow:**
```bash
# 1. Run SwiftScan for quick security check
swiftscan . --json > security-scan.json

# 2. Review findings
cat security-scan.json | jq '.results[] | {rule: .check_id, file: .path, line: .start.line, message: .extra.message}'

# 3. Create Beads issues for findings
bd create "Fix: <finding description>" -t bug -p 1
```

**Resources:**
- **GitHub:** https://github.com/semgrep/semgrep
- **Swift Documentation:** https://semgrep.dev/docs/languages/swift
- **Rule Registry:** https://semgrep.dev/r
- **Playground:** https://semgrep.dev/editor
- **Academy:** https://academy.semgrep.dev
- **Swift Rules (akabe1):** https://github.com/akabe1/akabe1-semgrep-rules
- **OWASP Mobile Rules:** https://github.com/insideapp-oss/mobile-application-security-rules
- **MCP Server (archived):** https://github.com/semgrep/mcp
- **MCP Hosted:** https://mcp.semgrep.ai

---

## Sync MCP Config

**Repository:** https://github.com/jgrichardson/sync-mcp-cfg

**Implementation:** CLI-agnostic terminal tool

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

## direnv

**Website:** https://direnv.net/
**Repository:** https://github.com/direnv/direnv

**Purpose:** Automatically load and unload environment variables based on the current directory

**Key Features:**
- Automatic environment switching per directory
- .envrc file-based configuration
- Shell-agnostic (bash, zsh, fish, tcsh, etc.)
- Security-focused with allowlist mechanism
- Fast and lightweight
- Extensive stdlib for common patterns
- Integration with version managers (nvm, rbenv, pyenv, etc.)
- Support for layered environments
- No shell wrappers required

**Installation:**
```bash
# macOS
brew install direnv

# Add to shell (bash example)
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc

# Or for zsh
echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
```

**Core Commands:**
- `direnv allow [PATH]` - Allow .envrc to execute (security check)
- `direnv deny [PATH]` - Revoke permission for .envrc
- `direnv reload` - Force reload of the environment
- `direnv edit [PATH]` - Edit and auto-allow .envrc
- `direnv status` - Show current state
- `direnv stdlib` - Show built-in functions

**Example .envrc:**
```bash
# Load environment variables from .env file
dotenv

# Add local bin to PATH
PATH_add bin

# Use specific Node version
use node 18

# Set project-specific variables
export DATABASE_URL=postgresql://localhost/mydb
export API_KEY=dev-key-here

# Load different config based on environment
if [ "$ENVIRONMENT" = "production" ]; then
  export API_URL=https://api.production.com
else
  export API_URL=http://localhost:3000
fi
```

**Best Use Cases:**
- Project-specific environment variables
- Automatic tool version switching (Node, Python, Ruby)
- Per-project PATH modifications
- Development vs production config management
- Sensitive credential isolation per project
- CI/CD environment simulation locally

**Security Notes:**
- .envrc files must be explicitly allowed with `direnv allow`
- Files are SHA-256 hashed; changes require re-allowing
- Prevents malicious code execution from untrusted directories
- Recommended to add .envrc to .gitignore for sensitive data

---

# Multi-Agent Orchestration

The following tools enable multi-agent coordination and session management.

## Owlex

**Repository:** https://github.com/agentic-mcp-tools/owlex

**Implementation:** MCP Server

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

## Agent Deck

**Repository:** https://github.com/asheshgoplani/agent-deck

**Implementation:** Terminal-based Session Manager

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

# Claude Desktop Tools

The following MCP servers are configured for Claude Desktop application.

## Basic Memory

**Repository:** https://github.com/basicmachines-co/basic-memory
**Website:** https://basicmachines.co
**Documentation:** https://memory.basicmachines.co
**Discord:** https://discord.gg/tyvKNccgqN

**Purpose:** Local-first knowledge management system that builds a semantic graph from Markdown files, enabling persistent memory across AI conversations

**Key Features:**
- Local-first knowledge management - Store information as Markdown files you control
- Bi-directional sync - Both humans and LLMs can read and write to the same files
- Knowledge graph navigation - LLMs can follow links between related topics
- Multi-AI platform support - Works with Claude Desktop, VS Code, ChatGPT, Gemini, and others
- Semantic search across your knowledge base
- Optional cloud synchronization with subscription
- Data stored locally in ~/basic-memory directory
- Never re-explain your project to your AI again

**Installation:**
```bash
# Recommended method
uv tool install basic-memory

# Alternative via Smithery
npx -y @smithery/cli install @basicmachines-co/basic-memory --client claude
```

**Configuration for Claude Desktop:**
Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "basic-memory": {
      "command": "uvx",
      "args": ["basic-memory", "mcp"]
    }
  }
}
```

**Core Commands:**
- `basic-memory sync` - One-time sync of local knowledge
- `basic-memory sync --watch` - Real-time synchronization with watch mode
- `basic-memory telemetry disable` - Opt out of anonymous usage tracking
- `basic-memory cloud login` - Authenticate with cloud service
- `basic-memory cloud sync` - Bidirectional cloud synchronization
- `basic-memory cloud mount` - Mount cloud storage for direct access

**Main Tools (MCP):**
- **create_entities**: Store new information in knowledge graph
- **search_nodes**: Semantic search across knowledge base
- **open_nodes**: Open and read specific knowledge nodes
- **get_relations**: Navigate relationships between topics
- **read_graph**: Query the knowledge graph structure

**Best Use Cases:**
- Persistent project context across conversations
- Building a personal/project knowledge base
- Linking related concepts and documentation
- Eliminating repetitive explanations to AI
- Team knowledge sharing (with cloud sync)
- Cross-conversation memory retention

**Current Project:**
- Project: wedding-app-knowledge
- Location: /Users/jessicaclark/Development/nextjs-projects/my-nextjs-app/knowledge

**Cloud Features (Optional):**
- 7-day free trial available at https://basicmemory.com/beta
- 25% early supporter discount
- Bidirectional cloud synchronization
- Team collaboration features

---

# Xcode/Agnostic Tools

The following tools are Swift packages and development utilities for Xcode projects.

## Themis

**Repository:** https://github.com/cossacklabs/themis
**Swift Documentation:** https://docs.cossacklabs.com/themis/languages/swift/
**Installation Guide:** https://docs.cossacklabs.com/themis/languages/swift/installation/
**Swift Examples:** https://github.com/cossacklabs/themis/tree/master/docs/examples/swift
**Swift Package Index:** https://swiftpackageindex.com/cossacklabs/themis

**Purpose:** Cross-platform cryptographic library providing easy-to-use, high-level cryptographic primitives for secure data storage, messaging, and session management

**Key Features:**
- **Secure Cell**: Symmetric encryption for data at rest (AES-256)
- **Secure Message**: Asymmetric encryption and digital signatures for messaging
- **Secure Session**: Stateful session-based encryption with perfect forward secrecy
- **Secure Comparator**: Zero-knowledge proof-based secret comparison
- **Key Generation**: EC and RSA keypair generation, symmetric key generation
- Cross-platform support (14 platforms including iOS, macOS, Android, Web)
- No cryptographic expertise required - high-level APIs
- Unified API across all supported languages
- Apache 2.0 licensed with 1,900+ GitHub stars
- Zero data race safety errors (Swift 6 ready)

**Supported Platforms:**
- macOS 10.12–11+
- iOS 10–14+
- Swift 4 and Swift 5
- visionOS, watchOS, tvOS support

**Installation:**

**Swift Package Manager (Recommended):**
```swift
// In Package.swift or Xcode > File > Add Package Dependencies
dependencies: [
    .package(url: "https://github.com/cossacklabs/themis", from: "0.15.5")
]
```

**CocoaPods:**
```ruby
# In Podfile
pod 'themis'
```

**Carthage:**
```
# In Cartfile
github "cossacklabs/themis"

# Then run
carthage update --use-xcframeworks
```

**Import:**
```swift
import themis
```

---

### Cryptographic Primitives

#### 1. Key Generation

**Asymmetric Keypairs (EC or RSA):**
```swift
// Generate EC keypair (recommended for most use cases)
let keypair = TSKeyGen(algorithm: .EC)!
let privateKey: Data = keypair.privateKey!
let publicKey: Data = keypair.publicKey!

// Generate RSA keypair (for legacy compatibility)
let rsaKeypair = TSKeyGen(algorithm: .RSA)!
```

**Symmetric Keys:**
```swift
// Generate AES-256 symmetric key
let masterKey: Data = TSGenerateSymmetricKey()!
```

#### 2. Secure Cell (Data at Rest)

**Seal Mode (Recommended):**
```swift
// With symmetric key
let symmetricKey = TSGenerateSymmetricKey()!
let cell = TSCellSeal(key: symmetricKey)!

// Or with passphrase (uses KDF internally)
let cell = TSCellSeal(passphrase: "user-password")!

// Encrypt
let plaintext: Data = "Sensitive wedding data".data(using: .utf8)!
let context: Data = "guest-list-v1".data(using: .utf8)!  // Optional context
let encrypted: Data = try! cell.encrypt(plaintext, context: context)

// Decrypt
let decrypted = try? cell.decrypt(encrypted, context: context)
```

**Token Protect Mode (Fixed-length output):**
```swift
let cell = TSCellToken(key: symmetricKey)!

// Encrypt - returns separate encrypted data and auth token
let result = try! cell.encrypt(plaintext, context: context)
let encrypted: Data = result.encrypted  // Same length as plaintext
let authToken: Data = result.token      // Store separately

// Decrypt - requires both encrypted data and token
let decrypted = try? cell.decrypt(encrypted, token: authToken, context: context)
```

**Context Imprint Mode (Length-preserving, no auth tag):**
```swift
let cell = TSCellContextImprint(key: symmetricKey)!

// Context is REQUIRED in this mode
let encrypted = try! cell.encrypt(plaintext, context: context)
// encrypted.count == plaintext.count

// Decrypt - no automatic integrity verification
let decrypted = try! cell.decrypt(encrypted, context: context)
```

#### 3. Secure Message (Authenticated Messaging)

**Signature Mode (Sign/Verify):**
```swift
// Sender signs with private key
let senderKeypair = TSKeyGen(algorithm: .EC)!
let signer = TSMessage(inSignVerifyModeWithPrivateKey: senderKeypair.privateKey,
                       peerPublicKey: nil)!
let signedMessage = try! signer.wrap(message)

// Recipient verifies with sender's public key
let verifier = TSMessage(inSignVerifyModeWithPrivateKey: nil,
                         peerPublicKey: senderKeypair.publicKey)!
let verified = try? verifier.unwrapData(signedMessage)
```

**Encryption Mode (Encrypt/Decrypt):**
```swift
// Alice encrypts for Bob
let aliceKeypair = TSKeyGen(algorithm: .EC)!
let bobKeypair = TSKeyGen(algorithm: .EC)!

let aliceMessage = TSMessage(inEncryptModeWithPrivateKey: aliceKeypair.privateKey,
                             peerPublicKey: bobKeypair.publicKey)!
let encrypted = try! aliceMessage.wrap(message)

// Bob decrypts from Alice
let bobMessage = TSMessage(inEncryptModeWithPrivateKey: bobKeypair.privateKey,
                           peerPublicKey: aliceKeypair.publicKey)!
let decrypted = try? bobMessage.unwrapData(encrypted)
```

#### 4. Secure Session (Perfect Forward Secrecy)

```swift
// Callback for peer public key lookup
final class SessionCallbacks: TSSessionTransportInterface {
    private let knownPeers: [Data: Data]  // peerID -> publicKey
    
    override func publicKey(for peerID: Data) throws -> Data? {
        return knownPeers[peerID]
    }
}

// Initialize session
let myID: Data = "alice".data(using: .utf8)!
let myPrivateKey: Data = keypair.privateKey!
let callbacks = SessionCallbacks(knownPeers: peerDatabase)

let session = TSSession(userId: myID, privateKey: myPrivateKey,
                        callbacks: callbacks)!

// Client initiates connection
let negotiationMessage = try! session.connectRequest()
sendToPeer(negotiationMessage)

// Both parties negotiate until established
while !session.isSessionEstablished() {
    let request = receiveFromPeer()
    if let reply = try? session.unwrapData(request) {
        sendToPeer(reply)
    }
}

// Exchange encrypted messages
let encrypted = try! session.wrap(message)
let decrypted = try? session.unwrapData(receivedMessage)
```

#### 5. Secure Comparator (Zero-Knowledge Proof)

```swift
// Both parties initialize with their secret
let secret: Data = "shared-wedding-code".data(using: .utf8)!
let comparator = TSComparator(messageToCompare: secret)!

// Client initiates
let initialMessage = try! comparator.beginCompare()
sendToPeer(initialMessage)

// Exchange messages until comparison complete
while comparator.status() == .comparatorNotReady {
    let message = receiveFromPeer()
    if let response = try? comparator.proceedCompare(message) {
        sendToPeer(response)
    }
}

// Check result
if comparator.status() == .comparatorMatch {
    // Secrets match - grant access
} else {
    // Secrets don't match - deny access
}
```

---

### I Do Blueprint Use Cases

#### 1. Encrypting Sensitive Wedding Data at Rest

**Secure Cell for Local Storage:**
```swift
// WeddingDataEncryptionService.swift
import themis

actor WeddingDataEncryptionService {
    private let masterKey: Data
    private let cell: TSCellSeal
    
    init() throws {
        // Load or generate master key from Keychain
        if let existingKey = KeychainManager.shared.getData(forKey: "wedding_master_key") {
            self.masterKey = existingKey
        } else {
            self.masterKey = TSGenerateSymmetricKey()!
            try KeychainManager.shared.save(masterKey, forKey: "wedding_master_key")
        }
        self.cell = TSCellSeal(key: masterKey)!
    }
    
    /// Encrypt sensitive guest data before local caching
    func encryptGuestData(_ guest: Guest) throws -> Data {
        let encoder = JSONEncoder()
        let plaintext = try encoder.encode(guest)
        let context = "guest_\(guest.id.uuidString)".data(using: .utf8)!
        return try cell.encrypt(plaintext, context: context)
    }
    
    /// Decrypt guest data from local cache
    func decryptGuestData(_ encrypted: Data, guestId: UUID) throws -> Guest {
        let context = "guest_\(guestId.uuidString)".data(using: .utf8)!
        let decrypted = try cell.decrypt(encrypted, context: context)
        return try JSONDecoder().decode(Guest.self, from: decrypted)
    }
    
    /// Encrypt budget information
    func encryptBudgetData(_ budget: BudgetSummary, coupleId: UUID) throws -> Data {
        let plaintext = try JSONEncoder().encode(budget)
        let context = "budget_\(coupleId.uuidString)".data(using: .utf8)!
        return try cell.encrypt(plaintext, context: context)
    }
    
    /// Encrypt vendor contract details
    func encryptVendorContract(_ contract: VendorContract) throws -> Data {
        let plaintext = try JSONEncoder().encode(contract)
        let context = "contract_\(contract.vendorId.uuidString)".data(using: .utf8)!
        return try cell.encrypt(plaintext, context: context)
    }
}
```

#### 2. Secure Collaborator Invitation Links

**Secure Message for Invitation Tokens:**
```swift
// CollaboratorInvitationCrypto.swift
import themis

struct CollaboratorInvitationCrypto {
    private let serverPublicKey: Data  // From Supabase Edge Function
    private let appKeypair: TSKeyGen
    
    init(serverPublicKey: Data) {
        self.serverPublicKey = serverPublicKey
        self.appKeypair = TSKeyGen(algorithm: .EC)!
    }
    
    /// Create encrypted invitation payload
    func createSecureInvitation(
        coupleId: UUID,
        inviteeEmail: String,
        role: CollaboratorRole,
        expiresAt: Date
    ) throws -> SecureInvitation {
        let payload = InvitationPayload(
            coupleId: coupleId,
            inviteeEmail: inviteeEmail,
            role: role,
            expiresAt: expiresAt,
            nonce: UUID().uuidString
        )
        
        let message = TSMessage(
            inEncryptModeWithPrivateKey: appKeypair.privateKey,
            peerPublicKey: serverPublicKey
        )!
        
        let plaintext = try JSONEncoder().encode(payload)
        let encrypted = try message.wrap(plaintext)
        
        return SecureInvitation(
            encryptedPayload: encrypted.base64EncodedString(),
            appPublicKey: appKeypair.publicKey!.base64EncodedString()
        )
    }
    
    /// Verify invitation signature from server
    func verifyInvitationResponse(_ signedResponse: Data) throws -> InvitationResponse {
        let verifier = TSMessage(
            inSignVerifyModeWithPrivateKey: nil,
            peerPublicKey: serverPublicKey
        )!
        
        let verified = try verifier.unwrapData(signedResponse)
        return try JSONDecoder().decode(InvitationResponse.self, from: verified)
    }
}
```

#### 3. Secure Real-time Collaboration Sessions

**Secure Session for Collaborator Communication:**
```swift
// CollaborationSessionManager.swift
import themis

actor CollaborationSessionManager {
    private var sessions: [UUID: TSSession] = [:]
    private let myKeypair: TSKeyGen
    private let callbacks: CollaboratorCallbacks
    
    init(collaboratorKeys: [UUID: Data]) {
        self.myKeypair = TSKeyGen(algorithm: .EC)!
        self.callbacks = CollaboratorCallbacks(knownCollaborators: collaboratorKeys)
    }
    
    /// Establish secure session with collaborator
    func establishSession(with collaboratorId: UUID) async throws -> Data {
        let myId = "app_\(UUID().uuidString)".data(using: .utf8)!
        let session = TSSession(
            userId: myId,
            privateKey: myKeypair.privateKey!,
            callbacks: callbacks
        )!
        
        sessions[collaboratorId] = session
        return try session.connectRequest()
    }
    
    /// Process session negotiation message
    func processNegotiation(from collaboratorId: UUID, message: Data) throws -> Data? {
        guard let session = sessions[collaboratorId] else {
            throw CollaborationError.sessionNotFound
        }
        return try session.unwrapData(message)
    }
    
    /// Check if session is established
    func isSessionEstablished(with collaboratorId: UUID) -> Bool {
        sessions[collaboratorId]?.isSessionEstablished() ?? false
    }
    
    /// Send encrypted activity update
    func encryptActivityUpdate(_ activity: ActivityEvent, to collaboratorId: UUID) throws -> Data {
        guard let session = sessions[collaboratorId],
              session.isSessionEstablished() else {
            throw CollaborationError.sessionNotEstablished
        }
        
        let plaintext = try JSONEncoder().encode(activity)
        return try session.wrap(plaintext)
    }
    
    /// Decrypt received activity update
    func decryptActivityUpdate(_ encrypted: Data, from collaboratorId: UUID) throws -> ActivityEvent {
        guard let session = sessions[collaboratorId] else {
            throw CollaborationError.sessionNotFound
        }
        
        let decrypted = try session.unwrapData(encrypted)
        return try JSONDecoder().decode(ActivityEvent.self, from: decrypted)
    }
}

final class CollaboratorCallbacks: TSSessionTransportInterface {
    private let knownCollaborators: [UUID: Data]
    
    init(knownCollaborators: [UUID: Data]) {
        self.knownCollaborators = knownCollaborators
        super.init()
    }
    
    override func publicKey(for peerID: Data) throws -> Data? {
        guard let idString = String(data: peerID, encoding: .utf8),
              let uuid = UUID(uuidString: idString.replacingOccurrences(of: "collaborator_", with: "")) else {
            return nil
        }
        return knownCollaborators[uuid]
    }
}
```

#### 4. Secure Vendor Access Codes

**Secure Comparator for Vendor Verification:**
```swift
// VendorAccessVerification.swift
import themis

actor VendorAccessVerification {
    /// Verify vendor has correct access code without revealing it
    func verifyVendorAccess(
        vendorProvidedCode: String,
        expectedCodeHash: String,
        via channel: AsyncChannel<Data>
    ) async throws -> Bool {
        let secret = vendorProvidedCode.data(using: .utf8)!
        let comparator = TSComparator(messageToCompare: secret)!
        
        // Initiate comparison
        let initialMessage = try comparator.beginCompare()
        await channel.send(initialMessage)
        
        // Exchange messages until comparison complete
        while comparator.status() == .comparatorNotReady {
            let response = await channel.receive()
            if let reply = try? comparator.proceedCompare(response) {
                await channel.send(reply)
            }
        }
        
        return comparator.status() == .comparatorMatch
    }
}
```

#### 5. Encrypting Cached Repository Data

**Integration with RepositoryCache:**
```swift
// SecureRepositoryCache.swift
import themis

actor SecureRepositoryCache {
    private let cache: RepositoryCache
    private let encryptionService: WeddingDataEncryptionService
    
    init(cache: RepositoryCache, encryptionService: WeddingDataEncryptionService) {
        self.cache = cache
        self.encryptionService = encryptionService
    }
    
    /// Store encrypted data in cache
    func setSecure<T: Codable>(_ key: String, value: T, ttl: TimeInterval) async throws {
        let plaintext = try JSONEncoder().encode(value)
        let context = "cache_\(key)".data(using: .utf8)!
        
        let cell = TSCellSeal(key: try await getOrCreateCacheKey())!
        let encrypted = try cell.encrypt(plaintext, context: context)
        
        await cache.set(key, value: encrypted, ttl: ttl)
    }
    
    /// Retrieve and decrypt data from cache
    func getSecure<T: Codable>(_ key: String, maxAge: TimeInterval) async throws -> T? {
        guard let encrypted: Data = await cache.get(key, maxAge: maxAge) else {
            return nil
        }
        
        let context = "cache_\(key)".data(using: .utf8)!
        let cell = TSCellSeal(key: try await getOrCreateCacheKey())!
        let decrypted = try cell.decrypt(encrypted, context: context)
        
        return try JSONDecoder().decode(T.self, from: decrypted)
    }
    
    private func getOrCreateCacheKey() async throws -> Data {
        if let key = KeychainManager.shared.getData(forKey: "cache_encryption_key") {
            return key
        }
        let newKey = TSGenerateSymmetricKey()!
        try KeychainManager.shared.save(newKey, forKey: "cache_encryption_key")
        return newKey
    }
}
```

#### 6. Secure Document Storage

**Encrypting Wedding Documents:**
```swift
// SecureDocumentService.swift
import themis

actor SecureDocumentService {
    private let masterKey: Data
    
    init(masterKey: Data) {
        self.masterKey = masterKey
    }
    
    /// Encrypt document before uploading to Supabase Storage
    func encryptDocument(_ document: WeddingDocument) throws -> EncryptedDocument {
        let cell = TSCellSeal(key: masterKey)!
        
        // Use document ID as context for additional security
        let context = "doc_\(document.id.uuidString)_\(document.coupleId.uuidString)".data(using: .utf8)!
        
        let encryptedContent = try cell.encrypt(document.content, context: context)
        let encryptedMetadata = try cell.encrypt(
            JSONEncoder().encode(document.metadata),
            context: context
        )
        
        return EncryptedDocument(
            id: document.id,
            coupleId: document.coupleId,
            encryptedContent: encryptedContent,
            encryptedMetadata: encryptedMetadata,
            contentHash: SHA256.hash(data: document.content).description
        )
    }
    
    /// Decrypt document after downloading from Supabase Storage
    func decryptDocument(_ encrypted: EncryptedDocument) throws -> WeddingDocument {
        let cell = TSCellSeal(key: masterKey)!
        let context = "doc_\(encrypted.id.uuidString)_\(encrypted.coupleId.uuidString)".data(using: .utf8)!
        
        let content = try cell.decrypt(encrypted.encryptedContent, context: context)
        let metadataData = try cell.decrypt(encrypted.encryptedMetadata, context: context)
        let metadata = try JSONDecoder().decode(DocumentMetadata.self, from: metadataData)
        
        return WeddingDocument(
            id: encrypted.id,
            coupleId: encrypted.coupleId,
            content: content,
            metadata: metadata
        )
    }
}
```

---

### Security Best Practices

1. **Key Management:**
   - Store symmetric keys in Keychain, never in UserDefaults or plain files
   - Use separate keys for different data categories (guests, budget, documents)
   - Rotate keys periodically for long-lived data

2. **Context Usage:**
   - Always use context/associated data with Secure Cell
   - Include entity IDs and version info in context
   - Context prevents data from being decrypted in wrong context

3. **Error Handling:**
   ```swift
   do {
       let decrypted = try cell.decrypt(encrypted, context: context)
   } catch {
       AppLogger.security.error("Decryption failed - possible tampering", error: error)
       SentryService.shared.captureError(error, context: ["operation": "decrypt"])
       throw SecurityError.decryptionFailed
   }
   ```

4. **Secure Session Lifecycle:**
   - Establish new sessions for each collaboration period
   - Don't reuse session keys across app launches
   - Implement session timeout for inactive collaborators

5. **App Store Compliance:**
   - Themis uses encryption, requiring US export compliance declaration
   - See: https://docs.cossacklabs.com/themis/regulations/us-crypto-regulations/
   - Select "Yes" for encryption in App Store Connect

---

### Integration with Existing Architecture

**Repository Pattern Integration:**
```swift
// LiveGuestRepository+Encryption.swift
extension LiveGuestRepository {
    /// Fetch and decrypt guests from encrypted cache
    func fetchGuestsSecure() async throws -> [Guest] {
        let cacheKey = "guests_encrypted_\(tenantId.uuidString)"
        
        // Try encrypted cache first
        if let cached: [Guest] = try? await secureCache.getSecure(cacheKey, maxAge: 60) {
            return cached
        }
        
        // Fetch from Supabase (data is encrypted at rest by Supabase)
        let guests = try await fetchGuests()
        
        // Cache with client-side encryption
        try? await secureCache.setSecure(cacheKey, value: guests, ttl: 60)
        
        return guests
    }
}
```

**Store Integration:**
```swift
// GuestStoreV2+Security.swift
extension GuestStoreV2 {
    /// Export guest list with encryption
    func exportGuestListSecure(password: String) async throws -> Data {
        let cell = TSCellSeal(passphrase: password)!
        let guestData = try JSONEncoder().encode(guests)
        return try cell.encrypt(guestData)
    }
    
    /// Import encrypted guest list
    func importGuestListSecure(_ encrypted: Data, password: String) async throws {
        let cell = TSCellSeal(passphrase: password)!
        let decrypted = try cell.decrypt(encrypted)
        let importedGuests = try JSONDecoder().decode([Guest].self, from: decrypted)
        // Process imported guests...
    }
}
```

---

### Resources

- **GitHub:** https://github.com/cossacklabs/themis
- **Swift Documentation:** https://docs.cossacklabs.com/themis/languages/swift/
- **Features Guide:** https://docs.cossacklabs.com/themis/languages/swift/features/
- **Installation:** https://docs.cossacklabs.com/themis/languages/swift/installation/
- **Swift Examples:** https://github.com/cossacklabs/themis/tree/master/docs/examples/swift
- **Swift Package Index:** https://swiftpackageindex.com/cossacklabs/themis
- **Cryptography Theory:** https://docs.cossacklabs.com/themis/crypto-theory/
- **Key Management:** https://docs.cossacklabs.com/themis/crypto-theory/key-management/
- **US Export Regulations:** https://docs.cossacklabs.com/themis/regulations/us-crypto-regulations/
- **Security Whitepaper:** https://www.cossacklabs.com/files/secure-comparator-paper-rev12.pdf

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

### For Environment Management:
1. Use **direnv** for project-specific environment variables
2. Configure .envrc with API keys, database URLs, and tool versions
3. Environment auto-loads when entering project directory
4. Supports layered configs for development/staging/production

### For Knowledge Management & Memory:
1. Use **Basic Memory** in Claude Desktop for persistent project context
2. Store architectural decisions, patterns, and project-specific knowledge
3. Build a semantic knowledge graph that links related concepts
4. Eliminate repetitive explanations across conversations
5. Sync knowledge with `basic-memory sync --watch` for real-time updates
6. Optional cloud sync for team collaboration

---

## Summary Table

| Tool | Type | Primary Purpose | Best For |
|------|------|-----------------|----------|
| **ADR Analysis** | MCP Server | Architectural decision records | ADR-driven development, deployment validation |
| **Code Guardian** | MCP Server | Code quality & refactoring | Quality enforcement, automated fixes |
| **Grep MCP** | MCP Server | Semantic code search | Large codebase exploration, pattern finding |
| **Semgrep** | CLI + MCP Server | Static analysis & security scanning | SAST, SCA, secrets detection, Swift security |
| **Supabase MCP** | MCP Server | Database operations | Supabase development, migrations, Edge Functions |
| **Swiftzilla** | MCP Server | Swift documentation search | Swift development, API lookup |
| **Beads** | Plugin/MCP | Task tracking | Persistent task memory, dependency graphs |
| **Beads Viewer** | Plugin/MCP | Task visualization | Triage, planning, graph-aware metrics |
| **Sync MCP Config** | CLI Tool | Configuration management | Managing MCPs across clients |
| **direnv** | Environment Manager | Auto-load environment variables | Per-project configuration, version switching |
| **Owlex** | MCP Server | Multi-agent orchestration | Agent councils, cross-agent critique |
| **Agent Deck** | Session Manager | AI session management | Running multiple agents, dynamic MCP toggling |
| **Basic Memory** | MCP Server | Knowledge graph memory | Persistent context, project knowledge base |
| **Themis** | Swift Package | Cryptographic primitives | Data encryption, secure messaging, session security |

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

# 7. Setup environment for project
echo "export DATABASE_URL=postgresql://localhost/mydb" > .envrc
direnv allow

# 8. Enable persistent memory (Claude Desktop)
basic-memory sync --watch
```
