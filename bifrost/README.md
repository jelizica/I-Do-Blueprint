# Bifrost MCP Gateway

Custom Docker image for Bifrost with full STDIO MCP server support.

## Quick Start

```bash
# Build image (first time ~15-20 min, subsequent ~1 min with cache)
bifrost-build

# Start gateway
bifrost

# Open Web UI
open http://localhost:8080
```

## Shell Commands

| Command | Description |
|---------|-------------|
| `bifrost-build` | Build Docker image |
| `bifrost-rebuild` | Force rebuild (no cache) |
| `bifrost` | Start Bifrost gateway |
| `bifrost-stop` | Stop container |
| `bifrost-stop --colima` | Stop container + Colima |
| `bifrost-shell` | Shell into running container |

## Architecture

```
Claude Code → Bifrost Gateway (localhost:8080) → MCP Servers (in container)
                     ↓
              data/config.db (persisted)
```

## Installed MCP Servers

### Quick Reference

| Server | Type | Purpose | Env Vars |
|--------|------|---------|----------|
| [narsil-mcp](#narsil-mcp) | Rust | Code intelligence, call graphs, security | `VOYAGE_API_KEY` or `OPENAI_API_KEY` (optional) |
| [mcp-adr-analysis-server](#mcp-adr-analysis-server) | NPM | ADR analysis & generation | `OPENROUTER_API_KEY` |
| [@swiftzilla/mcp](#swiftzilla) | NPM | Swift/Apple documentation | `SWIFTZILLA_API_KEY` |
| [reddit-mcp-buddy](#reddit-mcp-buddy) | NPM | Reddit browsing & search | None |
| [code-sentinel-mcp](#code-sentinel-mcp) | NPM | Code quality analysis | None |
| [basic-memory](#basic-memory) | Python | Knowledge management | None |
| [beads-mcp](#beads-mcp) | Python | Git-backed issue tracking | None |
| [cheetah-greb](#cheetah-greb) | Python | AI code search (cloud GPU) | `GREB_API_KEY` |
| [kindly-web-search](#kindly-web-search) | Python | Web search with Chromium | `SERPER_API_KEY` |
| [mcpls](#mcpls) | Rust | MCP-to-LSP bridge | None |
| [mcp-prompt-engine](#mcp-prompt-engine) | Go | Dynamic prompt templates | None |
| [code-guardian](#code-guardian) | Local | Code quality & validation | None |
| [local-file-organizer](#local-file-organizer) | Local | File organization | None |
| [llm-council](#llm-council) | Local | Multi-model deliberation | `OPENROUTER_API_KEY` |

---

### narsil-mcp

> Blazing-fast, privacy-first MCP server for deep code intelligence

| | |
|---|---|
| **Repository** | [github.com/postrv/narsil-mcp](https://github.com/postrv/narsil-mcp) |
| **Crates.io** | [narsil-mcp](https://crates.io/crates/narsil-mcp) |
| **NPM** | [narsil-mcp](https://www.npmjs.com/package/narsil-mcp) |
| **Language** | Rust (93%), TypeScript (4.5%) |
| **License** | Apache-2.0 / MIT |
| **Tools** | 76 |
| **Version** | 1.2.0 |
| **Install** | `npm install -g narsil-mcp` or `cargo install narsil-mcp` |

**Why narsil-mcp?**

| Feature | narsil-mcp | XRAY | Serena | GitHub MCP |
|---------|------------|------|--------|------------|
| **Languages** | 15 | 4 | 30+ (LSP) | N/A |
| **Neural Search** | ✅ | ❌ | ❌ | ❌ |
| **Taint Analysis** | ✅ | ❌ | ❌ | ❌ |
| **SBOM/Licenses** | ✅ | ❌ | ❌ | Partial |
| **Offline/Local** | ✅ | ✅ | ✅ | ❌ |
| **WASM/Browser** | ✅ | ❌ | ❌ | ❌ |
| **Call Graphs** | ✅ | Partial | ❌ | ❌ |
| **Type Inference** | ✅ | ❌ | ❌ | ❌ |

**Features:**
- 🔍 **Code Intelligence** - Symbol extraction, semantic search, call graph analysis
- 🧠 **Neural Search** - Find similar code using Voyage AI or OpenAI embeddings
- 🔒 **Security Analysis** - Taint analysis, vulnerability scanning, OWASP/CWE coverage
- 📦 **Supply Chain** - SBOM generation, dependency auditing, license compliance
- 🌳 **15 Languages** - Rust, Python, JS/TS, Go, C/C++, Java, C#, Bash, Ruby, Kotlin, PHP, Swift, Verilog/SystemVerilog
- ⚡ **Blazing Performance** - Tree-sitter parsing at ~2 GiB/s, symbol lookup <1µs
- 🔐 **Privacy-First** - Fully local, no data leaves your machine
- 🧬 **Type Inference** - Infer types in Python/JS/TS without external tools (mypy/tsc)
- 🧪 **Test Filtering** - `exclude_tests` parameter on 22 tools to filter out test files (v1.2.0)
- 📁 **Path Expansion** - Auto-expands "." to current directory for convenience (v1.2.0)

**When to Use narsil-mcp:**

| Use Case | narsil-mcp | Alternative |
|----------|------------|-------------|
| **Deep code navigation** (call graphs, callers/callees) | ✅ Best choice | mcpls (for single language with LSP) |
| **Security vulnerability scanning** | ✅ Built-in taint analysis, OWASP/CWE | code-sentinel (pattern-based) |
| **Finding similar/duplicate code** | ✅ Neural + TF-IDF similarity | greb-mcp (cloud-based AI search) |
| **Multi-language codebase** | ✅ 15 languages, single tool | mcpls (needs per-language LSP) |
| **Supply chain security** | ✅ SBOM, CVE checking, licenses | Dedicated tools (Snyk, etc.) |
| **Git history analysis** | ✅ Blame, contributors, hotspots | Native git or GitHub MCP |
| **Real-time code completion** | ❌ Use LSP instead | mcpls + sourcekit-lsp |
| **Semantic code search** | ✅ BM25 + TF-IDF + Neural | greb-mcp (AI reranking) |

**Supported Languages:**

| Language | Extensions | Symbols Extracted |
|----------|------------|-------------------|
| Rust | `.rs` | functions, structs, enums, traits, impls, mods |
| Python | `.py`, `.pyi` | functions, classes |
| JavaScript | `.js`, `.jsx`, `.mjs` | functions, classes, methods, variables |
| TypeScript | `.ts`, `.tsx` | functions, classes, interfaces, types, enums |
| Go | `.go` | functions, methods, types |
| C | `.c`, `.h` | functions, structs, enums, typedefs |
| C++ | `.cpp`, `.cc`, `.hpp` | functions, classes, structs, namespaces |
| Java | `.java` | methods, classes, interfaces, enums |
| C# | `.cs` | methods, classes, interfaces, structs, enums, delegates |
| Bash | `.sh`, `.bash`, `.zsh` | functions, variables |
| Ruby | `.rb`, `.rake`, `.gemspec` | methods, classes, modules |
| Kotlin | `.kt`, `.kts` | functions, classes, objects, interfaces |
| PHP | `.php`, `.phtml` | functions, methods, classes, interfaces, traits |
| Swift | `.swift` | classes, structs, enums, protocols, functions |
| Verilog/SystemVerilog | `.v`, `.vh`, `.sv`, `.svh` | modules, tasks, functions, interfaces, classes |

**Tool Categories (76 total):**

| Category | Tools | Description |
|----------|-------|-------------|
| **Repository & Files** | 8 | `list_repos`, `get_project_structure`, `get_file`, `get_excerpt`, `reindex` |
| **Symbol Navigation** | 7 | `find_symbols`, `get_symbol_definition`, `find_references`, `get_dependencies` |
| **Code Search** | 6 | `search_code`, `semantic_search`, `hybrid_search`, `find_similar_code` |
| **Neural Search** | 3 | `neural_search`, `find_semantic_clones`, `get_neural_stats` (requires `--neural`) |
| **Call Graph** | 6 | `get_call_graph`, `get_callers`, `get_callees`, `find_call_path`, `get_complexity` (requires `--call-graph`) |
| **Control Flow** | 2 | `get_control_flow`, `find_dead_code` |
| **Data Flow** | 4 | `get_data_flow`, `get_reaching_definitions`, `find_uninitialized`, `find_dead_stores` |
| **Type Inference** | 3 | `infer_types`, `check_type_errors`, `get_typed_taint_flow` |
| **Import Graph** | 3 | `get_import_graph`, `find_circular_imports`, `get_incremental_status` |
| **Security - Taint** | 4 | `find_injection_vulnerabilities`, `trace_taint`, `get_taint_sources`, `get_security_summary` |
| **Security - Rules** | 5 | `scan_security`, `check_owasp_top10`, `check_cwe_top25`, `explain_vulnerability`, `suggest_fix` |
| **Supply Chain** | 4 | `generate_sbom`, `check_dependencies`, `check_licenses`, `find_upgrade_path` |
| **Git Integration** | 9 | `get_blame`, `get_file_history`, `get_recent_changes`, `get_hotspots`, `get_contributors` (requires `--git`) |
| **LSP Integration** | 3 | `get_hover_info`, `get_type_info`, `go_to_definition` (requires `--lsp`) |
| **Remote Repos** | 3 | `add_remote_repo`, `list_remote_files`, `get_remote_file` (requires `--remote`) |

**Key Tools:**
- `search_code` - Keyword search with relevance ranking (BM25)
- `hybrid_search` - BM25 + TF-IDF with Reciprocal Rank Fusion
- `find_symbols` - Find structs, classes, functions by type/pattern
- `get_call_graph` - Function call analysis with complexity metrics
- `get_callers` / `get_callees` - Call hierarchy (transitive supported)
- `find_injection_vulnerabilities` - SQL injection, XSS, command injection, path traversal
- `trace_taint` - Track tainted data from source to sink
- `generate_sbom` - SBOM in CycloneDX/SPDX/JSON format
- `check_dependencies` - CVE checking via OSV database
- `infer_types` - Infer types without mypy/tsc
- `get_blame` / `get_file_history` - Git integration
- `get_hotspots` - Files with high churn + complexity (refactoring candidates)

**Test Filtering (v1.2.0):**

22 tools support `exclude_tests: true` parameter to filter out test files:

| Category | Tools with `exclude_tests` |
|----------|----------------------------|
| **Security** | `check_owasp_top10`, `check_cwe_top25`, `find_injection_vulnerabilities`, `get_taint_sources`, `get_security_summary` |
| **Analysis** | `find_dead_code`, `find_uninitialized`, `find_dead_stores`, `check_type_errors`, `find_circular_imports` |
| **Symbols** | `find_symbols`, `find_references`, `find_symbol_usages` |
| **Search** | `search_code`, `semantic_search`, `hybrid_search`, `search_chunks`, `find_similar_code` |
| **Call Graph** | `get_call_graph`, `get_callers`, `get_callees`, `get_function_hotspots` |

**Performance (Apple M1):**

| Operation | Corpus | Time |
|-----------|--------|------|
| Tree-sitter parsing | 278 KB Rust file | 131 µs (~2 GiB/s) |
| Symbol exact match | 1,000 symbols | 483 ns |
| BM25 full-text search | 1,000 docs | 80 µs |
| Hybrid search (BM25+TF-IDF) | 1,000 docs | 151 µs |
| Index rust-analyzer repo | 2,847 files, ~50K symbols | 2.1s |

**Security Rules (111 bundled):**
- `owasp-top10.yaml` - OWASP Top 10 2021 patterns
- `cwe-top25.yaml` - CWE Top 25 Most Dangerous Weaknesses
- `crypto.yaml` - Weak algorithms, hardcoded keys
- `secrets.yaml` - API keys, passwords, tokens

**Feature Flags:**

| Flag | Description | Default |
|------|-------------|---------|
| `--git` | Enable git blame, history, contributors | Off |
| `--call-graph` | Enable function call analysis | Off |
| `--persist` | Save index to disk for fast startup | Off |
| `--watch` | Auto-reindex on file changes | Off |
| `--lsp` | Enable LSP for hover, go-to-definition | Off |
| `--streaming` | Stream large result sets | Off |
| `--remote` | Enable GitHub remote repo support | Off |
| `--neural` | Enable neural semantic embeddings | Off |

**Bifrost Configuration:**
```json
{
  "name": "narsil-mcp",
  "command": "narsil-mcp",
  "args": ["--repos", "/workspace", "--git", "--call-graph"],
  "env": {
    "VOYAGE_API_KEY": "${VOYAGE_API_KEY}"
  }
}
```

**Full-Featured Configuration:**
```json
{
  "name": "narsil-mcp",
  "command": "narsil-mcp",
  "args": [
    "--repos", "/workspace",
    "--git",
    "--call-graph",
    "--persist",
    "--watch",
    "--neural",
    "--neural-backend", "api",
    "--neural-model", "voyage-code-2"
  ],
  "env": {
    "VOYAGE_API_KEY": "${VOYAGE_API_KEY}"
  }
}
```

**Optional Env Vars:**
- `VOYAGE_API_KEY` - For neural semantic search (Voyage AI, recommended for code)
- `OPENAI_API_KEY` - Alternative for neural search (OpenAI)
- `EMBEDDING_API_KEY` - Generic embedding API key

**Troubleshooting:**

| Issue | Solution |
|-------|----------|
| Index not finding files | Check `.gitignore`, run with `--verbose`, or use `--reindex` |
| Neural search API errors | Verify API key format (`pa-` for Voyage, `sk-` for OpenAI) |
| Memory issues (large repos) | Set `RUST_MIN_STACK=8388608` or index subdirectories |
| Tree-sitter build errors | Install C compiler: `xcode-select --install` (macOS) |

### mcp-adr-analysis-server

> Research-driven architectural analysis with live infrastructure validation and zero-tolerance deployment gates

| | |
|---|---|
| **Repository** | [github.com/tosin2013/mcp-adr-analysis-server](https://github.com/tosin2013/mcp-adr-analysis-server) |
| **Documentation** | [tosin2013.github.io/mcp-adr-analysis-server](https://tosin2013.github.io/mcp-adr-analysis-server/) |
| **NPM** | [mcp-adr-analysis-server](https://www.npmjs.com/package/mcp-adr-analysis-server) |
| **Language** | TypeScript |
| **License** | MIT |
| **Tools** | 37+ |
| **Test Coverage** | >80% |
| **Install** | `npm install -g mcp-adr-analysis-server` or `npx mcp-adr-analysis-server` |

**Why mcp-adr-analysis-server?**

| Feature | mcp-adr-analysis-server | Generic ADR Tools | Static Analyzers |
|---------|-------------------------|-------------------|------------------|
| **Live Infrastructure Detection** | ✅ Docker, K8s, OpenShift, Podman, Ansible | ❌ | ❌ |
| **Research-Driven Architecture** | ✅ Cascading sources with confidence scoring | ❌ | ❌ |
| **Memory-Centric Context** | ✅ `.mcp-server-context.md` + knowledge graph | ❌ | ❌ |
| **Zero-Tolerance Deployment Gates** | ✅ Hard blocking for unsafe deployments | Partial | ❌ |
| **Security Content Masking** | ✅ Auto-detection + configurable patterns | ❌ | Partial |
| **ADR Generation from PRD** | ✅ AI-powered with advanced prompting | Manual | ❌ |
| **Red Hat Ecosystem Support** | ✅ Native OpenShift, RHEL, Ansible | ❌ | ❌ |
| **Confidence Scoring** | ✅ 0-1 scale with reliability indicators | ❌ | ❌ |

**Core Architecture:**

```
Research-Driven Source Hierarchy:
┌─────────────────────────────────────────────────────────────┐
│  1. Project Files (highest priority)                        │
│     └── Codebase, configs, existing ADRs, README            │
├─────────────────────────────────────────────────────────────┤
│  2. Knowledge Graph                                         │
│     └── Memory entities, relationships, patterns            │
├─────────────────────────────────────────────────────────────┤
│  3. Environment Resources                                   │
│     └── Docker, Kubernetes, OpenShift, Podman, Ansible      │
├─────────────────────────────────────────────────────────────┤
│  4. Web Search (fallback when confidence < 60%)             │
│     └── Firecrawl-powered research                          │
└─────────────────────────────────────────────────────────────┘
```

**Confidence Scoring:**

| Score | Level | Meaning |
|-------|-------|---------|
| ≥ 0.70 | **High** | Results from verified project files or validated infrastructure |
| 0.60-0.69 | **Medium** | Cross-referenced from multiple sources |
| < 0.60 | **Low** | Triggers web search recommendation |

**Key Features:**

- 🔬 **Research-Driven Architecture** - Cascading source hierarchy with confidence scoring
- 🧠 **Memory-Centric Context** - `.mcp-server-context.md` as project memory + ADR loading into knowledge graph
- 🏗️ **Live Infrastructure Detection** - Docker, Kubernetes, OpenShift, Podman, Ansible detection
- 📋 **ADR Lifecycle Management** - Generate, suggest, validate, and track ADR implementation
- 🛡️ **Security Content Masking** - Auto-detect credentials, secrets, and sensitive patterns
- 🚀 **Zero-Tolerance Deployment Gates** - Hard blocking for failing tests or security issues
- 🔄 **Bootstrap Validation Loop** - Guided deployment with platform detection and auto-fix
- 📊 **Health Scoring System** - Project health metrics with score optimization
- 🤖 **Advanced AI Techniques** - APE (Automatic Prompt Engineering), Knowledge Generation, Reflexion

**Tool Categories (37+ tools):**

| Category | Tools | Description |
|----------|-------|-------------|
| **Project Analysis** | 4 | `analyze_project_ecosystem`, `get_architectural_context`, `search_codebase`, `analyze_environment` |
| **ADR Management** | 8 | `suggest_adrs`, `generate_adr_from_decision`, `generate_adrs_from_prd`, `validate_adr`, `validate_all_adrs`, `review_existing_adrs`, `discover_existing_adrs`, `analyze_adr_timeline` |
| **Research** | 4 | `perform_research`, `generate_research_questions`, `incorporate_research`, `llm_web_search` |
| **Deployment** | 6 | `deployment_readiness`, `smart_git_push`, `generate_adr_bootstrap`, `bootstrap_validation_loop`, `generate_deployment_guidance`, `analyze_deployment_progress` |
| **Security** | 4 | `analyze_content_security`, `generate_content_masking`, `configure_custom_patterns`, `apply_basic_content_masking` |
| **Rules & Compliance** | 3 | `generate_rules`, `validate_rules`, `create_rule_set` |
| **Workflow & Planning** | 6 | `get_workflow_guidance`, `get_development_guidance`, `mcp_planning`, `interactive_adr_planning`, `troubleshoot_guided_workflow`, `smart_score` |
| **Memory & Context** | 5 | `memory_loading`, `expand_analysis_section`, `get_server_context`, `update_knowledge`, `get_conversation_snapshot` |
| **Utilities** | 4+ | `manage_cache`, `set_project_path`, `get_current_datetime`, `load_prompt`, `tool_chain_orchestrator` |

**Key Tools Deep Dive:**

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `analyze_project_ecosystem` | Comprehensive recursive project analysis with Knowledge Generation + Reflexion | Start of any project analysis, technology detection |
| `perform_research` | Research-driven queries with cascading sources and confidence scoring | Architecture questions, technology decisions |
| `suggest_adrs` | Discover implicit architectural decisions in codebase | After codebase changes, before major refactoring |
| `validate_adr` / `validate_all_adrs` | Validate ADRs against live infrastructure reality | Pre-deployment, compliance checks |
| `deployment_readiness` | Zero-tolerance deployment validation with test tracking | Before any production deployment |
| `bootstrap_validation_loop` | Guided deployment with platform detection (OpenShift/K8s/Docker) | First-time deployment, CI/CD setup |
| `memory_loading` | Load ADRs into memory system for intelligent queries | Session start, context building |
| `smart_git_push` | Security-focused git operations with credential detection | Every git push operation |
| `troubleshoot_guided_workflow` | Systematic failure diagnosis with pattern recognition | Build failures, test failures, deployment issues |
| `smart_score` | Project health scoring with trend analysis | Health monitoring, improvement tracking |

**Memory System:**

The server maintains persistent context through:

1. **`.mcp-server-context.md`** - Auto-generated project memory file containing:
   - Project structure and technology stack
   - Existing ADRs and their status
   - Research findings and decisions
   - Knowledge graph state

2. **ADR Memory Loading** - Load ADRs into structured memory for:
   - Intelligent querying across decisions
   - Relationship discovery between ADRs
   - Implementation tracking

```bash
# Generate/update project context file
mcp__adr-analysis__get_server_context()

# Load ADRs into memory
mcp__adr-analysis__memory_loading(action: "load_adrs")
```

**Live Infrastructure Detection:**

| Platform | Detection | Validation |
|----------|-----------|------------|
| **Docker** | Dockerfile, docker-compose.yml, .dockerignore | Container health, image builds |
| **Kubernetes** | k8s/, kustomize/, helm/, *.yaml manifests | Deployment status, pod health |
| **OpenShift** | .s2i/, oc commands, OpenShift-specific configs | Route status, build configs |
| **Podman** | Containerfile, podman-compose | Container health |
| **Ansible** | ansible/, playbooks/, inventory | Playbook validation |

**Advanced AI Techniques:**

| Technique | Used In | Purpose |
|-----------|---------|---------|
| **APE (Automatic Prompt Engineering)** | ADR generation from PRD | Optimizes prompts for better output quality |
| **Knowledge Generation** | Project analysis, research | Generates domain-specific insights |
| **Reflexion** | Validation, troubleshooting | Learns from past outcomes to improve suggestions |

**When to Use mcp-adr-analysis-server:**

| Use Case | This Server | Alternative |
|----------|-------------|-------------|
| **ADR creation and management** | ✅ Best choice - AI-powered generation | Manual ADR templates |
| **Architecture decision tracking** | ✅ With validation against live infrastructure | Static documentation |
| **Pre-deployment validation** | ✅ Zero-tolerance gates with security scanning | CI/CD pipeline checks |
| **Infrastructure documentation** | ✅ Auto-detection of Docker/K8s/OpenShift | Manual documentation |
| **Security content scanning** | ✅ Built-in credential detection + masking | Dedicated secret scanners |
| **Research-driven decisions** | ✅ Confidence-scored multi-source research | Manual research |
| **Code-level static analysis** | Use narsil-mcp instead | ✅ narsil-mcp |
| **Real-time code intelligence** | Use mcpls instead | ✅ mcpls + LSP |

**Bifrost Configuration:**

```json
{
  "name": "adr-analysis",
  "command": "mcp-adr-analysis-server",
  "env": {
    "PROJECT_PATH": "/workspace",
    "ADR_DIRECTORY": "docs/adrs",
    "OPENROUTER_API_KEY": "${OPENROUTER_API_KEY}",
    "EXECUTION_MODE": "full"
  }
}
```

**Full-Featured Configuration:**

```json
{
  "name": "adr-analysis",
  "command": "mcp-adr-analysis-server",
  "env": {
    "PROJECT_PATH": "/workspace",
    "ADR_DIRECTORY": "docs/adrs",
    "OPENROUTER_API_KEY": "${OPENROUTER_API_KEY}",
    "EXECUTION_MODE": "full",
    "FIRECRAWL_API_KEY": "${FIRECRAWL_API_KEY}",
    "FIRECRAWL_ENABLED": "true"
  }
}
```

**Environment Variables:**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `OPENROUTER_API_KEY` | **Yes** | - | Required for AI-powered analysis |
| `EXECUTION_MODE` | Recommended | `prompt` | Set to `full` for actual results (not just prompts) |
| `PROJECT_PATH` | Optional | Current dir | Default project directory |
| `ADR_DIRECTORY` | Optional | `docs/adrs` | Where ADRs are stored |
| `FIRECRAWL_API_KEY` | Optional | - | For enhanced web research capabilities |
| `FIRECRAWL_ENABLED` | Optional | `false` | Enable Firecrawl integration |

**Troubleshooting:**

| Issue | Solution |
|-------|----------|
| Getting prompt-only responses | Set `EXECUTION_MODE=full` in environment |
| Low confidence scores | Check project files are accessible, enable Firecrawl for web research |
| ADRs not detected | Verify `ADR_DIRECTORY` path, run `discover_existing_adrs` |
| Memory not persisting | Call `get_server_context` to generate `.mcp-server-context.md` |
| Deployment blocked | Use `troubleshoot_guided_workflow` to diagnose issues |

**Integration with Other Tools:**

| Combined With | Use Case |
|--------------|----------|
| **narsil-mcp** | ADR analysis uses architectural context; narsil provides code-level intelligence |
| **code-guardian** | ADR validation + code quality gates for comprehensive deployment readiness |
| **basic-memory** | Store ADR decisions and research findings for long-term knowledge |
| **beads-mcp** | Track ADR implementation as tasks with dependencies |

---

### @swiftzilla/mcp

> Stop your AI agent from hallucinating Swift code with the only RAG API built for Apple Development

| | |
|---|---|
| **Website** | [swiftzilla.dev](https://swiftzilla.dev/) |
| **Repository** | [github.com/SwiftZilla/mcp](https://github.com/SwiftZilla/mcp) |
| **NPM** | [@swiftzilla/mcp](https://www.npmjs.com/package/@swiftzilla/mcp) |
| **Language** | TypeScript |
| **License** | ISC |
| **Pricing** | Free tier (50 queries/day) or $3/mo unlimited |
| **Install** | `npm install -g @swiftzilla/mcp` |

**Features:**
- 📚 **Official Documentation** - Complete indexing of Apple Developer Documentation and Swift API Guidelines
- 🎓 **WWDC Transcripts** - Searchable knowledge from framework engineers
- 🔄 **Daily Updates** - Re-indexed within 24 hours of Apple docs changes
- ⚡ **Swift 6.0 Ready** - Latest concurrency patterns, macros, and SwiftUI modifiers
- 🔌 **MCP Native** - Supports both SSE and STDIO transports

**Why SwiftZilla?**
General purpose LLMs struggle with Swift because:
- Training data cuts off before WWDC updates
- Hallucinated APIs that don't exist or were deprecated
- Broken SwiftUI views with invalid modifiers

SwiftZilla provides real-time access to 100,000+ pages of official docs, recipes, and evolution proposals.

**Compatible With:**
Cursor, Windsurf, Claude Desktop, Claude Code, VS Code Copilot, and any MCP-compatible agent.

**Bifrost Configuration:**
```json
{
  "name": "swiftzilla",
  "command": "npx",
  "args": ["-y", "@swiftzilla/mcp", "--api-key", "${SWIFTZILLA_API_KEY}"]
}
```

**Required Env Vars:**
- `SWIFTZILLA_API_KEY` - API key from [swiftzilla.dev](https://swiftzilla.dev/) (free tier available)

---

### reddit-mcp-buddy

> Clean, LLM-optimized Reddit MCP server - browse posts, search content, analyze users

| | |
|---|---|
| **Repository** | [github.com/karanb192/reddit-mcp-buddy](https://github.com/karanb192/reddit-mcp-buddy) |
| **NPM** | [reddit-mcp-buddy](https://www.npmjs.com/package/reddit-mcp-buddy) |
| **Language** | TypeScript |
| **License** | MIT |
| **Tools** | 5 |
| **Stars** | 187+ |
| **Install** | `npm install -g reddit-mcp-buddy` |

**Features:**
- 🚀 **Zero Setup** - Works instantly, no Reddit API registration needed
- ⚡ **Three-Tier Auth** - 10/60/100 requests per minute based on auth level
- 🎯 **Clean Data** - No fake "sentiment analysis" or made-up metrics
- 🧠 **LLM-Optimized** - Built specifically for AI assistants
- 📦 **Smart Caching** - 50MB memory-safe cache with adaptive TTLs

**Available Tools:**

| Tool | Description |
|------|-------------|
| `browse_subreddit` | Browse posts from any subreddit (hot, new, top, rising) |
| `search_reddit` | Search across Reddit with filters (subreddit, author, time, flair) |
| `get_post_details` | Get post with full comment threads |
| `user_analysis` | Analyze user karma, posts, comments, activity |
| `reddit_explain` | Explain Reddit terms (karma, cake day, AMA, etc.) |

**Rate Limits:**

| Mode | Requests/Min | Requirements |
|------|--------------|--------------|
| Anonymous | 10 | None |
| App-only | 60 | Client ID + Secret |
| Authenticated | 100 | All 4 credentials |

**Bifrost Configuration:**
```json
{
  "name": "reddit",
  "command": "npx",
  "args": ["-y", "reddit-mcp-buddy"]
}
```

**Optional Env Vars** (for higher rate limits):
- `REDDIT_CLIENT_ID` - Reddit app client ID
- `REDDIT_CLIENT_SECRET` - Reddit app secret
- `REDDIT_USERNAME` - Reddit account username
- `REDDIT_PASSWORD` - Reddit account password

---

### code-sentinel-mcp

> Comprehensive code quality analysis - detect security vulnerabilities, deceptive patterns, and incomplete code

| | |
|---|---|
| **Repository** | [github.com/salrad22/code-sentinel](https://github.com/salrad22/code-sentinel) |
| **NPM** | [code-sentinel-mcp](https://www.npmjs.com/package/code-sentinel-mcp) |
| **Remote** | [code-sentinel-mcp.sharara.dev](https://code-sentinel-mcp.sharara.dev/) |
| **Language** | TypeScript |
| **License** | MIT |
| **Tools** | 7 |
| **Patterns** | 93 |
| **Install** | `npm install -g code-sentinel-mcp` |

**Features:**
- 🔒 **Security Analysis** - 16 patterns: hardcoded secrets, SQL injection, XSS, command injection
- 🎭 **Deceptive Pattern Detection** - 17 patterns: empty catch blocks, silent failures, error hiding
- 📝 **Placeholder Detection** - 19 patterns: TODO/FIXME, lorem ipsum, incomplete implementations
- 🐛 **Error & Code Smell Detection** - 18 patterns: type coercion, null references, async anti-patterns
- ✅ **Strength Recognition** - 23 patterns: highlights good practices like proper typing, error handling

**Why Pattern-Based?**
Traditional linters detect syntax errors. CodeSentinel detects **semantically deceptive patterns** - code that is syntactically valid but hides serious issues that AI agents commonly produce:
- Empty catches that swallow errors
- Fake implementations (`return true; // TODO: implement`)
- Error-masking fallbacks (`|| []` hiding fetch failures)
- Linter suppression abuse (`@ts-ignore`)

**Available Tools:**

| Tool | Description |
|------|-------------|
| `analyze_code` | Full analysis returning structured JSON with issues and strengths |
| `generate_report` | Full analysis with visual HTML report |
| `check_security` | Security-focused vulnerability audit |
| `check_deceptive_patterns` | Detect error-hiding and false confidence patterns |
| `check_placeholders` | Find TODOs, dummy data, incomplete implementations |
| `analyze_patterns` | Architectural, design, and implementation pattern analysis |
| `analyze_design_patterns` | Gang of Four design pattern detection |

**Supported Languages:**
TypeScript, JavaScript, Python, Go, Rust, Java, Kotlin, Swift, C#, C/C++, PHP, Vue, Svelte

**Scoring Algorithm:**
```
Score = 100 - (critical × 25) - (high × 15) - (medium × 5) - (low × 1) + (strengths × 2)
```

**Bifrost Configuration:**
```json
{
  "name": "code-sentinel",
  "command": "npx",
  "args": ["code-sentinel-mcp"]
}
```

**No env vars required.**

---

### basic-memory

> AI conversations that actually remember - build persistent knowledge through natural conversations

| | |
|---|---|
| **Repository** | [github.com/basicmachines-co/basic-memory](https://github.com/basicmachines-co/basic-memory) |
| **Website** | [basicmemory.com](https://basicmemory.com) |
| **PyPI** | [basic-memory](https://pypi.org/project/basic-memory/) |
| **Language** | Python |
| **License** | AGPL-3.0 |
| **Stars** | 2.3k+ |
| **Tools** | 15+ |
| **Install** | `uv tool install basic-memory` |

**Features:**
- 🧠 **Persistent Memory** - AI assistants remember context across conversations
- 📝 **Markdown Files** - All knowledge stored as local Markdown files you control
- 🔗 **Knowledge Graph** - Semantic links between topics with traversable relationships
- 🔍 **Full-Text Search** - Search across your entire knowledge base
- 📁 **Obsidian Compatible** - Works with existing Markdown editors
- ☁️ **Cloud Sync** (Optional) - Cross-device sync with Basic Memory Cloud

**Available Tools:**

| Tool | Description |
|------|-------------|
| `write_note` | Create or update notes with semantic content |
| `read_note` | Read notes by title or permalink |
| `search` | Search across the knowledge base |
| `build_context` | Navigate knowledge graph via memory:// URLs |
| `recent_activity` | Find recently updated information |
| `edit_note` | Edit notes incrementally |
| `move_note` | Move notes with database consistency |
| `delete_note` | Delete notes from knowledge base |
| `canvas` | Generate knowledge visualizations |
| `list_memory_projects` | List all available projects |

**Semantic Markdown Format:**
```markdown
---
title: Coffee Brewing Methods
permalink: coffee-brewing-methods
tags: [coffee, brewing]
---

## Observations
- [method] Pour over provides more clarity #brewing
- [tip] Water temperature at 205°F extracts optimal compounds

## Relations
- relates_to [[Coffee Bean Origins]]
- requires [[Proper Grinding Technique]]
```

**Bifrost Configuration:**
```json
{
  "name": "basic-memory",
  "command": "uvx",
  "args": ["basic-memory", "mcp"]
}
```

**No env vars required.** Data stored in `~/basic-memory/` by default.

---

### beads-mcp

> A memory upgrade for your coding agent - distributed, git-backed graph issue tracker

| | |
|---|---|
| **Repository** | [github.com/steveyegge/beads](https://github.com/steveyegge/beads) |
| **NPM** | [@beads/bd](https://www.npmjs.com/package/@beads/bd) |
| **PyPI** | [beads-mcp](https://pypi.org/project/beads-mcp/) |
| **Language** | Go (94%), Python (4%) |
| **License** | MIT |
| **Stars** | 9.4k+ |
| **Contributors** | 131 |
| **Install** | `uv tool install beads-mcp` |

**Features:**

- **Git as Database** - Issues stored as JSONL in `.beads/`. Versioned, branched, and merged like code
- **Agent-Optimized** - JSON output, dependency tracking, auto-ready task detection
- **Zero Conflict** - Hash-based IDs (`bd-a1b2`) prevent merge collisions in multi-agent/multi-branch workflows
- **Invisible Infrastructure** - SQLite local cache for speed; background daemon for auto-sync
- **Compaction** - Semantic "memory decay" summarizes old closed tasks to save context window
- **Hierarchical IDs** - Supports epics (`bd-a3f8`) → tasks (`bd-a3f8.1`) → subtasks (`bd-a3f8.1.1`)
- **Stealth Mode** - `bd init --stealth` for personal use on shared projects without committing

**Essential Commands:**

| Command | Action |
|---------|--------|
| `bd ready` | List tasks with no open blockers |
| `bd create "Title" -p 0` | Create a P0 (critical) task |
| `bd dep add <child> <parent>` | Link tasks (blocks, related, parent-child) |
| `bd show <id>` | View task details and audit trail |
| `bd sync` | Sync with git remote |
| `bd stats` | Project statistics |

**Bifrost Configuration:**
```json
{
  "name": "beads",
  "command": "uvx",
  "args": ["beads-mcp"]
}
```

**No env vars required.** Issues stored in `.beads/` directory (git-tracked).

---

### cheetah-greb (Greb MCP)

> AI-powered intelligent code search - natural language queries with cloud GPU reranking

| | |
|---|---|
| **PyPI** | [cheetah-greb](https://pypi.org/project/cheetah-greb/) |
| **API** | `https://search.grebmcp.com` |
| **Language** | Python |
| **License** | MIT |
| **Python** | 3.10-3.13 (3.14 not yet supported) |
| **Install** | `uv tool install cheetah-greb` |

**Features:**

- 🔍 **Natural Language Search** - Search code using conversational queries like "find authentication middleware"
- 🧠 **AI-Powered Reranking** - Cloud GPU acceleration for intelligent result ranking
- 📊 **Relevance Scoring** - Each result includes score (0-1) and AI explanation of why it matches
- 🎯 **Code Spans** - Returns actual code context with surrounding lines
- 🔌 **Dual Integration** - REST API for programmatic access or MCP server for AI assistants

**Available Tools:**

| Tool | Description |
|------|-------------|
| `code_search` | Search code using natural language queries |

**Search Response Format:**
```json
{
  "results": [{
    "path": "src/middleware/auth.js",
    "line_start": 15,
    "line_end": 25,
    "score": 0.950,
    "reason": "Core authentication middleware with JWT verification",
    "span": { "text": "function authenticateToken(req, res, next)..." }
  }]
}
```

**Bifrost Configuration:**
```json
{
  "name": "greb-mcp",
  "command": "greb-mcp",
  "env": {
    "GREB_API_KEY": "${GREB_API_KEY}",
    "GREB_API_URL": "https://search.grebmcp.com"
  }
}
```

**Required Env Vars:**

| Variable | Description |
|----------|-------------|
| `GREB_API_KEY` | API key from Greb dashboard (format: `grb_xxx`) |

**Optional:** `GREB_API_URL` defaults to `https://search.grebmcp.com`

**Note:** First search is slower (~30-60s) as models download from HuggingFace. Subsequent searches are fast.

---

### kindly-web-search

> Web search + robust content retrieval for AI coding tools - returns the full conversation, not just snippets

| | |
|---|---|
| **Repository** | [github.com/Shelpuk-AI-Technology-Consulting/kindly-web-search-mcp-server](https://github.com/Shelpuk-AI-Technology-Consulting/kindly-web-search-mcp-server) |
| **Website** | [shelpuk.com](https://www.shelpuk.com) |
| **Language** | Python |
| **License** | MIT |
| **Stars** | 69+ |
| **Tools** | 2 |
| **Install** | `uv tool install git+https://github.com/Shelpuk-AI-Technology-Consulting/kindly-web-search-mcp-server` |

**Features:**

- 🔍 **Full Conversation Retrieval** - Returns questions, answers, comments, reactions - not just snippets
- 📚 **Direct API Integration** - StackExchange, GitHub Issues, arXiv, Wikipedia in LLM-optimized formats
- 🌐 **Real-Time Parsing** - Headless browser (Chromium) for cutting-edge issues posted yesterday
- 🔄 **Multi-Provider Support** - Serper (primary), Tavily, or self-hosted SearXNG
- 📦 **Replaces Multiple Tools** - Generic web search, StackOverflow, web scraping MCP servers

**Why Different?** Most web search MCPs return just title, URL, and snippet. Kindly returns the full page content (Markdown, best-effort) in a single call - no need for follow-up scraping.

**Available Tools:**

| Tool | Description |
|------|-------------|
| `web_search` | Search query → top results with title, link, snippet, and `page_content` (Markdown) |
| `get_content` | URL → full page content (Markdown, best-effort) |

**Bifrost Configuration:**
```json
{
  "name": "kindly-web-search",
  "command": "uvx",
  "args": [
    "--from", "git+https://github.com/Shelpuk-AI-Technology-Consulting/kindly-web-search-mcp-server",
    "kindly-web-search-mcp-server", "start-mcp-server"
  ],
  "env": {
    "SERPER_API_KEY": "${SERPER_API_KEY}",
    "GITHUB_TOKEN": "${GITHUB_TOKEN}"
  }
}
```

**Environment Variables:**

| Variable | Required | Description |
|----------|----------|-------------|
| `SERPER_API_KEY` | One of these | Serper search API (recommended) |
| `TAVILY_API_KEY` | One of these | Tavily search API (alternative) |
| `SEARXNG_BASE_URL` | One of these | Self-hosted SearXNG instance |
| `GITHUB_TOKEN` | Recommended | Better GitHub Issue extraction (read-only, public repos) |
| `KINDLY_BROWSER_EXECUTABLE_PATH` | Auto-detect | Override Chromium path if needed |

**Note:** Requires Chromium-based browser on same machine. Docker image includes Chromium for container deployments.

---

### code-guardian (CodeGuardian Studio)

> AI-powered code refactor engine for large repositories - 113+ MCP tools for code quality, workflow management, and automated optimization

| | |
|---|---|
| **Repository** | [github.com/phuongrealmax/code-guardian](https://github.com/phuongrealmax/code-guardian) |
| **NPM** | [codeguardian-studio](https://www.npmjs.com/package/codeguardian-studio) |
| **Website** | [codeguardian.studio](https://codeguardian.studio) |
| **Language** | TypeScript (97.4%) |
| **License** | MIT |
| **Version** | 4.1.1 |
| **Node.js** | >=18.0.0 |

**Overview:**

CodeGuardian Studio is a comprehensive MCP server providing **113+ tools** organized into specialized modules for code analysis, refactoring, workflow management, and AI-assisted development. Built for Claude Code integration.

**Core Modules:**

| Module | Tools | Purpose |
|--------|-------|---------|
| **Code Optimizer** | 8 | Scan repos, calculate metrics, detect hotspots, generate refactor plans |
| **Memory** | 5 | Persistent memory across sessions (decisions, patterns, conventions) |
| **Guard** | 6 | Code validation, fake test detection, security checks |
| **Workflow** | 12 | Task management, progress tracking, dependencies |
| **Latent Chain** | 15 | Multi-phase reasoning (analysis → plan → impl → review) |
| **Agents** | 7 | Specialized agent coordination and selection |
| **Thinking** | 10 | Structured reasoning models, code style references |
| **Documents** | 9 | Document registry, search, and management |
| **Testing** | 10 | Test execution, browser automation, coverage |
| **Resources** | 12 | Token budgeting, checkpoints, governor states |
| **Session** | 10 | Session lifecycle, timeline, export/resume |
| **AutoAgent** | 7 | Task decomposition, tool routing, error fix loops |
| **RAG** | 6 | Semantic code search with embeddings |
| **Progress** | 4 | Workflow visualization, blocker detection |
| **Proof Pack** | 3 | Tamper-evident validation records with SHA-256 |

**Key Features:**

- **Code Hotspot Detection** - Identifies files with high complexity and churn for prioritized refactoring
- **Latent Chain Mode** - 4-phase workflow (analysis → plan → impl → review) with context persistence
- **Memory Persistence** - Store decisions, patterns, and conventions across sessions
- **Token Budget Governor** - Manages context window usage with automatic checkpointing
- **Proof Packs** - Creates tamper-evident records of code validation with SHA-256 hashes
- **Browser Testing** - Playwright integration for visual testing and screenshot capture

**Bifrost Configuration:**

```json
{
  "name": "code-guardian",
  "command": "node",
  "args": ["/opt/mcp-servers/code-guardian/dist/index.js"],
  "env": {
    "CCG_PROJECT_ROOT": "/workspace"
  }
}
```

**Note:** Local server - copied into Docker image and built during image creation. Requires the `@ccg/cloud-client` package to be built first.

---

### mcpls + sourcekit-lsp

> Universal MCP-to-LSP bridge - expose Language Server Protocol capabilities as MCP tools for AI agents

| | |
|---|---|
| **Repository** | [github.com/bug-ops/mcpls](https://github.com/bug-ops/mcpls) |
| **Crates.io** | [mcpls](https://crates.io/crates/mcpls) |
| **Language** | Rust (99.7%) |
| **License** | MIT / Apache-2.0 |
| **Stars** | 7+ |
| **MSRV** | Rust 1.85+ |

**Overview:**

mcpls bridges the gap between AI coding assistants and language servers. Instead of treating code as text, it gives AI agents access to the same compiler-level understanding that IDEs have: type information, cross-references, semantic navigation, and real diagnostics.

**Why mcpls:**

- AI assistants "see" code as text, not as structured, typed systems
- mcpls exposes LSP capabilities through MCP, enabling compiler-level reasoning
- Zero configuration for Rust projects - just install and go

**MCP Tools:**

| Category | Tool | Description |
|----------|------|-------------|
| **Intelligence** | `get_hover` | Type signatures, documentation, inferred types |
| | `get_definition` | Jump to symbol definition across files |
| | `get_references` | Find all usages of a symbol workspace-wide |
| | `get_completions` | Context-aware suggestions respecting types/scope |
| | `get_document_symbols` | Structured outline (functions, types, imports) |
| | `workspace_symbol_search` | Find symbols by name across workspace |
| **Diagnostics** | `get_diagnostics` | Real compiler errors and warnings |
| | `get_cached_diagnostics` | Fast access to push-based diagnostics |
| | `get_code_actions` | Quick fixes and refactorings |
| **Refactoring** | `rename_symbol` | Workspace-wide rename with reference tracking |
| | `format_document` | Language-specific formatting |
| **Call Hierarchy** | `prepare_call_hierarchy` | Get callable items at position |
| | `get_incoming_calls` | Find all callers (who calls this?) |
| | `get_outgoing_calls` | Find all callees (what does this call?) |

**Supported Language Servers:**

| Language | Server | Notes |
|----------|--------|-------|
| **Swift** | sourcekit-lsp | Included in Swift toolchain |
| Rust | rust-analyzer | Zero-config, built-in |
| Python | pyright | Full type inference |
| TypeScript/JS | typescript-language-server | JSX/TSX support |
| Go | gopls | Modules and workspaces |
| C/C++ | clangd | compile_commands.json |

**Bifrost Configuration (Swift via sourcekit-lsp):**

```json
{
  "name": "mcpls",
  "command": "mcpls",
  "args": []
}
```

**mcpls Configuration (`~/.config/mcpls/mcpls.toml`):**

```toml
[[lsp_servers]]
language_id = "swift"
command = "sourcekit-lsp"
args = []
file_patterns = ["**/*.swift"]
```

**Architecture:**

```
AI Agent (Claude) ←→ MCP Protocol ←→ mcpls ←→ LSP Protocol ←→ Language Servers
                                                              ├── sourcekit-lsp (Swift)
                                                              ├── rust-analyzer (Rust)
                                                              └── pyright (Python)
```

**Note:** Single Rust binary with no runtime dependencies. The Docker image includes Swift 5.10.1 toolchain with sourcekit-lsp for Swift language intelligence.

---

### mcp-prompt-engine

> MCP server for managing and serving dynamic prompt templates using Go's powerful text/template engine

| | |
|---|---|
| **Repository** | [github.com/vasayxtx/mcp-prompt-engine](https://github.com/vasayxtx/mcp-prompt-engine) |
| **Docker** | [ghcr.io/vasayxtx/mcp-prompt-engine](https://ghcr.io/vasayxtx/mcp-prompt-engine) |
| **Language** | Go (97.5%) |
| **License** | MIT |
| **Stars** | 15+ |
| **Version** | 0.4.0 |

**Overview:**

MCP Prompt Engine is a server for managing reusable, logic-driven prompt templates. Create prompts with variables, partials, and conditionals that can be served to any MCP-compatible client (Claude Code, Claude Desktop, Gemini CLI, VSCode with Copilot).

**Key Features:**

- **Go Templates** - Full power of `text/template` syntax (variables, conditionals, loops)
- **Reusable Partials** - Define common components in `_partial.tmpl` files
- **Prompt Arguments** - Template variables automatically exposed as MCP prompt arguments
- **Hot-Reload** - Auto-detects file changes without server restart
- **JSON Argument Parsing** - Automatic parsing of booleans, numbers, arrays, objects
- **Environment Fallbacks** - Inject env vars as fallback values for arguments

**Template Syntax:**

```go
{{/* Brief description of the prompt */}}
{{- template "_partial_name" . -}}

Your prompt text with {{.variable}} placeholders.

{{if .condition}}
  Conditional content
{{end}}

{{range .items}}
  - {{.}}
{{end}}
```

**CLI Commands:**

| Command | Description |
|---------|-------------|
| `list` | List available prompts (add `--verbose` for details) |
| `render <name>` | Render a prompt with arguments (`-a key=value`) |
| `validate` | Check templates for syntax errors |
| `serve` | Start the MCP server |

**Bifrost Configuration:**

```json
{
  "name": "mcp-prompt-engine",
  "command": "mcp-prompt-engine",
  "args": [
    "--prompts", "/workspace/prompts",
    "serve", "--quiet"
  ]
}
```

**Prompt Directory Structure:**

```
prompts/
├── _header.tmpl          # Partial (reusable, starts with _)
├── _git_commit_role.tmpl # Partial for git commits
├── git_stage_commit.tmpl # Main prompt
└── code_review.tmpl      # Another prompt
```

**Note:** Supports any MCP client with prompts capability. Pre-built Docker image available at `ghcr.io/vasayxtx/mcp-prompt-engine`.

---

### local-file-organizer

> MCP server for intelligent file organization - automatically categorize and organize files by type with project-aware safety

| | |
|---|---|
| **Repository** | [github.com/diganto-deb/local_file_organizer](https://github.com/diganto-deb/local_file_organizer) |
| **Language** | Python |
| **License** | MIT |
| **Framework** | MCP Python SDK (FastMCP) |

**Overview:**

A file organization system that safely manages files across directories. Features smart categorization by file type, project directory detection to avoid disrupting code repositories, and detailed analytics on file distribution.

**File Categories:**

| Category | Extensions |
|----------|------------|
| Documents | PDF, DOC, DOCX, TXT, RTF, MD, HTML, JSON, CSV, XLSX |
| Images | JPG, PNG, GIF, SVG, WEBP, HEIC, TIFF, BMP |
| Videos | MP4, MOV, AVI, MKV, WMV, FLV, WEBM |
| Audio | MP3, WAV, OGG, FLAC, M4A, AAC |
| Archives | ZIP, RAR, 7Z, TAR, GZ, ISO, DMG |
| Code | PY, JS, TS, HTML, CSS, Java, Swift, Go, Rust |
| Applications | DMG, APP, EXE, MSI, PKG, APK |
| Others | Uncategorized files |

**MCP Tools:**

| Tool | Description |
|------|-------------|
| `list_categories` | List all file categories supported |
| `list_allowed_directories` | Show directories MCP server can access |
| `create_category_directories` | Create category folders in target directory |
| `list_directory_files` | List all files in a directory |
| `analyze_directory` | Categorize files without moving (preview mode) |
| `organize_files` | Move files into category directories |
| `get_metadata` | Detailed file/directory metadata and stats |
| `analyze_project_directories` | Identify project directories (won't be disrupted) |
| `bulk_move_files` | Move files by type or extension in batch |

**Key Features:**

- **Directory Security** - Only operates on explicitly allowed directories
- **Project Detection** - Identifies git repos, npm projects, etc. and avoids disrupting them
- **Recursive Processing** - Analyze and organize nested directory structures
- **Dry Run Mode** - Preview changes before executing (`confirm=false`)
- **Bulk Operations** - Move files by category or extension efficiently

**Bifrost Configuration:**

```json
{
  "name": "local-file-organizer",
  "command": "/opt/mcp-servers/local_file_organizer/venv/bin/python",
  "args": ["/opt/mcp-servers/local_file_organizer/file_organizer.py"]
}
```

**Note:** Local server - copied into Docker image with Python virtual environment. Respects project directories (detects `.git`, `package.json`, `Cargo.toml`, etc.).

---

## Data Persistence

| What | Where | Persisted |
|------|-------|-----------|
| MCP configs | `data/config.db` | ✅ Volume mount |
| Request logs | `data/logs.db` | ✅ Volume mount |
| Empirica data | `.empirica/` | ✅ Volume mount |
| Workspace | `/workspace` | ✅ Read-only mount |

## Environment Variables

Set in `~/.zshrc`, passed to container:

- `GREB_API_KEY` - Greb MCP (cheetah-greb cloud API)
- `SWIFTZILLA_API_KEY` - Swiftzilla
- `OPENROUTER_API_KEY` - LLM Council, ADR Analysis
- `SUPABASE_ACCESS_TOKEN` - Supabase MCP
- `SERPER_API_KEY` - Kindly web search
- `GITHUB_TOKEN` - GitHub operations

## Build Requirements

- **Rust 1.85+**: Required for narsil-mcp (uses `edition2024` feature)
- **Node.js 20**: For NPM-based MCP servers
- **Python 3.11**: For uv/pipx packages
- **Swift 5.10.1**: For sourcekit-lsp integration

## Adding New MCP Servers

### HTTP/SSE servers (no rebuild needed)
Add via Web UI at localhost:8080

### STDIO servers (rebuild required)
1. Add install command to `Dockerfile`
2. Run `bifrost-rebuild`
3. Configure via Web UI

## Troubleshooting

### MCP servers not showing in UI
Check that Bifrost is using the correct data directory:
```bash
bifrost-shell
cat /proc/1/cmdline | tr '\0' ' '
# Should show: /app/main -app-dir /app/data ...
```

### Container can't connect to host services
Use `host.docker.internal` instead of `localhost`

### Permission errors on mounted volumes
Bifrost runs as root in container, should auto-fix permissions.

### narsil-mcp build fails
Requires Rust 1.85+. The Dockerfile uses multi-stage build with `rust:1.85-bookworm`.
If build fails with "edition2024" error, update the Rust version in the builder stage.

### greb-mcp not working
Ensure `GREB_API_KEY` is set. Get key from https://grebmcp.com/
v2.x uses cloud API for GPU reranking - no local tree-sitter compilation needed.

### Colima storage corruption
If you see `containerd I/O error`, reset Colima:
```bash
pkill -9 -f colima && pkill -9 -f qemu
rm -rf ~/.colima
colima start --cpu 4 --memory 8 --disk 60
```
