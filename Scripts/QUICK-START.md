# LLM Council - Quick Start Guide

> **Problem:** Qodo Gen times out on LLM Council queries
> **Solution:** Use these scripts with proper timeout handling

## ⚡ Fastest Way to Run a Query

```bash
./scripts/council "Your question here"
```

That's it! The script handles timeouts, retries, and error recovery.

## 🎯 Three Ways to Use LLM Council

### 1. Command Line (This Script) ✅ Recommended for Speed
```bash
# Quick comparison (30 seconds)
./scripts/council --stage1 "Redis vs Memcached?"

# Full deliberation (30-120 seconds)
./scripts/council "Architecture question?"
```

### 2. Claude Code CLI ✅ Recommended for Reliability
```
mcp__llm-council__council_query(
  question: "Your question",
  save_conversation: true
)
```

### 3. Python Script
```bash
python3 scripts/llm-council-query.py "Your question"
```

## 🔥 Most Common Commands

```bash
# Basic query
./scripts/council "Should we use microservices?"

# Fast query (Stage 1 only - no synthesis)
./scripts/council --stage1 "Compare Next.js vs Remix"

# Long query (extend timeout)
./scripts/council --timeout=300 "Complex architecture question"

# Save to log
./scripts/council --save-log "Important decision"

# Help
./scripts/council --help
```

## 📁 What You Get

When you run `./scripts/council "question"`:

1. **Stage 1 Only** (`--stage1`):
   - Individual responses from 5 frontier models
   - Fast (~30 seconds)
   - Great for quick comparisons

2. **Full Council** (default):
   - Stage 1: Individual responses
   - Stage 2: Models rank each other
   - Stage 3: Chairman synthesizes final answer
   - Comprehensive (30-120 seconds)

## 💻 Installation for Convenience

Add to `~/.zshrc`:

```bash
# Short aliases
alias council='~/Development/nextjs-projects/I\ Do\ Blueprint/scripts/council'
alias council1='~/Development/nextjs-projects/I\ Do\ Blueprint/scripts/council --stage1'

# Then reload
source ~/.zshrc
```

Now use from anywhere:
```bash
council "Your question"
```

## 🎓 Examples

### Architecture Decisions
```bash
./scripts/council "Monolith vs microservices for 100k user app?"
```

### Technology Choices
```bash
./scripts/council --stage1 "PostgreSQL vs MongoDB for wedding planning?"
```

### Performance Questions
```bash
./scripts/council "Best caching strategy for real-time collaboration?"
```

### Security Decisions
```bash
./scripts/council --timeout=300 "JWT refresh token rotation best practices?"
```

## 🛠️ All Available Scripts

| Script | Purpose |
|--------|---------|
| `council` | Main shortcut (calls wrapper) |
| `llm-council-wrapper.sh` | Full-featured bash wrapper |
| `llm-council-query.py` | Python version with colors |
| `llm-council-query.sh` | Basic bash implementation |
| `.council-examples.sh` | Example queries |

## 🚨 Troubleshooting

### Timeouts in Qodo Gen
**Solution:** Use this script instead
```bash
./scripts/council "Your question"
```

### Still timing out?
**Solution:** Use Stage 1 only
```bash
./scripts/council --stage1 "Your question"
```

### Need more time?
**Solution:** Increase timeout
```bash
./scripts/council --timeout=300 "Your question"
```

### Most reliable?
**Solution:** Use Claude Code CLI
```
mcp__llm-council__council_query(question: "...", save_conversation: true)
```

## 🔑 Environment Setup

Required environment variable:
```bash
export OPENROUTER_API_KEY="your-key-here"
```

Add to `~/.zshrc` or `~/.bashrc` for persistence.

Get your key: https://openrouter.ai/keys

## 📊 Performance Comparison

| Method | Speed | Reliability | Use When |
|--------|-------|-------------|----------|
| Stage 1 (`--stage1`) | ⚡⚡⚡ | ⭐⭐⭐⭐⭐ | Quick comparison |
| Full Council | ⚡⚡ | ⭐⭐⭐⭐ | Need synthesis |
| Claude Code CLI | ⚡⚡ | ⭐⭐⭐⭐⭐ | Maximum reliability |
| Qodo Gen | ⚡⚡ | ⭐⭐ | ❌ Times out |

## 📚 More Info

- **This Guide:** Quick start commands
- **Full Guide:** [README-llm-council.md](README-llm-council.md)
- **Installation:** [INSTALL.md](INSTALL.md)
- **Main Docs:** [../LLM-COUNCIL.md](../LLM-COUNCIL.md)

## 🎬 Try It Now

```bash
# Test with a simple question
./scripts/council --stage1 "What is the difference between REST and GraphQL?"

# Should complete in ~30 seconds
# Shows individual model responses
```

## ✅ Verification

The script is working if you see:
- Colorful formatted output
- "MCP Tool Call" section showing the query
- "EXECUTION INSTRUCTIONS" with Claude Code command
- No timeout errors

## 🤝 For AI Assistants Reading This

When you need to run LLM Council:

1. **Check if user has it installed:**
   ```bash
   which council
   ```

2. **If installed, use short command:**
   ```bash
   council "question"
   ```

3. **If not installed, use full path:**
   ```bash
   ./scripts/council "question"
   ```

4. **Most reliable: MCP direct call**
   ```
   mcp__llm-council__council_query(question: "...", save_conversation: true)
   ```

5. **For Qodo Gen timeout issues:**
   - Recommend this script
   - Use `--stage1` for faster queries
   - Suggest Claude Code CLI as alternative

---

**That's it!** You now have timeout-resistant LLM Council queries. 🎉
