---
title: Narsil MCP - Code Intelligence Server
type: note
permalink: ai-tools/code-intelligence/narsil-mcp-code-intelligence-server
---

# Narsil MCP - Code Intelligence Server

> **Blazing-fast, privacy-first MCP server for deep code intelligence**

## Overview

Narsil MCP is a Rust-powered Model Context Protocol (MCP) server that provides AI assistants with comprehensive code understanding through 76 specialized tools. It offers multi-language parsing, semantic search, security analysis, and supply chain intelligence—all running entirely locally with no data leaving your machine.

**Agent Attachments:**
- ✅ **Qodo Gen** (MCP Server)
- ✅ **Claude Code** (MCP Server)
- ❌ Claude Desktop
- ❌ CLI/Shell (standalone server)

---

## Key Features

### Core Capabilities

1. **Code Intelligence**
   - Symbol extraction and navigation across 14 languages
   - Semantic search with BM25, TF-IDF, and hybrid ranking
   - AST-aware code chunking for context-aware analysis
   - Cross-file reference tracking

2. **Neural Semantic Search** (Optional)
   - Find functionally similar code even with different naming
   - Powered by Voyage AI or OpenAI code-specialized embeddings
   - Semantic clone detection (Type-3/4 clones)
   - Example-based code discovery

3. **Security Analysis**
   - Taint tracking for injection vulnerabilities (SQL, XSS, command injection, path traversal)
   - Built-in security rules engine (OWASP Top 10, CWE Top 25)
   - Secrets detection (API keys, passwords, tokens)
   - Cryptographic issue detection (weak algorithms, hardcoded keys)

4. **Supply Chain Security**
   - SBOM generation (CycloneDX, SPDX, JSON formats)
   - Dependency vulnerability checking via OSV database
   - License compliance analysis
   - Safe upgrade path recommendations

5. **Advanced Analysis**
   - Call graph analysis with complexity metrics
   - Control flow graphs (CFG) showing basic blocks and branches
   - Data flow analysis (DFA) with reaching definitions
   - Dead code and dead store detection
   - Type inference for Python/JavaScript/TypeScript

---

## Supported Languages

| Language | Extensions | Symbol Types Extracted |
|----------|------------|------------------------|
| **Rust** | `.rs` | functions, structs, enums, traits, impls, mods |
| **Python** | `.py`, `.pyi` | functions, classes |
| **JavaScript** | `.js`, `.jsx`, `.mjs` | functions, classes, methods, variables |
| **TypeScript** | `.ts`, `.tsx` | functions, classes, interfaces, types, enums |
| **Go** | `.go` | functions, methods, types |
| **C** | `.c`, `.h` | functions, structs, enums, typedefs |
| **C++** | `.cpp`, `.cc`, `.hpp` | functions, classes, structs, namespaces |
| **Java** | `.java` | methods, classes, interfaces, enums |
| **C#** | `.cs` | methods, classes, interfaces, structs, enums, delegates, namespaces |
| **Bash** | `.sh`, `.bash`, `.zsh` | functions, variables |
| **Ruby** | `.rb`, `.rake`, `.gemspec` | methods, classes, modules |
| **Kotlin** | `.kt`, `.kts` | functions, classes, objects, interfaces |
| **PHP** | `.php`, `.phtml` | functions, methods, classes, interfaces, traits |
| **Swift** | `.swift` | *Planned support* |

---

## Installation

### Quick Install (Recommended)

```bash
# One-click installation script
curl -fsSL https://raw.githubusercontent.com/postrv/narsil-mcp/main/install.sh | bash
```

### From Source

```bash
# Requires Rust 1.70+
git clone git@github.com:postrv/narsil-mcp.git
cd narsil-mcp
cargo build --release

# Binary will be at: target/release/narsil-mcp
```

### Feature Builds

Narsil MCP supports different feature sets for different use cases:

```bash
# Default build - native MCP server (~30MB)
cargo build --release

# With neural vector search - adds TF-IDF similarity (~18MB)
cargo build --release --features neural

# With ONNX model support - adds local neural embeddings (~50MB)
cargo build --release --features neural-onnx

# With embedded visualization frontend (~31MB)
cargo build --release --features frontend

# For browser/WASM usage
cargo build --release --target wasm32-unknown-unknown --features wasm
```

