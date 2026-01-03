---
title: Claude Code Skills vs Manual Agent Context Loading
type: note
permalink: architecture/automation/claude-code-skills-vs-manual-agent-context-loading
tags:
- claude-code
- skills
- qodo-gen
- multi-agent
- workflows
- automation
---

# Claude Code Skills vs Manual Agent Context Loading

## Understanding Claude Code Skills

### What Are Skills?

Skills are **user-defined prompts** that Claude Code can execute via the `/` command or the `Skill` MCP tool.

**Location**: `.claude/skills/` directory in your project

**Format**: Markdown files with structured prompts

**Invocation**:
- User types: `/skill-name` in Claude Code
- Or agent calls: `Skill` tool with skill name
- Claude executes the prompt defined in the skill file

### How Skills Work

```markdown
# Example: .claude/skills/load-context.md

You are starting a new work session. Follow these steps:

1. Read the morning context file:
   - Look for newest file in ~/.agent-context/session-*.md
   - Read entire file to understand current state

2. Load Basic Memory context:
   - Call: mcp__basic-memory__recent_activity(timeframe="7d", project="i-do-blueprint")
   - Call: mcp__basic-memory__build_context(url="projects/i-do-blueprint", depth=2)

3. Load Beads triage:
   - Read: ~/.agent-context/triage-*.json (newest)
   - Parse recommendations

4. Present to user:
   - Summarize git status
   - List top 3 recommended tasks
   - Ask: "Which would you like to work on?"

When user selects task:
- Load full task details: bd show <task-id>
- Load relevant architecture context from Basic Memory
- Begin work
```

**User invokes**:
```bash
# In Claude Code
/load-context

# Or just type it as a message
load-context
```

**Claude automatically**:
1. Reads the skill file
2. Executes the instructions
3. Makes all the MCP calls
4. Presents organized summary
5. Asks what to work on

---

## Claude Code Skills: Pros & Cons

### ✅ Pros

1. **Automatic Context Loading**
   - User types `/load-context` → everything loads automatically
   - No need to manually @ reference files
   - Agent makes all MCP calls for you

2. **Consistent Workflow**
   - Same steps every time
   - No forgetting to load something
   - Standardized for whole team

3. **Smart Integration**
   - Skills can call other skills
   - Can use conditions (if git status shows uncommitted, warn)
   - Can chain multiple operations

4. **Session Continuity**
   - Skills can check for previous session
   - Resume where you left off
   - Load yesterday's summary automatically

5. **User-Friendly**
   - Single command vs multiple steps
   - Natural language interface
   - Self-documenting (skill file shows what it does)

### ❌ Cons

1. **Claude Code Specific**
   - **Won't work in Qodo Gen** (doesn't support skills)
   - **Won't work in Cursor** (different skill system)
   - **Won't work in Claude Desktop** (no skill support)
   - **Only Claude Code CLI**

2. **Requires Setup**
   - Must create `.claude/skills/` directory
   - Must write skill files
   - Must keep them updated

3. **Less Transparent**
   - User doesn't see all the MCP calls
   - Harder to debug if something goes wrong
   - Black box behavior

4. **File Discovery Issues**
   - Skills can't easily find "newest file matching pattern"
   - Would need to hardcode paths or use Bash tool
   - More brittle than manual approach

---

## Manual Route: Pros & Cons

### ✅ Pros

1. **Universal**
   - **Works in Claude Code** ✅
   - **Works in Qodo Gen** ✅
   - **Works in Cursor** ✅
   - **Works in any AI coding assistant** ✅
   - Just reference the file: `@~/.agent-context/session-*.md`

2. **Transparent**
   - You see exactly what's loaded
   - You control when to load what
   - Easy to debug

3. **Flexible**
   - Load context when needed, not automatically
   - Can skip parts you don't need
   - Customize per session

4. **Simple**
   - Just reference a file
   - No special syntax to learn
   - Works with standard file references

