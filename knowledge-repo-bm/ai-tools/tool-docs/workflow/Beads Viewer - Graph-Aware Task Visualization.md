---
title: Beads Viewer - Graph-Aware Task Visualization
type: note
permalink: ai-tools/workflow/beads-viewer-graph-aware-task-visualization
tags:
- beads-viewer
- visualization
- tui
- graph-analysis
- ai-agents
- task-management
- beads
---

# Beads Viewer - Graph-Aware Task Visualization

**Repository**: https://github.com/Dicklesworthstone/beads_viewer  
**Type**: Terminal User Interface (TUI) + AI Robot Protocol  
**Purpose**: Graph-aware visualization and analysis for Beads projects  
**Command**: `bv`  
**Requires**: [Beads](./beads-git-backed-task-tracking.md) (the underlying task tracker)

---

## Overview

Beads Viewer is a powerful **Terminal User Interface (TUI)** and **AI-ready analysis tool** for Beads projects. While Beads provides the data layer for task tracking, Beads Viewer adds sophisticated graph analysis, visualization, and AI-powered recommendations to help you understand your project's task dependencies and make informed decisions about what to work on next.

### Key Capabilities

1. **Interactive TUI** - Rich terminal interface with multiple views
2. **Graph Metrics** - PageRank, Betweenness, HITS, Critical Path analysis
3. **AI Robot Protocol** - JSON output for AI agent consumption
4. **Time-Travel Mode** - Historical analysis of task evolution
5. **Export Capabilities** - Markdown, HTML, static site generation

---

## Installation

### Quick Install (Recommended)

```bash
curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/beads_viewer/main/install.sh?$(date +%s)" | bash
```

The `$(date +%s)` timestamp prevents caching issues.

### Manual Installation

```bash
git clone https://github.com/Dicklesworthstone/beads_viewer.git
cd beads_viewer
cargo build --release
cp target/release/bv ~/.local/bin/  # or /usr/local/bin
```

### Verify Installation

```bash
bv --version
```

---

## Core Concepts

### 1. Graph Metrics

Beads Viewer computes sophisticated graph metrics to help prioritize work:

#### PageRank (30% weight)
- **What**: Measures foundational importance in dependency graph
- **Use**: Identifies tasks that many others depend on
- **High Score**: Critical infrastructure work that unblocks many tasks

#### Betweenness Centrality (30% weight)
- **What**: Measures how often a task lies on paths between other tasks
- **Use**: Identifies bottleneck tasks
- **High Score**: Tasks that, if completed, open up multiple parallel work streams

#### HITS (Hub/Authority)
- **Hub Score**: Tasks that depend on many others (integration points)
- **Authority Score**: Tasks that many others depend on (foundational work)
- **Use**: Understand task roles in the dependency network

#### Critical Path
- **What**: Longest dependency chain from start to finish
- **Use**: Identifies the minimum time to complete all work
- **High Score**: Tasks on the critical path directly impact project timeline

#### Eigenvector Centrality
- **What**: Measures influence based on connections to other influential tasks
- **Use**: Identifies tasks in high-value clusters
- **High Score**: Tasks surrounded by other important work

#### Cycle Detection
- **What**: Identifies circular dependencies
- **Use**: Prevents deadlocks in task graph
- **Alert**: Circular dependencies must be resolved before work can proceed

### 2. Robot Protocol

Beads Viewer provides **AI-ready JSON output** via `--robot-*` flags:
- Structured data for programmatic consumption
- No ANSI colors or formatting
- Deterministic output for agent parsing
- Comprehensive analysis in single commands

### 3. Time-Travel Mode

Analyze historical task states:
- View task graph at any point in git history
- Track how priorities and dependencies evolved
- Identify patterns in task completion
- Audit decision-making over time

---

## Interactive TUI

### Launching the TUI

```bash
# Launch interactive interface
bv

# Launch with specific project
bv --project /path/to/project
```

### TUI Views

#### 1. List View
- Tabular display of all tasks
- Sort by priority, status, or metrics
- Filter by assignee, type, or labels
- Quick navigation with keyboard shortcuts

#### 2. Kanban View
- Visual board with status columns
- Drag-and-drop task movement (conceptual)
- Swimlanes by priority or assignee
- WIP limits and flow metrics

#### 3. Graph View
- Visual dependency graph
- Node size = importance (PageRank)
- Edge thickness = dependency strength
- Color coding by status/priority

#### 4. Insights View
- Real-time graph metrics
- Bottleneck identification
- Critical path visualization
- Health score dashboard

