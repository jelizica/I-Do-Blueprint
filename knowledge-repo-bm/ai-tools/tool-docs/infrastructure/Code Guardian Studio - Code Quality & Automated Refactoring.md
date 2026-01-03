---
title: Code Guardian Studio - Code Quality & Automated Refactoring
type: note
permalink: ai-tools/infrastructure/code-guardian-studio-code-quality-automated-refactoring
tags:
- mcp
- infrastructure
- code-quality
- refactoring
- technical-debt
- workflow
- memory
- guards
- analysis
---

# Code Guardian Studio - Code Quality & Automated Refactoring

## Overview

**Category**: Infrastructure  
**Status**: ✅ Active - Code Quality Tool  
**Installation**: `npm install -g codeguardian-studio`  
**CLI Command**: `ccg`  
**Repository**: https://github.com/phuongrealmax/code-guardian  
**Website**: https://codeguardian.studio  
**Case Study**: https://codeguardian.studio/case-study  
**npm**: https://www.npmjs.com/package/codeguardian-studio  
**MCP Directory**: https://mcp.so/server/code-guardian  
**License**: MIT (open-core)  
**Agent Attachment**: Qodo Gen (MCP), Claude Code (MCP)

---

## What It Does

Code Guardian Studio (CCG) is an MCP server that transforms Claude Code into an intelligent refactoring assistant. It scans your codebase, identifies code hotspots (files with complexity and maintainability issues), generates detailed optimization reports, and helps you refactor safely with persistent memory, workflow management, and guard rules.

### Core Philosophy

CCG stands out as the **most comprehensive MCP server** for Claude Code with **113+ MCP tools**, addressing the full software refactoring lifecycle from analysis to execution. Unlike simple code scanners or basic guard systems, CCG provides:

- **All-in-one solution**: Guard + Metrics + Workflow + Memory in a single server
- **Session management**: Resume work across conversations without losing context
- **Real-time progress**: Track refactoring progress with live dashboard
- **Latent Chain reasoning**: Multi-phase reasoning for complex refactoring tasks
- **Proven results**: Dogfooded on itself (68,000 lines analyzed, 212 files scanned, 20 hotspots found in <1 minute)

### Key Differentiators vs Competitors

| Feature | CCG | Guardrails AI | NeMo | Semgrep MCP |
|---------|-----|---------------|------|-------------|
| **MCP Tools** | 113+ | - | - | ~10 |
| **Code Analysis** | ✅ | ❌ | ❌ | ✅ |
| **Hotspot Detection** | ✅ | ❌ | ❌ | ❌ |
| **Workflow Management** | ✅ | ❌ | ❌ | ❌ |
| **Session Persistence** | ✅ | ❌ | ❌ | ❌ |
| **Memory System** | ✅ | ❌ | ❌ | ❌ |
| **Progress Dashboard** | ✅ | ❌ | ❌ | ❌ |
| **Latent Chain Reasoning** | ✅ | ❌ | ❌ | ❌ |
| **Guard Rules** | ✅ | ✅ | ✅ | ✅ |

**See full comparison**: https://github.com/phuongrealmax/code-guardian/blob/master/docs/COMPARISON.md

---

## Architecture

CCG is built on a modular architecture with specialized modules for different aspects of code quality:

```
Code Guardian Studio (CCG)
├── Code Optimizer (8 tools)       # Code analysis & hotspot detection
├── Memory System (15+ tools)      # Persistent context across sessions
├── Guard Rules (10+ tools)        # Dangerous pattern blocking
├── Workflow Management (20+ tools) # Task tracking & dependencies
├── Latent Chain (15+ tools)       # Multi-phase reasoning
├── Agents (10+ tools)             # Specialized agent coordination
├── Thinking (5+ tools)            # Structured reasoning models
├── Documents (8+ tools)           # Documentation management
└── Testing (6+ tools)             # Test runner integration
```

**Total**: 113+ MCP tools

---

## Key Features

### 1. Code Optimizer (8 Tools)

The Code Optimizer module is CCG's core analysis engine. It scans your codebase, calculates complexity metrics, identifies hotspots, and generates actionable refactoring plans.

#### `code_scan_repository`

**Purpose**: Map your entire codebase structure.

**What it does**:
- Recursively scans all files in the repository
- Identifies file types (JavaScript, TypeScript, Python, etc.)
- Measures file sizes and line counts
- Detects directory structure
- Returns structured JSON for further analysis