5. **Reliable**
   - Files are there or they're not
   - No skill execution failures
   - No MCP call failures (you make them manually when needed)

### ❌ Cons

1. **Manual Steps**
   - Must remember to reference the file
   - Must call Basic Memory MCP tools yourself
   - More typing

2. **Inconsistent**
   - Might forget a step
   - Different approach each time
   - Harder to standardize across team

3. **More Verbose**
   - Have to type out full MCP calls
   - Have to reference files explicitly
   - More context window usage

---

## Recommendation for Multi-Agent Workflows

### 🎯 Best Approach: **Manual Route with Template**

**Why?**

1. **You use multiple agents** (Claude Code, Qodo Gen, Code Guardian, etc.)
   - Skills only work in Claude Code
   - Manual file references work everywhere

2. **Consistency across agents**
   - Same context file for all agents
   - Same workflow regardless of tool
   - Easier to switch between agents

3. **Simpler to maintain**
   - Just run `agent-morning` → context file created
   - Reference it in any agent
   - No skill maintenance needed

### How It Works

**Morning**:
```bash
# Terminal
agent-morning

# Output shows:
# 📄 Session Context: ~/.agent-context/session-2025-12-30-0900.md
# 📊 Triage Analysis: ~/.agent-context/triage-2025-12-30-0900.json
```

**In Claude Code**:
```
@~/.agent-context/session-2025-12-30-0900.md

Load recent context from Basic Memory (timeframe: 7d, project: i-do-blueprint) 
and review the triage recommendations. What should I work on first?
```

**In Qodo Gen**:
```
@~/.agent-context/session-2025-12-30-0900.md

I'm ready to start work. Load the triage analysis and Basic Memory context,
then recommend the highest-priority task.
```

**In Cursor**:
```
@~/.agent-context/session-2025-12-30-0900.md

Context loaded. What's the next task from the triage recommendations?
```

**Same file, works everywhere.** ✅

---

## Hybrid Approach (Optional)

You can create a **template prompt** and save it as a text snippet:

**File**: `~/snippets/agent-start.txt`

```
@~/.agent-context/session-REPLACE_WITH_DATE.md

Load recent context from Basic Memory:
- mcp__basic-memory__recent_activity(timeframe="7d", project="i-do-blueprint")
- mcp__basic-memory__build_context(url="projects/i-do-blueprint", depth=2)

Review the triage analysis at ~/.agent-context/triage-REPLACE_WITH_DATE.json
and recommend the top 3 tasks I should work on.

Once I select a task, load its full details with bd show <task-id> and
any relevant architecture patterns from Basic Memory.
```

**Usage**:
```bash
# 1. Run morning workflow
agent-morning

# 2. Copy template
cat ~/snippets/agent-start.txt | pbcopy

# 3. Paste into any agent, replace REPLACE_WITH_DATE with actual date
# 4. Send
```

**Even better**: Use keyboard shortcut or shell alias:

```bash
# In ~/.zshrc
agent-prompt() {
    local date=$(date +%Y-%m-%d-%H%M)
    cat ~/snippets/agent-start.txt | sed "s/REPLACE_WITH_DATE/$date/g" | pbcopy
    echo "✅ Agent start prompt copied to clipboard!"
    echo "   Paste into Claude Code, Qodo Gen, or any agent"
}
```

Then:
```bash
agent-morning  # Generate context
agent-prompt   # Copy start prompt to clipboard
# Paste into any agent
```

---

## Specific Skill Example (If You Want It)

If you **only use Claude Code**, here's what a skill would look like:

**File**: `.claude/skills/session-start.md`