#### 5. History View
- Git commit timeline
- Task state changes over time
- Velocity and throughput metrics
- Trend analysis

### Keyboard Shortcuts

```
j/k       - Navigate up/down
h/l       - Navigate left/right
Enter     - Select/expand item
Space     - Toggle selection
/         - Search
f         - Filter
s         - Sort
v         - Change view
q         - Quit
?         - Help
```

---

## Robot Protocol (AI Agents)

### The Mega-Command: `--robot-triage`

**This is the most important command for AI agents.**

```bash
bv --robot-triage
```

**Returns comprehensive JSON with**:
- All graph metrics (PageRank, Betweenness, HITS, etc.)
- Prioritized task recommendations
- Bottleneck identification
- Critical path analysis
- Health score and alerts
- Suggested next actions

**Use this as your primary decision-making tool.**

### Individual Robot Commands

#### Get Next Task Recommendation

```bash
bv --robot-next
```

Returns single top-priority task with reasoning:
```json
{
  "task_id": "bd-a1b2c3d4",
  "title": "Implement authentication",
  "priority": 1,
  "score": 0.87,
  "reasoning": [
    "Highest PageRank (0.45) - foundational work",
    "On critical path - blocks 5 other tasks",
    "No dependencies - ready to start immediately"
  ],
  "estimated_impact": "Unblocks 5 tasks worth 3 days of work"
}
```

#### Get Full Graph Insights

```bash
bv --robot-insights
```

Returns comprehensive graph analysis:
```json
{
  "metrics": {
    "total_tasks": 42,
    "open_tasks": 15,
    "blocked_tasks": 3,
    "ready_tasks": 7,
    "avg_dependencies": 2.3
  },
  "graph_metrics": {
    "pagerank": {...},
    "betweenness": {...},
    "critical_path": [...]
  },
  "bottlenecks": [...],
  "recommendations": [...]
}
```

#### Get Execution Plan

```bash
bv --robot-plan
```

Returns optimized execution plan with parallel tracks:
```json
{
  "plan": {
    "total_duration_estimate": "12 days",
    "parallel_tracks": 3,
    "phases": [
      {
        "phase": 1,
        "tasks": ["bd-a1b2", "bd-c3d4", "bd-e5f6"],
        "can_run_parallel": true,
        "estimated_duration": "3 days"
      },
      {
        "phase": 2,
        "tasks": ["bd-g7h8"],
        "can_run_parallel": false,
        "estimated_duration": "2 days",
        "blocked_by": ["bd-a1b2", "bd-c3d4"]
      }
    ]
  }
}
```

#### Get Priority Recommendations

```bash
bv --robot-priority
```

Returns priority adjustment suggestions:
```json
{
  "recommendations": [
    {
      "task_id": "bd-a1b2",
      "current_priority": 2,
      "suggested_priority": 1,
      "reason": "On critical path, high PageRank",
      "impact": "Would unblock 4 P1 tasks"
    }
  ]
}
```

#### Get Health Alerts

```bash
bv --robot-alerts
```

Returns project health warnings:
```json
{
  "alerts": [
    {
      "severity": "high",
      "type": "circular_dependency",
      "tasks": ["bd-a1b2", "bd-c3d4", "bd-e5f6"],
      "message": "Circular dependency detected",
      "action": "Remove dependency between bd-e5f6 and bd-a1b2"
    },
    {
      "severity": "medium",
      "type": "bottleneck",
      "task": "bd-g7h8",
      "message": "Task blocks 8 others",
      "action": "Consider breaking into smaller tasks"
    }
  ]
}
```

#### Get Label Health Metrics

```bash
bv --robot-label-health
```

Returns per-label health analysis:
```json
{
  "labels": {
    "backend": {
      "total_tasks": 15,
      "completed": 8,
      "in_progress": 3,
      "blocked": 2,
      "health_score": 0.73,
      "velocity": "2.1 tasks/week"
    },
    "frontend": {
      "total_tasks": 12,
      "completed": 10,
      "in_progress": 2,
      "blocked": 0,
      "health_score": 0.91,
      "velocity": "3.2 tasks/week"
    }
  }
}
```

#### Get Forecast

```bash
bv --robot-forecast
```

Returns completion time estimates:
```json
{
  "forecast": {
    "completion_date": "2025-03-15",
    "confidence": 0.75,
    "assumptions": [
      "Current velocity: 2.5 tasks/week",
      "No new tasks added",
      "No scope changes"
    ],
    "risks": [
      "3 tasks on critical path with no assignee",
      "Velocity declining over last 2 weeks"
    ]
  }
}
```