| Feature | Description | Binary Size |
|---------|-------------|-------------|
| `native` (default) | Full MCP server with all tools | ~30MB |
| `frontend` | + Embedded visualization web UI | ~31MB |
| `neural` | + TF-IDF vector search, API embeddings | ~32MB |
| `neural-onnx` | + Local ONNX model inference | ~50MB |
| `wasm` | Browser build (no file system, git) | ~3MB |

---

## Configuration

### Qodo Gen Configuration

Add to your Qodo Gen MCP configuration:

```json
{
  "mcpServers": {
    "narsil-mcp": {
      "command": "/path/to/narsil-mcp",
      "args": [
        "--repos", "/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint",
        "--git",
        "--call-graph",
        "--persist",
        "--watch"
      ]
    }
  }
}
```

### Claude Code Configuration

Add to `~/.mcp.json` or project-specific `.mcp.json`:

```json
{
  "mcpServers": {
    "narsil-mcp": {
      "command": "narsil-mcp",
      "args": [
        "--repos", "~/Development/nextjs-projects/I Do Blueprint",
        "--git",
        "--call-graph",
        "--persist"
      ]
    }
  }
}
```

### Advanced Configuration (All Features)

```bash
narsil-mcp \
  --repos ~/projects/my-app \
  --git \              # Enable git blame, history, contributors
  --call-graph \       # Enable function call analysis
  --persist \          # Save index to disk for fast startup
  --watch \            # Auto-reindex on file changes
  --lsp \              # Enable LSP for hover, go-to-definition
  --streaming \        # Stream large result sets
  --remote \           # Enable GitHub remote repo support
  --neural \           # Enable neural semantic embeddings
  --neural-backend api \      # Backend: "api" (Voyage/OpenAI) or "onnx"
  --neural-model voyage-code-2  # Model to use
```

### Neural Search Setup

For semantic code search with neural embeddings:

```bash
# Using Voyage AI (recommended for code)
export VOYAGE_API_KEY="pa-your-key-here"
narsil-mcp --repos ~/project --neural --neural-backend api --neural-model voyage-code-2

# Using OpenAI
export OPENAI_API_KEY="sk-your-key-here"
narsil-mcp --repos ~/project --neural --neural-backend api --neural-model text-embedding-3-small

# Using local ONNX model (no API key needed)
narsil-mcp --repos ~/project --neural --neural-backend onnx
```

---

## Available Tools (76 Total)

### Repository & File Management (8 tools)

| Tool | Description | Example Usage |
|------|-------------|---------------|
| `list_repos` | List all indexed repositories with metadata | "Show me all indexed repositories" |
| `get_project_structure` | Get directory tree with file icons and sizes | "Show the project structure for I Do Blueprint" |
| `get_file` | Get file contents with optional line range | "Get the contents of AppView.swift" |
| `get_excerpt` | Extract code around specific lines with context | "Show me lines 50-60 from DatabaseManager.swift" |
| `reindex` | Trigger re-indexing of repositories | "Reindex the project to pick up new files" |
| `discover_repos` | Auto-discover repositories in a directory | "Find all git repos in ~/Development" |
| `validate_repo` | Check if path is a valid repository | "Is ~/projects/my-app a valid repository?" |
| `get_index_status` | Show index stats and enabled features | "What's the current index status?" |

**Example:**
```typescript
// Get project structure
get_project_structure({ repo: "I Do Blueprint" })

// Returns:
{
  "structure": {
    "src/": {
      "AppView.swift": { "size": "4.2 KB", "type": "swift" },
      "Models/": {
        "Guest.swift": { "size": "2.1 KB", "type": "swift" },
        "Event.swift": { "size": "3.5 KB", "type": "swift" }
      }
    }
  }
}
```

### Symbol Search & Navigation (7 tools)

| Tool | Description | Example Usage |
|------|-------------|---------------|
| `find_symbols` | Find structs, classes, functions by type/pattern | "Find all View structs in the project" |
| `get_symbol_definition` | Get symbol source with surrounding context | "Show me the definition of EventViewModel" |
| `find_references` | Find all references to a symbol | "Where is DatabaseManager used?" |
| `get_dependencies` | Analyze imports and dependents | "What files import Supabase?" |
| `workspace_symbol_search` | Fuzzy search symbols across workspace | "Find symbols matching 'guest'" |
| `find_symbol_usages` | Cross-file symbol usage with imports | "Show all usages of the Guest model" |
| `get_export_map` | Get exported symbols from a file/module | "What does DatabaseManager.swift export?" |