**Example Output**:
```json
{
  "total_files": 212,
  "total_lines": 68000,
  "file_types": {
    "typescript": 145,
    "javascript": 32,
    "json": 25,
    "markdown": 10
  },
  "largest_files": [
    {"path": "src/legacy/parser.ts", "lines": 850},
    {"path": "src/utils/helpers.ts", "lines": 620}
  ]
}
```

**Use Case**: Initial codebase assessment, understanding project structure.

---

#### `code_metrics`

**Purpose**: Calculate detailed complexity, nesting depth, and branch scores per file.

**What it does**:
- **Cyclomatic Complexity**: Number of independent paths through code
- **Nesting Depth**: Maximum level of nested blocks (if/for/while)
- **Branching Score**: Number of decision points (if/else, switch, ternary)
- **Per-file metrics**: Individual file analysis
- **Aggregate metrics**: Repository-wide statistics

**Metrics Explained**:
- **Complexity > 10**: High complexity, hard to understand
- **Nesting > 4**: Deep nesting, consider extracting functions
- **Branching > 5**: Too many decision points, consider simplification

**Example Output**:
```json
{
  "files": [
    {
      "path": "src/legacy/parser.ts",
      "complexity": 35,
      "nesting": 7,
      "branching": 18,
      "lines": 850
    }
  ],
  "averages": {
    "complexity": 8.2,
    "nesting": 2.5,
    "branching": 4.1
  }
}
```

**Use Case**: Identifying maintainability issues, tracking code quality trends.

---

#### `code_hotspots`

**Purpose**: Identify files that need immediate attention.

**What it does**:
- Calculates **hotspot score** = (complexity × 0.4) + (nesting × 0.3) + (size × 0.3)
- Ranks files from highest to lowest score
- Highlights top 10-20 refactoring priorities
- Provides reasoning for each hotspot

**Hotspot Score Interpretation**:
- **Score > 8.0**: Critical - refactor immediately
- **Score 6.0-8.0**: High - schedule refactoring soon
- **Score 4.0-6.0**: Medium - consider refactoring
- **Score < 4.0**: Low - acceptable for now

**Example Output**:
```
Top Hotspots:
1. src/legacy/parser.ts (score: 8.5)
   - 850 lines, cyclomatic complexity: 35, nesting depth: 7
   - Suggested: Split into smaller modules, extract helper functions

2. src/utils/helpers.ts (score: 7.2)
   - 620 lines, cyclomatic complexity: 28, nesting depth: 6
   - Suggested: Group related utilities, reduce branching
```

**Use Case**: Prioritizing refactoring efforts, focusing on highest-impact improvements.

---

#### `code_refactor_plan`

**Purpose**: Generate step-by-step refactoring plans.

**What it does**:
- Analyzes hotspot files
- Suggests specific refactoring strategies
- Provides dependency analysis
- Breaks down complex refactors into incremental steps

**Refactoring Strategies**:
- **Extract Function**: Pull out complex logic into separate functions
- **Split Module**: Divide large files into smaller, focused modules
- **Reduce Nesting**: Flatten nested if/else structures with early returns
- **Simplify Branching**: Replace complex conditionals with polymorphism or strategy pattern

**Example Plan**:
```markdown
## Refactor Plan: src/legacy/parser.ts

**Current Issues**:
- 850 lines (target: <300 per file)
- Cyclomatic complexity: 35 (target: <10)
- Nesting depth: 7 (target: <4)

**Incremental Steps**:

### Phase 1: Extract Helper Functions
1. Extract `validateInput()` (lines 50-120)
2. Extract `parseTokens()` (lines 150-240)
3. Extract `buildAST()` (lines 300-450)

### Phase 2: Split into Modules
1. Create `parser-validators.ts` for validation logic
2. Create `parser-tokenizer.ts` for tokenization
3. Create `parser-ast.ts` for AST building
4. Keep orchestration in main `parser.ts`

### Phase 3: Reduce Nesting
1. Replace nested if/else with early returns
2. Use guard clauses for validation
3. Flatten error handling with early exits

**Expected Outcome**:
- 4 files ~200 lines each instead of 1 file 850 lines
- Complexity reduced from 35 to ~8 per file
- Nesting reduced from 7 to ~3 per file
```

**Use Case**: Planning complex refactoring work, breaking down large tasks.

---

#### `code_record_optimization`

**Purpose**: Log optimization sessions for historical tracking.

**What it does**:
- Records before/after metrics
- Tracks refactoring sessions with timestamps
- Maintains optimization history
- Enables trend analysis

