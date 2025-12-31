# Context Engineering Analysis for Claude Code & Qodo Gen

**Source Article**: [Benchmark for Agent Context Engineering](https://www.tarasyarema.com/blog/agent-context-engineering) by Taras Yarema

**Date Analyzed**: December 2025

---

## Executive Summary

This document analyzes context engineering principles from Taras Yarema's benchmark research and provides actionable recommendations for optimizing Claude Code and Qodo Gen workflows in the I Do Blueprint project.

**Key Finding**: Context engineering (how you structure and manage conversation history) matters more than framework choice or code quality for agent success rates.

---

## Links Extracted from Article

### Primary Resources

1. **GitHub Repository**: [desplega-ai/context-engineering](https://github.com/desplega-ai/context-engineering)
   - Contains full implementation of three agent approaches (raw, summarization, intent)
   - Includes benchmark results and analysis code

2. **Full Benchmark Report**: [summary_report.md](https://github.com/desplega-ai/context-engineering/blob/main/analysis_output/summary_report.md)
   - Detailed metrics across all models and approaches

3. **Intent Agent Prompt Code**: [intent_prompts.py](https://github.com/desplega-ai/context-engineering/blob/main/src/agents/intent_prompts.py)
   - Shows deterministic context compression implementation

### Referenced Articles & Resources

#### Context Engineering Concepts

4. **LangChain Dynamic Runtime Context**: https://docs.langchain.com/oss/python/concepts/context#dynamic-runtime-context
   - Context-driven libraries and patterns

5. **Anthropic: Code Execution with MCP**: https://www.anthropic.com/engineering/code-execution-with-mcp
   - How context and coding agents work together for complex tool chains

6. **Anthropic: Effective Context Engineering for AI Agents**: https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
   - Official Anthropic guidance on context engineering

7. **Manus Blog: Context Engineering for AI Agents**: https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus
   - Real-world lessons from building production agents

#### Agent Architecture

8. **CodeCut: LangChain 1.0 Middleware for Production Agents**: https://codecut.ai/langchain-1-0-middleware-production-agents/
   - Middleware patterns for production-ready agents

9. **BAML (Boundary ML)**: https://github.com/BoundaryML/baml
   - Language for building AI agents with structured outputs

10. **12 Factor Agents**: https://github.com/humanlayer/12-factor-agents
    - Best practices for building production agents

11. **Advanced Context Engineering for Coding Agents**: https://github.com/humanlayer/advanced-context-engineering-for-coding-agents
    - Specific patterns for coding agents

12. **HumanLayer YC Video**: https://www.youtube.com/watch?v=8kMaTybvDUw
    - Context engineering presentation to Y Combinator

#### Needle in Haystack Problem

13. **LangChain: Multi-Needle in a Haystack**: https://blog.langchain.com/multi-needle-in-a-haystack/
    - Understanding context retrieval challenges

14. **Google Cloud: Needle in Haystack Test**: https://cloud.google.com/blog/products/ai-machine-learning/the-needle-in-the-haystack-test-and-how-gemini-pro-solves-it
    - How Gemini handles long context

15. **Research Paper: Needle in Haystack**: https://arxiv.org/abs/2407.01437
    - Academic research on context retrieval

---

## Three Context Engineering Approaches

### 1. Raw Approach (Append-Only)
**How it works**: Simple message history that grows with each turn

**Pros**:
- Simple to implement
- Works well for short conversations
- No information loss

**Cons**:
- Context grows linearly with steps
- "Needle in haystack" problem at scale
- Expensive token usage

**When to use**: Simple agents with <10 steps, minimal tool usage

### 2. Summarization Approach
**How it works**: Auto-compress history after hitting token threshold (e.g., 12k tokens)

**Pros**:
- Caps context growth
- Reduces noise in long conversations
- Tunable threshold

**Cons**:
- Information loss through summarization
- Can hallucinate or forget original task
- Poor for analytical tasks requiring precision
- "Broken telephone" effect

**When to use**: Medium complexity agents where approximate context is acceptable

### 3. Intent Approach (Recommended)
**How it works**: Deterministic context compression with reusable prompt template

**Pros**:
- 100% success rate in benchmarks
- Fewer steps required (consistently <25)
- Linear context growth
- Maintains task fidelity
- Controllable and predictable

**Cons**:
- More upfront work to design template
- Larger initial context bump
- Requires domain-specific customization

**When to use**: Complex agents requiring reliability and precision

---

## Benchmark Results Summary

### Success Rates
- **Intent**: 100% across all models
- **Raw**: ~90% (flaky on GPT-4.1-mini)
- **Summarization**: ~60-70% (worst performer)

### Accuracy
- **Intent**: Consistently highest across models
- **Raw**: Medium accuracy
- **Summarization**: Slightly worse than raw

### Steps Required
- **Intent**: <25 steps consistently
- **Raw**: 30-40 steps
- **Summarization**: 35-45 steps

### Token Usage
- **Raw**: Highest (exponential growth)
- **Intent**: Medium (linear growth)
- **Summarization**: Medium (plateau after threshold)

### Cost
- **Raw**: Most expensive
- **Summarization**: Cheapest
- **Intent**: Medium (worth it for 100% success rate)

### Latency
- **Intent**: Slowest (~4 minutes)
- **Raw**: Fastest
- **Summarization**: Medium

**Key Insight**: For background agentic flows, latency differences of ~60s are negligible. Users expect 10+ minute wait times for deep research tasks.

---

## Applying to Claude Code & Qodo Gen

### Current State Analysis

#### Claude Code
- Uses append-only message history (raw approach)
- Has auto-compactification feature
- Excellent for interactive coding sessions
- Struggles with very long sessions (>50 turns)

#### Qodo Gen
- Focused on code generation and testing
- Shorter conversation contexts
- Task-specific prompts
- Less affected by context issues

### Recommendations

#### 1. For Claude Code Sessions

**Problem**: Long coding sessions accumulate context noise, leading to:
- Forgetting earlier decisions
- Repeating failed approaches
- Missing critical constraints

**Solution**: Implement Intent-Based Context Management

```markdown
# Session Context Template (Update on each major milestone)

## Current Goal
[One-sentence task description]

## Completed Milestones
- [x] Milestone 1: Brief outcome
- [x] Milestone 2: Brief outcome

## Active Context
- Current file: [path]
- Current task: [specific action]
- Blockers: [if any]

## Key Decisions
1. Decision: [what] | Rationale: [why] | Impact: [where]
2. ...

## Failed Approaches (Don't Retry)
- Approach: [what] | Reason: [why it failed]

## Next Steps
1. [Immediate next action]
2. [Following action]
```

**Implementation**:
1. Create `.claude-context.md` in project root
2. Update after every 5-10 turns or major milestone
3. Reference in prompts: "See .claude-context.md for session state"

#### 2. For Qodo Gen Workflows

**Problem**: Generating tests/code without full project context

**Solution**: Pre-load Intent Context

```markdown
# Code Generation Context

## Project Architecture
- Pattern: [e.g., Repository Pattern with Domain Services]
- Key conventions: [e.g., V2 suffix, @MainActor for stores]

## Current Feature
- Domain: [e.g., Budget Management]
- Models: [relevant models]
- Dependencies: [repositories, services]

## Generation Requirements
- Must follow: [specific patterns]
- Must avoid: [anti-patterns]
- Test with: [mock repositories]

## Recent Patterns
[Last 3 similar implementations for consistency]
```

#### 3. Hybrid Approach for I Do Blueprint

**Strategy**: Combine Basic Memory (long-term) + Intent Context (session)

```bash
# Session Start
1. Load from Basic Memory:
   mcp__basic-memory__build_context(url: "projects/i-do-blueprint")
   
2. Create session intent context:
   - Goal: [from Beads task]
   - Relevant ADRs: [from Basic Memory search]
   - Recent patterns: [from Basic Memory]
   
3. Update intent context every 10 turns:
   - Completed: [what's done]
   - Learned: [new patterns/decisions]
   - Next: [remaining work]

# Session End
4. Persist to Basic Memory:
   mcp__basic-memory__write_note(
     title: "Pattern: [discovered pattern]",
     folder: "architecture/patterns"
   )
```

---

## Practical Implementation Guide

### Step 1: Create Context Templates

Create `docs/context-templates/` with:

1. **coding-session-template.md**: For Claude Code sessions
2. **test-generation-template.md**: For Qodo Gen
3. **architecture-decision-template.md**: For ADR work
4. **debugging-session-template.md**: For troubleshooting

### Step 2: Integrate with Existing Workflow

Update `BASIC-MEMORY-AND-BEADS-GUIDE.md` to include:

```markdown
## Context Engineering Protocol

### Before Starting Work
1. Load Beads task: `bd show <id>`
2. Search Basic Memory: `mcp__basic-memory__search_notes("relevant topic")`
3. Create session context from template
4. Update context every 10 turns

### During Work
- Reference session context in prompts
- Update context on major milestones
- Document failed approaches

### After Completing Work
- Extract patterns to Basic Memory
- Close Beads task
- Archive session context
```

### Step 3: Automate Context Updates

Create `Scripts/update-session-context.sh`:

```bash
#!/bin/bash
# Updates session context with current state

CONTEXT_FILE=".claude-context.md"

# Extract current Beads task
CURRENT_TASK=$(bd list --status=in_progress | head -n 1)

# Update context file
cat > $CONTEXT_FILE <<EOF
# Session Context (Auto-updated: $(date))

## Current Goal
$CURRENT_TASK

## Completed This Session
$(git log --oneline --since="1 hour ago")

## Active Files
$(git status --short)

## Next Steps
[Update manually]
EOF

echo "Context updated in $CONTEXT_FILE"
```

### Step 4: Create Context Validation

Add to `.swiftlint.yml`:

```yaml
custom_rules:
  session_context_exists:
    name: "Session Context File"
    message: "Long sessions should have .claude-context.md"
    regex: ".*"
    match_kinds: []
    severity: warning
```

---

## Measuring Success

### Metrics to Track

1. **Success Rate**: % of tasks completed without manual intervention
2. **Steps to Completion**: Average turns needed per task type
3. **Context Efficiency**: Tokens used per successful task
4. **Pattern Reuse**: How often we reference previous solutions

### Baseline Measurements (To Establish)

```bash
# Create tracking file
cat > docs/context-engineering-metrics.md <<EOF
# Context Engineering Metrics

## Week of [Date]

### Claude Code Sessions
- Tasks completed: X
- Average turns: Y
- Context resets needed: Z
- Success rate: %

### Qodo Gen Usage
- Code generations: X
- First-try success: Y
- Revisions needed: Z

### Pattern Reuse
- Basic Memory references: X
- Context template usage: Y
EOF
```

---

## Action Items

### Immediate (This Week)

- [ ] Create `docs/context-templates/` directory
- [ ] Write 4 core context templates
- [ ] Update `BASIC-MEMORY-AND-BEADS-GUIDE.md` with context protocol
- [ ] Create `.claude-context.md` for current session

### Short-term (This Month)

- [ ] Implement `update-session-context.sh` script
- [ ] Add context validation to pre-commit hooks
- [ ] Establish baseline metrics
- [ ] Document 3 successful intent-based sessions

### Long-term (This Quarter)

- [ ] Build context template library (10+ templates)
- [ ] Integrate with Beads workflow automation
- [ ] Create context engineering training guide
- [ ] Measure ROI (time saved, quality improved)

---

## Key Takeaways

1. **Context engineering > Framework choice**: How you structure context matters more than which tools you use

2. **Intent approach wins for complex tasks**: 100% success rate vs 60-90% for other approaches

3. **Deterministic compression beats summarization**: Maintain task fidelity, avoid "broken telephone" effect

4. **Latency is acceptable**: 60s difference negligible for background agent tasks

5. **Cost is worth reliability**: Pay slightly more for guaranteed success

6. **Integration with existing tools**: Combine with Basic Memory and Beads for optimal workflow

---

## References

See "Links Extracted from Article" section above for all 15 referenced resources.

**Primary Reading**:
1. Original article: https://www.tarasyarema.com/blog/agent-context-engineering
2. GitHub repo: https://github.com/desplega-ai/context-engineering
3. Anthropic guide: https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents

---

**Next Steps**: Review this document with the team and prioritize implementation of context templates for immediate productivity gains.
