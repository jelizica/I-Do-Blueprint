# 🏛️ LLM Council - Quick Reference

> Multi-model deliberation for architecture decisions with timeout-resistant execution

## 🚀 Quick Start

```bash
# Fastest way (30 seconds)
./scripts/council --stage1 "Your question here"

# Full deliberation (30-120 seconds)
./scripts/council "Your question here"
```

## 📦 Installation

**One-time setup:**
```bash
# Add to ~/.zshrc
alias council='~/Development/nextjs-projects/I\ Do\ Blueprint/scripts/council'
alias council1='~/Development/nextjs-projects/I\ Do\ Blueprint/scripts/council --stage1'

# Then reload
source ~/.zshrc
```

Now use from anywhere:
```bash
council "Should we use microservices or monolith?"
```

## 🎯 Common Use Cases

### Architecture Decisions
```bash
council "Should we split the monolith into microservices?"
council "SQLite vs PostgreSQL for local-first macOS app?"
council "Best state management for React: Redux, Zustand, or Jotai?"
```

### Technology Choices
```bash
council1 "Compare Next.js vs Remix for new project"
council1 "Should we use GraphQL or REST?"
```

### Security Questions
```bash
council --timeout=300 "Best practices for JWT refresh token rotation"
```

## 🛠️ All Commands

| Command | Duration | Use Case |
|---------|----------|----------|
| `council "question"` | 30-120s | Full deliberation with synthesis |
| `council1 "question"` | ~30s | Quick model comparison |
| `council-full "question"` | Up to 5min | Complex architecture decisions |
| `council --save-log "q"` | Variable | Save to logs/llm-council/ |
| `council --help` | Instant | Show all options |

## 🎭 What Happens

### Stage 1 Only (`council1`)
1. Queries 5 frontier models in parallel
2. Returns individual responses
3. Fast (~30 seconds)

### Full Council (`council`)
1. **Stage 1:** Individual responses from all models
2. **Stage 2:** Models rank each other (anonymized)
3. **Stage 3:** Chairman synthesizes final answer
4. Total: 30-120 seconds

## 🤖 Default Models

**Council Members:**
- OpenAI GPT-5.1
- Google Gemini 3 Pro Preview
- Anthropic Claude Sonnet 4.5
- Anthropic Claude Opus 4
- xAI Grok 4

**Chairman:** Google Gemini 3 Pro Preview

## 🔧 Advanced Usage

### Custom Models
```bash
council --models="openai/gpt-5.1,anthropic/claude-opus-4" "Question"
```

### Custom Chairman
```bash
council --chairman="anthropic/claude-opus-4" "Question"
```

### Save Important Decisions
```bash
council --save-log "Critical architecture decision about database sharding"
```

## 🚨 Troubleshooting Qodo Gen Timeouts

### Problem
Qodo Gen times out on long-running queries.

### Solution 1: Use This Script ✅
```bash
./scripts/council "Your question"
```
The script handles timeouts properly.

### Solution 2: Use Claude Code CLI ✅
```
mcp__llm-council__council_query(
  question: "Your question",
  save_conversation: true
)
```
Most reliable method.

### Solution 3: Stage 1 Only ✅
```bash
council1 "Your question"
```
Faster, less likely to timeout.

## 📚 Documentation

- **Full Guide:** [scripts/README-llm-council.md](scripts/README-llm-council.md)
- **Installation:** [scripts/INSTALL.md](scripts/INSTALL.md)
- **Main Docs:** [CLAUDE.md](CLAUDE.md#llm-council-integration)

## 🔑 Environment Setup

Required:
```bash
export OPENROUTER_API_KEY="your-key-here"
```

Get your key: https://openrouter.ai/keys

## 💡 Tips for AI Assistants

When you (AI) need to run LLM Council:

1. **Check if aliases are installed:**
   ```bash
   which council
   ```

2. **If yes, use short command:**
   ```bash
   council "question"
   ```

3. **If no, use full path:**
   ```bash
   ./scripts/council "question"
   ```

4. **Most reliable: Use MCP directly**
   ```
   mcp__llm-council__council_query(question: "...", save_conversation: true)
   ```

5. **For timeout issues, recommend:**
   - Use `council1` for faster queries
   - Increase timeout: `--timeout=300`
   - Use Claude Code CLI instead of Qodo Gen

## 🎬 Example Session

```bash
# Question: Should we use Redis or Memcached for caching?
$ council1 "Redis vs Memcached for session caching in wedding planning app"

# Output shows individual model opinions
# Then synthesizes recommendation
# Takes ~30 seconds

# For complex decision
$ council --timeout=300 --save-log \
  "Design a multi-tenant architecture for wedding planning SaaS"

# Saved to: logs/llm-council/council_20250101_143022.json
```

## 🏃 Next Steps

1. Install aliases (see [scripts/INSTALL.md](scripts/INSTALL.md))
2. Test: `council --help`
3. Try quick query: `council1 "test question"`
4. Read full guide: [scripts/README-llm-council.md](scripts/README-llm-council.md)

---

**Remember:** This is designed to work around Qodo Gen timeout issues. The scripts provide robust timeout handling and graceful error recovery.
