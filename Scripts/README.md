# Scripts Directory

Collection of automation scripts for the I Do Blueprint project.

## 🏛️ LLM Council (Multi-Model Deliberation)

Run architecture decisions through multiple frontier AI models to avoid Qodo Gen timeouts.

**Quick Start:**
```bash
./scripts/council "Your question here"
```

**Documentation:**
- [QUICK-START.md](QUICK-START.md) - Start here! ⭐
- [README-llm-council.md](README-llm-council.md) - Full usage guide
- [INSTALL.md](INSTALL.md) - Shell alias setup
- [../LLM-COUNCIL.md](../LLM-COUNCIL.md) - Quick reference card

**Files:**
- `council` - Main shortcut
- `llm-council-wrapper.sh` - Full bash wrapper
- `llm-council-query.py` - Python version
- `test-council.sh` - Installation test

## 🤖 For AI Assistants

When you need LLM Council:

```bash
# Most reliable: use MCP directly
mcp__llm-council__council_query(question: "...", save_conversation: true)

# Alternative: use script
./scripts/council "question"
```

See [QUICK-START.md](QUICK-START.md) for full details.

---

**Need help?** Run `./scripts/council --help`

---

## 🏛️ LLM Council Integration

Run multi-model architecture deliberations with proper timeout handling.

**Quick Start:**
```bash
./scripts/council "Your question here"
```

**Why?** Qodo Gen times out on LLM Council queries. These scripts provide robust timeout handling and error recovery.

**Documentation:**
- **[QUICK-START.md](QUICK-START.md)** - Start here! ⭐
- **[README-llm-council.md](README-llm-council.md)** - Full usage guide  
- **[INSTALL.md](INSTALL.md)** - Shell alias setup
- **[../LLM-COUNCIL.md](../LLM-COUNCIL.md)** - Quick reference card

**Available Commands:**
```bash
# Quick comparison (30s, Stage 1 only)
./scripts/council --stage1 "Redis vs Memcached?"

# Full deliberation (30-120s, 3 stages)
./scripts/council "Architecture question?"

# Extended timeout for complex questions
./scripts/council --timeout=300 "Complex decision?"

# Save to log
./scripts/council --save-log "Important decision"

# Help
./scripts/council --help

# Test installation
./scripts/test-council.sh
```

**For AI Assistants:**

When you need LLM Council, use MCP directly (most reliable):
```
mcp__llm-council__council_query(
  question: "Your question",
  save_conversation: true
)
```

Or use the script as a fallback:
```bash
./scripts/council "Your question"
```

**See [QUICK-START.md](QUICK-START.md) for complete details.**

