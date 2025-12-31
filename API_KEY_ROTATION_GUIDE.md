# API Key Rotation Guide

**Quick reference for rotating your MCP API keys**

---

## ✅ Your Setup is Perfect!

You're using **direnv + .env.mcp.local** which is the recommended approach:

```
.envrc (committed) → loads → .env.mcp.local (gitignored, has keys)
```

**Benefits:**
- ✅ Automatic loading when you `cd` into directory
- ✅ Automatic unloading when you leave
- ✅ MCP servers can access the keys
- ✅ Keys never committed to git
- ✅ Pre-commit hook prevents accidents

---

## 🔄 How to Rotate Keys

### 1. OpenRouter API Key

```bash
# Go to: https://openrouter.ai/keys

# Steps:
1. Sign in to OpenRouter
2. Go to "API Keys" section
3. Find key starting with: sk-or-v1-39a5d293...
4. Click "Revoke" or "Delete"
5. Click "Create New Key"
6. Copy the new key

# Update .env.mcp.local:
nano .env.mcp.local
# Change line:
export OPENROUTER_API_KEY="sk-or-v1-NEW-KEY-HERE"
```

### 2. Greb API Key

```bash
# Go to: https://greb.ai/

# Steps:
1. Sign in to Greb
2. Navigate to API Keys or Account Settings
3. Find key starting with: grb_7wUw-FX6g...
4. Revoke old key
5. Generate new key
6. Copy the new key

# Update .env.mcp.local:
nano .env.mcp.local
# Change line:
export GREB_API_KEY="grb_NEW-KEY-HERE"
```

### 3. Swiftzilla API Key

```bash
# Go to: Swiftzilla dashboard or contact support

# Steps:
1. Access Swiftzilla account
2. Find API Keys section
3. Find key starting with: sk_live_UtXVNE...
4. Revoke old key
5. Generate new key
6. Copy the new key

# Update .env.mcp.local:
nano .env.mcp.local
# Change line:
export SWIFTZILLA_API_KEY="sk_live_NEW-KEY-HERE"
```

---

## 🔄 After Rotating Keys

### Reload Environment

```bash
# Option 1: Exit and re-enter directory (easiest)
cd ..
cd "I Do Blueprint"
# direnv will automatically reload

# Option 2: Manual reload
direnv reload

# Option 3: Manual source
source .env.mcp.local
```

### Verify Keys Loaded

```bash
# Check each key is set
echo $OPENROUTER_API_KEY
echo $GREB_API_KEY
echo $SWIFTZILLA_API_KEY

# All should show your new keys
```

### Test MCP Servers

1. **Restart Claude Desktop** (important!)
2. Try using each MCP server:
   - ADR Analysis (uses OpenRouter)
   - Grep MCP (uses Greb)
   - Swiftzilla (uses Swiftzilla)
3. Verify they work with new keys

---

## 📝 Your .env.mcp.local File

Location: `/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint/.env.mcp.local`

Current structure:
```bash
# MCP Server Environment Variables
# DO NOT COMMIT THIS FILE - It's in .gitignore
# Source this file: source .env.mcp.local

export OPENROUTER_API_KEY="your-openrouter-key-here"
export GREB_API_KEY="your-greb-key-here"
export SWIFTZILLA_API_KEY="your-swiftzilla-key-here"
export PROJECT_PATH="/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint"
```

**To edit:**
```bash
nano .env.mcp.local
# or
code .env.mcp.local
# or
open -e .env.mcp.local
```

---

## 🛡️ Pre-commit Hook

**Status:** ✅ Installed and working!

**What it does:**
- Scans staged files for secrets with TruffleHog
- Blocks commits of .env files
- Warns about Config.plist changes

**Test it:**
```bash
.git/hooks/pre-commit

# Should show:
# 🔍 Running security checks...
#   → Scanning for secrets with TruffleHog...
#   → Checking for .env files...
#   → Checking for Config.plist...
# ✅ Security checks passed!
```

---

## ❓ Troubleshooting

### Keys not loading?

```bash
# Check direnv is working
direnv status

# Allow .envrc
direnv allow

# Reload
direnv reload
```

### MCP servers not working?

```bash
# 1. Verify keys in environment
env | grep -E "OPENROUTER|GREB|SWIFTZILLA"

# 2. Check .mcp.json uses variables (not hardcoded)
grep -E "API_KEY" .mcp.json
# Should show: "${OPENROUTER_API_KEY}"

# 3. Restart Claude Desktop
# Keys are loaded when Claude starts
```

### Pre-commit hook blocking legitimate commits?

```bash
# Check what was detected
trufflehog filesystem <file> --only-verified

# If false positive, bypass once
git commit --no-verify -m "message"
```

---

## 📋 Checklist

After rotating keys:

- [ ] Updated OPENROUTER_API_KEY in .env.mcp.local
- [ ] Updated GREB_API_KEY in .env.mcp.local
- [ ] Updated SWIFTZILLA_API_KEY in .env.mcp.local
- [ ] Reloaded environment (cd out and back in)
- [ ] Verified keys with `echo $VARIABLE_NAME`
- [ ] Restarted Claude Desktop
- [ ] Tested each MCP server
- [ ] Confirmed pre-commit hook still works
- [ ] Documented rotation date (below)

**Last Rotation:** _________________  
**Next Rotation:** _________________ (3 months from now)

---

## 🔗 Related Files

- **Environment config:** `.env.mcp.local` (your keys)
- **direnv config:** `.envrc` (auto-loader)
- **MCP config:** `.mcp.json` (uses ${VARIABLES})
- **Pre-commit hook:** `.git/hooks/pre-commit`
- **Gitignore:** `.gitignore` (protects .env files)

---

## 📚 Full Documentation

For complete details, see Basic Memory:
- `security/API Key Management Guide - direnv + Pre-commit Hooks.md`
- `security/Git History Scrubbing Complete - December 2024.md`
- `security/TruffleHog Security Scan - December 2024.md`

---

**Quick Start:** Just update the three keys in `.env.mcp.local`, then `cd .. && cd "I Do Blueprint"` to reload!