**Example:**
```typescript
// Find all View structs
find_symbols({ 
  kind: "struct",
  pattern: "View$"  // Matches structs ending with "View"
})

// Returns:
[
  {
    "name": "EventDetailView",
    "kind": "struct",
    "file_path": "src/Views/EventDetailView.swift",
    "start_line": 15,
    "end_line": 89,
    "signature": "struct EventDetailView: View"
  },
  {
    "name": "GuestListView",
    "kind": "struct",
    "file_path": "src/Views/GuestListView.swift",
    "start_line": 10,
    "end_line": 65,
    "signature": "struct GuestListView: View"
  }
]
```

### Code Search (6 tools)

| Tool | Description | Example Usage |
|------|-------------|---------------|
| `search_code` | Keyword search with relevance ranking | "Search for 'supabase authentication'" |
| `semantic_search` | BM25-ranked semantic search | "Find code that handles user login" |
| `hybrid_search` | Combined BM25 + TF-IDF with rank fusion | "Search for database migrations" |
| `search_chunks` | Search over AST-aware code chunks | "Find chunks related to RSVP logic" |
| `find_similar_code` | Find code similar to a snippet (TF-IDF) | "Find similar error handling patterns" |
| `find_similar_to_symbol` | Find code similar to a symbol | "Find functions similar to createGuest()" |

**Example:**
```typescript
// Hybrid search combining BM25 and TF-IDF
hybrid_search({ 
  query: "database connection pooling",
  max_results: 5
})

// Returns ranked results with scores
[
  {
    "file": "src/Database/SupabaseClient.swift",
    "start_line": 45,
    "end_line": 67,
    "content": "class SupabaseClient {\n  private var client: SupabaseClient\n  ...",
    "score": 0.92,
    "rank_fusion_score": 0.88
  }
]
```

### Neural Semantic Search (3 tools - requires `--neural`)

| Tool | Description | Example Usage |
|------|-------------|---------------|
| `neural_search` | Semantic search using neural embeddings | "Find code that validates email addresses" |
| `find_semantic_clones` | Find Type-3/4 semantic clones of a function | "Find semantic clones of validateEmail()" |
| `get_neural_stats` | Neural embedding index statistics | "Show neural embedding statistics" |

**Example:**
```typescript
// Find semantically similar code (works even with different naming)
neural_search({ 
  query: "function that validates email format"
})

// Finds functions like:
// - isValidEmail()
// - checkEmailFormat()
// - validateUserEmail()
// Even if they have different implementations but similar purpose
```

### Call Graph Analysis (6 tools - requires `--call-graph`)

| Tool | Description | Example Usage |
|------|-------------|---------------|
| `get_call_graph` | Get call graph for repository/function | "Show the call graph for createEvent()" |
| `get_callers` | Find functions that call a function | "What calls DatabaseManager.save()?" |
| `get_callees` | Find functions called by a function | "What does EventViewModel.loadEvents() call?" |
| `find_call_path` | Find path between two functions | "Find call path from AppView to SupabaseClient" |
| `get_complexity` | Get cyclomatic/cognitive complexity | "What's the complexity of handleRSVP()?" |
| `get_function_hotspots` | Find highly connected functions | "Show the most connected functions" |

**Example:**
```typescript
// Get call graph with complexity metrics
get_call_graph({ 
  function: "createEvent",
  depth: 3
})

// Returns:
{
  "root": "createEvent",
  "calls": [
    {
      "function": "validateEventData",
      "complexity": { "cyclomatic": 5, "cognitive": 8 },
      "calls": [
        { "function": "checkDateRange", "complexity": { "cyclomatic": 2 } },
        { "function": "validateVenue", "complexity": { "cyclomatic": 3 } }
      ]
    },
    {
      "function": "saveToDatabase",
      "complexity": { "cyclomatic": 7, "cognitive": 12 },
      "calls": [
        { "function": "supabase.insert", "external": true }
      ]
    }
  ]
}
```

### Security Analysis - Taint Tracking (4 tools)

| Tool | Description | Example Usage |
|------|-------------|---------------|
| `find_injection_vulnerabilities` | Find SQL injection, XSS, command injection, path traversal | "Scan for injection vulnerabilities" |
| `trace_taint` | Trace tainted data flow from a source | "Trace taint from user input in handleLogin()" |
| `get_taint_sources` | List taint sources (user input, files, network) | "Show all taint sources in the API layer" |
| `get_security_summary` | Comprehensive security risk assessment | "Give me a security summary of the project" |