---

## Advanced Features

### Time-Travel Analysis

```bash
# View task state at specific commit
bv --time-travel abc123

# View task state at date
bv --time-travel "2025-01-01"

# Compare two points in time
bv --time-travel abc123 --compare def456
```

### Export Capabilities

#### Markdown Report

```bash
# Generate comprehensive markdown report
bv --export-md > project-status.md

# Include specific sections
bv --export-md --sections=metrics,bottlenecks,recommendations
```

#### HTML Dashboard

```bash
# Generate static HTML dashboard
bv --export-html --output=dashboard.html

# Generate full static site
bv --export-pages --output-dir=./site
```

#### JSON Export

```bash
# Export all data as JSON
bv --export-json > project-data.json

# Export specific metrics
bv --export-json --metrics=pagerank,betweenness
```

---

## Workflow Patterns

### 1. Morning Standup

```bash
# Get comprehensive triage
bv --robot-triage | jq '.recommendations[0:3]'

# Check for alerts
bv --robot-alerts

# Get next task
bv --robot-next
```

### 2. Sprint Planning

```bash
# Get execution plan
bv --robot-plan

# Check label health
bv --robot-label-health

# Get forecast
bv --robot-forecast

# Export plan to markdown
bv --export-md --sections=plan > sprint-plan.md
```

### 3. Bottleneck Analysis

```bash
# Get full insights
bv --robot-insights | jq '.bottlenecks'

# Check critical path
bv --robot-insights | jq '.graph_metrics.critical_path'

# Get priority recommendations
bv --robot-priority
```

### 4. Health Monitoring

```bash
# Daily health check
bv --robot-alerts

# Weekly velocity check
bv --robot-label-health

# Monthly forecast update
bv --robot-forecast
```

---

## Integration with Beads

Beads Viewer is designed to work seamlessly with Beads:

```bash
# Beads: Create and manage tasks
bd create "Implement feature X" --priority=1
bd dep add bd-child bd-parent
bd update bd-a1b2 --status=in_progress

# Beads Viewer: Analyze and decide
bv --robot-triage  # What should I work on?
bv --robot-next    # Give me the top task
bv --robot-alerts  # Any problems?

# Beads: Execute decision
bd update bd-recommended --status=in_progress
# [Do the work...]
bd close bd-recommended
bd sync
```

**Division of Responsibilities**:
- **Beads (`bd`)**: CRUD operations, data management, git sync
- **Beads Viewer (`bv`)**: Analysis, visualization, recommendations

---

## AI Agent Integration

### Why Beads Viewer is Perfect for AI Agents

1. **Structured JSON Output** - All robot commands return parseable JSON
2. **Comprehensive Analysis** - Single command (`--robot-triage`) provides everything
3. **Deterministic** - Same input always produces same output
4. **No Authentication** - Works offline, no API keys needed
5. **Graph-Aware** - Understands task dependencies and priorities
6. **Actionable Recommendations** - Tells you exactly what to do next

### Agent Workflow Example

```python
import subprocess
import json

# Get comprehensive triage
result = subprocess.run(
    ['bv', '--robot-triage'],
    capture_output=True,
    text=True
)
triage = json.loads(result.stdout)

# Get top recommendation
next_task = triage['recommendations'][0]
task_id = next_task['task_id']

# Claim task with Beads
subprocess.run(['bd', 'update', task_id, '--status=in_progress'])

# [Agent does the work...]

# Complete task
subprocess.run(['bd', 'close', task_id])
subprocess.run(['bd', 'sync'])
```

---

## Configuration

### `.beads_viewer/config.toml`

```toml
[display]
# Color scheme
theme = "dark"  # or "light"

# Default view
default_view = "list"  # or "kanban", "graph", "insights"

[metrics]
# Metric weights for scoring
pagerank_weight = 0.30
betweenness_weight = 0.30
hits_weight = 0.20
critical_path_weight = 0.20

[robot]
# Number of recommendations to return
max_recommendations = 5

# Minimum score threshold
min_score = 0.5

[export]
# Default export format
format = "markdown"

# Include sections
sections = ["metrics", "bottlenecks", "recommendations", "forecast"]
```

---

## Comparison with Other Tools

