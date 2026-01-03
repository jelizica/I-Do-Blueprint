---
title: Owlex - Multi-Agent Orchestration
type: note
permalink: ai-tools/orchestration/owlex-multi-agent-orchestration
tags:
- mcp
- orchestration
- multi-agent
- council
- deliberation
- codex
- gemini
- opencode
---

# Owlex - Multi-Agent Orchestration

## Overview

**Category**: Orchestration  
**Status**: ✅ Active - Multi-Agent Coordination  
**Installation**: `uv tool install git+https://github.com/agentic-mcp-tools/owlex.git`  
**MCP Server**: `owlex-server`  
**Repository**: https://github.com/agentic-mcp-tools/owlex  
**License**: MIT  
**Agent Attachment**: Qodo Gen (MCP), Claude Code (MCP)

---

## What It Does

Owlex is an MCP server that enables **multi-agent orchestration**, allowing Claude Code to query multiple AI coding agents (Codex, Gemini, OpenCode) in parallel. It implements a **council deliberation pattern** where agents can provide initial answers, then optionally revise their responses after seeing what other agents said, or critique each other's work to find bugs and flaws.

### Core Concept: Council Deliberation

Instead of relying on a single AI agent's perspective, Owlex orchestrates multiple agents to:

1. **Parallel Query**: Send the same question to all agents simultaneously
2. **Initial Answers**: Each agent responds independently (Round 1)
3. **Deliberation** (optional): Agents see each other's answers and revise (Round 2)
4. **Critique Mode** (optional): Agents find bugs, security issues, and architectural flaws in each other's responses

**Use Case**: Get diverse perspectives on complex technical decisions, code reviews, or architectural choices.

---

## Key Features

### 1. Council Deliberation Pattern

**Two-Round System**:

**Round 1 - Independent Answers**:
- All agents receive the same prompt
- Each agent responds without seeing others' work
- Ensures diverse, independent perspectives
- Timeout control per agent (default: 300 seconds)

**Round 2 - Deliberation** (optional):
- Agents see all Round 1 answers
- Can revise their original response
- Learn from other perspectives
- Synthesize better solutions

**Critique Mode** (alternative to revision):
- Instead of revising, agents critique each other
- Find bugs, security vulnerabilities, architectural issues
- Adversarial approach to code quality

### 2. Session Management

**Codex Sessions**:
- `start_codex_session`: Create new session
- `resume_codex_session`: Resume with session ID or `--last`

**Gemini Sessions**:
- `start_gemini_session`: Create new session
- `resume_gemini_session`: Resume with index or `latest`

**Session Persistence**: Full context preserved across conversations.

### 3. Async Task Execution

**Background Tasks**:
- Agents run in parallel (non-blocking)
- Timeout control per agent
- Status monitoring without blocking

**Task Management Tools**:
- `wait_for_task`: Block until task completes
- `get_task_result`: Check result without blocking
- `list_tasks`: List tasks with status filter
- `cancel_task`: Kill running task

---

## Installation & Configuration

### Installation

```bash
# Install via uv
uv tool install git+https://github.com/agentic-mcp-tools/owlex.git
```

### MCP Server Configuration

**Claude Code** (`~/.mcp.json` or project `.mcp.json`):

```json
{
  "mcpServers": {
    "owlex": {
      "command": "owlex-server"
    }
  }
}
```

**Qodo Gen**: Similar configuration in Qodo Gen's MCP settings.

---

## MCP Tools Reference

### Core Tool: `council_ask`

**Purpose**: Query all agents and collect answers with optional deliberation.

**Parameters**:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `prompt` | string | (required) | Question to send to all agents |
| `claude_opinion` | string | (optional) | Your opinion to share with agents |
| `deliberate` | boolean | `true` | Enable revision round (Round 2) |
| `critique` | boolean | `false` | Agents critique instead of revise |
| `timeout` | integer | `300` | Timeout per agent in seconds |

**Returns**:
- `round_1`: Object with initial answers from each agent
  - `codex`: Codex's initial response
  - `gemini`: Gemini's initial response
  - `opencode`: OpenCode's initial response
- `round_2` (if `deliberate=true`): Object with revised answers
  - Each agent's revision after seeing others' work

**Example Usage**:

```javascript
// Basic council query (with deliberation)
council_ask({
  prompt: "How should I implement authentication in this Next.js app?",
  deliberate: true
})

// Critique mode (find flaws)
council_ask({
  prompt: "Review this authentication implementation for security issues",
  critique: true
})

// With your opinion
council_ask({
  prompt: "Should we use server components or client components for this feature?",
  claude_opinion: "I'm leaning toward server components for better SEO",
  deliberate: true
})

// Custom timeout
council_ask({
  prompt: "Analyze this large codebase",
  timeout: 600  // 10 minutes
})
```