**Stored Data**:
- Session ID and timestamp
- Files refactored
- Metrics before refactoring
- Metrics after refactoring
- Time spent
- Notes/comments

**Example Record**:
```json
{
  "session_id": "refactor-parser-2025-12-30",
  "timestamp": "2025-12-30T10:30:00Z",
  "files": ["src/legacy/parser.ts"],
  "before": {
    "complexity": 35,
    "nesting": 7,
    "lines": 850
  },
  "after": {
    "complexity": 8,
    "nesting": 3,
    "lines": 220
  },
  "duration_minutes": 180,
  "notes": "Split into 4 modules, extracted helpers, reduced nesting"
}
```

**Use Case**: Demonstrating refactoring impact, tracking team progress over time.

---

#### `code_generate_report`

**Purpose**: Create shareable Markdown reports.

**What it does**:
- Generates comprehensive Markdown reports
- Includes metrics, hotspots, recommendations
- Provides visualizations (tables, charts)
- Ready for sharing with team or stakeholders

**Report Sections**:
1. **Executive Summary**: High-level metrics, key findings
2. **Hotspot Analysis**: Top 10 files needing attention
3. **Metrics Overview**: Repository-wide statistics
4. **Refactoring Recommendations**: Prioritized action items
5. **Appendix**: Detailed per-file metrics

**Example Report Snippet**:
```markdown
# Code Quality Report
**Generated**: 2025-12-30 10:45 AM
**Repository**: I Do Blueprint

## Executive Summary
- **Total Files**: 212
- **Total Lines**: 68,000
- **Hotspots Identified**: 20
- **Average Complexity**: 8.2
- **Critical Files**: 5 (require immediate refactoring)

## Top Hotspots
| File | Score | Complexity | Nesting | Lines |
|------|-------|------------|---------|-------|
| src/legacy/parser.ts | 8.5 | 35 | 7 | 850 |
| src/utils/helpers.ts | 7.2 | 28 | 6 | 620 |

## Recommendations
1. **Immediate**: Refactor src/legacy/parser.ts (split into 4 modules)
2. **High Priority**: Simplify src/utils/helpers.ts (group utilities)
3. **Medium Priority**: Review src/api/routes.ts (reduce branching)
```

**Use Case**: Documenting refactoring needs, justifying engineering time, tracking progress.

---

#### `code_quick_analysis`

**Purpose**: Fastest way to analyze a codebase (combines scan + metrics + hotspots).

**What it does**:
- Runs `code_scan_repository`
- Calculates `code_metrics`
- Identifies `code_hotspots`
- Returns all results in one call

**When to Use**:
- Initial project assessment
- Quick health check
- Demonstrating code quality to stakeholders
- Starting a refactoring session

**Example Usage (Claude Code)**:
```
User: Analyze my codebase for refactoring priorities
Claude: [calls code_quick_analysis]

Result:
- Repository: 212 files, 68,000 lines
- Top hotspot: src/legacy/parser.ts (score: 8.5)
- Recommended: Split parser.ts into smaller modules
- Next steps: Review refactor plan for parser.ts
```

**Use Case**: Fast codebase assessment, identifying immediate priorities.

---

#### `code_optimizer_status`

**Purpose**: Check Code Optimizer module status.

**What it does**:
- Reports on tool availability
- Shows active analysis sessions
- Displays configuration settings
- Verifies CCG installation

**Example Output**:
```json
{
  "status": "active",
  "tools_available": 8,
  "active_sessions": 1,
  "last_analysis": "2025-12-30T10:30:00Z",
  "config": {
    "project_path": "/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint",
    "language_support": ["typescript", "javascript", "python"],
    "metrics_enabled": true
  }
}
```

**Use Case**: Troubleshooting CCG installation, verifying setup.

---

### 2. Memory System (15+ Tools)

**Purpose**: Persistent storage across sessions for decisions, patterns, and context.

The Memory System enables CCG to remember:
- Code patterns and conventions
- Similar errors and their fixes
- Architectural decisions
- Team preferences and style guides

**How it Works**:
- Stores key-value pairs in local SQLite database
- Persists across Claude Code sessions
- Searchable and retrievable
- No data sent to external servers (fully local)

**Example Use Cases**:

**1. Code Conventions**:
```
Store: "always use async/await, not callbacks"
Recall: When reviewing new code, suggest async/await if callbacks detected
```

**2. Bug Fixes**:
```
Store: "bug in parser.ts fixed by adding null check on line 150"
Recall: When similar parser errors occur, suggest null check pattern
```