```markdown
# Session Start Skill

You are beginning a new coding session for the I Do Blueprint project.

## Step 1: Find Latest Context

Look for the newest session context file in ~/.agent-context/ matching pattern:
- session-YYYY-MM-DD-HHMM.md

Use the Bash tool to find it:
```bash
ls -t ~/.agent-context/session-*.md | head -1
```

## Step 2: Load Session Context

Read the entire context file found above.

## Step 3: Load Basic Memory Context

Make these MCP calls:

1. Recent activity:
```
mcp__basic-memory__recent_activity({
  timeframe: "7d",
  project: "i-do-blueprint"
})
```

2. Build context:
```
mcp__basic-memory__build_context({
  url: "projects/i-do-blueprint",
  depth: 2,
  project: "i-do-blueprint"
})
```

## Step 4: Load Triage Analysis

Find and read the newest triage JSON:
```bash
ls -t ~/.agent-context/triage-*.json | head -1
```

Read the file and parse the recommendations.

## Step 5: Present Summary

Provide the user with:

1. **Git Status Summary**
   - Current branch
   - Uncommitted changes count
   - Unpushed commits count

2. **Task Overview**
   - In Progress: X tasks
   - Ready: X tasks
   - Blocked: X tasks

3. **Top 3 Recommended Tasks**
   (from triage analysis, sorted by priority/impact)

4. **Recent Context**
   (from Basic Memory - most relevant architectural decisions)

## Step 6: Interactive Selection

Ask: "Which task would you like to work on? (1, 2, 3, or specify task ID)"

When user selects:
1. Load full task details: `bd show <task-id>`
2. Search Basic Memory for relevant patterns
3. Begin work

## Notes

- If context files don't exist, remind user to run `agent-morning`
- If MCP calls fail, continue with available context
- Always be ready to start work on whatever user specifies
```

**Usage in Claude Code**:
```bash
# Just type:
/session-start

# Claude automatically:
# - Finds newest context files
# - Loads Basic Memory
# - Reads triage
# - Presents top 3 tasks
# - Asks what to work on
```

---

## Final Recommendation

### For You (Multi-Agent User):

**Use Manual Route** ✅

**Morning**:
```bash
agent-morning
```

**In Any Agent** (Claude Code, Qodo Gen, Cursor, etc.):
```
@~/.agent-context/session-2025-12-30-0900.md

[Your standard template here - load Basic Memory, review triage, etc.]
```

**Why?**
- Works everywhere (Qodo Gen ✅, Claude Code ✅, Cursor ✅)
- Simple and reliable
- Easy to customize per agent/session
- No skill maintenance overhead

---

## When to Use Skills

Consider skills if:
- ✅ You **only** use Claude Code (not Qodo Gen, Cursor, etc.)
- ✅ You want **maximum automation** (one command loads everything)
- ✅ You run the **same workflow every time** (standardization)
- ✅ You're willing to **maintain skill files** as workflow evolves

Skip skills if:
- ✅ You use **multiple AI agents** (Qodo Gen, Cursor, etc.) ← **You are here**
- ✅ You want **flexibility** in what you load
- ✅ You want **transparency** in what's happening
- ✅ You prefer **simple, reliable workflows**

---

## Summary Table

| Aspect | Claude Code Skill | Manual Route |
|--------|------------------|--------------|
| **Works in Claude Code** | ✅ | ✅ |
| **Works in Qodo Gen** | ❌ | ✅ |
| **Works in Cursor** | ❌ | ✅ |
| **Works in other agents** | ❌ | ✅ |
| **Automation level** | High (one command) | Medium (reference file + template) |
| **Setup complexity** | Medium (create skills) | Low (just reference files) |
| **Maintenance** | Medium (update skills) | Low (files auto-generated) |
| **Transparency** | Low (black box) | High (explicit) |
| **Flexibility** | Low (fixed workflow) | High (customize per session) |
| **Debugging** | Hard (skill execution) | Easy (see all steps) |

**Recommendation for your use case**: **Manual Route** with optional template snippet for consistency.

---

Last Updated: 2025-12-30
Use Case: Multi-agent workflows (Claude Code + Qodo Gen + others)
Recommendation: Manual route with context files