**Example:**
```typescript
// Find SQL injection vulnerabilities
find_injection_vulnerabilities({ 
  type: "sql_injection"
})

// Returns:
[
  {
    "type": "SQL_INJECTION",
    "severity": "HIGH",
    "file": "src/API/UserController.swift",
    "line": 78,
    "message": "User input flows directly into SQL query",
    "taint_flow": [
      { "source": "request.body.username", "line": 75 },
      { "sanitization": null },
      { "sink": "database.rawQuery(query)", "line": 78 }
    ],
    "recommendation": "Use parameterized queries or prepared statements"
  }
]
```

### Security Analysis - Rules Engine (5 tools)

| Tool | Description | Example Usage |
|------|-------------|---------------|
| `scan_security` | Scan with security rules (OWASP, CWE, crypto, secrets) | "Scan for OWASP vulnerabilities" |
| `check_owasp_top10` | Scan for OWASP Top 10 2021 vulnerabilities | "Check for OWASP Top 10 issues" |
| `check_cwe_top25` | Scan for CWE Top 25 weaknesses | "Scan for CWE Top 25 weaknesses" |
| `explain_vulnerability` | Get detailed vulnerability explanation | "Explain CWE-89 in detail" |
| `suggest_fix` | Get remediation suggestions for findings | "How do I fix this SQL injection?" |

**Example:**
```typescript
// Check for OWASP Top 10 vulnerabilities
check_owasp_top10()

// Returns:
[
  {
    "owasp_id": "A03:2021",
    "category": "Injection",
    "findings": [
      {
        "file": "src/API/GuestController.swift",
        "line": 45,
        "severity": "HIGH",
        "description": "Unsanitized user input in database query",
        "cwe": "CWE-89"
      }
    ]
  },
  {
    "owasp_id": "A07:2021",
    "category": "Identification and Authentication Failures",
    "findings": [
      {
        "file": "src/Auth/TokenManager.swift",
        "line": 23,
        "severity": "MEDIUM",
        "description": "Weak password policy (minimum 6 characters)",
        "cwe": "CWE-521"
      }
    ]
  }
]
```

### Supply Chain Security (4 tools)

| Tool | Description | Example Usage |
|------|-------------|---------------|
| `generate_sbom` | Generate SBOM (CycloneDX/SPDX/JSON) | "Generate a CycloneDX SBOM" |
| `check_dependencies` | Check for known vulnerabilities (OSV database) | "Check dependencies for vulnerabilities" |
| `check_licenses` | Analyze licenses for compliance issues | "Check for license compliance issues" |
| `find_upgrade_path` | Find safe upgrade paths for vulnerable deps | "Find upgrade path for vulnerable package" |

**Example:**
```typescript
// Check dependencies for known vulnerabilities
check_dependencies()

// Returns:
[
  {
    "package": "Alamofire",
    "version": "5.4.0",
    "vulnerabilities": [
      {
        "id": "GHSA-xxxx-yyyy-zzzz",
        "severity": "MEDIUM",
        "description": "Server-Side Request Forgery (SSRF) vulnerability",
        "fixed_versions": ["5.4.4", "5.5.0"],
        "url": "https://github.com/advisories/GHSA-xxxx-yyyy-zzzz"
      }
    ]
  }
]

// Get safe upgrade path
find_upgrade_path({ 
  package: "Alamofire",
  current_version: "5.4.0"
})

// Returns:
{
  "recommended_version": "5.4.4",
  "upgrade_path": ["5.4.0", "5.4.4"],
  "breaking_changes": false,
  "fixes_vulnerabilities": ["GHSA-xxxx-yyyy-zzzz"]
}
```

### Type Inference (3 tools - Python/JavaScript/TypeScript)

| Tool | Description | Example Usage |
|------|-------------|---------------|
| `infer_types` | Infer types for variables without type checkers | "Infer types for processData() function" |
| `check_type_errors` | Find potential type errors without mypy/tsc | "Check for type errors in API layer" |
| `get_typed_taint_flow` | Enhanced taint analysis with type information | "Get typed taint flow for user input" |

**Example:**
```typescript
// Infer types for a Python function
infer_types({ 
  file: "src/utils.py",
  function: "process_data"
})

// Returns:
{
  "function": "process_data",
  "inferred_types": {
    "data": "str",  // Inferred from .split() call
    "result": "list[str]",
    "count": "int",
    "return": "int"
  },
  "potential_errors": [
    {
      "line": 45,
      "message": "Potential type mismatch: trying to call .upper() on int"
    }
  ]
}
```

