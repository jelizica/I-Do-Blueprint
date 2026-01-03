# Beads Viewer (bv) Integration Skill

*Load with: base.md*

Use `bv` to get AI-optimized insights from the beads issue tracker.

---

## CRITICAL RULE

**NEVER run `bv` without flags** - it launches an interactive TUI that blocks the session.
**ALWAYS use `--robot-*` flags** for structured JSON output.

---

## Primary Entry Point

When you need to understand the project state or find work to do:

```bash
bv --robot-triage
```

Returns comprehensive project assessment:
- `quick_ref`: Issue counts, top 3 actionable items
- `recommendations`: Ranked issues with impact scores
- `quick_wins`: Low-effort, high-impact tasks
- `blockers_to_clear`: Items preventing downstream work
- `project_health`: Status distributions, graph metrics
- `commands`: Shell commands for next steps

**Output to user**: Parse the JSON and present insights in natural language.

---

## Common Robot Commands

### Find Parallel Work Streams
```bash
bv --robot-plan
```
Returns execution tracks with dependencies - ideal for planning parallel work.

### Deep Graph Analysis
```bash
bv --robot-insights
```
Returns 9 graph metrics (PageRank, betweenness, HITS, critical path, cycles, etc.)
**Note**: Has 500ms timeout for large graphs - check `status` field per metric.

### Dependency Visualization
```bash
bv --robot-graph --format json
# Or: --format dot, --format mermaid
```
Export dependency graph for documentation or analysis.

### Change Detection
```bash
bv --robot-diff --since HEAD~5
```
Shows beads created/updated/closed since a git reference.

### Anomaly Detection
```bash
bv --robot-alerts
```
Detects stale issues, blocking cascades, priority mismatches.

---

## Filtering & Scoping

```bash
# Domain-specific analysis
bv --robot-plan --label backend
bv --robot-plan --label frontend

# Ready-to-work items only (no blockers)
bv --recipe actionable --robot-triage

# Historical analysis
bv --robot-insights --as-of HEAD~30

# Group by work streams
bv --robot-triage --robot-triage-by-track
```

---

## Integration with bd Commands

**Workflow Pattern**:
1. `bv --robot-triage` → Get oriented, see top recommendations
2. `bd show <id>` → Inspect specific issue details
3. `bd update <id> --status=in_progress` → Claim work
4. Do the work
5. `bd close <id>` → Mark complete
6. `bv --robot-plan` → Identify next parallel work streams

---

## Output Validation

All robot JSON includes:
- `data_hash`: Fingerprint for cache consistency
- `status`: Per-metric state (computed|approx|timeout|skipped)
- Always check `status` on individual metrics before trusting them

---

## Performance Notes

- `--robot-plan` is faster than `--robot-insights` (Phase 1 vs Phase 2 metrics)
- Results are cached by data_hash - repeated calls are instant
- For graphs >500 nodes, some metrics may timeout or approximate

---

## Anti-Patterns

- ❌ Running bare `bv` (blocks terminal)
- ❌ Parsing `.beads/beads.jsonl` directly (use robot flags)
- ❌ Hallucinating graph traversals (bv pre-computes them)
- ❌ Ignoring `status` field on metrics (may be approximate/timed out)
- ❌ Using bv when you just need to show/update one issue (use `bd` instead)

---

## When to Use What

| Need | Command |
|------|---------|
| "What should I work on?" | `bv --robot-triage` |
| "What's blocking progress?" | `bv --robot-triage` → check `blockers_to_clear` |
| "Show me quick wins" | `bv --robot-triage` → check `quick_wins` |
| "What can run in parallel?" | `bv --robot-plan` |
| "Dependency graph for docs" | `bv --robot-graph --format mermaid` |
| "Is this issue blocking others?" | `bv --robot-insights` → check betweenness score |
| "Critical path to completion" | `bv --robot-insights` → check `critical_path` |
| "What changed recently?" | `bv --robot-diff --since HEAD~10` |
| "Backend-only analysis" | `bv --robot-plan --label backend` |

---

## Example: Using bv at Session Start

```bash
# Get project overview
bv --robot-triage

# Parse the JSON and tell the user:
# - Project health summary
# - Top 3 actionable items
# - Any critical blockers
# - Quick wins available

# Then find specific work
bd ready  # Show beads ready to work on
```

---

## Example: Planning Parallel Work

```bash
# Get execution tracks
bv --robot-plan

# Parse the JSON to show:
# - Independent work streams that can run in parallel
# - Dependencies between streams
# - Suggested execution order
```

---

## Example: Analyzing Blockers

```bash
# Get insights on blocking relationships
bv --robot-insights

# Parse the JSON to identify:
# - High betweenness issues (blocking multiple paths)
# - Critical path issues (zero slack)
# - Cycle detection (dependency loops to fix)
```
