# Claude Code Configuration Security Setup

**Date:** December 29, 2024  
**Status:** ✅ Completed

---

## What Was Done

Migrated API keys from hardcoded values in `.claude.json` to environment variables for better security.

### Changes Made

1. **Added environment variables to `~/.zshrc`**:
   ```bash
   export OPENROUTER_API_KEY="your-new-openrouter-key-here"
   export GREB_API_KEY="your-new-greb-key-here"
   export SWIFTZILLA_API_KEY="your-new-swiftzilla-key-here"
   export PREDEV_API_KEY="your-predev-key-here"
   ```

2. **Updated `.claude.json` to reference environment variables**:
   - `adr-analysis` → `${OPENROUTER_API_KEY}`
   - `greb-mcp` → `${GREB_API_KEY}`
   - `swiftzilla` → `${SWIFTZILLA_API_KEY}`
   - `predev` → `${PREDEV_API_KEY}`

---

## Next Steps for You

### 1. Add Your Rotated API Keys

Edit your `~/.zshrc` file and replace the placeholder values:

```bash
nano ~/.zshrc
# or
code ~/.zshrc
```

Find these lines (at the bottom of the file):

```bash
# ============================================
# Claude Code MCP Server API Keys
# Added: 2024-12-29
# ============================================
export OPENROUTER_API_KEY="your-new-openrouter-key-here"
export GREB_API_KEY="your-new-greb-key-here"
export SWIFTZILLA_API_KEY="your-new-swiftzilla-key-here"
export PREDEV_API_KEY="your-predev-key-here"
```

Replace each `"your-new-...-key-here"` with your actual rotated API keys.

### 2. Reload Your Shell

After saving the file:

```bash
source ~/.zshrc
```

### 3. Verify Environment Variables Are Set

```bash
echo $OPENROUTER_API_KEY
echo $GREB_API_KEY
echo $SWIFTZILLA_API_KEY
echo $PREDEV_API_KEY
```

Each should display your API key (not the placeholder text).

### 4. Test Claude Code

Restart Claude Code and test each MCP server:

```bash
# Restart Claude Code completely
# Then try using:
# - ADR Analysis (uses OpenRouter)
# - Grep MCP (uses Greb)
# - Swiftzilla (uses Swiftzilla)
# - Predev (uses Predev)
```

---

## Security Benefits

✅ **API keys no longer stored in plain text** in `.claude.json`  
✅ **Environment variables loaded from shell profile** (not committed to git)  
✅ **Easier key rotation** - just update `~/.zshrc` and reload  
✅ **Consistent with project's existing security practices** (like `.env.mcp.local`)

---

## File Locations

| File | Purpose | Committed to Git? |
|------|---------|-------------------|
| `~/.claude.json` | Claude Code config with `${VARIABLE}` references | No (global file) |
| `~/.zshrc` | Shell profile with actual API key values | No (global file) |
| `Scripts/update_claude_config.py` | Script that performed the migration | Yes |
| `docs/CLAUDE_CONFIG_SECURITY_SETUP.md` | This documentation | Yes |

---

## Troubleshooting

### MCP Servers Not Working?

1. **Check environment variables are set**:
   ```bash
   env | grep -E "OPENROUTER|GREB|SWIFTZILLA|PREDEV"
   ```

2. **Verify `.claude.json` uses variables**:
   ```bash
   grep -E "API_KEY|Authorization" ~/.claude.json
   ```
   Should show `${VARIABLE_NAME}`, not actual keys.

3. **Restart Claude Code completely** - environment variables are loaded at startup.

### Keys Not Loading?

Make sure you:
- Saved `~/.zshrc` after editing
- Ran `source ~/.zshrc` to reload
- Restarted Claude Code (not just the current session)

### Still See Hardcoded Keys?

Run the migration script again:
```bash
python3 Scripts/update_claude_config.py
```

---

## Related Documentation

- **API Key Rotation Guide**: `API_KEY_ROTATION_GUIDE.md`
- **Security Action Plan**: `SECURITY_ACTION_PLAN.md`
- **Git History Scrubbing**: `GIT_HISTORY_SCRUBBING_COMPLETE.md`

---

## Why Not direnv?

**Question**: Should we use direnv for `.claude.json`?

**Answer**: No, because:
1. `.claude.json` is a **global config file** (`~/.claude.json`), not project-specific
2. direnv only loads when you `cd` into a directory
3. Claude Code reads `.claude.json` directly on startup, not from environment
4. Shell profile (`~/.zshrc`) is the correct place for global environment variables

**direnv is still used** for project-specific variables in `.env.mcp.local` (which is the right approach for that use case).

---

**Status**: ✅ Migration complete. Just add your rotated keys to `~/.zshrc` and reload!
