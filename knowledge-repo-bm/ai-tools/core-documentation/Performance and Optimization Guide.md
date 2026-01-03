---
title: Performance and Optimization Guide
type: note
permalink: ai-tools/core-documentation/performance-and-optimization-guide
tags:
- performance
- optimization
- efficiency
- speed
- caching
---

# Performance and Optimization Guide

**Purpose**: Maximize efficiency, reduce context usage, and optimize tool performance for the I Do Blueprint AI development environment.

**Related Documentation**:
- [[ai-tools/core-documentation/architecture-overview|Architecture Overview]] - System design
- [[ai-tools/core-documentation/decision-matrix|Tool Decision Matrix]] - When to use tools
- [[ai-tools/core-documentation/best-practices|Best Practices Guide]] - Development guidelines
- [[ai-tools/_index|AI Tools Master Index]] - Complete catalog

---

## Table of Contents

1. [Context Window Optimization](#context-window-optimization)
2. [Tool-Specific Performance](#tool-specific-performance)
3. [Caching Strategies](#caching-strategies)
4. [Network and API Optimization](#network-and-api-optimization)
5. [Database Performance](#database-performance)
6. [Build and Compilation Speed](#build-and-compilation-speed)
7. [Memory Management](#memory-management)
8. [Monitoring and Profiling](#monitoring-and-profiling)

---

## Context Window Optimization

### Understanding the Problem

AI agents like Claude have finite context windows (200k tokens for Sonnet 4). Every tool call, file read, and response consumes this budget. When it fills, the agent loses important context.

**Token Budget Breakdown** (typical conversation):
```
System Prompt:           ~15,000 tokens
Tool Definitions:        ~8,000 tokens  
Conversation History:    ~50,000 tokens
Tool Responses:          ~80,000 tokens (variable)
Working Memory:          ~30,000 tokens
Buffer:                  ~17,000 tokens
---
Total Available:         200,000 tokens
```

### Optimization Strategies

#### 1. Selective Tool Calling

**❌ Inefficient Pattern**:
```javascript
// Agent calls tools unnecessarily
const allFiles = await narsil.listAllFiles();  // 10k tokens
const allIssues = await beads.list();          // 15k tokens
const fullHistory = await memory.recentActivity(); // 20k tokens
// Total: 45k tokens just to start!
```

**✅ Optimized Pattern**:
```javascript
// Only call what's needed
const readyTasks = await beads.ready({ limit: 5 });  // 2k tokens
// Total: 2k tokens - 95% reduction!
```

**Best Practices**:
- Use `--limit` or `--max-results` parameters
- Call tools only when information is actually needed
- Prefer targeted queries over broad searches
- Use `--brief` flags when available

#### 2. Beads Context Efficiency

**Reduce Task Data**:
```bash
# ❌ Returns full JSON with descriptions, notes, history
bd list --json

# ✅ Returns minimal info (id, title, status, priority)
bd ready --json --brief

# ✅ Even better - only what's needed
bd ready --limit 3 --fields id,title,priority --json
```

**Compaction for Long-Running Projects**:
```bash
# Summarize old closed tasks (>30 days)
bd compact --age 30d --dry-run  # Preview first
bd compact --age 30d            # Actually compact

# Before: 1000 detailed tasks = 150k tokens
# After:  1000 summarized tasks = 30k tokens  
# Savings: 120k tokens (80% reduction!)
```

**Strategic Notes Usage**:
```bash
# Instead of long descriptions, use concise notes
bd update bd-abc --notes "Blocked: waiting for API key from DevOps"
# vs verbose descriptions that eat tokens
```

#### 3. Basic Memory Pagination

**❌ Inefficient**:
```javascript
// Loads entire knowledge base
const allNotes = await memory.searchNotes({ query: "authentication" });
// Could return 50+ notes = 100k+ tokens
```

**✅ Optimized**:
```javascript
// Paginated retrieval
const notes = await memory.searchNotes({ 
  query: "authentication",
  page: 1,
  page_size: 5  // Only 5 results
});
// Returns ~8k tokens instead of 100k+
```

**Selective Depth**:
```javascript
// ❌ Deep graph traversal
await memory.buildContext({
  url: "memory://projects/i-do-blueprint",
  depth: 5,  // Loads 5 levels of related notes!
  max_related: 50
});

// ✅ Shallow, targeted
await memory.buildContext({
  url: "memory://projects/i-do-blueprint/rsvp-feature",
  depth: 1,  // Only immediate relations
  max_related: 5
});
```

#### 4. Narsil Smart Queries

**Exclude Unnecessary Directories**:
```json
// .mcp.json configuration
{
  "mcpServers": {
    "narsil-mcp": {
      "command": "narsil-mcp",
      "env": {
        "PROJECT_PATH": "/path/to/project",
        "NARSIL_EXCLUDE": "node_modules,.build,DerivedData,Pods,.git"
      }
    }
  }
}
```

**Targeted Searches**:
```bash
# ❌ Broad search returns 100+ results
narsil search "function" 

# ✅ Narrow to specific directory
narsil search "function" --path "src/auth"

# ✅ Even better - use specific tool
narsil find-functions --containing "authenticate"
```

**File Content Streaming**:
```javascript
// For large files, request specific line ranges
const content = await narsil.getFileContent({
  path: "App.swift",
  start_line: 100,
  end_line: 150  // Only 50 lines, not entire 5000-line file
});
```

### 5. Web Search Efficiency

**Minimize Redundant Searches**:
```javascript
// ❌ Three similar searches
await web_search("Swift URLSession tutorial");
await web_search("Swift URLSession examples");
await web_search("URLSession Swift guide");
// 3 searches = 3x API calls, 3x context usage

// ✅ One comprehensive search
await web_search("Swift URLSession tutorial examples");
// Then use web_fetch for deep dive on best result
```

**Fetch Only What's Needed**:
```javascript
// After web_search returns URLs
const topResult = searchResults[0].url;
const content = await web_fetch({ 
  url: topResult,
  text_content_token_limit: 4000  // Truncate long articles
});
```

---

## Tool-Specific Performance

### Narsil MCP

**Indexing Speed**:
```bash
# First-time indexing of large codebase
# Swift project ~50k LOC: ~3-5 seconds
# JavaScript monorepo ~500k LOC: ~30-60 seconds

# Subsequent queries use cached index - instant
```

**Optimization Techniques**:

1. **Use Incremental Parsing**:
   - Narsil watches files and re-parses only changed ones
   - No need to manually trigger re-indexing

2. **Filter Language Scope**:
   ```bash
   # Only parse Swift files (skip JS, Python, etc.)
   NARSIL_LANGUAGES="swift" narsil-mcp
   ```

3. **Limit Neural Embeddings**:
   ```bash
   # Use TF-IDF (fast) for most searches
   narsil search "auth" --mode tfidf
   
   # Only use neural for complex semantic queries
   narsil neural-search "error handling with exponential backoff"
   ```

### GREB MCP

**Search Response Time**: Sub-5 seconds for most codebases

**Optimization**:
```bash
# Set reasonable result limits
export GREB_MAX_RESULTS=10  # Default is often 20+

# Use file pattern filters
greb-search "authentication" --file-patterns "*.swift,*.ts"
```

### Supabase

**Migration Performance**:
```bash
# ❌ Slow - multiple sequential migrations
sb db push
sb db push
sb db push

# ✅ Fast - batch migrations
# Combine related schema changes into single migration file
# migrations/20250130_add_guest_features.sql
```

**Type Generation Speed**:
```bash
# Cache generated types - don't regenerate on every query
sb-gen-types  # Only run after schema changes

# Use direnv to detect schema changes
# .envrc
export SCHEMA_HASH=$(shasum supabase/migrations/*.sql | shasum)
if [[ "$SCHEMA_HASH" != "$LAST_SCHEMA_HASH" ]]; then
  sb-gen-types
  export LAST_SCHEMA_HASH="$SCHEMA_HASH"
fi
```

**Edge Function Cold Starts**:
- First invocation: ~2-3 seconds
- Warm invocations: <500ms
- Keep functions warm with health checks if needed

### Beads

**Query Performance**:
```bash
# SQLite local cache makes queries instant (<50ms)
bd ready --json    # ~20ms
bd list --json     # ~100ms for 500 tasks

# JSONL sync happens in background daemon - no user-facing slowdown
```

**Scaling Considerations**:

| Issue Count | Performance | Recommendation |
|-------------|-------------|----------------|
| 1-1000 | Excellent (<100ms) | No optimization needed |
| 1000-5000 | Good (<500ms) | Consider bd compact quarterly |
| 5000-10000 | Fair (~1-2s) | Compact monthly, use --brief |
| 10000+ | Slow (>2s) | Archive old issues, split projects |

### Basic Memory

**Search Performance**:
- Full-text search: <200ms for 10k notes
- Semantic graph traversal: <500ms for depth=2
- Build context: 1-3s depending on depth/breadth

**Optimization**:
```javascript
// ❌ Slow - loads entire graph
await memory.buildContext({
  url: "memory://",  // Root node!
  depth: 3,
  max_related: 100
});

// ✅ Fast - targeted subgraph
await memory.buildContext({
  url: "memory://projects/i-do-blueprint/features/rsvp",
  depth: 1,
  max_related: 5
});
```

---

## Caching Strategies

### File System Caching

**Narsil**: Automatic parse cache in `.narsil/cache/`
- Keep this directory - speeds up subsequent analyses
- Safe to delete if corrupted (will rebuild)

**Basic Memory**: SQLite index in project/.basic-memory/
- Indexes markdown for fast search
- Rebuilds automatically on file changes

**Beads**: SQLite cache in `.beads/beads.db`
- Syncs with `.beads/issues.jsonl` via background daemon
- Never manually edit - use `bd` commands

### API Response Caching

**GREB MCP**:
```bash
# Cache search results (default: 5 minutes)
export GREB_CACHE_TTL=300
```

**Web Search**:
- web_fetch includes ETag support
- Repeated fetches of same URL use cached version if not modified
- Claude's web_fetch has built-in rate limiting and caching

### Build Caching

**Swift/Xcode**:
```bash
# Use derived data caching
xcodebuild -derivedDataPath .build/derived

# Enable build parallelization
xcodebuild -parallelizeTargets -jobs 8
```

**Node.js**:
```bash
# Use npm ci for reproducible, cached installs
npm ci  # Faster than npm install
```

---

## Network and API Optimization

### MCP Server Connection Pooling

**Problem**: Starting/stopping MCP servers on every request is slow.

**Solution**: Claude Desktop/Code maintains persistent connections.

```json
// .mcp.json
{
  "mcpServers": {
    "narsil-mcp": {
      "command": "narsil-mcp",
      "env": {
        "PROJECT_PATH": "/path/to/project",
        "NARSIL_KEEP_ALIVE": "true"  // Maintains connection
      }
    }
  }
}
```

### API Rate Limiting

**GREB**: 100 requests/hour (free tier)
- Use sparingly, cache results
- Consider paid tier for heavy usage

**OpenRouter** (for ADR Analysis):
- Rate limits vary by model
- Use request batching when possible

**Anthropic API** (for MCP Shield):
- Standard Claude rate limits apply
- Batch security scans weekly, not per-commit

### Batch Operations

**Example: Bulk Task Creation**:
```bash
# ❌ Slow - one-by-one
for task in "${tasks[@]}"; do
  bd create "$task"
done
# 10 tasks = 10 git commits + syncs

# ✅ Fast - batch create, single sync
bd create "Task 1" "Task 2" "Task 3" --batch
bd sync  # One sync for all
```

---

## Database Performance

### SQLite Optimization (Beads, Basic Memory)

**Configuration**:
```sql
-- Already applied in Beads/Memory, but for reference:
PRAGMA journal_mode = WAL;        -- Write-ahead logging
PRAGMA synchronous = NORMAL;      -- Balance safety/speed
PRAGMA cache_size = -64000;       -- 64MB cache
PRAGMA temp_store = MEMORY;       -- In-memory temp tables
```

**Vacuum Periodically**:
```bash
# Beads
bd admin --action compact-db  # Reclaims space

# Basic Memory
# Happens automatically, but can force:
sqlite3 .basic-memory/index.db "VACUUM;"
```

### Supabase Performance

**Indexes**:
```sql
-- Always index foreign keys
CREATE INDEX idx_guests_event_id ON guests(event_id);

-- Index frequently queried columns
CREATE INDEX idx_guests_rsvp_status ON guests(rsvp_status);

-- Use partial indexes for common filters
CREATE INDEX idx_active_guests ON guests(id) 
WHERE deleted_at IS NULL;
```

**Query Optimization**:
```sql
-- ❌ Slow - full table scan
SELECT * FROM guests WHERE email LIKE '%@gmail.com';

-- ✅ Fast - indexed column first
SELECT * FROM guests WHERE rsvp_status = 'confirmed' 
  AND email LIKE '%@gmail.com';
```

---

## Build and Compilation Speed

### Swift/Xcode

**Optimization Techniques**:

1. **Modularize Code**:
   - Break monolithic files into smaller modules
   - Faster incremental compilation

2. **Use Build Configurations**:
   ```swift
   #if DEBUG
   // Debug-only code
   #endif
   ```

3. **Enable Whole Module Optimization (Release only)**:
   - Build Settings → Compilation Mode → Whole Module
   - Slower builds, faster runtime

### Parallel Builds

```bash
# Swift Package Manager
swift build -j 8  # Use 8 cores

# Xcodebuild
xcodebuild -jobs 8 -parallelizeTargets
```

---

## Memory Management

### AI Agent Memory Profiling

**Monitor Context Usage**:
```
Claude provides budget information in responses:
Token usage: 45000/200000; 155000 remaining
```

**When to Reset Context**:
- Usage > 150k tokens: Consider starting new conversation
- Lots of redundant tool calls: Agent is confused, reset
- Agent forgets earlier instructions: Context overflow

### System Memory

**Narsil**:
- Typical usage: 50-200MB RAM
- With neural embeddings: 500MB-1GB
- With frontend visualization: Add 100-200MB

**Beads**:
- SQLite cache: 1-10MB (small projects)
- Background daemon: 20-50MB RAM

**Basic Memory**:
- SQLite index: 10-100MB depending on note count
- In-memory search cache: 50-200MB

---

## Monitoring and Profiling

### Tool Performance Monitoring

**Narsil Diagnostics**:
```bash
# Check index size and status
narsil-mcp --repos /path/to/project --stats

# Output:
# Indexed files: 1,247
# Total LOC: 89,432
# Index size: 12.3 MB
# Last indexed: 2025-12-30 14:30:22
```

**Beads Health Check**:
```bash
bd doctor

# Output includes:
# - SQLite integrity
# - JSONL sync status
# - Daemon health
# - Circular dependency detection
```

**Basic Memory Stats**:
```bash
# Count notes by folder
fd . /path/to/vault --type f --extension md | wc -l

# Index size
du -sh .basic-memory/
```

### Profiling Slow Operations

**Measure Tool Call Time**:
```bash
# Shell timing
time bd ready --json

# Example output:
# real    0m0.089s   <-- Actual time
# user    0m0.034s
# sys     0m0.023s
```

**Network Latency**:
```bash
# Test Supabase connection
time sb status

# Test API calls
time curl -X POST https://api.grebmcp.com/search \
  -H "Authorization: Bearer $GREB_API_KEY" \
  -d '{"query": "test"}'
```

### Optimization Checklist

**Before Starting Work**:
- [ ] Check disk space (Xcode needs 20GB+)
- [ ] Clear derived data if >10GB: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- [ ] Verify network: `ping google.com`
- [ ] Test MCP servers: Check Claude Desktop MCP status

**During Development**:
- [ ] Monitor context usage in responses
- [ ] Use --brief flags for large queries
- [ ] Batch bd operations before sync
- [ ] Cache expensive computations in Basic Memory

**Weekly Maintenance**:
- [ ] Run `bd compact` if >1000 closed tasks
- [ ] Vacuum databases: `bd admin --action compact-db`
- [ ] Clear browser/editor caches
- [ ] Update dependencies: `brew upgrade`, `npm update -g`

**Monthly Optimization**:
- [ ] Review Basic Memory note count - archive old content
- [ ] Clean up Git history: `git gc --aggressive`
- [ ] Update MCP servers: `brew upgrade narsil-mcp`, `uvx --upgrade basic-memory`
- [ ] Performance baseline: Time key operations, track trends

---

## Performance Benchmarks

**Target Response Times** (I Do Blueprint Project):

| Operation | Target | Acceptable | Slow |
|-----------|--------|------------|------|
| bd ready | <100ms | <500ms | >1s |
| Narsil search | <500ms | <2s | >5s |
| GREB search | <3s | <5s | >10s |
| Basic Memory search | <200ms | <1s | >3s |
| Web search | <3s | <8s | >15s |
| Supabase query | <200ms | <1s | >3s |

**If you see slow times**:
1. Check network connectivity
2. Review exclude patterns (Narsil, GREB)
3. Reduce query scope (use limits, filters)
4. Compact databases (Beads, Basic Memory)
5. Restart MCP servers (connection issues)

---

## Related Documentation

- **Architecture**: [[ai-tools/core-documentation/architecture-overview|Architecture Overview]]
- **Tool Selection**: [[ai-tools/core-documentation/decision-matrix|Tool Decision Matrix]]
- **Setup**: [[ai-tools/getting-started/first-time-setup|First-Time Setup]]
- **Best Practices**: [[ai-tools/core-documentation/best-practices|Best Practices Guide]]
- **Troubleshooting**: [[ai-tools/getting-started/troubleshooting|Troubleshooting Guide]]

---

**Last Updated**: 2025-12-30  
**Version**: 1.0  
**Maintainer**: Jessica Clark