### Git Integration (10 tools - requires `--git`)

| Tool | Description | Example Usage |
|------|-------------|---------------|
| `get_blame` | Git blame for file | "Who last modified DatabaseManager.swift?" |
| `get_file_history` | Commit history for file | "Show commit history for AppView.swift" |
| `get_recent_changes` | Recent commits in repository | "Show recent changes in the last week" |
| `get_hotspots` | Files with high churn and complexity | "What are the code hotspots?" |
| `get_contributors` | Repository/file contributors | "Who contributed to the auth module?" |
| `get_commit_diff` | Diff for specific commit | "Show diff for commit abc123" |
| `get_symbol_history` | Commits that changed a symbol | "Show history of EventViewModel changes" |
| `get_branch_info` | Current branch and status | "What branch am I on?" |
| `get_modified_files` | Working tree changes | "What files have I modified?" |

**Example:**
```typescript
// Find code hotspots (high churn + high complexity)
get_hotspots({ 
  min_complexity: 10,
  min_commits: 5
})

// Returns:
[
  {
    "file": "src/ViewModels/EventViewModel.swift",
    "complexity": 24,
    "commits": 47,
    "last_modified": "2025-12-28",
    "contributors": ["jess", "collaborator1"],
    "risk_score": 0.87  // High churn + high complexity = high risk
  }
]
```

### Additional Tool Categories

- **AST-Aware Chunking** (3 tools): `get_chunks`, `get_chunk_stats`, `get_embedding_stats`
- **Control Flow & Data Flow Analysis** (6 tools): `get_control_flow`, `find_dead_code`, `get_data_flow`, `get_reaching_definitions`, `find_uninitialized`, `find_dead_stores`
- **Import/Dependency Graph** (2 tools): `get_import_graph`, `find_circular_imports`
- **LSP Integration** (3 tools, requires `--lsp`): `get_hover_info`, `get_type_info`, `go_to_definition`
- **Remote Repository Support** (3 tools, requires `--remote`): `add_remote_repo`, `list_remote_files`, `get_remote_file`
- **Metrics** (1 tool): `get_metrics`

---

## Performance Benchmarks

### Parsing Throughput

| Language | Input Size | Time | Throughput |
|----------|------------|------|------------|
| Rust (large file) | 278 KB | 131 µs | **1.98 GiB/s** |
| Rust (medium file) | 27 KB | 13.5 µs | 1.89 GiB/s |
| Python | ~4 KB | 16.7 µs | - |
| TypeScript | ~5 KB | 13.9 µs | - |

### Search Latency

| Operation | Corpus Size | Time |
|-----------|-------------|------|
| Symbol exact match | 1,000 symbols | **483 ns** |
| Symbol prefix match | 1,000 symbols | 2.7 µs |
| Symbol fuzzy match | 1,000 symbols | 16.5 µs |
| BM25 full-text | 1,000 docs | 80 µs |
| TF-IDF similarity | 1,000 docs | 130 µs |
| Hybrid search | 1,000 docs | 151 µs |

### End-to-End Indexing

| Repository | Files | Symbols | Time | Memory |
|------------|-------|---------|------|--------|
| Small (narsil-mcp) | 53 | 1,733 | 220 ms | ~50 MB |
| Medium (rust-analyzer) | 2,847 | ~50K | 2.1s | 89 MB |
| Large (Linux kernel) | 78,000+ | ~500K | 45s | 2.1 GB |

---

## I Do Blueprint Use Cases

### 1. Swift Code Navigation

```typescript
// Find all View structs in the project
find_symbols({ kind: "struct", pattern: "View$" })

// Get the definition of EventDetailView with context
get_symbol_definition({ symbol: "EventDetailView" })

// Find all usages of the Guest model
find_symbol_usages({ symbol: "Guest" })
```

### 2. Supabase Integration Analysis

```typescript
// Find all Supabase client usage
search_code({ query: "SupabaseClient" })

// Analyze dependencies on Supabase
get_dependencies({ file: "src/Database/SupabaseClient.swift" })

// Find all database query calls
find_symbols({ kind: "method", pattern: "query|insert|update|delete" })
```

### 3. Security Scanning