**3. Architectural Decisions**:
```
Store: "team prefers functional style for utilities, OOP for components"
Recall: When writing new utilities, default to functional approach
```

**4. Dependencies**:
```
Store: "avoid library X due to security vulnerabilities, use library Y instead"
Recall: When library X is suggested, recommend library Y
```

**Memory Tools** (examples):
- `memory_store`: Save key-value pair
- `memory_retrieve`: Get value by key
- `memory_search`: Search memory by keyword
- `memory_list`: List all stored memories
- `memory_delete`: Remove obsolete memories

**Integration with Other Modules**:
- **Code Optimizer**: Remembers past refactoring decisions
- **Guard Rules**: Stores custom rule configurations
- **Workflow**: Recalls task context and progress

**Use Case**: Long-term refactoring projects, maintaining consistency across sessions.

---

### 3. Guard Rules (10+ Tools)

**Purpose**: Validate code before commits, catch dangerous patterns.

Guard Rules act as a safety net, blocking code that violates security, quality, or team standards before it reaches version control.

**Built-in Guard Rules**:

**1. Fake Tests**:
- Detects empty test bodies
- Catches always-passing assertions (e.g., `expect(true).toBe(true)`)
- Identifies tests without meaningful logic

**Example**:
```typescript
// ❌ Blocked by Guard
test('should validate user input', () => {
  // Empty test body
})

// ❌ Blocked by Guard
test('should process data', () => {
  expect(true).toBe(true) // Always passes
})

// ✅ Allowed
test('should validate email format', () => {
  const result = validateEmail('test@example.com')
  expect(result).toBe(true)
})
```

**2. Empty Catch Blocks**:
- Detects `catch` blocks without error handling
- Flags swallowed exceptions
- Requires logging or re-throwing

**Example**:
```typescript
// ❌ Blocked by Guard
try {
  await riskyOperation()
} catch (error) {
  // Silent failure - error swallowed
}

// ✅ Allowed
try {
  await riskyOperation()
} catch (error) {
  console.error('Operation failed:', error)
  throw error // or handle appropriately
}
```

**3. Hardcoded Secrets**:
- Scans for API keys, passwords, tokens
- Detects patterns like `API_KEY = "abc123"`
- Prevents accidental commits of credentials

**Example**:
```typescript
// ❌ Blocked by Guard
const API_KEY = "sk_live_abc123xyz"

// ✅ Allowed
const API_KEY = process.env.NEXT_PUBLIC_API_KEY
```

**4. SQL Injection Risks**:
- Detects string concatenation in SQL queries
- Flags missing parameterization
- Requires prepared statements

**Example**:
```typescript
// ❌ Blocked by Guard
const query = `SELECT * FROM users WHERE id = ${userId}`

// ✅ Allowed
const query = 'SELECT * FROM users WHERE id = ?'
await db.query(query, [userId])
```

**5. XSS Vulnerabilities**:
- Detects `dangerouslySetInnerHTML` without sanitization
- Flags direct DOM manipulation with user input
- Requires proper escaping

**Custom Guard Rules**:

Define project-specific guards in `.claude/guardian/config.yml`:

```yaml
rules:
  no_console_in_production:
    pattern: 'console\.(log|warn|error)'
    severity: warning
    message: "Remove console statements before production"
    
  require_typescript:
    pattern: '\.js$'
    severity: error
    message: "Use TypeScript (.ts) instead of JavaScript (.js)"
    
  enforce_functional_utilities:
    pattern: 'class.*Util'
    severity: warning
    message: "Utilities should be functional, not class-based"
```

**Guard Tools** (examples):
- `guard_check`: Run all guards on specific files
- `guard_enable`: Enable specific guard rules
- `guard_disable`: Temporarily disable rules
- `guard_list`: Show all active guards
- `guard_report`: Generate guard violation report

**Use Case**: Pre-commit validation, enforcing coding standards, preventing security vulnerabilities.

---

### 4. Workflow Management (20+ Tools)

**Purpose**: Task tracking with priorities, dependencies, progress monitoring.

Workflow Management enables structured refactoring with:
- Task creation for refactoring targets
- Priority levels (P0-P5)
- Dependency tracking (task A blocks task B)
- Progress monitoring with live dashboard

**Workflow Concepts**:

**Tasks**: Discrete refactoring work items
- Title and description
- Priority (P0 = critical, P5 = nice-to-have)
- Status (todo, in_progress, done, blocked)
- Assignee (optional)
- Dependencies (blocked by other tasks)

