# LLM Council Query Scripts

Scripts to run LLM Council queries with proper timeout handling, designed to avoid the timeout issues you're experiencing in Qodo Gen.

## Available Scripts

### 1. `llm-council-wrapper.sh` (Recommended)
Comprehensive wrapper with detailed instructions and configuration options.

**Usage:**
```bash
# Quick comparison (Stage 1 only - faster)
./scripts/llm-council-wrapper.sh --stage1 "What is the best authentication pattern?"

# Full deliberation (3 stages)
./scripts/llm-council-wrapper.sh "Should we use microservices or monolith?"

# Custom timeout (5 minutes)
./scripts/llm-council-wrapper.sh --timeout=300 "Complex architecture question"

# Save log
./scripts/llm-council-wrapper.sh --save-log "Important decision question"
```

**Options:**
- `--stage1` - Run only Stage 1 (individual model responses, ~30s)
- `--timeout=SECONDS` - Custom timeout (default: 180)
- `--save-log` - Save to `logs/llm-council/`
- `--chairman=MODEL` - Specify chairman model
- `--models=LIST` - Comma-separated list of council models

### 2. `llm-council-query.py`
Python script with colored output and structured logging.

**Usage:**
```bash
python3 scripts/llm-council-query.py "Your question"
python3 scripts/llm-council-query.py --stage1 "Quick question"
python3 scripts/llm-council-query.py --help
```

### 3. Direct Claude Code CLI

The most reliable method - use the MCP tools directly in Claude Code:

```
# Stage 1 only (faster)
mcp__llm-council__council_stage1(question: "Your question here")

# Full council deliberation
mcp__llm-council__council_query(
  question: "Your question here",
  save_conversation: true
)
```

## Understanding the Stages

### Stage 1 Only (`--stage1`)
- **What it does:** Queries all council models in parallel
- **Output:** Individual responses from each model
- **Duration:** ~30 seconds
- **Use when:** You want quick comparison of different model perspectives

### Full Council (default)
- **Stage 1:** Individual responses from all models
- **Stage 2:** Models rank each other's responses (anonymized)
- **Stage 3:** Chairman synthesizes final answer
- **Duration:** 30-120 seconds
- **Use when:** You want a synthesized, ranked decision

## Troubleshooting Qodo Gen Timeouts

If you're experiencing timeouts in Qodo Gen:

### Solution 1: Use Claude Code CLI
The most reliable approach:
1. Open Claude Code terminal
2. Paste the command shown by the wrapper script
3. Wait for completion (will handle timeouts gracefully)

### Solution 2: Use Stage 1 Only
Faster and more reliable:
```bash
./scripts/llm-council-wrapper.sh --stage1 "Your question"
```

### Solution 3: Increase Timeout
If the query is complex:
```bash
./scripts/llm-council-wrapper.sh --timeout=300 "Complex question"
```

## Default Models

**Council Members:**
- `openai/gpt-5.1`
- `google/gemini-3-pro-preview`
- `anthropic/claude-sonnet-4.5`
- `anthropic/claude-opus-4-20250514`
- `x-ai/grok-4`

**Chairman (synthesis):**
- `google/gemini-3-pro-preview`

## Custom Models

Override defaults:

```bash
# Custom council models
./scripts/llm-council-wrapper.sh \
  --models="openai/gpt-5.1,anthropic/claude-opus-4,google/gemini-3-pro-preview" \
  "Your question"

# Custom chairman
./scripts/llm-council-wrapper.sh \
  --chairman="anthropic/claude-opus-4" \
  "Your question"
```

## Saved Conversations

When using full council mode with `save_conversation: true`, conversations are saved in the LLM Council database and can be retrieved:

```
# List all saved conversations
mcp__llm-council__council_list_conversations()

# Get specific conversation
mcp__llm-council__council_get_conversation(conversation_id: "conv_xxx")
```

## Environment Setup

Ensure you have the required environment variable:

```bash
export OPENROUTER_API_KEY="your-key-here"
```

Add to your shell profile (`.zshrc`, `.bashrc`, etc.) for persistence.

## Examples

### Architecture Decision
```bash
./scripts/llm-council-wrapper.sh \
  "Should we use a monolithic architecture or microservices for a wedding planning app with 100k users?"
```

### Technology Choice
```bash
./scripts/llm-council-wrapper.sh --stage1 \
  "Compare SQLite vs PostgreSQL for local-first macOS app"
```

### Security Question
```bash
./scripts/llm-council-wrapper.sh \
  --timeout=300 \
  --save-log \
  "Best practices for implementing JWT refresh token rotation"
```

## Tips

1. **Use Stage 1 for quick comparisons** - It's faster and more reliable
2. **Increase timeout for complex questions** - Architecture decisions may need 3-5 minutes
3. **Save important decisions** - Use `--save-log` for documentation
4. **Review saved conversations** - Use `council_list_conversations` to access history
5. **Prefer Claude Code CLI** - Most reliable for long-running queries

## Error Handling

The scripts handle common errors:

- **Timeout errors** - Increase `--timeout` value
- **API errors** - Check `OPENROUTER_API_KEY`
- **Network errors** - Retry or use Stage 1 only
- **Invalid model errors** - Verify model IDs on OpenRouter

## Performance

| Mode | Duration | Reliability | Use Case |
|------|----------|-------------|----------|
| Stage 1 | ~30s | ⭐⭐⭐⭐⭐ | Quick comparison |
| Full Council | 30-120s | ⭐⭐⭐⭐ | Synthesized decision |
| Claude Code | Variable | ⭐⭐⭐⭐⭐ | Most reliable |

## Support

If issues persist:
1. Try Stage 1 mode first
2. Use Claude Code CLI instead of Qodo Gen
3. Check OpenRouter status: https://status.openrouter.ai/
4. Verify API key has sufficient credits