```typescript
// Scan for injection vulnerabilities
find_injection_vulnerabilities({ type: "sql_injection" })

// Check for hardcoded secrets
scan_security({ ruleset: "secrets" })

// Analyze authentication flow for security issues
get_taint_sources({ module: "Auth" })

// Get comprehensive security summary
get_security_summary()
```

### 4. Code Quality Analysis

```typescript
// Find complex functions that need refactoring
get_complexity({ threshold: 15 })

// Find code hotspots (high churn + high complexity)
get_hotspots({ min_complexity: 10, min_commits: 5 })

// Find dead code
find_dead_code()

// Find circular dependencies
find_circular_imports()
```

### 5. Refactoring Support

```typescript
// Find similar error handling patterns
find_similar_code({ snippet: "do { try ... } catch { ... }" })

// Get call graph to understand impact of changes
get_call_graph({ function: "createEvent", depth: 3 })

// Find all callers before refactoring
get_callers({ function: "validateEventData" })
```

### 6. Documentation Generation

```typescript
// Get all exported symbols for API documentation
get_export_map({ file: "src/API/EventController.swift" })

// Generate SBOM for compliance
generate_sbom({ format: "cyclonedx" })

// Get symbol history for changelog
get_symbol_history({ symbol: "EventViewModel" })
```

---

## Why Choose Narsil MCP for I Do Blueprint?

1. **Swift Support**: Full Swift parsing and symbol extraction (planned)
2. **Privacy-First**: All analysis runs locally, no code sent to external services
3. **Fast**: Blazing-fast Rust implementation, <1ms search latency
4. **Comprehensive Security**: Built-in OWASP/CWE scanning, perfect for wedding app with user data
5. **Supabase Integration**: Analyze database queries, check for SQL injection
6. **Type-Safe**: Type inference helps catch errors in dynamic contexts
7. **Git-Aware**: Track code churn, find hotspots, understand contributor patterns
8. **MCP Native**: Seamless integration with Qodo Gen and Claude Code

---

## Architecture

```
+-----------------------------------------------------------------+
|                         MCP Server                               |
|  +-----------------------------------------------------------+  |
|  |                   JSON-RPC over stdio                      |  |
|  +-----------------------------------------------------------+  |
|                              |                                   |
|  +---------------------------v-------------------------------+  |
|  |                   Code Intel Engine                        |  |
|  |  +------------+ +------------+ +------------------------+  |  |
|  |  |  Symbol    | |   File     | |    Search Engine       |  |  |
|  |  |  Index     | |   Cache    | |  (Tantivy + TF-IDF)    |  |  |
|  |  | (DashMap)  | | (DashMap)  | +------------------------+  |  |
|  |  +------------+ +------------+                              |  |
|  |  +------------+ +------------+ +------------------------+  |  |
|  |  | Call Graph | |  Taint     | |   Security Rules       |  |  |
|  |  |  Analysis  | |  Tracker   | |   Engine               |  |  |
|  |  +------------+ +------------+ +------------------------+  |  |
|  +-----------------------------------------------------------+  |
|                              |                                   |
|  +---------------------------v-------------------------------+  |
|  |                Tree-sitter Parser                          |  |
|  |  +------+ +------+ +------+ +------+ +------+             |  |
|  |  | Rust | |Python| |  JS  | |  TS  | | Go   | ...         |  |
|  |  +------+ +------+ +------+ +------+ +------+             |  |
|  +-----------------------------------------------------------+  |
|                              |                                   |
|  +---------------------------v-------------------------------+  |
|  |                Repository Walker                           |  |
|  |           (ignore crate - respects .gitignore)             |  |
|  +-----------------------------------------------------------+  |
+-----------------------------------------------------------------+
```

---

## Related Tools

- **Greb MCP**: Semantic code search (use together for enhanced search)
- **Swiftzilla**: Swift documentation lookup (complements Narsil for Swift projects)
- **ADR Analysis Server**: Architectural decisions (use for high-level architecture docs)
- **Code Guardian**: Code quality automation (use for automated fixes after Narsil finds issues)

---

## Links & Resources

- **GitHub Repository**: https://github.com/postrv/narsil-mcp
- **Crates.io**: https://crates.io/crates/narsil-mcp
- **Model Context Protocol**: https://modelcontextprotocol.io
- **Tree-sitter**: https://tree-sitter.github.io/
- **Tantivy Search**: https://github.com/quickwit-oss/tantivy

---

## License

Licensed under Apache-2.0 OR MIT