### Session Management Tools

#### Codex Sessions

**`start_codex_session`**

Creates a new Codex session.

**Parameters**:
- `initial_prompt` (string, optional): Initial message to send

**Returns**: Session ID

**`resume_codex_session`**

Resumes an existing Codex session.

**Parameters**:
- `session_id` (string): Session ID to resume
- `use_last` (boolean): Use `--last` flag to resume most recent session

**Example**:
```javascript
// Resume specific session
resume_codex_session({ session_id: "abc123" })

// Resume last session
resume_codex_session({ use_last: true })
```

#### Gemini Sessions

**`start_gemini_session`**

Creates a new Gemini session.

**Parameters**:
- `initial_prompt` (string, optional): Initial message to send

**Returns**: Session index

**`resume_gemini_session`**

Resumes an existing Gemini session.

**Parameters**:
- `session_index` (integer): Session index to resume
- `use_latest` (boolean): Use `latest` to resume most recent session

**Example**:
```javascript
// Resume specific session
resume_gemini_session({ session_index: 3 })

// Resume latest session
resume_gemini_session({ use_latest: true })
```

### Task Management Tools

**`wait_for_task`**

Blocks until a task completes.

**Parameters**:
- `task_id` (string): Task ID to wait for

**Returns**: Task result

**`get_task_result`**

Checks task result without blocking.

**Parameters**:
- `task_id` (string): Task ID to check

**Returns**: 
- Task result (if complete)
- Status (if still running)

**`list_tasks`**

Lists all tasks with optional status filter.

**Parameters**:
- `status_filter` (string, optional): Filter by status (`running`, `completed`, `failed`, `cancelled`)

**Returns**: Array of tasks with IDs, statuses, timestamps

**`cancel_task`**

Cancels a running task.

**Parameters**:
- `task_id` (string): Task ID to cancel

**Returns**: Cancellation status

---

## Environment Variables

Configure agent behavior via environment variables:

### Codex Configuration

**`CODEX_BYPASS_APPROVALS`** (default: `false`)
- Bypass sandbox approval prompts
- **DANGEROUS**: Auto-approves all actions
- Use only in trusted, isolated environments

**`CODEX_ENABLE_SEARCH`** (default: `true`)
- Enable web search capabilities
- Allows Codex to search for documentation, examples

### Gemini Configuration

**`GEMINI_YOLO_MODE`** (default: `false`)
- Auto-approve all actions without confirmation
- **DANGEROUS**: Use with caution
- Useful for automated workflows

### OpenCode Configuration

**`OPENCODE_AGENT`** (default: `plan`)
- Agent mode: `plan` (read-only) or `build` (read-write)
- **`plan`**: Analysis and planning only (safer)
- **`build`**: Can modify code (more powerful)

### Council Configuration

**`COUNCIL_EXCLUDE_AGENTS`** (default: `""`)
- Comma-separated list of agents to exclude
- Example: `"codex,gemini"` (use only OpenCode)
- Useful for testing or limiting to specific agents

**`OWLEX_DEFAULT_TIMEOUT`** (default: `300`)
- Default timeout in seconds for all agents
- Can be overridden per `council_ask` call

**Example `.env` or shell config**:

```bash
export CODEX_ENABLE_SEARCH=true
export GEMINI_YOLO_MODE=false
export OPENCODE_AGENT=plan
export OWLEX_DEFAULT_TIMEOUT=300
```

---

## When to Use Each Agent

Owlex integrates three AI coding agents. Here's when to use each:

### Codex (GitHub Copilot's underlying model)

**Best For**:
- Code review and bug finding
- Discussing PRDs and requirements
- General programming questions
- Quick syntax and API lookups

**Strengths**:
- Fast responses
- Strong code completion
- Good for iterative development

**Limitations**:
- Smaller context window than Gemini
- Less sophisticated for complex architecture

### Gemini (Google's large context model)

**Best For**:
- Large codebase analysis (1M token context window)
- Multimodal tasks (images, diagrams, videos)
- Long-form documentation generation
- Complex architectural decisions

**Strengths**:
- Massive context window (1,000,000 tokens)
- Multimodal understanding (text + images)
- Strong reasoning for complex tasks

**Limitations**:
- Slower than Codex
- May be overkill for simple tasks

### OpenCode (Open-source alternative)

**Best For**:
- Alternative perspective to proprietary models
- Plan mode for read-only analysis
- Cost-sensitive workflows (open-source)

**Strengths**:
- Open-source transparency
- Two modes: `plan` (safe) and `build` (powerful)
- Good for code review and planning

