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
| `bifrost-build` | Build Docker image (auto-cleans old images, preserves cache) |
| `bifrost-rebuild` | Force rebuild (no cache, cleans all) |
| `bifrost` | Start Bifrost gateway |
| `bifrost-stop` | Stop container |
| `bifrost-stop --colima` | Stop container + Colima |
| `bifrost-status` | Check Bifrost status & MCP count |
| `bifrost-shell` | Shell into running container |
| `bifrost-clean` | Clean dangling images (preserves build cache) |
| `bifrost-clean-all` | Deep clean: all unused images + build cache |

### Disk Space Management

The build commands automatically manage Docker disk space:

| Command | Dangling Images | Build Cache | Use Case |
|---------|-----------------|-------------|----------|
| `bifrost-build` | Cleans | **Preserved** | Normal builds (~1 min with cache) |
| `bifrost-rebuild` | Cleans | **Clears** | After Dockerfile changes |
| `bifrost-clean` | Cleans | **Preserved** | Quick cleanup |
| `bifrost-clean-all` | Cleans | **Clears** | Reclaim max disk space |

> **Tip**: Build cache enables ~1 min rebuilds vs 15-20 min cold builds. Only use `bifrost-rebuild` or `bifrost-clean-all` when you need to reclaim significant disk space.

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
| [exa-mcp](#exa-mcp) | Remote | AI-native web search, code context | None (hosted) |
| [supabase-mcp](#supabase-mcp) | Remote | Database, Edge Functions, branching | `SUPABASE_ACCESS_TOKEN` (local only) |

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
| **Tools** | 1 (Deep RAG Query) |
| **Index Size** | 100,000+ pages |
| **Pricing** | Free tier (50 queries/day) or $3/mo unlimited |
| **Install** | `npm install -g @swiftzilla/mcp` |

**Why SwiftZilla?**

General purpose LLMs (Claude, GPT, Gemini) struggle with Swift because:

| Problem | Impact |
|---------|--------|
| **Outdated Context** | Training data cuts off before WWDC - misses new APIs |
| **Hallucinated APIs** | Methods that don't exist or were deprecated years ago |
| **Broken Views** | SwiftUI preview crashes from invalid modifiers |
| **Wrong Patterns** | Deprecated concurrency patterns (pre-Swift 6) |

**Example LLM Hallucinations SwiftZilla Prevents:**
```swift
// ❌ Standard LLM Output (broken)
.navigationBarTitle("Home")        // Deprecated in iOS 16.0
.standardStyle(.prominent)         // This modifier doesn't exist

// ✅ SwiftZilla-Enhanced Output (correct)
.navigationTitle("Home")           // Current API
.toolbarBackground(.visible)       // Real modifier
```

**Data Sources Indexed:**

| Source | Content | Update Frequency |
|--------|---------|------------------|
| **Apple Developer Documentation** | Complete Swift, SwiftUI, UIKit, AppKit, Foundation APIs | Daily |
| **Swift API Design Guidelines** | Official naming and design conventions | On change |
| **WWDC Transcripts** | Searchable knowledge from Apple engineers | After each WWDC |
| **Swift Evolution Proposals** | SE-xxxx proposals, accepted and implemented | On change |
| **Swift Recipes** | Official code patterns and best practices | Weekly |

**Key Features:**

- 📚 **100,000+ Pages Indexed** - Complete Apple Developer ecosystem
- 🎓 **WWDC Transcripts** - Search sessions by topic, not just title
- 🔄 **24-Hour Update Cycle** - When Apple updates docs, SwiftZilla knows within a day
- ⚡ **Swift 6.0 Ready** - Latest concurrency patterns, macros, Observation framework
- 🔌 **MCP Native** - Supports both SSE and STDIO transports
- 🤖 **Agentic DeepSearch** - Interactive AI that can answer complex Swift questions

**SwiftZilla vs Competitors:**

| Feature | SwiftZilla | Apple RAG MCP | Apple Doc MCP | narsil-mcp (Swift) |
|---------|------------|---------------|---------------|---------------------|
| **Primary Focus** | Apple docs RAG | Apple docs RAG | Apple docs | Code analysis |
| **Documentation Scope** | 100,000+ pages | Docs + YouTube | Docs only | None (code only) |
| **WWDC Transcripts** | ✅ Searchable | ✅ Video content | ❌ | ❌ |
| **Swift Evolution** | ✅ | ❌ | ❌ | ❌ |
| **Update Frequency** | Daily | Real-time | Unknown | N/A |
| **AI Reranking** | ✅ | ✅ Qwen3-Reranker | ❌ | TF-IDF only |
| **Free Tier** | 50 queries/day | Free (limited) | Free | Unlimited (local) |
| **Paid Tier** | $3/mo unlimited | API key limits | N/A | N/A |
| **Agentic Search** | ✅ DeepSearch | ❌ | ❌ | ❌ |
| **Code Intelligence** | ❌ | ❌ | ❌ | ✅ (15 languages) |

**When to Use SwiftZilla:**

| Use Case | SwiftZilla | Alternative |
|----------|------------|-------------|
| **Swift/SwiftUI API lookup** | ✅ Best choice | Generic web search |
| **WWDC session content** | ✅ Searchable transcripts | YouTube manual search |
| **Latest iOS/macOS APIs** | ✅ Daily updates | LLM (stale knowledge) |
| **Swift 6 concurrency** | ✅ Current patterns | LLM (outdated patterns) |
| **Code analysis/navigation** | Use narsil-mcp | ✅ narsil-mcp |
| **Symbol definitions** | Use mcpls + sourcekit-lsp | ✅ mcpls |
| **Security scanning** | Use narsil-mcp | ✅ narsil-mcp |

**Architecture:**

```
Claude Code → @swiftzilla/mcp (STDIO) → swiftzilla.dev/mcp/sse (SSE) → RAG Index
                     ↓
              API Key Authentication
                     ↓
              Deep RAG Query Results
```

The MCP package acts as a **STDIO-to-SSE proxy**, connecting local MCP clients to SwiftZilla's cloud-hosted RAG infrastructure.

**Compatible Clients:**

| Client | Support | Notes |
|--------|---------|-------|
| **Claude Code** | ✅ | Full STDIO support |
| **Claude Desktop** | ✅ | Full STDIO support |
| **Cursor** | ✅ | Full MCP support |
| **Windsurf** | ✅ | Full MCP support |
| **VS Code Copilot** | ✅ | Via MCP extension |
| **Kilo Code** | ✅ | Full MCP support |
| **OpenCode** | ✅ | Full MCP support |
| **Augment Code** | ✅ | Full MCP support |

**Bifrost Configuration:**
```json
{
  "name": "swiftzilla",
  "command": "npx",
  "args": ["-y", "@swiftzilla/mcp", "--api-key", "${SWIFTZILLA_API_KEY}"]
}
```

**Alternative Configuration (Environment Variable):**
```json
{
  "name": "swiftzilla",
  "command": "npx",
  "args": ["-y", "@swiftzilla/mcp"],
  "env": {
    "API_KEY": "${SWIFTZILLA_API_KEY}"
  }
}
```

**Environment Variables:**

| Variable | Required | Description |
|----------|----------|-------------|
| `SWIFTZILLA_API_KEY` | **Yes** | API key from [swiftzilla.dev](https://swiftzilla.dev/) |

**Getting an API Key:**

1. Go to [swiftzilla.dev](https://swiftzilla.dev/)
2. Click "Get Developer Access" (GitHub OAuth)
3. Free tier: 50 deep RAG queries per day
4. Developer Pass ($3/mo): Unlimited queries, priority handling

**Rate Limits:**

| Tier | Queries/Day | Priority |
|------|-------------|----------|
| Free | 50 | Standard |
| Developer ($3/mo) | Unlimited | Priority |
| Community Pool | Shared 10M tokens | While supplies last |

**Example Usage:**

When working on Swift/Apple development, SwiftZilla is automatically used by the AI agent to look up:

- SwiftUI view modifiers and their parameters
- Swift concurrency patterns (async/await, actors, Sendable)
- Foundation API signatures and behavior
- Platform availability (`@available` annotations)
- Deprecated API replacements

**Troubleshooting:**

| Issue | Solution |
|-------|----------|
| "API key invalid" | Verify key format, regenerate at swiftzilla.dev/dashboard |
| "Rate limit exceeded" | Upgrade to Developer Pass or wait for daily reset |
| Stale results | SwiftZilla updates daily; report issues via dashboard |
| Connection timeout | Check network; SwiftZilla uses SSE which may be blocked by firewalls |

**Integration with Other Bifrost Tools:**

| Combined With | Use Case |
|---------------|----------|
| **narsil-mcp** | SwiftZilla for API docs, narsil for code navigation/call graphs |
| **mcpls + sourcekit-lsp** | SwiftZilla for docs, mcpls for real-time type info/completions |
| **code-sentinel** | SwiftZilla for correct patterns, code-sentinel for quality checks |
| **basic-memory** | Store SwiftZilla findings for long-term project knowledge |

---

### reddit-mcp-buddy

> Clean, LLM-optimized Reddit MCP server - browse posts, search content, analyze users. No fluff, just Reddit data.

| | |
|---|---|
| **Repository** | [github.com/karanb192/reddit-mcp-buddy](https://github.com/karanb192/reddit-mcp-buddy) |
| **NPM** | [reddit-mcp-buddy](https://www.npmjs.com/package/reddit-mcp-buddy) |
| **MCP Registry** | [registry.modelcontextprotocol.io](https://registry.modelcontextprotocol.io/v0/servers/5677b351-373d-4137-bc58-28f1ba0d105d) |
| **Language** | TypeScript (68%), JavaScript (17%), Shell (14%) |
| **License** | MIT |
| **Tools** | 5 |
| **Stars** | 187+ |
| **Forks** | 34 |
| **Version** | 1.1.10 |
| **Node.js** | >=18.0.0 |
| **Install** | `npm install -g reddit-mcp-buddy` or `npx -y reddit-mcp-buddy` |

**Why reddit-mcp-buddy?**

| Feature | reddit-mcp-buddy | Other Reddit MCPs |
|---------|------------------|-------------------|
| **Zero Setup** | ✅ Works instantly | ❌ Requires API keys |
| **Max Rate Limit** | ✅ 100 req/min (proven) | ❓ Unverified claims |
| **Language** | TypeScript/Node.js | Python (most) |
| **Tools Count** | 5 (focused) | 8-10 (redundant) |
| **Fake Metrics** | ✅ Real data only | ❌ "Sentiment scores" |
| **Search** | ✅ Full search | Limited or none |
| **Caching** | ✅ Smart 50MB cache | Usually none |
| **LLM Optimized** | ✅ Clear params | Confusing options |
| **Rate Limit Testing** | ✅ Built-in tools | ❌ No verification |
| **Desktop Extension** | ✅ `.mcpb` one-click install | ❌ Manual config |

**What Makes It Different:**

Most Reddit MCP servers suffer from common problems:
- ❌ **Fake metrics** - "Sentiment scores" that are just keyword counting
- ❌ **Complex setup** - Requiring API keys just to start
- ❌ **Bloated responses** - Returning 100+ fields of Reddit's raw API
- ❌ **Poor LLM integration** - Confusing parameters and unclear descriptions

reddit-mcp-buddy does it right:
- ✅ **Real data only** - If it's not from Reddit's API, it's not made up
- ✅ **Clean responses** - Only the fields that matter
- ✅ **Clear parameters** - LLMs understand exactly what to send
- ✅ **Fast & cached** - Responses are instant when possible

**Key Features:**

- 🚀 **Zero Setup** - Works instantly, no Reddit API registration needed
- ⚡ **Three-Tier Auth** - 10/60/100 requests per minute based on auth level
- 🎯 **Clean Data** - No fake "sentiment analysis" or made-up metrics
- 🧠 **LLM-Optimized** - Built specifically for AI assistants like Claude
- 📦 **Smart Caching** - 50MB memory-safe cache with adaptive TTLs
- 🔒 **Privacy-First** - No tracking, no analytics, all data stays local
- 📋 **Read-Only** - Never posts, comments, or modifies Reddit content

**Available Tools:**

| Tool | Description | Key Parameters |
|------|-------------|----------------|
| `browse_subreddit` | Browse posts from any subreddit (hot, new, top, rising, controversial) | `subreddit`, `sort`, `time`, `limit`, `include_subreddit_info` |
| `search_reddit` | Search across Reddit with filters (subreddit, author, time, flair) | `query`, `subreddits[]`, `sort`, `time`, `author`, `flair` |
| `get_post_details` | Get post with full comment threads | `url` OR `post_id`, `comment_sort`, `comment_depth`, `max_top_comments` |
| `user_analysis` | Analyze user karma, posts, comments, activity patterns | `username`, `posts_limit`, `comments_limit`, `time_range` |
| `reddit_explain` | Explain Reddit terms (karma, cake day, AMA, ELI5, etc.) | `term` |

**Tool Deep Dive:**

**`browse_subreddit`** - Fetch posts from any subreddit:
```
- Subreddit options:
  - "all" - entire Reddit frontpage
  - "popular" - trending across Reddit
  - Any specific subreddit (e.g., "technology", "programming")
- Sort: hot, new, top, rising, controversial
- Time range: hour, day, week, month, year, all (for top/controversial)
- Limit: 1-100 posts (default 25)
- include_subreddit_info: Optional metadata (subscriber count, description)
```

**`search_reddit`** - Search across Reddit:
```
- Query: Your search terms
- Filter by: subreddit, author, time, flair
- Sort: relevance, hot, top, new, comments
```

**`get_post_details`** - Get post with comments:
```
- Input options:
  - Reddit URL (full URL including subreddit) - 1 API call
  - Post ID + subreddit (most efficient) - 1 API call
  - Post ID alone (auto-detects subreddit) - 2 API calls
- comment_sort: best, top, new, controversial, qa
- comment_depth: 1-10 (default 3)
- max_top_comments: 1-20 (default 5)
- extract_links: Include embedded links
```

**`user_analysis`** - Analyze Reddit users:
```
- Returns: karma breakdown, posts, comments, active subreddits
- posts_limit: 0-100 (default 10)
- comments_limit: 0-100 (default 10)
- time_range: day, week, month, year, all
- top_subreddits_limit: 1-50 (default 10)
```

**Three-Tier Authentication System:**

| Mode | Rate Limit | Cache TTL | Required Credentials | Best For |
|------|------------|-----------|----------------------|----------|
| **Anonymous** | 10 req/min | 15 min | None | Testing, light usage |
| **App-Only** | 60 req/min | 5 min | Client ID + Secret | Regular browsing |
| **Authenticated** | 100 req/min | 5 min | All 4 credentials | Heavy usage, automation |

**Authentication Setup (for higher rate limits):**

1. Go to [reddit.com/prefs/apps](https://www.reddit.com/prefs/apps)
2. Click "Create App" or "Create Another App"
3. Fill out the form:
   - **Name**: Any name (e.g., "reddit-mcp-buddy")
   - **App type**: Select **"script"** (CRITICAL for 100 rpm!)
   - **Redirect URI**: `http://localhost:8080` (required but unused)
4. Get your **Client ID** (under app name) and **Client Secret**

**Important**: Script apps support BOTH app-only (60 rpm) and authenticated (100 rpm) modes. Web apps only support app-only mode (60 rpm maximum). For 100 requests/minute, you MUST use a script app with username + password.

**Smart Caching System:**

| Feature | Description |
|---------|-------------|
| **Memory Safe** | Hard limit of 50MB - won't affect system performance |
| **Adaptive TTLs** | Hot posts (5min), New posts (2min), Top posts (30min) |
| **LRU Eviction** | Automatically removes least-used data when approaching limits |
| **Hit Tracking** | Optimizes cache based on actual usage patterns |
| **Disable Option** | Set `REDDIT_BUDDY_NO_CACHE=true` to always fetch fresh |

**When to Use reddit-mcp-buddy:**

| Use Case | reddit-mcp-buddy | Alternative |
|----------|------------------|-------------|
| **Quick Reddit research** | ✅ Best choice - zero setup | Other MCPs (require API keys) |
| **Trend analysis** | ✅ Browse hot/top/rising | Basic search MCPs |
| **User activity analysis** | ✅ Built-in user_analysis | Manual browsing |
| **Comment thread analysis** | ✅ Full comment trees | Limited depth MCPs |
| **Reddit terminology help** | ✅ reddit_explain tool | Web search |
| **Posting/commenting** | ❌ Read-only by design | jordanburke/reddit-mcp-server |
| **Moderation tasks** | ❌ No mod tools | Reddit's official API |

**Comparison with Other Reddit MCP Servers:**

| Server | Stars | Language | Auth Required | Tools | Write Access | Caching |
|--------|-------|----------|---------------|-------|--------------|---------|
| **reddit-mcp-buddy** | 187+ | TypeScript | No (optional) | 5 | ❌ Read-only | ✅ 50MB smart cache |
| adhikasp/mcp-reddit | ~50 | Python | Yes | 6 | ❌ Read-only | ❌ None |
| jordanburke/reddit-mcp-server | 7 | TypeScript | Yes | 8+ | ✅ Can post | ❌ None |
| GridfireAI/reddit-mcp | ~10 | Python | Yes | 4 | ❌ Read-only | ❌ None |

**Privacy & Data Handling:**

- **No Tracking**: No analytics, telemetry, or usage data collected
- **No Third Parties**: Data flows directly between your machine and Reddit's API
- **Local Cache Only**: Temporary in-memory cache, cleared on server stop
- **Credentials**: Stored locally in `~/.reddit-mcp-buddy/auth.json` (password never written to disk)
- **Open Source**: Full source available for security auditing

**Bifrost Configuration:**

```json
{
  "name": "reddit",
  "command": "npx",
  "args": ["-y", "reddit-mcp-buddy"]
}
```

**Authenticated Configuration (60-100 req/min):**

```json
{
  "name": "reddit",
  "command": "npx",
  "args": ["-y", "reddit-mcp-buddy"],
  "env": {
    "REDDIT_CLIENT_ID": "${REDDIT_CLIENT_ID}",
    "REDDIT_CLIENT_SECRET": "${REDDIT_CLIENT_SECRET}",
    "REDDIT_USERNAME": "${REDDIT_USERNAME}",
    "REDDIT_PASSWORD": "${REDDIT_PASSWORD}"
  }
}
```

**Environment Variables:**

| Variable | Required | Description | Rate Limit Impact |
|----------|----------|-------------|-------------------|
| `REDDIT_CLIENT_ID` | No | Reddit app client ID | 60 req/min (with secret) |
| `REDDIT_CLIENT_SECRET` | No | Reddit app secret | 60 req/min (with ID) |
| `REDDIT_USERNAME` | No | Reddit account username | 100 req/min (with all 4) |
| `REDDIT_PASSWORD` | No | Reddit account password | 100 req/min (with all 4) |
| `REDDIT_USER_AGENT` | No | Custom user agent string | - |
| `REDDIT_BUDDY_HTTP` | No | Run as HTTP server instead of stdio | - |
| `REDDIT_BUDDY_PORT` | No | HTTP server port (default: 3000) | - |
| `REDDIT_BUDDY_NO_CACHE` | No | Disable caching (always fetch fresh) | - |

**Example Queries:**

Ask your AI assistant:

| Query | Tool Used |
|-------|-----------|
| "What's trending on Reddit?" | `browse_subreddit` (subreddit="all", sort="hot") |
| "Search for discussions about AI" | `search_reddit` (query="AI") |
| "Get comments from this Reddit post" | `get_post_details` (url="...") |
| "Analyze user spez" | `user_analysis` (username="spez") |
| "Explain Reddit karma" | `reddit_explain` (term="karma") |
| "What's hot in r/technology?" | `browse_subreddit` (subreddit="technology", sort="hot") |
| "Top posts about GPT-4 this week" | `search_reddit` (query="GPT-4", time="week", sort="top") |

**Troubleshooting:**

| Issue | Solution |
|-------|----------|
| "Can't achieve 100 requests/minute" | Ensure app type is **"script"** not "web" or "installed". Script apps created by one account can only authenticate as that same account. |
| "Command not found" error | Ensure npm is installed: `node --version && npm --version`. Try with full path: `$(npm bin -g)/reddit-mcp-buddy` |
| Rate limit errors | Add Reddit credentials (see Authentication Setup above) |
| "Subreddit not found" | Check spelling (case-insensitive). Some subreddits may be private or quarantined. Try "all" or "popular" instead. |
| Connection issues | Check [redditstatus.com](https://www.redditstatus.com). Firewall may be blocking requests. Try restarting MCP server. |

**Integration with Other Bifrost Tools:**

| Combined With | Use Case |
|---------------|----------|
| **basic-memory** | Store Reddit research findings for long-term project knowledge |
| **mcp-adr-analysis** | Research community sentiment before architectural decisions |
| **kindly-web-search** | Combine Reddit discussions with broader web research |
| **narsil-mcp** | Find Reddit discussions about specific code patterns |

**Testing & Development:**

```bash
# Clone repository for testing
git clone https://github.com/karanb192/reddit-mcp-buddy.git
cd reddit-mcp-buddy
npm install

# Test rate limits
npm run test:rate-limit           # Test with current environment
npm run test:rate-limit:anon      # Test anonymous mode (10 rpm)
npm run test:rate-limit:app       # Test app-only mode (60 rpm)
npm run test:rate-limit:auth      # Test authenticated mode (100 rpm)

# Run in HTTP mode for testing
npx -y reddit-mcp-buddy --http    # Runs on port 3000
REDDIT_BUDDY_PORT=8080 npx -y reddit-mcp-buddy --http  # Custom port

# Interactive auth setup (local testing only)
npx -y reddit-mcp-buddy --auth
```

**Related Resources:**

- [MCP Registry Entry](https://registry.modelcontextprotocol.io/v0/servers/5677b351-373d-4137-bc58-28f1ba0d105d)
- [MCP Specification](https://spec.modelcontextprotocol.io)
- [MCP TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk)
- [Reddit API Documentation](https://www.reddit.com/dev/api/)

---

### code-sentinel-mcp

> Comprehensive code quality analysis - detect security vulnerabilities, deceptive patterns, and incomplete code that passes traditional linters

| | |
|---|---|
| **Repository** | [github.com/salrad22/code-sentinel](https://github.com/salrad22/code-sentinel) |
| **NPM** | [code-sentinel-mcp](https://www.npmjs.com/package/code-sentinel-mcp) |
| **Remote** | [code-sentinel-mcp.sharara.dev](https://code-sentinel-mcp.sharara.dev/) |
| **Language** | TypeScript |
| **License** | MIT |
| **Tools** | 7 |
| **Patterns** | 93 distinct patterns across 5 categories |
| **Install** | `npm install -g code-sentinel-mcp` |
| **Version** | 0.2.6 (latest) |

**The Problem Code Sentinel Solves:**

AI-generated code often produces **syntactically correct but semantically deceptive** patterns that pass all traditional linters. These include:

```typescript
// Passes ESLint, fails Code Sentinel (CS-DEC-006: empty catch)
try {
  await criticalOperation();
} catch (error) {
  // TODO: handle error
}

// Passes ESLint, fails Code Sentinel (CS-DEC-003: fake success)
async function validateUser(id: string): Promise<boolean> {
  return true; // TODO: implement actual validation
}

// Passes ESLint, fails Code Sentinel (CS-DEC-010: error-masking fallback)
const users = await fetchUsers().catch(() => []);
```

**Why Code Sentinel vs Traditional Tools:**

| Capability | ESLint/TSLint | Tree-sitter | Semgrep | Codacy | Code Sentinel |
|------------|---------------|-------------|---------|--------|---------------|
| Syntax errors | Yes | Yes | Yes | Yes | No (use linter) |
| Security patterns | Limited | No | Yes | Yes | Yes (16 patterns) |
| Deceptive patterns | No | No | Limited | No | **Yes (17 patterns)** |
| Placeholder detection | No | No | No | No | **Yes (19 patterns)** |
| Strength recognition | No | No | No | Limited | **Yes (23 patterns)** |
| AI-generated code focus | No | No | No | No | **Primary focus** |
| Pattern-based (not AST) | No | No | Yes | Mixed | **Yes (intentional)** |
| Offline/local | Yes | Yes | Yes | No | Yes |
| Zero config | Varies | Yes | No | No | **Yes** |

**When to Use Code Sentinel:**

| Use Case | Recommended Tool | Why |
|----------|------------------|-----|
| Syntax checking | ESLint/Prettier | Faster, purpose-built |
| Security audit (rules-based) | Semgrep | 3000+ community rules |
| Platform code quality | Codacy | Dashboard, team features |
| **AI output validation** | **Code Sentinel** | Catches deceptive patterns |
| **PR review automation** | **Code Sentinel** | Detects incomplete implementations |
| **Before production deploy** | **Code Sentinel** | Catches hidden failures |
| Refactoring assistance | Code Guardian | 113+ refactoring tools |
| Call graph analysis | Narsil MCP | AST-based navigation |

**Pattern Categories (93 Total):**

| Category | Count | ID Prefix | Examples |
|----------|-------|-----------|----------|
| **Security** | 16 | `CS-SEC-*` | Hardcoded secrets, SQL injection, XSS, command injection, path traversal, weak crypto |
| **Deceptive** | 17 | `CS-DEC-*` | Empty catch blocks, silent failures, fake implementations, error-masking fallbacks |
| **Placeholders** | 19 | `CS-PH-*` | TODO/FIXME markers, lorem ipsum, hardcoded test data, incomplete stubs |
| **Errors/Smells** | 18 | `CS-ERR-*` | Type coercion bugs, null reference risks, async anti-patterns, memory leaks |
| **Strengths** | 23 | `CS-STR-*` | Proper typing, error handling, input validation, security headers |

**Available Tools:**

| Tool | Description | Best For |
|------|-------------|----------|
| `analyze_code` | Full analysis returning structured JSON with issues and strengths | CI/CD integration, programmatic analysis |
| `generate_report` | Full analysis with visual HTML report | Human review, PR comments |
| `check_security` | Security-focused vulnerability audit | Security reviews, pre-deploy |
| `check_deceptive_patterns` | Detect error-hiding and false confidence patterns | AI output validation |
| `check_placeholders` | Find TODOs, dummy data, incomplete implementations | Pre-merge gates |
| `analyze_patterns` | Architectural, design, and implementation pattern analysis | Architecture reviews |
| `analyze_design_patterns` | Gang of Four design pattern detection | Design audits |

**Tool Parameters:**

```typescript
// analyze_code
{
  code: string;           // Required: source code to analyze
  language?: string;      // Optional: auto-detected if not provided
  filename?: string;      // Optional: helps with language detection
}

// generate_report
{
  code: string;
  language?: string;
  filename?: string;
  format?: 'html' | 'json';  // Default: html
}
```

**Supported Languages:**
TypeScript, JavaScript, Python, Go, Rust, Java, Kotlin, Swift, C#, C/C++, PHP, Vue, Svelte

**Scoring Algorithm:**
```
Score = 100 - (critical × 25) - (high × 15) - (medium × 5) - (low × 1) + (strengths × 2)
```

- **90-100**: Excellent - Production ready
- **70-89**: Good - Minor issues to address
- **50-69**: Fair - Significant issues present
- **Below 50**: Poor - Major refactoring needed

**Sample Output:**

```json
{
  "score": 72,
  "issues": [
    {
      "id": "CS-DEC-006",
      "category": "deceptive",
      "severity": "high",
      "message": "Empty catch block swallows errors silently",
      "line": 45,
      "suggestion": "Log the error or rethrow with context"
    }
  ],
  "strengths": [
    {
      "id": "CS-STR-001",
      "category": "strengths",
      "message": "Proper TypeScript strict typing used",
      "line": 1
    }
  ],
  "summary": {
    "total_issues": 3,
    "critical": 0,
    "high": 1,
    "medium": 2,
    "low": 0,
    "strengths_found": 5
  }
}
```

**Extensibility - Data-Driven Patterns:**

Code Sentinel uses a data-driven pattern system. Each pattern is defined declaratively with match types:

| Match Type | Purpose | Example Pattern |
|------------|---------|-----------------|
| `empty_block` | Detects empty code blocks | Empty catch handlers |
| `function_call` | Matches specific function calls | `console.log` in production |
| `catch_handler` | Analyzes error handling | Silent error swallowing |
| `secret_pattern` | Regex-based secret detection | API keys, passwords |
| `string_literal` | Matches string content | Hardcoded credentials |
| `comment_marker` | Finds comment patterns | TODO, FIXME, HACK |

**Adding Custom Patterns** (future roadmap):
```json
{
  "id": "CUSTOM-001",
  "name": "Deprecated API Usage",
  "category": "errors",
  "severity": "medium",
  "match_type": "function_call",
  "pattern": "legacyApi\\.",
  "message": "Legacy API is deprecated, use newApi instead",
  "suggestion": "Migrate to newApi.* methods"
}
```

**Bifrost Configuration (Local):**
```json
{
  "name": "code-sentinel",
  "command": "npx",
  "args": ["code-sentinel-mcp"]
}
```

**Bifrost Configuration (Remote - No Local Install):**
```json
{
  "name": "code-sentinel",
  "transport": {
    "type": "sse",
    "url": "https://code-sentinel-mcp.sharara.dev/sse"
  }
}
```

The remote server runs on Cloudflare Workers with Durable Objects for stateful MCP sessions.

**No env vars required.**

**Integration with Other MCP Tools:**

Code Sentinel works best as part of a validation pipeline:

```
1. Narsil MCP     → Navigate codebase, find code to review
2. Code Sentinel  → Analyze for deceptive patterns and issues
3. Semgrep MCP    → Deep security rule scanning (if needed)
4. Basic Memory   → Store findings for future reference
```

**CI/CD Integration Example:**

```yaml
# .github/workflows/code-quality.yml
- name: Code Sentinel Analysis
  run: |
    npx code-sentinel-mcp analyze-code \
      --file src/**/*.ts \
      --format json \
      --fail-on-score 70
```

**Troubleshooting:**

| Issue | Cause | Solution |
|-------|-------|----------|
| "Language not detected" | Missing filename/extension | Provide `language` parameter explicitly |
| Low score on valid code | Overly strict patterns | Review specific pattern IDs, consider context |
| Remote server timeout | Network/server issues | Fall back to local `npx` installation |
| Missing patterns in output | Pattern not applicable to language | Check language support for specific pattern |

**Competitor Comparison:**

| Tool | Focus | Strengths | Limitations |
|------|-------|-----------|-------------|
| **Code Sentinel** | AI code validation | Deceptive pattern detection, zero-config, offline | Not a linter replacement |
| **Codacy MCP** | Platform integration | Dashboard, team features, 40+ language support | Requires Codacy account/API |
| **Semgrep MCP** | Security scanning | 3000+ rules, custom rules | Security-focused only, complex setup |
| **Code Guardian** | Refactoring | 113+ tools, workflow automation | Broad scope, less specialized |

**Related Resources:**

- [Code Sentinel GitHub](https://github.com/salrad22/code-sentinel)
- [NPM Package](https://www.npmjs.com/package/code-sentinel-mcp)
- [Remote Server](https://code-sentinel-mcp.sharara.dev/)
- [Pattern Documentation](https://github.com/salrad22/code-sentinel#patterns)

---

### basic-memory

> AI conversations that actually remember - build persistent knowledge through natural conversations

| | |
|---|---|
| **Repository** | [github.com/basicmachines-co/basic-memory](https://github.com/basicmachines-co/basic-memory) |
| **Website** | [basicmemory.com](https://basicmemory.com) |
| **Documentation** | [docs.basicmemory.com](https://docs.basicmemory.com) |
| **PyPI** | [basic-memory](https://pypi.org/project/basic-memory/) |
| **Language** | Python 3.12+ |
| **License** | AGPL-3.0 |
| **Version** | 0.17.4+ |
| **Stars** | 2.3k+ |
| **Tools** | 15+ MCP tools |
| **Install** | `uv tool install basic-memory` or `pipx install basic-memory` |

**Core Architecture:**

```
┌─────────────────────────────────────────────────────────────────┐
│                     AI Assistants                                │
│     (Claude Desktop, Claude Code, Cursor, VS Code)              │
└─────────────────────────┬───────────────────────────────────────┘
                          │ MCP Protocol
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Basic Memory Server                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ MCP Tools   │  │ Knowledge   │  │ Full-Text + Semantic    │  │
│  │ (15+ tools) │  │ Graph       │  │ Search (SQLite FTS5)    │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────┬───────────────────────────────────────┘
                          │
           ┌──────────────┼──────────────┐
           ▼              ▼              ▼
    ┌────────────┐ ┌────────────┐ ┌────────────┐
    │ Markdown   │ │ SQLite     │ │ Basic      │
    │ Files      │ │ Index      │ │ Memory     │
    │ (local)    │ │ (local)    │ │ Cloud      │
    └────────────┘ └────────────┘ └────────────┘
```

**Why Basic Memory?**

| Problem | Basic Memory Solution |
|---------|----------------------|
| **AI Amnesia** | Persistent knowledge graph survives conversation restarts |
| **Vendor Lock-in** | Plain Markdown files you own - no proprietary formats |
| **Context Limits** | `build_context` retrieves relevant knowledge on-demand |
| **Knowledge Silos** | Semantic links connect related topics automatically |
| **Manual Handoffs** | `recent_activity` shows what changed across sessions |

**Core Features:**

- 🧠 **Persistent Memory** - AI assistants remember context across conversations and sessions
- 📝 **Markdown Files** - All knowledge stored as local Markdown files you control
- 🔗 **Knowledge Graph** - Semantic links between topics with traversable relationships via WikiLinks
- 🔍 **Full-Text + Semantic Search** - SQLite FTS5 powered search across your entire knowledge base
- 📁 **Obsidian Compatible** - Works with existing Markdown editors (Obsidian, VS Code, etc.)
- 🔄 **File Watching** - Automatic sync when files change externally
- 🏷️ **Tags & Categories** - Organize knowledge with hashtags and observation categories
- 📊 **Canvas Visualization** - Generate visual knowledge maps compatible with Obsidian Canvas
- ☁️ **Cloud Sync** (Optional) - Cross-device sync with Basic Memory Cloud ($14.25/mo)

**Available MCP Tools:**

| Tool | Description | Example Use |
|------|-------------|-------------|
| `write_note` | Create or update notes with semantic content | Store meeting notes, decisions, research |
| `read_note` | Read notes by title or permalink | Retrieve specific knowledge |
| `view_note` | View note as formatted artifact | Better readability for complex notes |
| `search_notes` | Full-text search with filters | Find information by keyword |
| `search` | Quick content search | Fast lookups |
| `build_context` | Navigate knowledge graph via `memory://` URLs | Continue from previous discussions |
| `recent_activity` | Find recently updated information | Session handoffs, "what changed?" |
| `edit_note` | Incremental edits (append, prepend, replace) | Update existing knowledge |
| `move_note` | Move notes maintaining database consistency | Reorganize knowledge structure |
| `delete_note` | Remove notes from knowledge base | Clean up outdated information |
| `canvas` | Generate Obsidian-compatible visualizations | Create knowledge maps |
| `list_memory_projects` | List all available projects | Multi-project management |
| `create_memory_project` | Create new knowledge project | Start fresh knowledge base |
| `delete_project` | Remove a project | Clean up unused projects |
| `list_directory` | Browse knowledge structure | Explore folder organization |
| `read_content` | Read raw file content by path | Access specific files |

**Knowledge Format - Semantic Markdown:**

Basic Memory uses a structured Markdown format with three key sections:

```markdown
---
title: Coffee Brewing Methods
type: reference
permalink: coffee-brewing-methods
tags: [coffee, brewing, specialty]
created: 2024-01-15
modified: 2024-01-20
---

## Observations

Observations capture discrete facts with optional categories and tags:

- [method] Pour over provides more clarity and highlights origin flavors #brewing #manual
- [tip] Water temperature at 195-205°F extracts optimal compounds #temperature
- [equipment] Gooseneck kettle essential for controlled pour rate #gear
- [science] Bloom phase releases CO2, improving extraction uniformity

## Relations

Relations create the knowledge graph using WikiLinks:

- relates_to [[Coffee Bean Origins]]
- requires [[Proper Grinding Technique]]
- contrasts_with [[French Press Method]]
- part_of [[Home Barista Guide]]
- influences [[Extraction Time]]
```

**Observation Categories:**

| Category | Purpose | Example |
|----------|---------|---------|
| `[fact]` | Verified information | `[fact] Water boils at 212°F at sea level` |
| `[tip]` | Practical advice | `[tip] Pre-wet filter to remove paper taste` |
| `[method]` | Process description | `[method] V60 uses spiral pour technique` |
| `[decision]` | Choices made | `[decision] Using Chemex for clarity` |
| `[question]` | Open questions | `[question] Does grind size affect bloom?` |
| `[insight]` | Discoveries | `[insight] Darker roasts need lower temp` |
| Custom | Any category you need | `[architecture] Service layer pattern` |

**Relation Types:**

| Relation | Meaning | Creates Link |
|----------|---------|--------------|
| `relates_to` | General connection | Bidirectional |
| `requires` | Dependency | Directional |
| `part_of` | Hierarchy/containment | Directional |
| `influences` | Causal relationship | Directional |
| `contrasts_with` | Comparison/opposition | Bidirectional |
| `implements` | Realization | Directional |
| `extends` | Enhancement | Directional |
| Custom | Any relation you need | As defined |

**Memory URLs - Knowledge Navigation:**

Basic Memory introduces the `memory://` URL scheme for knowledge navigation:

```
memory://coffee-brewing-methods           # Direct note access
memory://projects/web-app/*               # Pattern matching
memory://architecture/decisions           # Folder traversal
memory://*authentication*                 # Wildcard search
```

**Use with `build_context` tool:**
```python
# AI can request: "Continue from our discussion about authentication"
build_context(url="memory://authentication", depth=2, max_related=10)
```

**CLI Commands:**

| Command | Description |
|---------|-------------|
| `basic-memory mcp` | Start MCP server (used by AI clients) |
| `basic-memory sync` | Sync markdown files to database |
| `basic-memory import` | Import from Claude/ChatGPT exports |
| `basic-memory project list` | List all projects |
| `basic-memory project add <name> <path>` | Add new project |
| `basic-memory project set-default <name>` | Set default project |
| `basic-memory stats` | Show knowledge base statistics |
| `basic-memory search <query>` | Search from command line |
| `basic-memory cloud login` | Authenticate with Basic Memory Cloud |
| `basic-memory cloud bisync` | Bidirectional cloud sync |
| `basic-memory cloud mount` | FUSE mount for cloud storage |

**Configuration:**

Configuration file: `~/.basic-memory/config.json`

```json
{
  "projects": {
    "main": {
      "path": "~/basic-memory"
    },
    "work": {
      "path": "~/Documents/work-notes"
    },
    "research": {
      "path": "~/obsidian-vault/research"
    }
  },
  "default_project": "main",
  "sync_on_start": true,
  "watch_files": true
}
```

**Environment Variables:**

| Variable | Default | Description |
|----------|---------|-------------|
| `BASIC_MEMORY_HOME` | `~/.basic-memory` | Configuration directory |
| `BASIC_MEMORY_PROJECT` | `main` | Default project name |
| `BASIC_MEMORY_LOG_LEVEL` | `INFO` | Logging verbosity |

**Bifrost Configuration:**

```json
{
  "name": "basic-memory",
  "command": "uvx",
  "args": ["basic-memory", "mcp"]
}
```

**With Specific Project:**
```json
{
  "name": "basic-memory",
  "command": "uvx",
  "args": ["basic-memory", "mcp"],
  "env": {
    "BASIC_MEMORY_PROJECT": "work"
  }
}
```

**Using pipx instead of uv:**
```json
{
  "name": "basic-memory",
  "command": "basic-memory",
  "args": ["mcp"]
}
```

**Basic Memory vs Competitors:**

| Feature | Basic Memory | Mem0 | Zep | LangChain Memory | MemGPT | OpenAI Memory |
|---------|-------------|------|-----|------------------|--------|---------------|
| **Storage** | Local Markdown | Cloud/Vector DB | PostgreSQL | In-memory/Redis | JSON + Vector | Cloud (OpenAI) |
| **Data Ownership** | ✅ Full local control | ❌ Cloud-dependent | ⚠️ Self-host option | ⚠️ Depends on backend | ✅ Local files | ❌ OpenAI servers |
| **Knowledge Graph** | ✅ WikiLinks + Relations | ⚠️ Limited | ✅ Temporal graph | ❌ | ⚠️ Hierarchical | ❌ |
| **MCP Native** | ✅ First-class | ⚠️ Via adapters | ❌ | ❌ | ⚠️ Experimental | ❌ |
| **Human Readable** | ✅ Plain Markdown | ❌ JSON/Vectors | ❌ Database | ❌ | ⚠️ JSON | ❌ |
| **Obsidian Compatible** | ✅ Native | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Multi-User** | ⚠️ Via cloud sync | ✅ Built-in | ✅ Built-in | ⚠️ Depends | ❌ | ✅ |
| **Cost** | Free (Cloud: $14.25/mo) | Free tier + paid | Self-host or paid | Free | Free | Included with Plus |
| **Offline** | ✅ Full functionality | ❌ | ⚠️ Self-host only | ✅ | ✅ | ❌ |
| **Search** | Full-text + Semantic | Vector similarity | Hybrid | Configurable | Vector | Semantic |

**When to Use Basic Memory:**

| Use Case | Basic Memory | Alternative |
|----------|-------------|-------------|
| **Long-term project knowledge** | ✅ Best choice - persistent, searchable | Beads for task tracking |
| **Cross-session context** | ✅ `build_context` with memory:// URLs | Session files (manual) |
| **Architectural decisions** | ✅ Store with relations | ADR-analysis for formal ADRs |
| **Research notes** | ✅ Observations + tags | Plain Markdown files |
| **Meeting notes** | ✅ Structured capture | Obsidian/Notion |
| **Code patterns** | ✅ With code blocks | narsil-mcp for code analysis |
| **Team collaboration** | ⚠️ Via Cloud sync | Notion/Confluence |
| **Task/Issue tracking** | Use beads-mcp instead | ✅ beads-mcp |
| **Git-backed history** | Use beads-mcp | ✅ beads-mcp |
| **Real-time collaboration** | ❌ Not supported | Google Docs/Notion |

**Integration with Other Tools:**

| Combined With | Use Case |
|--------------|----------|
| **beads-mcp** | Beads tracks tasks (HOW/WHEN), Basic Memory stores knowledge (WHY/WHAT) |
| **adr-analysis** | Store ADR decisions and research findings for long-term reference |
| **narsil-mcp** | Store code pattern discoveries, architecture insights |
| **code-guardian** | Persist quality decisions and validation learnings |
| **llm-council** | Archive council deliberations and decisions |

**Typical Workflow:**

```bash
# 1. Start a session - check recent activity
recent_activity(timeframe="7d", project="my-project")

# 2. Load relevant context for current work
build_context(url="memory://authentication-design", depth=2)

# 3. Work with AI assistant... discoveries happen

# 4. Capture new knowledge
write_note(
  title="OAuth2 Implementation Insights",
  folder="architecture/auth",
  content="""
## Observations
- [decision] Using PKCE flow for public clients #security
- [insight] Refresh token rotation prevents replay attacks #tokens
- [tip] Store tokens in httpOnly cookies for web apps #storage

## Relations
- implements [[Authentication Strategy]]
- relates_to [[Session Management]]
"""
)

# 5. End session - knowledge persists for next time
```

**Troubleshooting:**

| Issue | Solution |
|-------|----------|
| Notes not appearing | Run `basic-memory sync` to rebuild index |
| Search returns nothing | Check project path, verify files exist |
| MCP connection fails | Ensure `uvx` or `basic-memory` is in PATH |
| Memory URLs not resolving | Check permalink matches note title/path |
| Slow search | Large knowledge bases may need index optimization |
| Cloud sync conflicts | Use `basic-memory cloud bisync --dry-run` to preview |
| Permission errors | Check file permissions in knowledge directory |

**Best Practices:**

1. **Use descriptive titles** - Titles become permalinks for `memory://` URLs
2. **Add tags liberally** - Tags improve searchability (`#architecture`, `#decision`)
3. **Create relations** - WikiLinks build the knowledge graph
4. **Use observation categories** - `[decision]`, `[insight]`, `[tip]` add semantic meaning
5. **Organize by folder** - `architecture/`, `research/`, `meetings/` for structure
6. **Regular sync** - Run `basic-memory sync` after external edits
7. **Start sessions with context** - Use `build_context` to load relevant knowledge

**Resources:**

- [Documentation](https://docs.basicmemory.com)
- [User Guide](https://docs.basicmemory.com/user-guide/)
- [Knowledge Format Guide](https://docs.basicmemory.com/guides/knowledge-format/)
- [CLI Reference](https://docs.basicmemory.com/guides/cli-reference/)
- [GitHub Issues](https://github.com/basicmachines-co/basic-memory/issues)

---

### beads-mcp

> A memory upgrade for your coding agent - distributed, git-backed graph issue tracker with dependency tracking

| | |
|---|---|
| **Repository** | [github.com/steveyegge/beads](https://github.com/steveyegge/beads) |
| **NPM** | [@beads/bd](https://www.npmjs.com/package/@beads/bd) |
| **PyPI** | [beads-mcp](https://pypi.org/project/beads-mcp/) |
| **Language** | Go (94%), Python (4%) |
| **License** | MIT |
| **Stars** | 9.5k+ |
| **Forks** | 576+ |
| **Contributors** | 131+ |
| **Tools** | 10 |
| **Install** | `uv tool install beads-mcp` or `brew install steveyegge/tap/bd` |

**Why beads-mcp?**

| Feature | beads-mcp | GitHub Issues | Jira | Linear | Taskwarrior |
|---------|-----------|---------------|------|--------|-------------|
| **Git-native storage** | ✅ JSONL in `.beads/` | ❌ Remote API | ❌ Cloud | ❌ Cloud | ❌ Local files |
| **Agent-optimized** | ✅ JSON output, MCP tools | ❌ Needs scraping | ❌ API complexity | Partial | ❌ Human CLI |
| **Dependency graph** | ✅ 4 link types | Partial (mentions) | ✅ | ✅ | ❌ |
| **Ready task detection** | ✅ `bd ready` | ❌ Manual | ❌ Filters | ❌ Views | ❌ |
| **Multi-agent/branch safe** | ✅ Hash-based IDs | ❌ Conflicts | ❌ Locks | ❌ | ❌ |
| **Memory compaction** | ✅ Semantic decay | ❌ | ❌ | ❌ | ❌ |
| **Offline-first** | ✅ Git sync | ❌ | ❌ | ❌ | ✅ |
| **Zero config** | ✅ | ❌ Token/auth | ❌ Complex setup | ❌ Account | ✅ |
| **Survives context reset** | ✅ Persistent | ❌ | ❌ | ❌ | ✅ |

**Features:**

- 🗂️ **Git as Database** - Issues stored as JSONL in `.beads/`. Versioned, branched, and merged like code
- 🤖 **Agent-Optimized** - JSON output (`--output json`), MCP tools, dependency tracking, auto-ready task detection
- 🔀 **Zero Conflict** - Hash-based IDs (`beads-a1b2`) prevent merge collisions in multi-agent/multi-branch workflows
- ⚡ **Invisible Infrastructure** - SQLite local cache for speed; background daemon for auto-sync
- 🧠 **Memory Compaction** - Semantic "memory decay" summarizes old closed tasks to save context window tokens
- 📊 **Hierarchical IDs** - Supports epics (`beads-a3f8`) → tasks (`beads-a3f8.1`) → subtasks (`beads-a3f8.1.1`)
- 👻 **Stealth Mode** - `bd init --stealth` for personal use on shared projects without committing to git
- 🔄 **Background Daemon** - Auto-sync with git remote, global daemon for multi-project workflows
- 📈 **Project Statistics** - Track velocity, completion rates, and issue health

**When to Use beads-mcp:**

| Use Case | beads-mcp | Alternative |
|----------|-----------|-------------|
| **AI agent task tracking** | ✅ Best choice - built for agents | GitHub Issues (needs MCP wrapper) |
| **Multi-session memory** | ✅ Survives context resets | basic-memory (knowledge, not tasks) |
| **Dependency-aware work queue** | ✅ `bd ready` shows unblocked tasks | Linear/Jira (complex setup) |
| **Multi-agent coordination** | ✅ Hash IDs prevent collisions | None - unique to beads |
| **Offline development** | ✅ Git-native, local-first | Taskwarrior (no deps) |
| **Knowledge documentation** | ❌ Use basic-memory | basic-memory ([[links]], notes) |
| **CI/CD integration** | ❌ Use GitHub Issues | GitHub Issues (native actions) |
| **Team with non-technical users** | ❌ CLI-only | Linear, Jira (web UI) |

**Dependency Types (4 link types):**

| Type | Syntax | Meaning |
|------|--------|---------|
| **blocks** | `bd dep add A B` | A is blocked by B (B must complete first) |
| **related** | `bd dep add A B --type related` | A and B are related (no ordering) |
| **parent** | `bd dep add A B --type parent` | A is a child of B (epic/task hierarchy) |
| **discovered-from** | `bd dep add A B --type discovered-from` | A was discovered while working on B |

**MCP Tools (10 total):**

| Tool | Description | Example Use |
|------|-------------|-------------|
| `init` | Initialize beads in current project | `mcp__beads__init()` |
| `create` | Create a new issue | `mcp__beads__create(title: "Fix auth bug", type: "bug", priority: 1)` |
| `list` | List issues with filters | `mcp__beads__list(status: ["open", "in_progress"])` |
| `ready` | Find issues with no open blockers | `mcp__beads__ready()` → what to work on next |
| `show` | View issue details and audit trail | `mcp__beads__show(id: "beads-a1b2")` |
| `update` | Update issue status/priority/fields | `mcp__beads__update(id: "beads-a1b2", status: "in_progress")` |
| `close` | Mark issue as completed | `mcp__beads__close(id: "beads-a1b2")` |
| `dep` | Manage dependencies between issues | `mcp__beads__dep(action: "add", from: "beads-x", to: "beads-y")` |
| `blocked` | Show all blocked issues | `mcp__beads__blocked()` → identify bottlenecks |
| `stats` | Project statistics and health | `mcp__beads__stats()` → velocity, open/closed counts |

**CLI Commands (Full Reference):**

| Command | Action | Agent Output |
|---------|--------|--------------|
| `bd init` | Initialize `.beads/` directory | `--output json` for structured init result |
| `bd create "Title" -p 0` | Create a P0 (critical) task | Returns issue ID |
| `bd create "Title" --type bug` | Create a bug report | Types: `task`, `bug`, `feature`, `epic` |
| `bd list --status open` | List open issues | JSON array of issues |
| `bd list --status in_progress` | Show active work | What am I working on? |
| `bd ready` | Issues with no open blockers | **THE key command** - what to work on next |
| `bd show <id>` | View issue details + audit trail | Full issue with history |
| `bd update <id> --status in_progress` | Claim an issue | Marks you as working on it |
| `bd update <id> --priority 0` | Escalate priority | P0=critical, P1=high, P2=medium, P3=low, P4=backlog |
| `bd close <id>` | Mark issue as done | Updates status to `closed` |
| `bd close <id1> <id2> <id3>` | Batch close multiple | Efficient multi-close |
| `bd dep add <A> <B>` | A is blocked by B | Creates `blocks` relationship |
| `bd dep add <A> <B> --type related` | A relates to B | Creates `related` relationship |
| `bd dep remove <A> <B>` | Remove dependency | Unlinks issues |
| `bd blocked` | Show blocked issues | Find bottlenecks |
| `bd stats` | Project statistics | Open, closed, blocked counts |
| `bd sync` | Sync with git remote | Push/pull `.beads/` changes |
| `bd sync --status` | Check sync status | Dry run before sync |
| `bd daemon start` | Start background sync | Auto-sync every 30s |
| `bd daemon stop` | Stop background sync | Manual mode |
| `bd compact` | Summarize old closed issues | Memory decay for context savings |
| `bd restore <id>` | Restore compacted issue | Full history from git notes |

**Priority Levels:**

| Priority | CLI Flag | Meaning |
|----------|----------|---------|
| P0 | `-p 0` or `--priority 0` | Critical - drop everything |
| P1 | `-p 1` | High - do this sprint |
| P2 | `-p 2` | Medium (default) |
| P3 | `-p 3` | Low - nice to have |
| P4 | `-p 4` | Backlog - someday |

**Daemon Mode:**

Beads supports background auto-sync to keep your local cache up-to-date with the git remote:

```bash
# Start daemon for current project
bd daemon start

# Start global daemon (multi-project)
bd daemon start --global

# Check daemon status
bd daemon status

# Stop daemon
bd daemon stop
```

**Memory Compaction:**

Old closed issues can be "compacted" to save context window tokens. Beads uses semantic summarization to preserve key information while reducing token count:

```bash
# Compact issues older than 30 days
bd compact --older-than 30d

# Preview what would be compacted
bd compact --dry-run

# Restore a compacted issue (pulls from git notes)
bd restore beads-a1b2
```

**Hierarchical Task Structure:**

```
beads-a3f8 (Epic: User Authentication)
├── beads-a3f8.1 (Task: Login page)
│   ├── beads-a3f8.1.1 (Subtask: Email validation)
│   └── beads-a3f8.1.2 (Subtask: Password strength)
├── beads-a3f8.2 (Task: OAuth integration)
└── beads-a3f8.3 (Task: Session management)
```

**Bifrost Configuration:**
```json
{
  "name": "beads",
  "command": "uvx",
  "args": ["beads-mcp"]
}
```

**Environment Variables (all optional):**

| Variable | Default | Description |
|----------|---------|-------------|
| `BEADS_PATH` | `.beads/` | Custom path for beads storage |
| `BEADS_DB` | `.beads/beads.db` | SQLite cache location |
| `BEADS_ACTOR` | Git user.name | Actor name for audit trail |
| `BEADS_NO_AUTO_FLUSH` | `false` | Disable auto-flush to JSONL |
| `BEADS_NO_AUTO_IMPORT` | `false` | Disable auto-import from JSONL |

**Installation Options:**

```bash
# Homebrew (macOS/Linux) - recommended
brew install steveyegge/tap/bd

# NPM (Node.js)
npm install -g @beads/bd

# Go
go install github.com/steveyegge/beads/cmd/bd@latest

# Python MCP server
uv tool install beads-mcp
# or
pip install beads-mcp

# Direct binary (curl)
curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/install.sh | bash
```

**Integration with Other Bifrost Tools:**

| Tool | Integration Pattern |
|------|---------------------|
| **basic-memory** | Document decisions in basic-memory, track execution in beads |
| **narsil-mcp** | Use narsil to find code, create beads issues for refactoring work |
| **mcp-adr-analysis** | Generate ADRs for architectural decisions, track implementation in beads |
| **code-guardian** | Code quality findings → beads issues for fixes |
| **greb-mcp** | Search for patterns, create beads issues for matches needing attention |

**AI Agent Best Practices:**

1. **Session Start:** Run `bd ready` to see available work
2. **Claim Work:** `bd update <id> --status in_progress` before starting
3. **Track Discoveries:** Create new issues for discovered work with `--type discovered-from`
4. **Maintain Deps:** Use `bd dep add` to link related work
5. **Session End:** `bd close` completed work, `bd sync` to push changes
6. **Context Recovery:** After compaction, `bd show` retrieves full history from git

**Troubleshooting:**

| Issue | Solution |
|-------|----------|
| "Not a beads project" | Run `bd init` in project root |
| Sync conflicts | `bd sync` uses git merge - resolve like code conflicts |
| Missing issues after clone | Run `bd sync` to import from JSONL |
| Daemon not syncing | Check `bd daemon status`, restart with `bd daemon start` |
| Compacted issue lost data | Use `bd restore <id>` to recover from git notes |

**Resources:**

- [Documentation](https://github.com/steveyegge/beads#readme)
- [CLI Reference](https://github.com/steveyegge/beads/blob/main/docs/CLI.md)
- [Agent Instructions](https://github.com/steveyegge/beads/blob/main/AGENT_INSTRUCTIONS.md)
- [MCP Server (PyPI)](https://pypi.org/project/beads-mcp/)
- [NPM Package](https://www.npmjs.com/package/@beads/bd)
- [GitHub Issues](https://github.com/steveyegge/beads/issues)

---

### cheetah-greb (Greb MCP)

> AI-powered intelligent code search - hybrid local + cloud GPU architecture for natural language code queries

| | |
|---|---|
| **Website** | [grebmcp.com](https://grebmcp.com) |
| **PyPI** | [cheetah-greb](https://pypi.org/project/cheetah-greb/) |
| **API** | `https://search.grebmcp.com` |
| **Language** | Python (local) + Rust/CUDA (cloud) |
| **License** | MIT |
| **Python** | 3.10-3.13 (3.14 not yet supported) |
| **Install** | `uv tool install cheetah-greb` or `pip install cheetah-greb` |

**Architecture Overview:**

Greb uses a **hybrid local + cloud GPU** approach that balances privacy, speed, and intelligence:

```
┌─────────────────────────────────────────────────────────────────────┐
│                         LOCAL (Your Machine)                        │
├─────────────────────────────────────────────────────────────────────┤
│  1. ripgrep text search (fast pattern matching)                     │
│  2. Tree-sitter AST parsing (code structure awareness)              │
│  3. Chunk extraction & deduplication                                │
│  4. Semantic reference extraction                                   │
└────────────────────────────┬────────────────────────────────────────┘
                             │ Compressed chunks (minimal data)
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      CLOUD GPU (grebmcp.com)                        │
├─────────────────────────────────────────────────────────────────────┤
│  1. SPLADE sparse embeddings (vocabulary-based matching)            │
│  2. Cross-encoder reranking (deep semantic understanding)           │
│  3. ONNX Runtime + CUDA acceleration                                │
│  4. Relevance scoring with natural language explanations            │
└─────────────────────────────────────────────────────────────────────┘
```

**Key Architectural Benefits:**
- **Privacy-first**: Only compressed code chunks leave your machine, not full files
- **Speed**: Local ripgrep pre-filtering reduces cloud processing load
- **Intelligence**: GPU-accelerated neural reranking understands code semantics
- **Cost-effective**: Token-based billing means you pay only for what you use

**Features:**

- 🔍 **Natural Language Search** - Query code conversationally: "find authentication middleware", "where is database connection pooling configured"
- 🧠 **AI-Powered Reranking** - SPLADE + cross-encoder models on cloud GPUs understand code semantics, not just text matching
- 📊 **Relevance Scoring** - Each result includes score (0-1) and AI-generated explanation of why it matches
- 🎯 **Code Spans** - Returns actual code context with surrounding lines for immediate understanding
- 🌳 **AST-Aware** - Tree-sitter parsing extracts semantic references (imports, function calls, class inheritance)
- 🔌 **Dual Integration** - REST API for programmatic access or MCP server for AI assistants
- 💰 **Token-Based Pricing** - Pay-as-you-go model, no monthly subscriptions required

**Why Greb? (vs Competitors)**

| Feature | Greb MCP | narsil-mcp | Sourcegraph MCP | Code-Index-MCP |
|---------|----------|------------|-----------------|----------------|
| **Search Type** | Hybrid (local + cloud GPU) | Local TF-IDF + optional embeddings | Enterprise graph search | Local-only indexing |
| **Natural Language** | ✅ Neural reranking | ⚠️ BM25/TF-IDF (keyword-focused) | ✅ With Cody | ❌ Pattern-based |
| **GPU Acceleration** | ✅ Cloud CUDA | ❌ CPU only | ✅ Enterprise servers | ❌ None |
| **Privacy** | ⚠️ Chunks sent to cloud | ✅ Fully local | ⚠️ Requires Sourcegraph instance | ✅ Fully local |
| **Setup Complexity** | Low (API key) | Low (single binary) | High (enterprise deployment) | Medium (indexing required) |
| **Call Graphs** | ❌ | ✅ Full analysis | ✅ Code intelligence | ❌ |
| **Git Integration** | ❌ | ✅ Blame, history, contributors | ✅ Repository context | ❌ |
| **Pricing** | Token-based (~$0.001/search) | Free (optional embedding costs) | Enterprise licensing | Free |
| **Best For** | Semantic "what does X do" queries | Structure "who calls X" queries | Enterprise codebases | Small projects |

**When to Use Greb:**

| Use Case | Greb MCP | Better Alternative |
|----------|----------|-------------------|
| "Find where we handle authentication" | ✅ Best choice | - |
| "What functions process payments" | ✅ Best choice | - |
| "Similar code to this snippet" | ✅ Best choice | - |
| "Who calls this function" | ❌ Use narsil-mcp | ✅ narsil-mcp |
| "Show me the call graph" | ❌ Use narsil-mcp | ✅ narsil-mcp |
| "Git blame for this file" | ❌ Use narsil-mcp | ✅ narsil-mcp |
| "Find all struct definitions" | ⚠️ Works, but narsil faster | ✅ narsil-mcp |
| Enterprise-scale codebase search | ⚠️ Works, but enterprise needs | ✅ Sourcegraph |
| Fully offline/air-gapped | ❌ Requires cloud | ✅ narsil-mcp |

**Available Tools:**

| Tool | Description |
|------|-------------|
| `code_search` | Search code using natural language queries with AI reranking |

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
| `GREB_API_KEY` | API key from [Greb dashboard](https://grebmcp.com) (format: `grb_xxx`) |

**Optional:** `GREB_API_URL` defaults to `https://search.grebmcp.com`

**REST API Usage (Alternative to MCP):**
```bash
# Direct REST API call
curl -X POST "https://search.grebmcp.com/search" \
  -H "Authorization: Bearer $GREB_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "find authentication middleware",
    "directory": "/path/to/project"
  }'
```

**Performance Notes:**
- First search: ~30-60s (models download from HuggingFace to cloud cache)
- Subsequent searches: ~2-5s depending on codebase size
- Local ripgrep pre-filtering: <1s for most codebases

**Complementary Usage with narsil-mcp:**

Greb and narsil-mcp serve different purposes and work well together:

```
# Semantic discovery (Greb)
"What handles user authentication?" → Greb finds relevant code semantically

# Structural analysis (narsil)
Found auth.js → narsil: "What calls authenticateToken?" → Full call graph

# Combined workflow
1. Greb: "Find payment processing logic" → Discovers PaymentService.ts
2. narsil: get_callers(function: "processPayment") → See all entry points
3. narsil: get_callees(function: "processPayment") → See dependencies
4. narsil: get_symbol_history(symbol: "processPayment") → Git history
```

**Privacy Considerations:**
- Only code chunks (not full files) are sent to Greb cloud
- No code is stored persistently on Greb servers
- Processing happens in ephemeral GPU instances
- For fully air-gapped environments, use narsil-mcp instead

**Pricing:**
- Token-based billing (~$0.001 per search query)
- No monthly subscription required
- Free tier available for evaluation
- See [grebmcp.com](https://grebmcp.com) for current pricing

**Resources:**
- [Architecture Blog Post](https://grebmcp.com/blog/architecture)
- [Getting Started Guide](https://grebmcp.com/get-started/introduction)
- [PyPI Package](https://pypi.org/project/cheetah-greb/)

---

### kindly-web-search

> Web search + robust content retrieval for AI coding tools - returns full conversations (questions, answers, comments), not just snippets

| | |
|---|---|
| **Repository** | [github.com/Shelpuk-AI-Technology-Consulting/kindly-web-search-mcp-server](https://github.com/Shelpuk-AI-Technology-Consulting/kindly-web-search-mcp-server) |
| **Website** | [shelpuk.com](https://www.shelpuk.com) |
| **Language** | Python |
| **License** | MIT |
| **Stars** | 69+ |
| **Tools** | 2 |
| **Install** | `uv tool install git+https://github.com/Shelpuk-AI-Technology-Consulting/kindly-web-search-mcp-server` |

**The Problem Kindly Solves:**

Most web search MCP servers return search results with title, URL, and a brief snippet - but not the actual content you need. When debugging an error, you don't just want to know a StackOverflow question exists; you want the accepted answer, comments, and alternative solutions. Traditional MCP servers require:

1. Search → get URLs
2. Scrape each URL separately
3. Parse and clean the content
4. Hope the scraper handles dynamic content

Kindly combines all of this into a single `web_search` call that returns full page content in Markdown format.

**Core Features:**

| Feature | Description |
|---------|-------------|
| **Full Conversation Retrieval** | Returns questions, answers, comments, reactions, metadata - not just snippets |
| **Direct API Integration** | StackExchange, GitHub Issues, arXiv, Wikipedia via native APIs (LLM-optimized formats) |
| **Real-Time Browser Parsing** | Headless Chromium via `nodriver` for dynamic content and cutting-edge issues |
| **Multi-Provider Search** | Serper (primary), Tavily (fallback), or self-hosted SearXNG |
| **Anti-Bot Bypass** | Uses `nodriver` (successor to undetected-chromedriver) for sites with bot protection |
| **Single-Call Architecture** | No follow-up scraping needed - content included in search results |

**Architecture:**

```
┌─────────────────────────────────────────────────────────────────┐
│                      Kindly Web Search                          │
├─────────────────────────────────────────────────────────────────┤
│  Search Providers          │  Content Extraction               │
│  ├─ Serper (primary)       │  ├─ Native APIs (optimal)         │
│  ├─ Tavily (fallback)      │  │   ├─ StackExchange API         │
│  └─ SearXNG (self-hosted)  │  │   ├─ GitHub Issues API         │
│                            │  │   ├─ arXiv API                  │
│                            │  │   └─ Wikipedia API              │
│                            │  └─ nodriver Browser (fallback)    │
│                            │      └─ Chromium headless          │
├─────────────────────────────────────────────────────────────────┤
│  Output: Markdown-formatted content ready for LLM consumption   │
└─────────────────────────────────────────────────────────────────┘
```

**Available Tools:**

| Tool | Parameters | Description |
|------|------------|-------------|
| `web_search` | `query` (str), `num_results` (int, default=3) | Search and return top results with full page content in Markdown |
| `get_content` | `url` (str) | Fetch and parse a specific URL to Markdown (best-effort) |

**Tool Output Structure:**

```json
{
  "results": [
    {
      "title": "How to fix TypeScript error TS2345",
      "link": "https://stackoverflow.com/questions/12345",
      "snippet": "I'm getting error TS2345 when...",
      "page_content": "# How to fix TypeScript error TS2345\n\n## Question\n...\n\n## Accepted Answer\n...\n\n## Comments\n..."
    }
  ]
}
```

**When to Use Kindly:**

| Scenario | Kindly | Alternative |
|----------|--------|-------------|
| Debug error messages | ✅ Full SO answers with comments | Exa/Tavily snippets need follow-up |
| Research GitHub issues | ✅ Native API with full discussion | Generic scraping misses dynamic content |
| Find code examples | ✅ Complete examples in context | Snippets truncate important details |
| Academic paper lookup | ✅ arXiv API integration | PDF parsing complications |
| General web research | ✅ Good | Exa semantic search may be better |
| Site-specific deep crawling | ❌ Use Firecrawl | Single-page focus |
| JavaScript-heavy SPAs | ⚠️ Works via nodriver | Dedicated browser MCP may be better |

**When NOT to Use Kindly:**

- **Semantic/neural search** - Use Exa for meaning-based queries across large corpora
- **Deep site crawling** - Use Firecrawl for crawling entire sites/sitemaps
- **Real-time collaboration data** - Use dedicated Slack/Discord MCPs
- **Structured data extraction** - Use specialized scrapers with schemas

**Competitor Comparison:**

| Feature | Kindly | Exa | Tavily | Firecrawl | Generic Search MCP |
|---------|--------|-----|--------|-----------|-------------------|
| **Full page content** | ✅ Included | ❌ Separate call | ✅ AI Extract | ✅ Yes | ❌ No |
| **StackOverflow optimized** | ✅ Native API | ❌ | ❌ | ❌ | ❌ |
| **GitHub Issues** | ✅ Native API | ❌ | ❌ | ❌ | ❌ |
| **Anti-bot bypass** | ✅ nodriver | ❌ | ❌ | ✅ | ❌ |
| **Semantic search** | ❌ | ✅ Neural | ✅ AI-native | ❌ | ❌ |
| **Site crawling** | ❌ Single page | ❌ | ❌ | ✅ Full site | ❌ |
| **Self-hosted option** | ✅ SearXNG | ❌ | ❌ | ✅ | Varies |
| **Cost (per 1K searches)** | ~$5 (Serper) | ~$138 | ~$190 | ~$20 | Varies |
| **Setup complexity** | Medium | Low | Low | Medium | Low |

**Search Provider Comparison:**

| Provider | Pros | Cons | Cost |
|----------|------|------|------|
| **Serper** (recommended) | Fast, reliable, good value | Requires API key | ~$5/1K searches |
| **Tavily** | AI-optimized results, RAG-friendly | Higher cost | ~$190/1K searches |
| **SearXNG** | Self-hosted, no API costs, privacy | Requires setup, variable quality | Free (self-hosted) |

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

**Alternative: Tavily Provider:**

```json
{
  "name": "kindly-web-search",
  "command": "uvx",
  "args": [
    "--from", "git+https://github.com/Shelpuk-AI-Technology-Consulting/kindly-web-search-mcp-server",
    "kindly-web-search-mcp-server", "start-mcp-server"
  ],
  "env": {
    "TAVILY_API_KEY": "${TAVILY_API_KEY}",
    "GITHUB_TOKEN": "${GITHUB_TOKEN}"
  }
}
```

**Alternative: Self-Hosted SearXNG:**

```json
{
  "name": "kindly-web-search",
  "command": "uvx",
  "args": [
    "--from", "git+https://github.com/Shelpuk-AI-Technology-Consulting/kindly-web-search-mcp-server",
    "kindly-web-search-mcp-server", "start-mcp-server"
  ],
  "env": {
    "SEARXNG_BASE_URL": "http://localhost:8080",
    "GITHUB_TOKEN": "${GITHUB_TOKEN}"
  }
}
```

**Environment Variables:**

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SERPER_API_KEY` | One of three | - | Serper.dev API key (recommended provider) |
| `TAVILY_API_KEY` | One of three | - | Tavily API key (AI-optimized alternative) |
| `SEARXNG_BASE_URL` | One of three | - | Self-hosted SearXNG instance URL |
| `GITHUB_TOKEN` | Recommended | - | GitHub PAT for better Issues extraction (read-only, public repos) |
| `KINDLY_BROWSER_EXECUTABLE_PATH` | Optional | Auto-detect | Override Chromium/Chrome executable path |

**Requirements:**

- **Python 3.10+** - Required for `nodriver` async features
- **Chromium-based browser** - Chrome, Chromium, or Edge on the same machine
- **Search API key** - At least one of: Serper, Tavily, or SearXNG instance
- **UV package manager** - For `uvx` installation method

**Docker Deployment:**

For containerized environments, the official Docker image includes Chromium:

```bash
# Run with Streamable HTTP transport
docker run -p 8000:8000 \
  -e SERPER_API_KEY=your_key \
  -e GITHUB_TOKEN=your_token \
  ghcr.io/shelpuk-ai-technology-consulting/kindly-web-search-mcp-server
```

**Supported AI Clients:**

| Client | Status | Notes |
|--------|--------|-------|
| Claude Code | ✅ Full support | Primary development target |
| Codex CLI | ✅ Full support | `codex mcp add` integration |
| Cursor | ✅ Full support | Via `mcp.json` config |
| Claude Desktop | ✅ Full support | Via `claude_desktop_config.json` |
| GitHub Copilot | ✅ Full support | VS Code settings integration |
| Gemini CLI | ✅ Full support | Via `settings.json` |
| Antigravity | ✅ Full support | Direct config support |

**Troubleshooting:**

| Issue | Cause | Solution |
|-------|-------|----------|
| `Browser not found` | Chromium not installed or not in PATH | Install Chrome/Chromium, or set `KINDLY_BROWSER_EXECUTABLE_PATH` |
| `No search results` | Missing or invalid API key | Verify `SERPER_API_KEY` or `TAVILY_API_KEY` is set correctly |
| `GitHub content incomplete` | Missing token or rate limited | Add `GITHUB_TOKEN` with `repo:read` scope |
| `Timeout on page load` | Site blocking headless browsers | Try different search results; site may have strong anti-bot |
| `Empty page_content` | Dynamic content not loaded | Content may require JS execution; `nodriver` handles most cases |
| `SearXNG connection refused` | Instance not running | Verify SearXNG is running at `SEARXNG_BASE_URL` |

**nodriver Technology:**

Kindly uses `nodriver` for browser automation - the successor to `undetected-chromedriver`:

- **Async-first design** - Built on `asyncio` for efficient concurrent page loading
- **No external dependencies** - Pure Python, no Selenium/WebDriver
- **Anti-detection built-in** - Bypasses common bot detection (Cloudflare, etc.)
- **Fresh browser profiles** - Each session uses a clean profile
- **Memory efficient** - Lower overhead than traditional browser automation

**Usage Examples:**

```
# Search for error solutions (returns full SO answers)
User: "Search for TypeScript error TS2345 argument of type"

# Research a specific GitHub issue
User: "Get the content from https://github.com/vercel/next.js/issues/12345"

# Find implementation examples
User: "Search for React useEffect cleanup pattern examples"

# Academic research
User: "Search arXiv for transformer attention mechanism papers"
```

**Comparison with Bifrost's Other Search Tools:**

| Tool | Best For | Content Depth | Search Type |
|------|----------|---------------|-------------|
| **Kindly** | Developer Q&A, GitHub Issues, full page content | Full page (Markdown) | Keyword + extraction |
| **Exa** | Semantic search, research, embeddings | Snippets + optional content | Neural/semantic |
| **Reddit MCP** | Community discussions, sentiment | Full threads | Platform-specific |
| **Narsil** | Codebase search | Code chunks | AST-aware |

**Resources:**

- [GitHub Repository](https://github.com/Shelpuk-AI-Technology-Consulting/kindly-web-search-mcp-server)
- [Shelpuk AI Technology Consulting](https://www.shelpuk.com)
- [Serper API](https://serper.dev) - Recommended search provider
- [Tavily API](https://tavily.com) - AI-optimized alternative
- [nodriver Documentation](https://github.com/nickolaj-jepsen/nodriver) - Browser automation library

---

### code-guardian (CodeGuardian Studio)

> AI safety layer and code refactor engine for Claude Code - 113+ MCP tools for code quality, workflow management, automated optimization, and **AI guardrails** that prevent dangerous operations

| | |
|---|---|
| **Repository** | [github.com/phuongrealmax/code-guardian](https://github.com/phuongrealmax/code-guardian) |
| **NPM** | [codeguardian-studio](https://www.npmjs.com/package/codeguardian-studio) |
| **Website** | [codeguardian.studio](https://codeguardian.studio) |
| **Language** | TypeScript (97.4%) |
| **License** | MIT (Open Core) |
| **Version** | 4.1.1 |
| **Node.js** | >=18.0.0 |
| **Pricing** | Dev (Free) / Team ($19/mo) / Enterprise (Custom) |

**Why Code Guardian?**

| Feature | Code Guardian | Guardrails AI | NeMo Guardrails | Semgrep MCP |
|---------|---------------|---------------|-----------------|-------------|
| **MCP Tools** | 113+ | N/A | N/A | ~10 |
| **Code Analysis** | ✅ Deep hotspot detection | ❌ | ❌ | ✅ Pattern-based |
| **AI Safety Layer** | ✅ Blocks dangerous ops | ✅ LLM output validation | ✅ Conversation rails | ❌ |
| **Session Persistence** | ✅ Resume across sessions | ❌ | ❌ | ❌ |
| **Memory System** | ✅ Decisions, patterns, conventions | ❌ | ❌ | ❌ |
| **Latent Chain Reasoning** | ✅ 4-phase workflow | ❌ | ❌ | ❌ |
| **Tech Debt Scoring** | ✅ TDI grades A-F | ❌ | ❌ | ❌ |
| **Token Budget Governor** | ✅ Context management | ❌ | ❌ | ❌ |
| **100% Local** | ✅ No data leaves machine | ❌ Cloud-based | Partial | ✅ |

**What Makes Code Guardian Different:**

1. **AI Safety Layer** - Prevents dangerous AI actions *before* they execute:
   - ❌ Blocks `rm -rf /` and mass file deletions
   - ❌ Blocks breaking API changes without deprecation
   - ❌ Blocks unsafe database migrations (DROP TABLE)
   - ❌ Blocks force push to main/protected branches
   - ❌ Blocks secrets/credentials in code
   - ❌ Blocks fake tests (tests without assertions)

2. **Tech Debt Index (TDI)** - Composite metric (0-100) grading code health:
   - **Grade A (0-20)**: Excellent, minimal tech debt
   - **Grade B (21-40)**: Good, manageable tech debt
   - **Grade C (41-60)**: Fair, needs attention
   - **Grade D (61-80)**: Poor, significant debt
   - **Grade F (81-100)**: Critical, urgent refactoring needed

3. **Latent Chain Mode** - Structured 4-phase reasoning:
   - **Analysis** → Understand the problem, gather context
   - **Plan** → Design solution, identify risks
   - **Impl** → Execute with safety checks
   - **Review** → Validate, document, learn

**Core Modules (113+ Tools):**

| Module | Tools | Purpose |
|--------|-------|---------|
| **Code Optimizer** | 8 | `code_scan_repository`, `code_metrics`, `code_hotspots`, `code_refactor_plan`, `code_quick_analysis` |
| **Memory** | 5 | `memory_store`, `memory_recall`, `memory_forget`, `memory_list`, `memory_summary` |
| **Guard** | 6 | `guard_validate`, `guard_check_test`, `guard_rules`, `guard_toggle_rule`, `guard_status` |
| **Workflow** | 12 | `workflow_task_create`, `workflow_task_start`, `workflow_task_update`, `workflow_task_complete` |
| **Latent Chain** | 15 | `latent_context_create`, `latent_context_update`, `latent_phase_transition`, `latent_apply_patch` |
| **Agents** | 7 | `agents_list`, `agents_select`, `agents_register`, `agents_coordinate`, `agents_reload` |
| **Thinking** | 10 | `thinking_get_model`, `thinking_suggest_model`, `thinking_get_workflow`, `thinking_save_snippet` |
| **Documents** | 9 | `documents_search`, `documents_create`, `documents_update`, `documents_register`, `documents_scan` |
| **Testing** | 10 | `testing_run`, `testing_run_affected`, `testing_browser_open`, `testing_browser_screenshot` |
| **Resources** | 12 | `resource_status`, `resource_checkpoint_create`, `resource_governor_state`, `resource_action_allowed` |
| **Session** | 10 | `session_init`, `session_end`, `session_status`, `session_timeline`, `session_resume` |
| **AutoAgent** | 7 | `auto_decompose_task`, `auto_route_tools`, `auto_fix_loop`, `auto_recall_errors` |
| **RAG** | 6 | `rag_build_index`, `rag_query`, `rag_related_code`, `rag_status`, `rag_clear_index` |
| **Progress** | 4 | `progress_status`, `progress_blockers`, `progress_mermaid`, `progress_clear` |
| **Proof Pack** | 3 | `proof_pack_create`, `proof_pack_verify`, `proof_tdi_calculate` |

**When to Use Code Guardian:**

| Use Case | Code Guardian | Alternative |
|----------|---------------|-------------|
| **AI safety guardrails** | ✅ Best choice - blocks dangerous ops | Guardrails AI (LLM output only) |
| **Code refactoring prioritization** | ✅ Hotspot detection + TDI scoring | SonarQube (heavyweight) |
| **Session persistence** | ✅ Resume work across conversations | None (unique feature) |
| **Multi-phase reasoning** | ✅ Latent Chain workflow | Manual process |
| **Fake test detection** | ✅ Guard module catches assertions | Semgrep (rules-based) |
| **Token budget management** | ✅ Governor + checkpointing | Manual tracking |
| **Code pattern memory** | ✅ Store conventions, decisions | Basic Memory (general purpose) |
| **Security scanning** | ⚠️ Basic (use narsil-mcp) | narsil-mcp (taint analysis) |
| **Deep code search** | ⚠️ Basic RAG (use greb/narsil) | greb-mcp, narsil-mcp |

**Key Features:**

- **Code Hotspot Detection** - Identifies files with high complexity and churn for prioritized refactoring
- **Latent Chain Mode** - 4-phase workflow (Analysis → Plan → Impl → Review) with context persistence
- **Memory Persistence** - Store decisions, patterns, and conventions across sessions
- **Token Budget Governor** - Manages context window with automatic checkpointing at 70%/85% thresholds
- **Proof Packs** - Creates tamper-evident records of code validation with SHA-256 hashes
- **Browser Testing** - Playwright integration for visual testing and screenshot capture
- **Thinking Models** - Chain-of-thought, tree-of-thoughts, ReAct, decomposition, first-principles
- **Agent Coordination** - Select and coordinate specialized agents for complex tasks

**Guard Module - What Gets Blocked:**

| Category | Examples | Rule |
|----------|----------|------|
| **File Operations** | `rm -rf /`, mass delete, overwrite system files | `dangerous-commands` |
| **API Breaking** | Remove public endpoints, change signatures | `breaking-changes` |
| **Database** | `DROP TABLE`, `TRUNCATE`, unsafe migrations | `unsafe-migrations` |
| **Git Operations** | Force push main, delete protected branches | `unsafe-git` |
| **Secrets** | Hardcoded passwords, API keys in code | `secrets-detection` |
| **Test Quality** | Tests without assertions, mocked everything | `fake-tests` |
| **Code Smells** | Empty catch blocks, disabled features | `code-quality` |

**Session Lifecycle:**

```
┌─────────────────────────────────────────────────────────┐
│  session_init  →  Work  →  session_end                  │
│       │                         │                       │
│       ▼                         ▼                       │
│  Creates session         Saves to disk                  │
│  Loads memory            Exports timeline               │
│  Sets up guards          Creates handoff                │
└─────────────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│  Next Session: session_resume                           │
│  • Full context restored                                │
│  • Memory persisted                                     │
│  • Timeline continued                                   │
└─────────────────────────────────────────────────────────┘
```

**Token Budget Governor:**

| Mode | Threshold | Behavior |
|------|-----------|----------|
| **Normal** | < 70% | All actions allowed |
| **Conservative** | 70-84% | Delta-only responses, no browser testing |
| **Critical** | ≥ 85% | Must checkpoint immediately, finish and save only |

**Thinking Models Available:**

| Model | When to Use |
|-------|-------------|
| `chain-of-thought` | Step-by-step debugging, logic problems |
| `tree-of-thoughts` | Multiple approaches, compare trade-offs |
| `react` | Exploration, experimentation (Reason + Act) |
| `self-consistency` | Verification, reliability (multiple solutions) |
| `decomposition` | Break complex problems into smaller parts |
| `first-principles` | Question assumptions, find fundamentals |

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

**Full-Featured Configuration:**

```json
{
  "name": "code-guardian",
  "command": "node",
  "args": ["/opt/mcp-servers/code-guardian/dist/index.js"],
  "env": {
    "CCG_PROJECT_ROOT": "/workspace",
    "CCG_MEMORY_DIR": "/workspace/.ccg",
    "CCG_ENABLE_BROWSER": "true",
    "CCG_STRICT_MODE": "true"
  }
}
```

**Environment Variables:**

| Variable | Description | Default |
|----------|-------------|---------|
| `CCG_PROJECT_ROOT` | Project root directory | Required |
| `CCG_MEMORY_DIR` | Memory/session storage directory | `.ccg/` |
| `CCG_ENABLE_BROWSER` | Enable Playwright browser testing | `false` |
| `CCG_STRICT_MODE` | Treat warnings as blocking errors | `false` |
| `CCG_CONFIRM_POLICY` | Diff confirmation: `auto`, `prompt`, `never` | `auto` |

**Quick Start Commands:**

```bash
# Initialize session
session_init

# Scan repository for hotspots
code_quick_analysis

# Store a decision
memory_store --content "Use Repository pattern" --type decision --importance 8

# Create a task
workflow_task_create --name "Refactor auth module" --priority high

# Validate code before commit
guard_validate --code "..." --filename "auth.ts" --ruleset backend

# End session (saves everything)
session_end --reason "Day end"
```

**Case Study Results (Self-Dogfooding):**

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| **TDI Score** | 75 (Grade D) | 68 (Grade D) | -9.3% |
| **Hotspots** | 12 files | 5 files | -58% |
| **Avg Complexity** | 28.4 | 22.1 | -22% |
| **Max Nesting** | 8 levels | 5 levels | -37% |

**Troubleshooting:**

| Issue | Solution |
|-------|----------|
| Session not persisting | Check `CCG_MEMORY_DIR` exists and is writable |
| Guards not blocking | Verify `CCG_STRICT_MODE=true` for strict enforcement |
| Browser tests failing | Ensure Playwright is installed: `npx playwright install` |
| Memory recall empty | Store memories with `importance >= 5` for retention |
| Token budget exceeded | Use `resource_checkpoint_create` before large operations |

**Integration with Other Bifrost Tools:**

| Tool Combination | Use Case |
|------------------|----------|
| **Code Guardian + narsil-mcp** | CCG for guardrails + narsil for deep security scanning |
| **Code Guardian + greb-mcp** | CCG for workflow + greb for semantic code search |
| **Code Guardian + Basic Memory** | CCG for code patterns + Basic Memory for project knowledge |
| **Code Guardian + beads-mcp** | CCG for session tracking + beads for issue management |

**Resources:**

- [Official Website](https://codeguardian.studio) - Features, pricing, case studies
- [GitHub Repository](https://github.com/phuongrealmax/code-guardian) - Source code, issues
- [NPM Package](https://www.npmjs.com/package/codeguardian-studio) - Installation
- [Case Study](https://codeguardian.studio/case-study) - TDI metrics and results

**Note:** Local server - copied into Docker image and built during image creation. 100% local execution - no data leaves your machine.

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
| **Version** | 0.3.0 |
| **MSRV** | Rust 1.85+ |
| **Install** | `cargo install mcpls` |

**Overview:**

mcpls bridges the gap between AI coding assistants and language servers. Instead of treating code as text, it gives AI agents access to the same compiler-level understanding that IDEs have: type information, cross-references, semantic navigation, and real diagnostics.

**Why mcpls?**

| Feature | mcpls | mcp-language-server | lsp-mcp | SwiftLens | narsil-mcp |
|---------|-------|---------------------|---------|-----------|------------|
| **Implementation** | Rust (single binary) | Go | TypeScript | Python | Rust |
| **Multi-Language** | ✅ 6+ LSP servers | ✅ 5 servers | ✅ Multiple | ❌ Swift only | ✅ 15 (tree-sitter) |
| **Live Diagnostics** | ✅ Push-based | ✅ | ❌ | ✅ | ❌ Static only |
| **Call Hierarchy** | ✅ Incoming/Outgoing | ❌ | ❌ | ✅ | ✅ Call graph |
| **Code Actions** | ✅ Quick fixes | ✅ | ❌ | ❌ | ❌ |
| **Rename Refactoring** | ✅ Workspace-wide | ❌ | ❌ | ❌ | ❌ |
| **Completions** | ✅ Type-aware | ✅ | ❌ | ❌ | ❌ |
| **Zero Config** | ✅ Rust projects | Partial | ❌ | ❌ | ✅ |
| **Stars** | 7+ | 1.4k | 161 | 102 | 200+ |

**Key Differentiators:**

- **Compiler-Level Intelligence**: Uses actual language servers (rust-analyzer, sourcekit-lsp) for real type info
- **Async-First Architecture**: Built on Tokio for non-blocking, concurrent LSP communication
- **Single Binary**: No Python, Node.js, or runtime dependencies - just the Rust binary
- **Push-Based Diagnostics**: Real-time compiler errors via `get_cached_diagnostics`
- **Refactoring Support**: Workspace-wide symbol rename with reference tracking

**When to Use mcpls:**

| Use Case | mcpls | Alternative |
|----------|-------|-------------|
| **Swift/iOS development** | ✅ sourcekit-lsp integration | SwiftLens (simpler, fewer tools) |
| **Rust development** | ✅ Zero-config rust-analyzer | narsil-mcp (security focus) |
| **Real-time compiler diagnostics** | ✅ Best choice - push-based | narsil-mcp (static only) |
| **Code completion suggestions** | ✅ Type-aware completions | Native IDE |
| **Workspace-wide refactoring** | ✅ rename_symbol with tracking | Manual find/replace |
| **Call hierarchy analysis** | ✅ get_incoming/outgoing_calls | narsil-mcp (get_callers) |
| **Security scanning** | ❌ Use narsil-mcp | narsil-mcp (taint, CVE) |
| **Code search & similarity** | ❌ Use narsil-mcp/greb | narsil-mcp (BM25, neural) |
| **Git integration** | ❌ Use narsil-mcp | narsil-mcp (--git flag) |

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
| **Monitoring** | `get_server_logs` | View language server output for debugging |
| | `get_server_messages` | Check server status and protocol messages |

**Supported Language Servers:**

| Language | Server | Auto-Detect | Notes |
|----------|--------|-------------|-------|
| **Swift** | sourcekit-lsp | `.swift` | Included in Swift toolchain |
| **Rust** | rust-analyzer | `.rs` | Zero-config, built-in detection |
| **Python** | pyright | `.py` | Full type inference, strict mode |
| **TypeScript/JS** | typescript-language-server | `.ts`, `.tsx`, `.js` | JSX/TSX support |
| **Go** | gopls | `.go` | Module and workspace support |
| **C/C++** | clangd | `.c`, `.cpp`, `.h` | Requires compile_commands.json |
| **Java** | jdtls | `.java` | Eclipse JDT Language Server |

**Installation:**

```bash
# From crates.io (recommended)
cargo install mcpls

# From source
git clone https://github.com/bug-ops/mcpls
cd mcpls
cargo build --release
```

**Bifrost Configuration (Basic):**

```json
{
  "name": "mcpls",
  "command": "mcpls",
  "args": []
}
```

**Bifrost Configuration (Swift Project):**

```json
{
  "name": "mcpls",
  "command": "mcpls",
  "args": [],
  "env": {
    "SOURCEKIT_TOOLCHAIN_PATH": "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain"
  }
}
```

**mcpls Configuration (`~/.config/mcpls/mcpls.toml`):**

```toml
# Swift via sourcekit-lsp
[[lsp_servers]]
language_id = "swift"
command = "sourcekit-lsp"
args = []
file_patterns = ["**/*.swift"]

# Rust via rust-analyzer (auto-detected, optional explicit config)
[[lsp_servers]]
language_id = "rust"
command = "rust-analyzer"
args = []
file_patterns = ["**/*.rs"]

# Python via pyright
[[lsp_servers]]
language_id = "python"
command = "pyright-langserver"
args = ["--stdio"]
file_patterns = ["**/*.py"]

# TypeScript/JavaScript
[[lsp_servers]]
language_id = "typescript"
command = "typescript-language-server"
args = ["--stdio"]
file_patterns = ["**/*.ts", "**/*.tsx", "**/*.js", "**/*.jsx"]
```

**Architecture:**

```
                         mcpls (Rust Binary)
                               │
    ┌──────────────────────────┼──────────────────────────┐
    │                          │                          │
    ▼                          ▼                          ▼
┌────────────┐          ┌────────────┐          ┌────────────┐
│ MCP Client │          │ LSP Router │          │ Config Mgr │
│ (stdio)    │          │            │          │ (TOML)     │
└─────┬──────┘          └─────┬──────┘          └────────────┘
      │                       │
      ▼                       ▼
┌────────────┐     ┌────────────────────────────────────────┐
│ AI Agent   │     │        Language Servers (LSP)           │
│ (Claude)   │     ├────────────────────────────────────────┤
└────────────┘     │ sourcekit-lsp │ rust-analyzer │ pyright│
                   └────────────────────────────────────────┘
```

**Integration with Other Tools:**

| Tool | Integration Pattern | Use Case |
|------|---------------------|----------|
| **narsil-mcp** | mcpls for live diagnostics, narsil for security | Code intelligence + security scanning |
| **SwiftZilla** | mcpls for code nav, SwiftZilla for Apple docs | Swift development workflow |
| **greb-mcp** | mcpls for local LSP, greb for cloud AI search | Semantic search + type navigation |
| **code-sentinel** | mcpls for refactoring, sentinel for quality | Refactoring with quality gates |

**Troubleshooting:**

| Issue | Solution |
|-------|----------|
| `sourcekit-lsp` not found | Install Xcode CLI Tools: `xcode-select --install` |
| Swift diagnostics not working | Set `SOURCEKIT_TOOLCHAIN_PATH` environment variable |
| Rust projects not detected | Install rust-analyzer: `rustup component add rust-analyzer` |
| Python type errors incomplete | Install pyright: `npm install -g pyright` |
| Config file not loading | Check path: `~/.config/mcpls/mcpls.toml` |
| LSP server crashes | Check server logs: `get_server_logs` tool |
| High memory usage | Exclude large generated directories in file_patterns |
| Slow initial indexing | Normal for large projects - subsequent queries fast |

**Note:** Single Rust binary with no runtime dependencies. The Docker image includes Swift 5.10.1 toolchain with sourcekit-lsp for Swift language intelligence. For Rust projects, mcpls auto-detects rust-analyzer without configuration.

---

### mcp-prompt-engine

> MCP server for managing and serving dynamic prompt templates using Go's powerful text/template engine. Create reusable, logic-driven prompts with variables, partials, and conditionals.

| | |
|---|---|
| **Repository** | [github.com/vasayxtx/mcp-prompt-engine](https://github.com/vasayxtx/mcp-prompt-engine) |
| **Docker** | [ghcr.io/vasayxtx/mcp-prompt-engine](https://ghcr.io/vasayxtx/mcp-prompt-engine) |
| **Go.Dev** | [pkg.go.dev/github.com/vasayxtx/mcp-prompt-engine](https://pkg.go.dev/github.com/vasayxtx/mcp-prompt-engine) |
| **Language** | Go (97.5%) |
| **License** | MIT |
| **Stars** | 15+ |
| **Version** | 0.4.0 |
| **Install** | `go install github.com/vasayxtx/mcp-prompt-engine@latest` |

**Why mcp-prompt-engine?**

| Feature | mcp-prompt-engine | Smart Prompts MCP | prompts-mcp-server | Langfuse Prompt Mgmt |
|---------|-------------------|-------------------|---------------------|----------------------|
| **Template Engine** | ✅ Go text/template | ❌ No templating | ❌ Static markdown | ✅ Mustache |
| **Logic Support** | ✅ Conditionals, loops, functions | ❌ | ❌ | Partial |
| **Reusable Partials** | ✅ `_partial.tmpl` inclusion | ❌ | ❌ | ❌ |
| **Hot-Reload** | ✅ File watching | ❌ GitHub fetch | ❌ | ✅ API-based |
| **JSON Args Parsing** | ✅ Auto booleans/arrays/objects | ❌ | ❌ | ❌ |
| **Environment Fallbacks** | ✅ Env vars as defaults | ❌ | ❌ | ❌ |
| **Storage** | Local files | GitHub only | Local markdown | Cloud SaaS |
| **Offline/Local** | ✅ Fully local | ❌ Requires GitHub | ✅ | ❌ Cloud required |
| **CLI Tools** | ✅ list/render/validate | ❌ | ❌ | ❌ |
| **Docker Image** | ✅ Pre-built GHCR | ❌ | ❌ | N/A |
| **Dependencies** | None (single binary) | Node.js | Node.js | API key |
| **Cost** | Free | Free (GitHub limits) | Free | Freemium |

**The Problem It Solves:**

Prompt engineering suffers from several issues:
- ❌ **Scattered prompts** - Copy-pasted across projects and tools
- ❌ **No reusability** - Common patterns duplicated everywhere
- ❌ **Static content** - No dynamic logic or conditionals
- ❌ **Version drift** - Different versions in different places
- ❌ **No validation** - Syntax errors discovered at runtime

mcp-prompt-engine solves these by treating prompts as **code**:
- ✅ **Single source of truth** - All prompts in one directory
- ✅ **DRY with partials** - Extract common patterns once
- ✅ **Dynamic templates** - Conditionals, loops, functions
- ✅ **Git-friendly** - Version control your prompts
- ✅ **CLI validation** - Catch errors before runtime

**Key Features:**

- 🔧 **Go Templates** - Full power of `text/template` syntax (variables, conditionals, loops, functions)
- 📦 **Reusable Partials** - Define common components in `_partial.tmpl` files and include anywhere
- 🔌 **MCP Native** - Works with any MCP client: Claude Code, Claude Desktop, Gemini CLI, VSCode Copilot
- 📝 **Prompt Arguments** - Template variables automatically exposed as MCP prompt arguments
- 🔄 **Hot-Reload** - Auto-detects file changes without server restart
- 🔢 **Smart JSON Parsing** - Automatic parsing of booleans, numbers, arrays, objects
- 🌍 **Environment Fallbacks** - Inject env vars as default values for missing arguments
- 📋 **Rich CLI** - List, validate, and render prompts from the command line
- 🐳 **Docker Ready** - Pre-built container image for easy deployment

**Template Syntax (Go text/template):**

```go
{{/* Brief description of the prompt - becomes the MCP prompt description */}}

{{- template "_partial_name" . -}}  {{/* Include a partial */}}

Your prompt text with {{.variable}} placeholders.

{{/* Conditionals */}}
{{if .enable_feature}}
  Feature is enabled: {{.feature_name}}
{{else}}
  Feature is disabled
{{end}}

{{/* Loops */}}
{{range .items}}
  - {{.}}
{{end}}

{{/* Logical operators */}}
{{if and .condition1 .condition2}}
  Both conditions are true
{{end}}

{{if or .option1 .option2}}
  At least one option is set
{{end}}

{{/* Built-in variables */}}
Current date: {{.date}}
```

**JSON Argument Parsing:**

The server automatically parses argument values as JSON, enabling rich data types:

| Input | Parsed As | Example |
|-------|-----------|---------|
| `true`, `false` | Go boolean | `{{if .enabled}}...{{end}}` |
| `42`, `3.14` | Go number | `Timeout: {{.timeout}}s` |
| `["a", "b", "c"]` | Go slice | `{{range .items}}{{.}}{{end}}` |
| `{"key": "value"}` | Go map | `Setting: {{.config.timeout}}` |
| Invalid JSON | String | Treated as literal text |

Use `--disable-json-args` flag to treat all arguments as strings.

**CLI Commands:**

| Command | Description | Example |
|---------|-------------|---------|
| `list` | List available prompts | `mcp-prompt-engine list --verbose` |
| `render <name>` | Render a prompt with arguments | `mcp-prompt-engine render git_commit -a type=feat` |
| `validate` | Check templates for syntax errors | `mcp-prompt-engine validate git_commit` |
| `serve` | Start the MCP server | `mcp-prompt-engine serve --quiet` |

**Render with Environment Variables:**

```bash
# Environment variables are automatically injected as fallbacks
TYPE=fix mcp-prompt-engine render git_commit
# Equivalent to: mcp-prompt-engine render git_commit -a type=fix
```

**Prompt Directory Structure:**

```
prompts/
├── _header.tmpl              # Partial (starts with _) - shared header
├── _git_commit_role.tmpl     # Partial for git commit context
├── _code_review_checklist.tmpl  # Partial for review checklist
├── git_stage_commit.tmpl     # Main prompt: uses _git_commit_role partial
├── git_amend_commit.tmpl     # Another commit prompt
├── code_review.tmpl          # Code review prompt
└── explain_code.tmpl         # Code explanation prompt
```

**Example: Git Commit Prompt with Partial**

**1. Create the partial (`prompts/_git_commit_role.tmpl`):**

```go
{{ define "_git_commit_role" }}
You are an expert programmer specializing in writing clear, concise, and conventional Git commit messages.
Commit message must strictly follow the Conventional Commits specification.

The final commit message format:
```
<<type>>: A brief, imperative-tense summary of changes

[Optional longer description explaining the "why" of the change]
```

{{ if .type -}}
Use {{.type}} as the commit type.
{{ end }}
{{ end }}
```

**2. Create the main prompt (`prompts/git_stage_commit.tmpl`):**

```go
{{- /* Commit currently staged changes */ -}}

{{- template "_git_commit_role" . -}}

Your task is to commit all currently staged changes.

To understand the context, analyze the staged code using: `git diff --staged`

Based on that analysis, commit staged changes using a suitable commit message.
```

**3. Validate and test:**

```bash
# Validate syntax
mcp-prompt-engine validate git_stage_commit
# ✓ git_stage_commit.tmpl - Valid

# Render with arguments
mcp-prompt-engine render git_stage_commit -a type=feat
```

**When to Use mcp-prompt-engine:**

| Use Case | mcp-prompt-engine | Alternative |
|----------|-------------------|-------------|
| **Reusable prompt templates** | ✅ Best choice - partials + templating | Manual copy-paste |
| **Dynamic prompts with logic** | ✅ Conditionals, loops, functions | Static prompts |
| **Team prompt standardization** | ✅ Git-versioned prompt library | Shared docs |
| **Local-first / offline** | ✅ No external dependencies | Cloud prompt managers |
| **CI/CD prompt validation** | ✅ CLI validate command | Manual testing |
| **Complex data in prompts** | ✅ JSON arrays/objects | String manipulation |
| **GitHub-hosted prompts** | Use Smart Prompts MCP | ✅ Fetches from GitHub |
| **SaaS prompt management** | Use Langfuse | ✅ Cloud UI + versioning |
| **Markdown-only prompts** | Use prompts-mcp-server | ✅ YAML frontmatter |

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

**Docker Configuration:**

```json
{
  "name": "mcp-prompt-engine",
  "command": "docker",
  "args": [
    "run", "-i", "--rm",
    "-v", "/path/to/prompts:/app/prompts:ro",
    "-v", "/path/to/logs:/app/logs",
    "ghcr.io/vasayxtx/mcp-prompt-engine"
  ]
}
```

**Installation Options:**

| Method | Command |
|--------|---------|
| **Go Install** | `go install github.com/vasayxtx/mcp-prompt-engine@latest` |
| **Docker** | `docker pull ghcr.io/vasayxtx/mcp-prompt-engine` |
| **From Source** | `git clone ... && make build` |
| **Pre-built Binary** | [GitHub Releases](https://github.com/vasayxtx/mcp-prompt-engine/releases) |

**Compatible Clients:**

| Client | Prompts Support | Notes |
|--------|-----------------|-------|
| **Claude Code** | ✅ | `/prompt_name` invocation |
| **Claude Desktop** | ✅ | Prompt picker UI |
| **Gemini CLI** | ✅ | `/prompt_name` invocation |
| **VSCode + Copilot** | ✅ | Via MCP extension |
| **Cursor** | ✅ | Full MCP support |
| **Windsurf** | ✅ | Full MCP support |

**Server Flags:**

| Flag | Description | Default |
|------|-------------|---------|
| `--prompts <dir>` | Directory containing `.tmpl` files | `./prompts` |
| `--quiet` | Suppress non-error output | Off |
| `--log-file <path>` | Write logs to file | stderr |
| `--disable-json-args` | Treat all arguments as strings | Off (JSON parsing enabled) |

**Troubleshooting:**

| Issue | Solution |
|-------|----------|
| Template syntax error | Run `mcp-prompt-engine validate <name>` to check syntax |
| Partial not found | Ensure partial starts with `_` and is in prompts directory |
| Variables not rendered | Check variable names match between template and arguments |
| Hot-reload not working | Check file permissions, ensure `.tmpl` extension |
| JSON args not parsing | Ensure valid JSON syntax; use `--disable-json-args` if needed |
| Docker mount issues | Use absolute paths, ensure `:ro` for read-only prompts |

**Integration with Other Bifrost Tools:**

| Combined With | Use Case |
|---------------|----------|
| **basic-memory** | Store prompt usage patterns and refinements |
| **beads-mcp** | Track prompt development as tasks |
| **code-guardian** | Validate prompt template quality |
| **adr-analysis** | Document prompt design decisions |

**Real-World Use Cases:**

| Scenario | Benefit |
|----------|---------|
| **Standardized git commits** | Team uses same commit message format via shared partial |
| **Code review checklists** | Consistent review criteria across all PRs |
| **Documentation generation** | Template-driven docs with project-specific variables |
| **Multi-language support** | Conditional content based on `{{.language}}` argument |
| **Feature flags in prompts** | Enable/disable prompt sections via boolean args |

**Resources:**

- [GitHub Repository](https://github.com/vasayxtx/mcp-prompt-engine)
- [Go.Dev Documentation](https://pkg.go.dev/github.com/vasayxtx/mcp-prompt-engine)
- [Go text/template Reference](https://pkg.go.dev/text/template)
- [MCP Prompts Specification](https://modelcontextprotocol.io/specification/2025-06-18/server/prompts)

---

### local-file-organizer

> Intelligent file organization MCP server with project-aware safety - automatically categorize, analyze, and organize files while protecting code repositories

| | |
|---|---|
| **Repository** | [github.com/diganto-deb/local_file_organizer](https://github.com/diganto-deb/local_file_organizer) |
| **Language** | Python 3.11+ |
| **License** | MIT |
| **Framework** | MCP Python SDK (FastMCP) |
| **Tools** | 9 |
| **Dependencies** | `mcp>=0.1.0`, `pathlib` |
| **Install** | Pre-installed in Bifrost Docker image |

**Why local-file-organizer?**

| Feature | local-file-organizer | Official Filesystem MCP | Better MCP File Server |
|---------|---------------------|------------------------|------------------------|
| **Smart Categorization** | ✅ 8 categories by extension | ❌ Raw file operations | ❌ Path aliasing only |
| **Project Detection** | ✅ 35+ project indicators | ❌ No awareness | ❌ No awareness |
| **Bulk Organization** | ✅ By category or extension | ❌ Manual moves | ❌ Manual moves |
| **Dry Run Preview** | ✅ `confirm=false` | ❌ Direct execution | ❌ Direct execution |
| **Recursive Analysis** | ✅ With depth control | Partial | ❌ |
| **Directory Analytics** | ✅ Size, counts, distribution | ❌ Basic metadata | ❌ |
| **File Writing** | ❌ Organization only | ✅ Full CRUD | ✅ Full CRUD |
| **Security Model** | Directory allowlist | Directory allowlist | Path aliasing |

**When to Use local-file-organizer:**

| Use Case | local-file-organizer | Alternative |
|----------|---------------------|-------------|
| **Cleaning up Downloads folder** | ✅ Best choice - auto-categorizes by type | Manual moves with Filesystem MCP |
| **Organizing media libraries** | ✅ Bulk move by Images/Videos/Audio | Manual sorting |
| **Analyzing disk usage by file type** | ✅ Built-in analytics with size stats | Third-party tools |
| **Tidying project archives** | ✅ Respects git repos and npm packages | Risk of breaking projects |
| **Reading/writing file contents** | Use Filesystem MCP instead | ✅ Filesystem MCP |
| **Creating/deleting files** | Use Filesystem MCP instead | ✅ Filesystem MCP |
| **Git-aware file operations** | Use narsil-mcp instead | ✅ narsil-mcp |

**Core Architecture:**

```
┌─────────────────────────────────────────────────────────────┐
│  analyze_directory (preview)                                │
│     └── Categorizes files without moving                    │
├─────────────────────────────────────────────────────────────┤
│  organize_files / bulk_move_files (execute)                 │
│     └── Moves files to category directories                 │
├─────────────────────────────────────────────────────────────┤
│  Project Detection Layer                                    │
│     └── Skips directories with project indicators           │
│         (.git, package.json, Cargo.toml, etc.)              │
└─────────────────────────────────────────────────────────────┘
```

**File Categories (8 total):**

| Category | Extensions | Example Use |
|----------|------------|-------------|
| **Documents** | `.pdf`, `.doc`, `.docx`, `.txt`, `.rtf`, `.md`, `.html`, `.json`, `.csv`, `.xlsx`, `.pptx`, `.tex`, `.pages`, `.key`, `.numbers`, `.odt`, `.ttl` | Reports, manuals, data files |
| **Images** | `.jpg`, `.jpeg`, `.png`, `.gif`, `.svg`, `.webp`, `.heic`, `.tiff`, `.bmp`, `.raw` | Photos, screenshots, graphics |
| **Videos** | `.mp4`, `.mov`, `.avi`, `.mkv`, `.wmv`, `.flv`, `.webm`, `.m4v` | Movies, screen recordings |
| **Audio** | `.mp3`, `.wav`, `.ogg`, `.flac`, `.m4a`, `.aac`, `.wma`, `.aiff` | Music, podcasts, recordings |
| **Archives** | `.zip`, `.rar`, `.7z`, `.tar`, `.gz`, `.bz2`, `.xz`, `.iso`, `.dmg` | Compressed files, disk images |
| **Code** | `.py`, `.js`, `.ts`, `.jsx`, `.tsx`, `.html`, `.css`, `.java`, `.cpp`, `.c`, `.h`, `.php`, `.rb`, `.go`, `.rs`, `.swift`, `.kt`, `.scala`, `.vue`, `.vsix` | Source files (moved only if loose) |
| **Applications** | `.dmg`, `.app`, `.exe`, `.msi`, `.deb`, `.rpm`, `.apk`, `.pkg` | Installers, executables |
| **Others** | All unrecognized extensions | Catch-all category |

**Project Indicators (35+ patterns):**

The server detects and protects directories containing:

| Type | Indicators |
|------|------------|
| **Version Control** | `.git`, `.gitignore` |
| **Node.js** | `package.json`, `package-lock.json`, `yarn.lock`, `node_modules` |
| **Python** | `requirements.txt`, `setup.py`, `Pipfile`, `venv`, `__pycache__` |
| **Rust** | `Cargo.toml`, `target` |
| **Java/Kotlin** | `pom.xml`, `build.gradle`, `build.sbt` |
| **Ruby** | `Gemfile` |
| **Go** | `go.mod` (detected via src directory) |
| **Docker** | `Dockerfile`, `docker-compose.yml` |
| **IDE** | `.idea`, `.vscode` |
| **Build** | `Makefile`, `CMakeLists.txt`, `build`, `dist` |
| **Xcode** | `.xcodeproj`, `Packages` |
| **Other** | `.env`, `tsconfig.json`, `webpack.config.js`, `composer.json` |

**MCP Tools (9 total):**

| Tool | Parameters | Description |
|------|------------|-------------|
| `list_categories` | None | List all 8 file categories with their extensions |
| `list_allowed_directories` | None | Show directories the server can access (home directory) |
| `create_category_directories` | `path` | Create all category folders in target directory |
| `list_directory_files` | `path` | List files and directories with `[FILE]`/`[DIR]` prefixes |
| `analyze_directory` | `path`, `recursive?`, `max_depth?` | Categorize files without moving - preview mode |
| `organize_files` | `path`, `confirm?`, `respect_projects?` | Move files to category directories (dry run by default) |
| `get_metadata` | `path`, `include_stats?` | Detailed metadata: size, dates, category breakdown, largest files |
| `analyze_project_directories` | `path` | Identify subdirectories that are projects with their indicators |
| `bulk_move_files` | `path`, `category?`, `file_extension?`, `respect_projects?` | Batch move by category or extension |

**Key Features:**

- **Directory Security** - Only operates on explicitly allowed directories (user home by default)
- **Project Detection** - Identifies 35+ project indicators to avoid disrupting repositories
- **Recursive Processing** - Analyze nested directories with configurable depth control (`max_depth`)
- **Dry Run Mode** - Preview all changes before executing (`confirm=false` is default)
- **Bulk Operations** - Move files by category (`category="Images"`) or extension (`file_extension=".mp4"`)
- **Smart Analytics** - File counts, size distribution, largest files, category breakdown
- **Excluded Directories** - Automatically skips `.git`, `node_modules`, `__pycache__`, `venv`, `.DS_Store`

**Workflow Example:**

```bash
# Step 1: Analyze what's in Downloads (dry run)
mcp__local-file-organizer__analyze_directory(path: "~/Downloads", recursive: true, max_depth: 2)
# Returns: 45 Documents, 120 Images, 15 Videos, 8 Archives...

# Step 2: Check for project directories that would be protected
mcp__local-file-organizer__analyze_project_directories(path: "~/Downloads")
# Returns: my-repo (indicators: .git, package.json)

# Step 3: Preview organization plan
mcp__local-file-organizer__organize_files(path: "~/Downloads", confirm: false)
# Returns: "To proceed with organizing files, call with confirm=True"

# Step 4: Execute organization
mcp__local-file-organizer__organize_files(path: "~/Downloads", confirm: true, respect_projects: true)
# Returns: Moved 188 files, my-repo preserved

# Step 5: Bulk move remaining videos to external drive
mcp__local-file-organizer__bulk_move_files(path: "~/Downloads/Videos", category: "Videos")
```

**Bifrost Configuration:**

```json
{
  "name": "local-file-organizer",
  "command": "/opt/mcp-servers/local_file_organizer/venv/bin/python",
  "args": ["/opt/mcp-servers/local_file_organizer/file_organizer.py"]
}
```

**Implementation Details:**

| Aspect | Detail |
|--------|--------|
| **Server Framework** | FastMCP (Python MCP SDK) |
| **File Operations** | `shutil.move()` for atomic moves |
| **Path Handling** | `pathlib.Path` for cross-platform compatibility |
| **Logging** | Python `logging` module with timestamps |
| **Error Handling** | Per-file error tracking with summary report |

**Comparison with Alternatives:**

| Server | Focus | Best For |
|--------|-------|----------|
| **local-file-organizer** | Organization & categorization | Cleaning up messy directories, analyzing file distribution |
| **Filesystem MCP** (official) | Raw file operations | Reading/writing file contents, creating files, general CRUD |
| **Better MCP File Server** | Simplified API with path aliases | LLM-friendly file access with 6-function API |
| **narsil-mcp** | Code intelligence | Git history, code search, call graphs (not general files) |

**Limitations:**

| Limitation | Workaround |
|------------|------------|
| Cannot read/write file contents | Use Filesystem MCP for content operations |
| Cannot create new files | Use Filesystem MCP for file creation |
| Cannot rename files individually | Use Filesystem MCP or shell commands |
| No cloud storage support | Limited to local filesystem |
| Categories are extension-based | Cannot detect file type by content/magic bytes |

**Troubleshooting:**

| Issue | Solution |
|-------|----------|
| Permission denied | Check that path is under user's home directory |
| Project not detected | Add missing indicators to `PROJECT_INDICATORS` in source |
| Files not categorized | Check extension is in `CATEGORIES` dict; falls back to "Others" |
| Recursive too slow | Reduce `max_depth` parameter or exclude more directories |
| Files moved unexpectedly | Use `confirm=false` first to preview; enable `respect_projects=true` |

**Integration with Other Bifrost Tools:**

| Combined With | Use Case |
|---------------|----------|
| **narsil-mcp** | Organize files first, then analyze code structure |
| **basic-memory** | Store organization patterns and file distribution notes |
| **beads-mcp** | Track file cleanup tasks as issues |

**Resources:**

- [GitHub Repository](https://github.com/diganto-deb/local_file_organizer)
- [MCP Python SDK Documentation](https://github.com/anthropics/mcp-python-sdk)
- [FastMCP Framework](https://github.com/jlowin/fastmcp)
- [Official Filesystem MCP](https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem) (for comparison)

---

### llm-council

> Multi-model LLM deliberation system with 3-stage consensus - collect diverse perspectives, peer-rank responses anonymously, synthesize final answer

| | |
|---|---|
| **Repository** | [github.com/karpathy/llm-council](https://github.com/karpathy/llm-council) (original by Andrej Karpathy) |
| **Fork** | [github.com/khuynh22/llm-council](https://github.com/khuynh22/llm-council) (MCP integration) |
| **Language** | Python 3.10+ |
| **License** | MIT |
| **Framework** | MCP Python SDK |
| **Tools** | 4 |
| **Backend** | OpenRouter API (single key, multiple models) |
| **Install** | Pre-installed in Bifrost Docker image |

**Why llm-council?**

| Feature | llm-council | ai-counsel | consensus | Single Model |
|---------|-------------|------------|-----------|--------------|
| **Multi-Model Diversity** | ✅ 5 models default | ✅ 4 models | ✅ Configurable | ❌ Single view |
| **Peer Review (Stage 2)** | ✅ Anonymized ranking | ❌ Voting only | ❌ No peer review | ❌ N/A |
| **Chairman Synthesis** | ✅ Dedicated synthesizer | ❌ Consensus merge | ❌ Strategy-based | ❌ N/A |
| **Conversation Memory** | ✅ SQLite storage | ✅ Decision graphs | ❌ Stateless | ✅ Context window |
| **MCP Protocol** | ✅ Native | ✅ Native | ❌ Langchain | ❌ Direct API |
| **Local Models** | ❌ OpenRouter only | ✅ Ollama support | ❌ Cloud only | ✅ Depends |
| **Execution Time** | 30-120s (3 stages) | 60-300s (debates) | 10-30s (parallel) | 3-10s |
| **API Cost** | Medium (5×3 calls) | Low (local option) | Medium | Low |

**The 3-Stage Deliberation Process:**

```
┌─────────────────────────────────────────────────────────────────────────┐
│  STAGE 1: Individual Responses                                          │
│  ─────────────────────────────                                          │
│  • Query 5 models in parallel via OpenRouter                            │
│  • Each model responds independently to the user question               │
│  • No cross-model contamination at this stage                           │
│                                                                         │
│  Models: GPT-5.1, Gemini 3 Pro, Claude Sonnet 4.5, Claude Opus 4, Grok 4│
├─────────────────────────────────────────────────────────────────────────┤
│  STAGE 2: Anonymized Peer Ranking                                       │
│  ────────────────────────────────                                       │
│  • Each model receives ALL Stage 1 responses (anonymized as A, B, C...) │
│  • Models evaluate and rank responses without knowing authorship        │
│  • Aggregate rankings calculated from all peer reviews                  │
│  • Reveals which models' responses are most valued by peers             │
├─────────────────────────────────────────────────────────────────────────┤
│  STAGE 3: Chairman Synthesis                                            │
│  ───────────────────────────                                            │
│  • Chairman model (Gemini 3 Pro by default) receives:                   │
│    - Original question                                                  │
│    - All Stage 1 responses with model names                            │
│    - All Stage 2 rankings and evaluations                              │
│  • Synthesizes final answer incorporating collective wisdom             │
│  • Result represents council consensus, not single-model bias           │
└─────────────────────────────────────────────────────────────────────────┘
```

**When to Use llm-council:**

| Use Case | llm-council | Alternative |
|----------|-------------|-------------|
| **Critical architectural decisions** | ✅ Best choice - diverse expert opinions | Single model with chain-of-thought |
| **Controversial or nuanced topics** | ✅ Reduces single-model bias | Manual comparison of responses |
| **Evaluating multiple approaches** | ✅ Peer ranking reveals quality | Human evaluation |
| **Complex trade-off analysis** | ✅ Synthesis weighs competing views | Decision matrix prompts |
| **Quick questions (< 10s needed)** | Use single model | ✅ Direct API call |
| **Cost-sensitive queries** | Use single model | ✅ Lower API costs |
| **Local/offline operation** | Use ai-counsel with Ollama | ✅ ai-counsel |
| **Multi-round debates** | Use ai-counsel | ✅ ai-counsel (deliberative rounds) |
| **Simple fact lookup** | Use single model + search | ✅ Web search tools |

**Default Council Configuration:**

| Role | Model | Purpose |
|------|-------|---------|
| **Council Member** | `openai/gpt-5.1` | OpenAI's latest reasoning model |
| **Council Member** | `google/gemini-3-pro-preview` | Google's frontier model |
| **Council Member** | `anthropic/claude-sonnet-4.5` | Anthropic's balanced model |
| **Council Member** | `anthropic/claude-opus-4-20250514` | Anthropic's most capable model |
| **Council Member** | `x-ai/grok-4` | xAI's frontier model |
| **Chairman** | `google/gemini-3-pro-preview` | Synthesis and final answer |

**MCP Tools (4 total):**

| Tool | Parameters | Description |
|------|------------|-------------|
| `council_query` | `question`, `council_models?`, `chairman_model?`, `save_conversation?` | Full 3-stage deliberation (30-120s). Returns synthesized answer with all stage data. |
| `council_stage1` | `question`, `council_models?` | Stage 1 only - parallel individual responses. Fast comparison without ranking. |
| `council_list_conversations` | None | List all saved council conversations with metadata |
| `council_get_conversation` | `conversation_id` | Retrieve full conversation by ID with all stages |

**Response Structure:**

```json
{
  "question": "What is the best caching strategy for a mobile app?",
  "stage1_responses": [
    {"model": "openai/gpt-5.1", "response": "For mobile apps, I recommend..."},
    {"model": "google/gemini-3-pro-preview", "response": "Consider a hybrid approach..."},
    {"model": "anthropic/claude-sonnet-4.5", "response": "The optimal strategy depends on..."},
    {"model": "anthropic/claude-opus-4-20250514", "response": "Mobile caching requires..."},
    {"model": "x-ai/grok-4", "response": "There are three main patterns..."}
  ],
  "stage2_rankings": [
    {
      "model": "openai/gpt-5.1",
      "ranking": "Response C provides the most comprehensive...\n\nFINAL RANKING:\n1. Response C\n2. Response E\n3. Response A\n4. Response B\n5. Response D",
      "parsed_ranking": ["Response C", "Response E", "Response A", "Response B", "Response D"]
    }
  ],
  "stage3_synthesis": {
    "model": "google/gemini-3-pro-preview",
    "response": "Based on the council's deliberation, the recommended caching strategy is..."
  },
  "metadata": {
    "label_to_model": {"Response A": "openai/gpt-5.1", "Response B": "google/gemini-3-pro-preview"},
    "aggregate_rankings": [
      {"model": "anthropic/claude-sonnet-4.5", "average_rank": 1.8, "rankings_count": 5},
      {"model": "x-ai/grok-4", "average_rank": 2.2, "rankings_count": 5}
    ]
  },
  "conversation_id": "550e8400-e29b-41d4-a716-446655440000",
  "resource_uri": "council://conversations/550e8400-e29b-41d4-a716-446655440000"
}
```

**Workflow Examples:**

```bash
# Full council deliberation for critical decisions
mcp__llm-council__council_query(
  question: "Should we use SQLite or PostgreSQL for local-first mobile architecture?",
  save_conversation: true
)
# Returns: 3-stage deliberation with synthesis (~60s)

# Quick comparison without ranking (Stage 1 only)
mcp__llm-council__council_stage1(
  question: "What are the pros and cons of SwiftUI vs UIKit?"
)
# Returns: 5 parallel responses (~15s)

# Use custom models for specialized topics
mcp__llm-council__council_query(
  question: "Evaluate this Go code for performance issues",
  council_models: ["anthropic/claude-opus-4-20250514", "google/gemini-3-pro-preview", "openai/gpt-5.1"],
  chairman_model: "anthropic/claude-opus-4-20250514"
)

# Retrieve past deliberation for reference
mcp__llm-council__council_get_conversation(
  conversation_id: "550e8400-e29b-41d4-a716-446655440000"
)
```

**Comparison with Competitors:**

| Aspect | llm-council | ai-counsel | consensus | PolyCouncil |
|--------|-------------|------------|-----------|-------------|
| **Philosophy** | Expert panel + chairman | Deliberative democracy | Voting strategies | Local model council |
| **Unique Feature** | Anonymized peer ranking | Multi-round debates | Langchain integration | LM Studio support |
| **Best For** | High-stakes decisions | Consensus building | Simple aggregation | Privacy-sensitive |
| **Complexity** | Medium | High | Low | Low |
| **Setup** | OpenRouter API key | Can use Ollama | Multiple API keys | LM Studio |
| **MCP Support** | ✅ Native | ✅ Native | ❌ Python library | ❌ Python library |

**Detailed Competitor Analysis:**

**ai-counsel** (166 GitHub stars):
- True deliberative consensus with multi-round debates
- Structured voting and decision graph memory
- Supports local models via Ollama
- Tracks decision history in knowledge graph
- Better for: Extended debates, local/private use, complex multi-round discussions

**consensus** (Langchain-compatible):
- Multiple voting strategies: majority, weighted, ranked choice
- Integrates with existing Langchain pipelines
- Simpler than llm-council (no peer review stage)
- Better for: Langchain users, simple aggregation needs

**PolyCouncil**:
- Designed for LM Studio local models
- No cloud API dependencies
- Better for: Air-gapped environments, local model testing

**Key Advantages of llm-council:**
1. **Peer Review Stage** - Only system with anonymized cross-model evaluation
2. **Aggregate Rankings** - Quantitative quality metrics from peer review
3. **Chairman Pattern** - Dedicated synthesis rather than voting/merging
4. **OpenRouter Integration** - Single API key for 100+ models
5. **Conversation Memory** - SQLite storage for reviewing past deliberations

**Bifrost Configuration:**

```json
{
  "name": "llm-council",
  "command": "/opt/mcp-servers/llm-council/venv/bin/python",
  "args": ["-m", "backend.mcp_server"],
  "env": {
    "OPENROUTER_API_KEY": "${OPENROUTER_API_KEY}"
  }
}
```

**CLI Usage (Outside MCP):**

```bash
# Quick Stage 1 comparison
./scripts/council --stage1 "What is the best caching strategy?"

# Full 3-stage deliberation
./scripts/council "Should we use SQLite or PostgreSQL for local-first?"

# Extended timeout for complex questions
./scripts/council --timeout=300 "Evaluate this architecture proposal..."
```

**Cost Estimation:**

| Query Type | API Calls | Approximate Cost* |
|------------|-----------|-------------------|
| `council_stage1` | 5 (parallel) | $0.05-0.15 |
| `council_query` | 5 + 5 + 1 = 11 | $0.15-0.40 |
| Custom 3 models | 3 + 3 + 1 = 7 | $0.10-0.25 |

*Costs vary by model and response length. OpenRouter pricing applies.

**Limitations:**

| Limitation | Workaround |
|------------|------------|
| No local model support | Use ai-counsel with Ollama for local models |
| 30-120s execution time | Use `council_stage1` for faster (15s) comparison |
| OpenRouter dependency | Requires internet and API key |
| No streaming responses | Wait for full completion |
| Fixed 3-stage process | Cannot customize deliberation stages |
| No real-time collaboration | Single-user, synchronous queries |

**Troubleshooting:**

| Issue | Solution |
|-------|----------|
| "All models failed to respond" | Check `OPENROUTER_API_KEY` is set and valid |
| Timeout errors | Increase timeout or use `council_stage1` for faster results |
| Empty stage2_rankings | Some models may fail to parse ranking format; check logs |
| High costs | Reduce council size or use cheaper models |
| Conversation not found | Verify `save_conversation: true` was used |

**Integration with Other Bifrost Tools:**

| Combined With | Use Case |
|---------------|----------|
| **basic-memory** | Store council decisions for long-term architectural knowledge |
| **beads-mcp** | Track deliberation tasks and outcomes as issues |
| **adr-analysis** | Generate ADRs from council architectural decisions |
| **narsil-mcp** | Analyze code before asking council for review |

**Resources:**

- [Original Repository (Karpathy)](https://github.com/karpathy/llm-council)
- [MCP Fork](https://github.com/khuynh22/llm-council)
- [OpenRouter API](https://openrouter.ai/docs)
- [OpenRouter Model List](https://openrouter.ai/models)
- [MCP Python SDK](https://github.com/anthropics/mcp-python-sdk)
- [ai-counsel Alternative](https://github.com/blueman82/ai-counsel)

---

### exa-mcp

> **AI-native web search using neural embeddings and next-link prediction**

| | |
|---|---|
| **Repository** | [github.com/exa-labs/exa-mcp-server](https://github.com/exa-labs/exa-mcp-server) |
| **GitHub Stars** | 3.5k+ |
| **Type** | Remote MCP (HTTP) |
| **License** | MIT |
| **Tools** | 7 |
| **Install** | None required (hosted) |

**Why Exa?**

| Feature | Exa | Tavily | Perplexity | Firecrawl |
|---------|-----|--------|------------|-----------|
| Neural/semantic search | **Yes (core)** | Keyword + AI | Yes | No (scraping) |
| Code-specific search | **Yes (billions of repos)** | No | Limited | No |
| Next-link prediction | **Yes (unique)** | No | No | No |
| Livecrawl (real-time) | **Yes (preferred mode)** | Limited | No | Yes |
| Deep research (agentic) | **Yes (multi-step)** | No | No | No |
| LinkedIn search | **Yes** | No | No | No |
| Company research | **Yes** | Basic | Yes | No |
| Response latency | Fast (<400ms) to Deep | Fast | Medium | Slow |
| Hosted MCP (no install) | **Yes** | No | No | No |
| Pricing | $0.005/search | $0.01/search | Subscription | $0.001/page |

**What Makes Exa Different:**

Exa is fundamentally different from traditional search engines. Instead of keyword matching, it uses **embeddings-based "next-link prediction"** - trained on billions of web links to predict what page should come next given a query context. This means:

1. **Semantic Understanding**: Queries like "best practices for SwiftUI MVVM" return conceptually relevant results, not just keyword matches
2. **AI-Optimized Output**: Returns structured data designed for LLM consumption, not HTML pages
3. **Code Intelligence**: Dedicated code search over GitHub repos, documentation, and StackOverflow
4. **Real-time Data**: Livecrawl fetches fresh content, not stale cached pages

**Available Tools:**

| Tool | Description | Use Case |
|------|-------------|----------|
| `web_search_exa` | Neural web search with semantic understanding | General research, finding articles, tutorials |
| `get_code_context_exa` | Code-specific search across billions of repos | API docs, code examples, library usage |
| `deep_researcher_start` | Start async multi-step agentic research | Complex questions requiring synthesis |
| `deep_researcher_check` | Poll research task status and get results | Retrieve deep research findings |
| `company_research_exa` | Comprehensive company intelligence | Business research, competitor analysis |
| `crawling_exa` | Extract full content from specific URLs | Read article content, scrape pages |
| `linkedin_search_exa` | Search LinkedIn profiles and companies | Recruiting, professional networking research |

**Search Types:**

| Type | Latency | Description | Best For |
|------|---------|-------------|----------|
| `auto` | Variable | Combines keyword + neural intelligently | **Default - most queries** |
| `neural` | ~500ms | Pure semantic/embedding search | Conceptual queries, research |
| `fast` | <400ms | Prioritizes speed over depth | Quick lookups, simple facts |
| `deep` | 15-120s | Comprehensive multi-step research | Complex analysis, synthesis |

**Livecrawl Options:**

| Mode | Description | Use Case |
|------|-------------|----------|
| `preferred` | Use live content when available | **Recommended default** |
| `fallback` | Live only if cached unavailable | Balance freshness/speed |
| `always` | Force live crawl every time | News, rapidly changing content |
| `never` | Only cached content | Maximum speed, historical data |

**When to Use:**

| Scenario | Tool | Why |
|----------|------|-----|
| "How do I use SwiftUI NavigationStack?" | `get_code_context_exa` | Code-specific search with examples |
| "Latest news about AI regulation" | `web_search_exa` (livecrawl: always) | Fresh content required |
| "Research Company X's market position" | `company_research_exa` | Structured business intelligence |
| "Compare microservices vs monolith" | `deep_researcher_start/check` | Complex multi-source synthesis |
| "Find React developers in SF" | `linkedin_search_exa` | Professional profile search |
| "Extract content from this URL" | `crawling_exa` | Full page content extraction |
| General web search | `web_search_exa` (auto) | Semantic understanding of intent |

**When NOT to Use (Use Alternatives):**

| Scenario | Use Instead | Why |
|----------|-------------|-----|
| Apple/Swift official documentation | **Swiftzilla** | Direct Apple docs access |
| Local codebase search | **narsil-mcp** or **greb-mcp** | Already indexed, faster |
| Reddit discussions | **Reddit MCP** | Dedicated Reddit API |
| Already have specific URL | `crawling_exa` or **Firecrawl** | Direct fetch is faster |
| Need structured data extraction | **Firecrawl** | Better HTML-to-structured conversion |

**Bifrost Configuration:**

Exa MCP is a **remote HTTP server** - no local installation required:

```json
{
  "mcpServers": {
    "exa": {
      "type": "http",
      "url": "https://mcp.exa.ai/mcp"
    }
  }
}
```

**Tool Selection (Optional):**

Limit which tools are exposed by adding query parameters:

```json
{
  "mcpServers": {
    "exa": {
      "type": "http",
      "url": "https://mcp.exa.ai/mcp?tools=web_search_exa,get_code_context_exa,crawling_exa"
    }
  }
}
```

Available tool parameter values:
- `web_search_exa`
- `get_code_context_exa`
- `deep_researcher_start`
- `deep_researcher_check`
- `company_research_exa`
- `crawling_exa`
- `linkedin_search_exa`

**Environment Variables:**

| Variable | Required | Description |
|----------|----------|-------------|
| None | - | Hosted service handles authentication |

Note: Exa MCP is fully hosted. API authentication is handled by the MCP server, not through environment variables. Usage is tied to your Exa account.

**Pricing:**

| Operation | Cost |
|-----------|------|
| Neural search | $0.005/search |
| Deep search | $0.015/search |
| Content retrieval | $0.001/page |
| Code context | $0.005/query |
| Company research | $0.01/query |
| LinkedIn search | $0.005/query |

**Rate Limits:**

| Endpoint | Limit |
|----------|-------|
| Search | 5 QPS |
| Contents | 50 QPS |
| Answer/Research | 5 QPS |

**Troubleshooting:**

| Issue | Solution |
|-------|----------|
| "Rate limit exceeded" | Reduce query frequency, implement backoff |
| Empty search results | Try `type: "neural"` for semantic queries |
| Stale content | Use `livecrawl: "always"` or `"preferred"` |
| Deep research timeout | Use `deep_researcher_check` to poll status |
| LinkedIn results empty | LinkedIn data availability varies by region |
| Code search irrelevant | Be specific about language/framework in query |
| High costs | Use `type: "fast"` for simple queries, cache results |

**Integration with Other Bifrost Tools:**

| Combined With | Use Case |
|---------------|----------|
| **basic-memory** | Store research findings for long-term knowledge |
| **narsil-mcp** | Exa for external docs, Narsil for local codebase |
| **greb-mcp** | Exa for web code examples, Greb for project search |
| **adr-analysis** | Research best practices before architectural decisions |
| **llm-council** | Gather Exa research, then deliberate with council |
| **beads-mcp** | Track research tasks and findings as issues |

**Example Workflows:**

1. **Code Research Pattern:**
   ```
   User: "How do I implement OAuth in SwiftUI?"

   1. get_code_context_exa("SwiftUI OAuth implementation ASWebAuthenticationSession")
   2. Review code examples from results
   3. Store key patterns in basic-memory
   ```

2. **Deep Research Pattern:**
   ```
   User: "Analyze the tradeoffs between SQLite and Core Data for iOS"

   1. deep_researcher_start("Compare SQLite vs Core Data for iOS apps: performance, complexity, sync capabilities")
   2. deep_researcher_check(taskId) - poll until complete
   3. Synthesize findings into ADR with adr-analysis
   ```

3. **Company Due Diligence:**
   ```
   User: "Research Supabase as a backend option"

   1. company_research_exa("Supabase")
   2. web_search_exa("Supabase production issues OR problems")
   3. linkedin_search_exa("Supabase engineers")
   4. Combine insights for decision
   ```

**Resources:**

- [Exa Documentation](https://docs.exa.ai/)
- [Exa MCP Reference](https://exa.ai/docs/reference/exa-mcp)
- [GitHub Repository](https://github.com/exa-labs/exa-mcp-server)
- [Exa Dashboard](https://dashboard.exa.ai/)
- [Search Types Guide](https://docs.exa.ai/reference/search)
- [API Pricing](https://exa.ai/pricing)

---

### supabase-mcp

> **Official Supabase MCP server for database operations, Edge Functions, and project management**

| | |
|---|---|
| **Repository** | [github.com/supabase-community/supabase-mcp](https://github.com/supabase-community/supabase-mcp) |
| **GitHub Stars** | 2.4k+ |
| **Type** | Remote MCP (HTTP via SSE) |
| **License** | Apache-2.0 |
| **Tools** | 20+ (varies by feature selection) |
| **Install** | None required for hosted; `npx supabase-mcp` for local |
| **Auth** | OAuth 2.1 (hosted) or Personal Access Token (local) |

**Why Supabase MCP?**

| Feature | Supabase MCP | Prisma MCP | DBHub | MCP Toolbox for DBs |
|---------|--------------|------------|-------|---------------------|
| Hosted (no install) | **Yes** | No | No | No |
| OAuth authentication | **Yes (2.1)** | No | No | No |
| Database read/write | **Yes** | Yes | Yes | Yes |
| Schema migrations | **Yes (apply_migration)** | No | No | No |
| Edge Functions | **Yes (deploy, manage)** | No | No | No |
| Branching support | **Yes (create, merge, rebase)** | No | No | No |
| Storage management | **Yes (buckets, files)** | No | No | No |
| Auth system integration | **Yes** | No | No | No |
| TypeScript types gen | **Yes** | Yes | No | No |
| Docs search | **Yes (RAG-style)** | No | No | No |
| Read-only mode | **Yes (?read_only)** | Yes | Yes | Yes |
| Multi-project | **Yes (?project_ref)** | Per-config | Yes | Yes |
| Prompt injection safety | Moderate (RLS helps) | Moderate | Moderate | Moderate |

**What Makes Supabase MCP Different:**

Supabase MCP is the **only full-stack database MCP** that includes:

1. **Hosted Remote Server**: No installation required - just configure the URL `https://mcp.supabase.com/mcp`
2. **OAuth 2.1 Auth**: Dynamic client registration (PKCE) - no API keys to manage
3. **Project Scoping**: Restrict AI to a single project with `?project_ref=<ref>`
4. **Feature Groups**: Control tool exposure with `?features=database,docs` for token efficiency
5. **Full DevOps Pipeline**: Database → Edge Functions → Branching → Deployment all in one MCP

**Available Tools by Category:**

| Category | Tools | Description |
|----------|-------|-------------|
| **Account** | `list_organizations`, `list_projects`, `get_project` | Project and org management |
| **Database** | `list_tables`, `list_extensions`, `execute_sql`, `apply_migration` | Full PostgreSQL control |
| **Debugging** | `get_logs`, `get_advisors` | Service logs, security/perf advisors |
| **Development** | `get_project_url`, `get_publishable_keys`, `generate_typescript_types` | Dev helpers |
| **Edge Functions** | `list_edge_functions`, `get_edge_function`, `deploy_edge_function` | Serverless deployment |
| **Branching** | `create_branch`, `list_branches`, `delete_branch`, `merge_branch`, `reset_branch`, `rebase_branch` | Git-like DB branching |
| **Docs** | `search_docs` | GraphQL-based docs search |
| **Storage** | Bucket and file operations | Object storage management |

**Key Tools Deep Dive:**

| Tool | Description | Example Use Case |
|------|-------------|------------------|
| `list_tables` | List all tables with schemas | "What tables exist in my project?" |
| `execute_sql` | Run arbitrary SQL (respects RLS) | "Count users created this week" |
| `apply_migration` | Create versioned migrations | "Add a status column to orders" |
| `get_logs` | Fetch logs by service | "Show me auth errors from today" |
| `get_advisors` | Security/performance insights | "Check for RLS policy issues" |
| `deploy_edge_function` | Deploy Deno functions | "Deploy my webhook handler" |
| `create_branch` | Create preview database | "Make a branch for testing" |
| `search_docs` | GraphQL docs search | "How do I set up RLS?" |
| `generate_typescript_types` | Generate types from schema | "Create types for my tables" |

**Feature Groups (Token Efficiency):**

| Configuration | Tools Loaded | Token Cost |
|---------------|--------------|------------|
| All features (default) | 20+ tools | ~19.3k tokens |
| `?features=database,docs` | 8 tools | ~4.2k tokens |
| `?features=database` | 5 tools | ~2.5k tokens |
| `?features=docs` | 1 tool | ~0.8k tokens |

Available feature groups: `account`, `database`, `debugging`, `development`, `edge_functions`, `branching`, `docs`, `storage`

**When to Use:**

| Scenario | Use Supabase MCP? | Why |
|----------|-------------------|-----|
| Query your Supabase database | ✅ **Yes** | Direct SQL access with RLS |
| Apply database migrations | ✅ **Yes** | Version-controlled schema changes |
| Deploy Edge Functions | ✅ **Yes** | One-command deployment |
| Branch for testing | ✅ **Yes** | Isolated preview environments |
| Debug auth/storage issues | ✅ **Yes** | Service logs access |
| Generate TypeScript types | ✅ **Yes** | Schema-to-types automation |
| General PostgreSQL (non-Supabase) | ❌ Use DBHub | Supabase-specific integration |
| Prisma-managed schemas | ❌ Use Prisma MCP | Prisma-specific migrations |
| Read-only analytics | ✅ Yes (with ?read_only) | Safe for prod exploration |

**When NOT to Use (Use Alternatives):**

| Scenario | Use Instead | Why |
|----------|-------------|-----|
| Non-Supabase PostgreSQL | **DBHub** or **MCP Toolbox** | Supabase-specific auth |
| Prisma-managed database | **Prisma MCP** | Schema drift risk |
| Production write operations | **Direct Supabase client** | More control, audit trails |
| Complex multi-step transactions | **Direct SQL/client** | MCP is per-query |
| Sensitive data environments | Consider **local MCP** | OAuth tokens in hosted |

**Security Considerations:**

⚠️ **The "Lethal Trifecta" (applies to ALL database MCPs):**

1. **Write access** to database
2. **AI-controlled SQL** execution
3. **User-influenced prompts** (potential injection)

**Mitigations provided by Supabase MCP:**

| Risk | Mitigation | Configuration |
|------|------------|---------------|
| Destructive queries | Read-only mode | `?read_only=true` |
| Cross-project access | Project scoping | `?project_ref=<ref>` |
| Tool sprawl | Feature groups | `?features=database,docs` |
| Direct table writes | RLS enforcement | Always enabled |
| Over-privileged access | Dedicated postgres user | `authenticator` role in read-only |

**Best Practice Configuration:**

```json
{
  "mcpServers": {
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp?project_ref=your-project-ref&read_only=true&features=database,docs"
    }
  }
}
```

**Bifrost Configuration Options:**

**Option 1: Hosted Remote (Recommended for most cases)**

```json
{
  "mcpServers": {
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp"
    }
  }
}
```

OAuth authentication happens automatically via browser redirect.

**Option 2: Hosted with Project Scoping (Production)**

```json
{
  "mcpServers": {
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp?project_ref=abcdefghijklmnop&read_only=true&features=database,docs,debugging"
    }
  }
}
```

**Option 3: Local STDIO (Self-managed auth)**

```json
{
  "mcpServers": {
    "supabase": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "supabase-mcp"],
      "env": {
        "SUPABASE_ACCESS_TOKEN": "${SUPABASE_ACCESS_TOKEN}"
      }
    }
  }
}
```

**URL Query Parameters:**

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `project_ref` | string | Restrict to single project | `?project_ref=abcdef123456` |
| `read_only` | boolean | Use read-only postgres user | `?read_only=true` |
| `features` | string | Comma-separated feature groups | `?features=database,docs` |

**Environment Variables (Local STDIO only):**

| Variable | Required | Description |
|----------|----------|-------------|
| `SUPABASE_ACCESS_TOKEN` | Yes (local) | Personal Access Token from dashboard |

For hosted version, OAuth handles authentication - no tokens needed.

**Integration with Other Bifrost Tools:**

| Combined With | Use Case |
|---------------|----------|
| **adr-analysis** | Generate ADRs from schema decisions |
| **narsil-mcp** | Search codebase for Supabase client usage |
| **basic-memory** | Store schema patterns and decisions |
| **beads-mcp** | Track migration tasks and database work |
| **llm-council** | Deliberate on schema design decisions |
| **greb-mcp** | Find all repository.fetch() calls |

**Example Workflows:**

1. **Database Exploration:**
   ```
   User: "What tables do I have and their relationships?"

   1. list_tables(schemas: ["public"])
   2. execute_sql("SELECT ... FROM information_schema.table_constraints")
   3. Summarize schema structure
   ```

2. **Safe Migration Pattern:**
   ```
   User: "Add a status column to the orders table"

   1. list_tables() - verify table exists
   2. execute_sql("SELECT column_name FROM information_schema.columns WHERE table_name = 'orders'")
   3. apply_migration(name: "add_orders_status", query: "ALTER TABLE orders ADD COLUMN status text DEFAULT 'pending'")
   4. generate_typescript_types() - update client types
   ```

3. **Debug Production Issue:**
   ```
   User: "Users are getting auth errors"

   1. get_logs(service: "auth") - recent auth logs
   2. get_advisors(type: "security") - check for RLS issues
   3. execute_sql("SELECT * FROM auth.users WHERE last_sign_in_at > now() - interval '1 hour'")
   ```

4. **Feature Branch Workflow:**
   ```
   User: "Create a branch for testing new schema"

   1. create_branch(name: "feature-new-schema")
   2. apply_migration(...) - make changes on branch
   3. Test via branch URL
   4. merge_branch(branch_id: "...") - apply to production
   ```

**Deploying Custom MCP Servers on Supabase:**

Supabase supports deploying your own MCP servers as Edge Functions using `mcp-lite`:

```typescript
// supabase/functions/my-mcp/index.ts
import { createMcpLiteServer } from 'npm:mcp-lite@0.0.4'

Deno.serve(async (req) => {
  const response = await createMcpLiteServer({
    tools: [{
      name: 'my_tool',
      description: 'Custom tool',
      parameters: { type: 'object', properties: {} },
      handler: async (params) => ({ result: 'Hello!' })
    }]
  })(req)
  return response
})
```

Deploy with: `supabase functions deploy my-mcp`

**Self-Hosting Requirements:**

If self-hosting Supabase and want MCP:

1. Supabase version with MCP support
2. OAuth server configuration (API Gateway)
3. Environment: `MCP_ENABLED=true`, `MCP_CLIENT_ID`, `MCP_CLIENT_SECRET`

See: [Supabase Self-Hosting MCP Docs](https://supabase.com/docs/guides/self-hosting/enable-mcp)

**Troubleshooting:**

| Issue | Cause | Solution |
|-------|-------|----------|
| OAuth redirect fails | Browser popup blocked | Allow popups for supabase.com |
| "Project not found" | Wrong project_ref | Get ref from Supabase dashboard URL |
| Read-only violations | Missing ?read_only param | Add `?read_only=true` for safe exploration |
| Tool not available | Feature group excluded | Add feature to `?features=` parameter |
| Token cost too high | All features loaded | Use `?features=database,docs` minimum |
| Edge function deploy fails | Invalid Deno syntax | Check `import "jsr:@supabase/functions-js/edge-runtime.d.ts"` |
| Branch operations fail | Branching not enabled | Enable in Supabase dashboard |

**Resources:**

- [Supabase MCP Documentation](https://supabase.com/docs/guides/getting-started/mcp)
- [GitHub Repository](https://github.com/supabase-community/supabase-mcp)
- [MCP Authentication Guide](https://supabase.com/docs/guides/auth/oauth-server/mcp-authentication)
- [Building MCP with mcp-lite](https://supabase.com/docs/guides/functions/examples/mcp-server-mcp-lite)
- [Self-Hosting MCP](https://supabase.com/docs/guides/self-hosting/enable-mcp)
- [Deploy Custom MCP Servers](https://supabase.com/docs/guides/getting-started/byo-mcp)

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