| Feature | Beads Viewer | GitHub Projects | Jira Dashboards | Linear Insights |
|---------|--------------|-----------------|-----------------|-----------------|
| **Graph Metrics** | ✅ Advanced | ❌ No | ⚠️ Basic | ⚠️ Basic |
| **AI Robot Protocol** | ✅ Built-in | ❌ No | ❌ No | ❌ No |
| **Offline Work** | ✅ Full | ❌ No | ❌ No | ❌ No |
| **Time-Travel** | ✅ Git-based | ❌ No | ⚠️ Limited | ⚠️ Limited |
| **Critical Path** | ✅ Automatic | ❌ No | ⚠️ Manual | ⚠️ Manual |
| **Export** | ✅ MD/HTML/JSON | ⚠️ CSV | ⚠️ CSV | ⚠️ CSV |
| **Cost** | ✅ Free | ✅ Free | 💰 Paid | 💰 Paid |

---

## Troubleshooting

### Issue: "bv: command not found"

```bash
# Check installation
which bv

# If not found, add to PATH
export PATH="$HOME/.local/bin:$PATH"

# Or reinstall
curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/beads_viewer/main/install.sh?$(date +%s)" | bash
```

### Issue: "No .beads directory found"

```bash
# Beads Viewer requires Beads to be initialized
bd init

# Then run Beads Viewer
bv
```

### Issue: TUI not rendering correctly

```bash
# Check terminal compatibility
echo $TERM

# Try different terminal emulator
# Recommended: iTerm2 (macOS), Windows Terminal, Alacritty

# Or use robot protocol instead
bv --robot-triage
```

### Issue: Slow performance on large projects

```bash
# Use robot protocol for faster analysis
bv --robot-next  # Much faster than TUI

# Or limit analysis scope
bv --max-tasks=100
```

---

## Best Practices

### 1. Use Robot Protocol for Automation

```bash
# ✅ Good: Fast, parseable, automatable
bv --robot-triage | jq '.recommendations[0]'

# ❌ Avoid: TUI in scripts (interactive only)
bv  # Don't use in automated workflows
```

### 2. Regular Health Checks

```bash
# Daily
bv --robot-alerts

# Weekly
bv --robot-label-health
bv --robot-forecast

# Monthly
bv --export-md > monthly-report.md
```

### 3. Combine with Beads Commands

```bash
# Get recommendation from Beads Viewer
TASK=$(bv --robot-next | jq -r '.task_id')

# Execute with Beads
bd update $TASK --status=in_progress
# [Do work...]
bd close $TASK
bd sync
```

### 4. Export for Documentation

```bash
# Generate sprint report
bv --export-md --sections=plan,metrics > sprint-report.md

# Generate dashboard for stakeholders
bv --export-html --output=dashboard.html
```

---

## Related Tools

- **[Beads](./beads-git-backed-task-tracking.md)** - The underlying task tracker (required)
- **[direnv](./direnv-environment-variable-management.md)** - Per-project environment management
- **[sync-mcp-cfg](./sync-mcp-cfg-multi-client-mcp-configuration.md)** - MCP configuration synchronization

---

## Resources

- **Repository**: https://github.com/Dicklesworthstone/beads_viewer
- **Installation Script**: https://raw.githubusercontent.com/Dicklesworthstone/beads_viewer/main/install.sh
- **Issue Tracker**: https://github.com/Dicklesworthstone/beads_viewer/issues
- **Beads (Required)**: https://github.com/steveyegge/beads

---

## Quick Reference Card

```bash
# Interactive TUI
bv                              # Launch TUI

# Robot Protocol (AI Agents)
bv --robot-triage               # THE MEGA-COMMAND: Complete analysis
bv --robot-next                 # Get next task recommendation
bv --robot-insights             # Full graph metrics
bv --robot-plan                 # Execution plan with parallel tracks
bv --robot-priority             # Priority recommendations
bv --robot-alerts               # Health warnings
bv --robot-label-health         # Per-label metrics
bv --robot-forecast             # Completion estimates

# Export
bv --export-md                  # Markdown report
bv --export-html                # HTML dashboard
bv --export-json                # JSON data
bv --export-pages               # Static site

# Time-Travel
bv --time-travel <commit>       # View historical state
bv --time-travel <date>         # View state at date

# Graph Metrics Computed
- PageRank (30%)                # Foundational importance
- Betweenness (30%)             # Bottleneck identification
- HITS (Hub/Authority)          # Role in network
- Critical Path                 # Timeline impact
- Eigenvector Centrality        # Influence clusters
- Cycle Detection               # Circular dependencies
```

---

**Last Updated**: 2025-01-15  
**Version**: Based on Dicklesworthstone/beads_viewer main branch  
**Status**: Production-ready, actively maintained  
**Requires**: Beads (steveyegge/beads)