**Limitations**:
- May not match Codex/Gemini quality on complex tasks
- Requires local or self-hosted deployment

### Claude (Anthropic, via Claude Code)

**Best For**:
- Complex multi-step implementation
- Thoughtful, nuanced explanations
- Ethical and safety-conscious responses
- Long conversations with context retention

**Strengths**:
- Excellent reasoning and explanation
- Strong safety features
- Good at breaking down complex problems

**Use in Owlex**: Claude typically **orchestrates** the council (via Claude Code), while Codex/Gemini/OpenCode provide diverse perspectives.

---

## I Do Blueprint Use Cases

### 1. Architecture Decision Review

**Scenario**: Decide whether to use server components or client components for RSVP form.

**Workflow**:
```javascript
council_ask({
  prompt: `
    I'm building an RSVP form in Next.js 14 with App Router.
    Should I use server components or client components?
    
    Requirements:
    - Form validation
    - Real-time guest search
    - Database updates (Supabase)
    - SEO-friendly
  `,
  claude_opinion: "I'm leaning toward server components for SEO, but worried about interactivity",
  deliberate: true
})
```

**Expected Outcome**:
- **Round 1**: Independent recommendations from each agent
- **Round 2**: Agents revise after seeing others' perspectives
- **Final Decision**: Informed by 3+ AI agents + your opinion

### 2. Security Code Review

**Scenario**: Review authentication implementation for security vulnerabilities.

**Workflow**:
```javascript
council_ask({
  prompt: `
    Review this authentication implementation for security issues:
    
    [paste code]
    
    Focus on:
    - SQL injection risks
    - XSS vulnerabilities
    - Session management
    - Password handling
  `,
  critique: true,  // Agents find flaws, not just suggest improvements
  timeout: 600
})
```

**Expected Outcome**:
- Codex: Syntax-level security issues
- Gemini: Architectural security concerns
- OpenCode: Alternative secure patterns
- **Combined**: Comprehensive security audit

### 3. Refactoring Strategy

**Scenario**: Plan refactoring approach for complex wedding planning scheduler.

**Workflow**:
```javascript
council_ask({
  prompt: `
    This 500-line scheduler function needs refactoring.
    Suggest modular approach with step-by-step plan.
    
    [paste code]
    
    Requirements:
    - Maintain backward compatibility
    - Improve testability
    - Reduce complexity
  `,
  deliberate: true,
  timeout: 600
})
```

**Expected Outcome**:
- Multiple refactoring strategies
- Agents revise after seeing each other's plans
- Best practices from different perspectives

### 4. Database Schema Design

**Scenario**: Design optimal Supabase schema for wedding planning features.

**Workflow**:
```javascript
council_ask({
  prompt: `
    Design Supabase schema for wedding planning app:
    
    Features:
    - Guest management (names, emails, RSVPs)
    - Vendor tracking (contracts, payments)
    - Timeline management (tasks, deadlines)
    
    Requirements:
    - Efficient queries
    - Real-time updates
    - Row-level security (RLS)
  `,
  deliberate: true
})
```

**Expected Outcome**:
- Multiple schema designs
- Tradeoff analysis (normalization vs. denormalization)
- RLS policy recommendations

### 5. Performance Optimization

**Scenario**: Optimize slow Next.js page with large guest list.

**Workflow**:
```javascript
council_ask({
  prompt: `
    This guest list page is slow (5+ seconds load time).
    Suggest performance optimizations.
    
    Current implementation:
    - Fetches all 500 guests on load
    - Client-side filtering
    - No pagination
    
    [paste code]
  `,
  critique: true  // Find performance issues
})
```

**Expected Outcome**:
- Codex: Code-level optimizations
- Gemini: Architectural suggestions (pagination, virtualization)
- OpenCode: Alternative implementations

---

## Workflow Patterns

### Pattern 1: Independent Review → Deliberation

**Use When**: You want diverse initial perspectives, then synthesis.

```javascript
// Step 1: Get independent answers
const result = await council_ask({
  prompt: "How should I implement feature X?",
  deliberate: true
})

// Step 2: Review Round 1 answers
console.log(result.round_1)

// Step 3: Review Round 2 revisions
console.log(result.round_2)

// Step 4: Make informed decision based on synthesis
```

### Pattern 2: Critique-First Security Review

**Use When**: You need adversarial review to find vulnerabilities.

```javascript
// Step 1: Critique mode for flaws
const critique = await council_ask({
  prompt: "Review this authentication code for security issues",
  critique: true
})

// Step 2: Address identified issues

// Step 3: Re-review with deliberation
const revised_review = await council_ask({
  prompt: "Review updated authentication code",
  deliberate: true
})
```

### Pattern 3: Parallel Exploration with Your Opinion