**Example Task**:
```json
{
  "id": "task-001",
  "title": "Refactor parser.ts into modules",
  "description": "Split 850-line parser into 4 focused modules",
  "priority": "P1",
  "status": "in_progress",
  "assignee": "jess",
  "blocked_by": [],
  "estimated_hours": 6,
  "actual_hours": 3.5
}
```

**Dependencies**: Task relationships
- Task A blocks Task B (B can't start until A is done)
- Prevents work on dependent tasks too early
- Visualized in dependency graph

**Example Dependency Graph**:
```
[Refactor parser.ts] (P1, done)
  ├── [Update parser tests] (P1, in_progress) ← blocked until parser done
  └── [Update API routes] (P2, todo) ← blocked until parser done
      └── [Update integration tests] (P2, todo) ← blocked until routes done
```

**Workflow Tools** (examples):
- `workflow_create_task`: Create new refactoring task
- `workflow_update_status`: Mark task as in_progress or done
- `workflow_set_dependency`: Define task dependencies
- `workflow_list_tasks`: Show all tasks with filters
- `workflow_dashboard`: Real-time progress visualization
- `workflow_next_task`: Get next available task (not blocked)

**Progress Dashboard**:

```
Code Guardian Workflow Dashboard
=================================

Overall Progress: 15/25 tasks (60%)

By Priority:
- P0 (Critical): 2/2 done ✅
- P1 (High):     8/10 done (80%)
- P2 (Medium):   4/8 done (50%)
- P3 (Low):      1/5 done (20%)

Active Tasks:
1. [P1] Update parser tests (jess, 70% done)
2. [P2] Simplify helpers.ts (unassigned)

Blocked Tasks:
1. [P2] Update API routes (blocked by: Update parser tests)

Next Available:
1. [P2] Simplify helpers.ts
```

**Integration with Beads**:

CCG integrates with Beads (Git-backed task tracking) for:
- Sync tasks to Git issues
- Track tasks in commit messages
- Generate task reports from Git history

**Use Case**: Managing large refactoring projects, coordinating team efforts, tracking progress.

---

### 5. Latent Chain Reasoning (15+ Tools)

**Purpose**: Multi-phase reasoning for complex refactoring tasks.

Latent Chain breaks down complex refactoring into structured phases, ensuring thorough planning, incremental execution, validation, and iteration.

**Four-Phase Workflow**:

**Phase 1: Planning**
- Analyze current code state
- Identify refactoring goals
- Break down into incremental steps
- Estimate effort and risks

**Phase 2: Execution**
- Implement each step incrementally
- Maintain working state throughout
- Commit after each successful step
- Document changes

**Phase 3: Validation**
- Run tests after each change
- Check metrics (complexity, nesting)
- Verify functionality unchanged
- Compare before/after performance

**Phase 4: Review**
- Assess overall changes
- Identify areas for improvement
- Iterate if needed
- Document lessons learned

**Example: Refactoring 500+ Line Function**

**Planning Phase**:
```markdown
**Goal**: Reduce `processUserData()` from 500 lines to <100 per function

**Analysis**:
- Current complexity: 45
- Current nesting: 8
- Identified 5 logical sections: validation, transformation, enrichment, storage, notification

**Plan**:
Step 1: Extract validation logic (lines 1-100) → `validateUserData()`
Step 2: Extract transformation (lines 101-250) → `transformUserData()`
Step 3: Extract enrichment (lines 251-350) → `enrichUserData()`
Step 4: Extract storage (lines 351-450) → `storeUserData()`
Step 5: Extract notification (lines 451-500) → `notifyUserCreated()`
Step 6: Orchestrate in main `processUserData()`

**Estimated Effort**: 4 hours
**Risk**: Medium (high test coverage exists)
```

**Execution Phase (Step 1)**:
```typescript
// Before: Lines 1-100 inline in processUserData()

// After: Extracted to separate function
function validateUserData(data: UserInput): ValidationResult {
  // Validation logic here (100 lines)
  // Complexity: 8 (down from 45)
  // Nesting: 3 (down from 8)
  return { isValid, errors }
}

// Commit: "refactor: extract user validation logic"
```

**Validation Phase (Step 1)**:
```bash
# Run tests
npm test -- user-data.test.ts
✅ All tests pass

# Check metrics
ccg code-metrics -- src/user-data.ts
Before: complexity 45, nesting 8
After:  complexity 37, nesting 7 (improvement!)
```

**Review Phase (After All Steps)**:
```markdown
**Outcome**:
- processUserData() reduced from 500 lines to 80 lines
- 5 new functions, each ~100 lines
- Complexity reduced from 45 to ~8 per function
- Nesting reduced from 8 to ~3 per function
- All tests passing
- No performance degradation

**Lessons Learned**:
- Incremental extraction safer than big-bang refactor
- Tests caught 2 edge cases during step 3
- Performance actually improved (10% faster)

**Next Steps**:
- Consider extracting enrichment sub-functions (still 100 lines)
- Add integration test for full user creation flow
```

**Latent Chain Tools** (examples):
- `latent_plan`: Create multi-phase refactoring plan
- `latent_execute_step`: Execute single step with validation
- `latent_validate`: Run tests and metrics checks
- `latent_review`: Assess changes and suggest improvements
- `latent_iterate`: Restart phase if needed

**Use Case**: Complex refactoring requiring careful planning, large legacy codebases, high-risk changes.

---

### 6. Additional Modules

**Agents Module (10+ Tools)**:
- **Purpose**: Coordinate specialized agents for different aspects of refactoring
- **Example Agents**: Analyzer agent, Refactor agent, Test agent, Reviewer agent
- **Tools**: `agent_create`, `agent_assign_task`, `agent_collaborate`

**Thinking Module (5+ Tools)**:
- **Purpose**: Structured reasoning models for decision-making
- **Techniques**: Chain-of-thought, tree-of-thought, reflection
- **Tools**: `think_chain`, `think_tree`, `think_reflect`

**Documents Module (8+ Tools)**:
- **Purpose**: Documentation management and generation
- **Capabilities**: API docs, README generation, changelog updates
- **Tools**: `doc_generate`, `doc_update`, `doc_validate`

**Testing Module (6+ Tools)**:
- **Purpose**: Test runner integration and coverage tracking
- **Capabilities**: Run tests, check coverage, generate test reports
- **Tools**: `test_run`, `test_coverage`, `test_report`

---

## Installation & Configuration

### Prerequisites

CCG uses `better-sqlite3` (native SQLite bindings) which requires build tools on your system.

**macOS**:
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install CCG
npm install -g codeguardian-studio
```

**Linux (Ubuntu/Debian)**:
```bash
# Install build dependencies
sudo apt-get update
sudo apt-get install build-essential python3

# Install CCG
npm install -g codeguardian-studio
```

**Windows**:
```bash
# Install Visual Studio Build Tools
# Download from: https://visualstudio.microsoft.com/downloads/

# Install CCG
npm install -g codeguardian-studio
```

**Docker**:
```dockerfile
FROM node:20-slim

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Install CCG
RUN npm install -g codeguardian-studio

# Set working directory
WORKDIR /workspace

# Run CCG
CMD ["ccg", "quickstart"]
```

### Troubleshooting Installation

**Error: `gyp ERR! stack Error: not found: make`**

**Solution**: Install build tools for your OS (see above).

**Error: `Module did not self-register`**

**Solution**: Node.js version mismatch. Rebuild with:
```bash
npm rebuild better-sqlite3
```

**ARM64 Compatibility**:
- ✅ Supported on Apple Silicon (M1/M2/M3)
- ✅ Supported on Ubuntu ARM64
- May require building from source on some platforms

---

### MCP Server Configuration

**Claude Code** (`~/.mcp.json` or project `.mcp.json`):

```json
{
  "mcpServers": {
    "code-guardian": {
      "command": "codeguardian-studio",
      "env": {
        "PROJECT_PATH": "/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint"
      }
    }
  }
}
```

**Qodo Gen**: Similar configuration in Qodo Gen's MCP settings.

**Environment Variables**:
- `PROJECT_PATH` (required): Absolute path to project root
- `CCG_LICENSE_KEY` (optional): License key for Team/Enterprise tiers
- `CCG_LOG_LEVEL` (optional): Logging level (`debug`, `info`, `warn`, `error`)

---

### Quickstart (Recommended)

The fastest way to get started with CCG:

```bash
# 1. Install globally
npm install -g codeguardian-studio

# 2. Navigate to your project
cd /path/to/your/project

# 3. Run quickstart (auto-initializes + analyzes)
ccg quickstart
```

**What quickstart does**:
1. Initializes CCG in project (creates `.claude/` directory)
2. Scans codebase structure
3. Calculates complexity metrics
4. Identifies hotspots
5. Generates detailed Markdown report

**Output**: Report saved to `.claude/reports/analysis-YYYY-MM-DD.md`

**Review the report** and start fixing hotspots (highest score first).

---

### Manual Setup

For more control over the setup process:

```bash
# 1. Navigate to project
cd /path/to/your/project

# 2. Initialize CCG
ccg init

# This creates:
# .claude/
# ├── config.yml          # CCG configuration
# ├── guardian/           # Guard rules
# │   ├── config.yml
# │   └── config.local.yml
# ├── memory/             # Persistent memory
# │   └── memory.db
# ├── workflows/          # Task tracking
# │   └── tasks.db
# └── reports/            # Generated reports

# 3. Run analysis with custom options
ccg code-optimize --report

# 4. For advanced options
ccg code-optimize --help-advanced
```

**Advanced Options**:
```bash
# Analyze specific directory
ccg code-optimize --dir src/legacy

# Generate JSON output
ccg code-optimize --format json

# Set complexity threshold
ccg code-optimize --complexity-threshold 15

# Include/exclude file patterns
ccg code-optimize --include "*.ts" --exclude "*.test.ts"

# Verbose logging
ccg code-optimize --verbose
```

---

## I Do Blueprint Use Cases

### 1. Code Quality Assessment

**Scenario**: Assess I Do Blueprint codebase for refactoring priorities.

**Workflow**:
1. Run `ccg quickstart` to generate initial analysis
2. Review generated report in `.claude/reports/`
3. Identify top 5 hotspots
4. Use `code_refactor_plan` for each hotspot
5. Track refactoring tasks in Workflow module

**Example**:
```bash
cd ~/Development/nextjs-projects/I\ Do\ Blueprint
ccg quickstart

# Review report
cat .claude/reports/analysis-2025-12-30.md

# Expected findings:
# - Top hotspot: app/api/rsvp/route.ts (complexity: 22, 450 lines)
# - Recommended: Extract validation, database logic, email sending
```

### 2. Pre-Commit Validation

**Scenario**: Block dangerous code patterns before committing to Git.

**Workflow**:
1. Configure Guard rules in `.claude/guardian/config.yml`
2. Add pre-commit hook to run `ccg guard-check`
3. Guards block commits if violations detected
4. Fix violations before committing

**Setup**:
```bash
# Create pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
ccg guard-check --staged
if [ $? -ne 0 ]; then
  echo "❌ Guard violations detected. Fix before committing."
  exit 1
fi
EOF

chmod +x .git/hooks/pre-commit
```

**Example Violation**:
```typescript
// This would be blocked by Guard:
try {
  await createRSVP(data)
} catch (error) {
  // Empty catch block - error swallowed
}

// Fix:
try {
  await createRSVP(data)
} catch (error) {
  console.error('RSVP creation failed:', error)
  throw new Error('Failed to create RSVP')
}
```

### 3. Legacy Code Refactoring

**Scenario**: Refactor complex API route handler (450 lines, complexity 22).

**Workflow**:
1. Use `code_quick_analysis` to identify hotspot
2. Use `code_refactor_plan` to generate incremental plan
3. Use Latent Chain to execute plan phase-by-phase
4. Use Workflow to track progress
5. Use Memory to remember refactoring decisions

**Example**:
```bash
# Identify hotspot
ccg code-optimize

# Generate refactor plan
ccg refactor-plan app/api/rsvp/route.ts

# Output: Plan to split into:
# - rsvp-validation.ts (input validation)
# - rsvp-database.ts (database operations)
# - rsvp-email.ts (email notifications)
# - route.ts (orchestration, ~100 lines)
```

### 4. Maintaining Code Quality Over Time

**Scenario**: Track code quality metrics over months, demonstrate improvements.

**Workflow**:
1. Run `ccg code-optimize --report` monthly
2. Use `code_record_optimization` after refactoring sessions
3. Compare metrics over time
4. Generate trend reports for stakeholders

**Example Report**:
```markdown
# Code Quality Trends - I Do Blueprint

## December 2024 → December 2025

**Overall Improvements**:
- Average complexity: 12.5 → 8.2 (34% improvement)
- Hotspots: 35 → 20 (43% reduction)
- Critical files: 12 → 5 (58% reduction)

**Refactoring Sessions**: 24
**Total Hours**: 180
**Files Refactored**: 48

**Impact**:
- Onboarding time reduced by 40%
- Bug rate decreased by 25%
- Feature velocity increased by 30%
```

### 5. Team Collaboration

**Scenario**: Multiple developers refactoring different parts of codebase.

**Workflow**:
1. Create tasks for each refactoring area
2. Assign tasks to developers
3. Track dependencies (can't refactor B until A is done)
4. Monitor progress via dashboard
5. Share memory across team (conventions, decisions)

**Example Task Assignment**:
```bash
# Create tasks
ccg workflow create "Refactor RSVP API" --priority P1 --assignee jess
ccg workflow create "Refactor Guest Management" --priority P1 --assignee alex
ccg workflow create "Update Integration Tests" --priority P2 --assignee jess

# Set dependency (tests blocked until APIs done)
ccg workflow set-dependency "Update Integration Tests" --blocked-by "Refactor RSVP API,Refactor Guest Management"

# Check dashboard
ccg workflow dashboard

# Output:
# Jess: Refactor RSVP API (in progress, 60%)
# Alex: Refactor Guest Management (in progress, 40%)
# Jess: Update Integration Tests (blocked)
```

---

## Pricing & Licensing

### License Tiers

| Tier | Price | Features | Best For |
|------|-------|----------|----------|
| **Dev** | Free | All 113+ tools, fully offline, self-hostable | Solo developers, fully local usage |
| **Team** | $19/month | Dev features + team collaboration, priority support | Product teams, agencies |
| **Enterprise** | Custom | Team features + SLA, custom integrations, dedicated support | Large organizations, compliance needs |

**Dev Tier**:
- 100% local (no internet required)
- Self-hostable
- No license validation
- Full feature access

**Team/Enterprise Tiers**:
- Require license validation via `api.codeguardian.studio`
- Additional features: team dashboards, advanced reporting, SSO integration
- Priority support channels

**Licensing**:
- Open-core model (MIT license for core functionality)
- Enterprise features require paid license
- See full details: https://github.com/phuongrealmax/code-guardian/blob/master/docs/LICENSE_SYSTEM.md

---

## Resources

### Official Links

- **GitHub**: https://github.com/phuongrealmax/code-guardian
- **Website**: https://codeguardian.studio
- **Case Study**: https://codeguardian.studio/case-study
- **Partners**: https://codeguardian.studio/partners
- **npm**: https://www.npmjs.com/package/codeguardian-studio
- **MCP Directory**: https://mcp.so/server/code-guardian

### Documentation

- **Features**: https://github.com/phuongrealmax/code-guardian/blob/master/docs/FEATURES.md
- **User Guide**: https://github.com/phuongrealmax/code-guardian/blob/master/docs/USER_GUIDE.md
- **Quickstart**: https://github.com/phuongrealmax/code-guardian/blob/master/docs/QUICKSTART.md
- **Comparison**: https://github.com/phuongrealmax/code-guardian/blob/master/docs/COMPARISON.md
- **Migration Guide**: https://github.com/phuongrealmax/code-guardian/blob/master/docs/MIGRATION_OPEN_CORE.md
- **License System**: https://github.com/phuongrealmax/code-guardian/blob/master/docs/LICENSE_SYSTEM.md
- **Changelog**: https://github.com/phuongrealmax/code-guardian/blob/master/CHANGELOG.md

### GitHub Action

- **ccg-action**: https://github.com/phuongrealmax/code-guardian/tree/master/ccg-action
- **Purpose**: CI/CD integration for PR analysis
- **Use Case**: Automated code quality checks in GitHub Actions

### Community & Support

- **GitHub Discussions**: https://github.com/phuongrealmax/code-guardian/discussions
- **Issue Tracker**: https://github.com/phuongrealmax/code-guardian/issues

---

## Summary

Code Guardian Studio is the **most comprehensive MCP server** for code quality and refactoring in AI-assisted development. With **113+ MCP tools** spanning analysis, workflow, memory, guards, and reasoning, it provides an all-in-one solution for maintaining and improving large codebases.

**Key Strengths**:
- 🔍 Comprehensive code analysis (scan, metrics, hotspots)
- 📊 Real-time progress tracking with dashboards
- 🧠 Persistent memory across sessions
- 🛡️ Safety guards for dangerous patterns
- 🔗 Workflow management with dependencies
- 🤔 Multi-phase reasoning for complex refactors
- 📈 Proven results (self-dogfooded on 68K lines)

**Perfect for**:
- I Do Blueprint code quality assessment
- Legacy code refactoring projects
- Pre-commit validation and safety
- Team collaboration on large refactors
- Long-term code quality tracking

---

**Last Updated**: December 30, 2025  
**Version**: 4.1.0  
**I Do Blueprint Integration**: Active