**Use When**: You have a hypothesis but want validation/alternatives.

```javascript
const result = await council_ask({
  prompt: "Should I use approach A or approach B?",
  claude_opinion: "I prefer approach A because of X, but worried about Y",
  deliberate: true
})

// Agents will address your concerns and suggest alternatives
```

### Pattern 4: Session-Based Deep Dive

**Use When**: Complex problem requires extended conversation with one agent.

```javascript
// Start Gemini session (large context)
const session_id = await start_gemini_session({
  initial_prompt: "Let's analyze this entire codebase for refactoring opportunities"
})

// Continue conversation in session
// ...

// Later: resume session
await resume_gemini_session({ use_latest: true })
```

---

## Best Practices

### 1. Use Deliberation for Complex Decisions

- Enable `deliberate=true` for architecture, design, or complex technical choices
- Agents learn from each other and produce better synthesis

### 2. Use Critique for Security and Quality

- Enable `critique=true` for security reviews, code audits, performance analysis
- Adversarial approach finds more issues than cooperative review

### 3. Share Your Opinion

- Use `claude_opinion` to guide agents toward your concerns
- Agents will validate or challenge your assumptions

### 4. Set Appropriate Timeouts

- Default 300s (5 minutes) is good for most queries
- Increase to 600s+ for large codebase analysis
- Decrease to 60-120s for quick questions

### 5. Exclude Agents When Needed

- Use `COUNCIL_EXCLUDE_AGENTS` to focus on specific agents
- Example: `"codex,gemini"` to test OpenCode alone

### 6. Monitor Tasks

- Use `list_tasks` to see all running tasks
- Use `cancel_task` if agent is stuck or taking too long
- Use `get_task_result` for non-blocking status checks

### 7. Combine with Other Tools

- Use Owlex for **decision-making** and **review**
- Use Code Guardian Studio for **metrics** and **hotspots**
- Use Beads for **task tracking**
- Use Basic Memory for **storing decisions**

---

## Limitations & Considerations

### 1. Requires Multiple Agent Installations

- Codex: Requires GitHub Copilot subscription
- Gemini: Requires Google AI Studio API key
- OpenCode: Requires local installation

### 2. Parallel Execution Cost

- Queries all agents simultaneously
- 3x API cost compared to single agent
- Mitigate: Use `COUNCIL_EXCLUDE_AGENTS` to limit agents

### 3. Response Synthesis Required

- Agents may disagree
- You must synthesize final decision
- Deliberation helps but doesn't guarantee consensus

### 4. Timeout Management

- Long-running queries may timeout
- Increase `timeout` parameter for complex tasks
- Monitor with `get_task_result`

### 5. Session Context Limits

- Each agent has its own context window limits
- Codex: ~8K tokens
- Gemini: 1M tokens
- OpenCode: Varies by deployment

---

## Resources

### Official Links

- **GitHub**: https://github.com/agentic-mcp-tools/owlex
- **Releases**: https://github.com/agentic-mcp-tools/owlex/releases
- **Reddit Discussion**: https://www.reddit.com/r/Anthropic/comments/1pytn3x/owlex_an_mcp_server_that_lets_claude_code_consult/

### Related Projects

- **CAMEL-AI OWL**: https://github.com/camel-ai/owl (Multi-agent framework that inspired Owlex)
- **Agent MCP**: https://github.com/rinadelph/Agent-MCP (Alternative multi-agent framework)
- **Swarms**: https://github.com/kyegomez/swarms (Enterprise multi-agent orchestration)

### Tutorials & Guides

- **Multi-Agent Orchestration Patterns**: https://microsoft.github.io/multi-agent-reference-architecture/docs/context-engineering/Agents-Orchestration.html
- **OpenAI Multi-Agent Guide**: https://openai.github.io/openai-agents-python/multi_agent/

---

## Summary

Owlex is a **multi-agent orchestration MCP server** that enables Claude Code to query multiple AI agents (Codex, Gemini, OpenCode) in parallel for diverse perspectives, deliberation, and critique.

**Key Strengths**:
- 🤝 Council deliberation (parallel + revision rounds)
- 🔍 Critique mode (adversarial review for quality)
- 📝 Session management (resume conversations)
- ⚡ Async task execution (non-blocking)
- 🎯 Agent specialization (Codex, Gemini, OpenCode)
- 🔧 Environment configuration (bypass approvals, search, modes)

**Perfect for**:
- Architecture decision reviews
- Security code audits
- Refactoring strategy planning
- Database schema design
- Performance optimization
- Getting diverse AI perspectives on complex problems

---

**Last Updated**: December 30, 2025  
**Version**: v0.1.5  
**I Do Blueprint Integration**: Active
