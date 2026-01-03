---
title: API Key Management Guide - direnv + Pre-commit Hooks
type: note
permalink: security/api-key-management-guide-direnv-pre-commit-hooks
tags:
- security
- api-keys
- direnv
- pre-commit
- hooks
- environment-variables
- best-practices
---

# API Key Management Guide

**Date:** December 30, 2024  
**Project:** I Do Blueprint  
**Status:** ✅ CONFIGURED

---

## Overview

This guide documents the API key management strategy for the I Do Blueprint project, including the use of direnv for automatic environment loading and pre-commit hooks for secret detection.

---

## Architecture: direnv + .env.mcp.local

### How It Works

```
┌─────────────────────────────────────────────────────┐
│  You cd into project directory                      │
└────────────────┬────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────┐
│  direnv automatically runs .envrc                   │
└────────────────┬─────���──────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────┐
│  .envrc loads .env.mcp.local                        │
└────────────────┬────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────┐
│  Environment variables available to:                │
│  - MCP servers                                      │
│  - Shell commands                                   │
│  - Development tools                                │
└─────────────────────────────────────────────────────┘
```

### File Structure

```
I Do Blueprint/
├── .envrc                    # Committed - loads .env.mcp.local
├── .env.mcp.local           # Gitignored - contains actual keys
├── .env.example             # Committed - template for team
└── .gitignore               # Contains: .env, .env.*, !.env.example
```

---

## Current Configuration

### .envrc (Committed to Git)

```bash
# direnv configuration for I Do Blueprint
# Automatically loads MCP environment variables when entering this directory

# Load MCP API keys and configuration
if [ -f .env.mcp.local ]; then
    source_env .env.mcp.local
    echo "✅ MCP environment loaded (direnv)"
else
    echo "⚠️  Warning: .env.mcp.local not found"
fi
```

**Purpose:**
- Automatically loads environment variables when entering directory
- Provides feedback on successful loading
- Warns if .env.mcp.local is missing
- Safe to commit (contains no secrets)

### .env.mcp.local (Gitignored)

```bash
# MCP Server Environment Variables
# DO NOT COMMIT THIS FILE - It's in .gitignore
# Source this file: source .env.mcp.local

export OPENROUTER_API_KEY="your-openrouter-key-here"
export GREB_API_KEY="your-greb-key-here"
export SWIFTZILLA_API_KEY="your-swiftzilla-key-here"
export PROJECT_PATH="/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint"
```

**Purpose:**
- Stores actual API keys
- Never committed to git
- Loaded automatically by direnv
- Each developer has their own copy

### .gitignore (Committed to Git)

```
.env
.env.*
!.env.example
```

**Purpose:**
- Prevents .env files from being committed
- Allows .env.example to be committed
- Protects all .env.* variants

---

## Why This Approach?

### ✅ Advantages

1. **Automatic Loading**
   - Keys available immediately when entering directory
   - No manual `source` commands needed
   - Consistent across terminal sessions

2. **Automatic Unloading**
   - Keys removed when leaving directory
   - Prevents key leakage to other projects
   - Clean environment isolation

3. **MCP Compatibility**
   - MCP servers can access environment variables
   - Works with Claude Desktop
   - No special configuration needed

4. **Team Friendly**
   - `.envrc` can be shared (no secrets)
   - `.env.example` provides template
   - Each developer manages their own keys

5. **Security**
   - Keys never committed
   - Pre-commit hooks prevent accidents
   - Single source of truth

### ❌ Alternative Approaches (Not Recommended)

**Putting keys directly in .envrc:**
- ❌ .envrc is often committed
- ❌ Would expose keys if accidentally committed
- ❌ Harder to manage per-developer keys

**Using shell profile (~/.zshrc):**
- ❌ Keys available globally (security risk)
- ❌ Not project-specific
- ❌ Harder to manage multiple projects

**Hardcoding in .mcp.json:**
- ❌ Already fixed this issue!
- ❌ Keys would be committed
- ❌ No flexibility per developer

---

## Pre-commit Hook

### Purpose

Prevents accidental commits of secrets by:
1. Scanning staged files with TruffleHog
2. Blocking .env file commits
3. Warning about Config.plist changes

### Installation

Already installed at: `.git/hooks/pre-commit`

### How It Works

```bash
#!/bin/bash

echo "🔍 Running security checks..."

# Check 1: TruffleHog scan for secrets
echo "  → Scanning for secrets with TruffleHog..."
if command -v trufflehog &> /dev/null; then
    # Scan only staged files
    STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)
    
    if [ -n "$STAGED_FILES" ]; then
        for file in $STAGED_FILES; do
            if [ -f "$file" ]; then
                if trufflehog filesystem "$file" --only-verified 2>&1 | grep -q "🐷🔑🐷"; then
                    echo "❌ SECRET DETECTED in $file! Commit blocked."
                    exit 1
                fi
            fi
        done
    fi
fi

# Check 2: Prevent committing .env files
echo "  → Checking for .env files..."
if git diff --cached --name-only | grep -E "\.env\..*|\.env$" | grep -v "\.env\.example"; then
    echo "❌ BLOCKED: Attempting to commit .env file!"
    exit 1
fi

# Check 3: Warn about Config.plist
echo "  → Checking for Config.plist..."
if git diff --cached --name-only | grep -q "Config.plist"; then
    echo "⚠️  WARNING: Config.plist is being committed"
    read -p "   Continue anyway? (y/N) " -n 1 -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "✅ Security checks passed!"
exit 0
```

### Testing

```bash
# Test the hook (should pass with no staged files)
.git/hooks/pre-commit

# Expected output:
# 🔍 Running security checks...
#   → Scanning for secrets with TruffleHog...
#   → Checking for .env files...
#   → Checking for Config.plist...
# ✅ Security checks passed!
```

### What It Blocks

1. **Verified Secrets**
   - API keys
   - Passwords
   - Tokens
   - Private keys

2. **.env Files**
   - `.env`
   - `.env.local`
   - `.env.mcp.local`
   - Any `.env.*` except `.env.example`

3. **Config.plist (with warning)**
   - Prompts for confirmation
   - Allows override if needed

---

## API Key Rotation Workflow

### When to Rotate

- **Immediately:** After exposure in git history
- **Quarterly:** Regular security practice
- **On team changes:** When developers leave
- **After incidents:** Security breaches or concerns

### How to Rotate

#### 1. OpenRouter

```bash
# 1. Go to https://openrouter.ai/keys
# 2. Find old key: sk-or-v1-39a5d293...
# 3. Click "Revoke" or "Delete"
# 4. Click "Create New Key"
# 5. Copy new key
# 6. Update .env.mcp.local:
export OPENROUTER_API_KEY="sk-or-v1-NEW-KEY-HERE"
```

#### 2. Greb

```bash
# 1. Go to https://greb.ai/
# 2. Navigate to API Keys section
# 3. Find old key: grb_7wUw-FX6g...
# 4. Revoke old key
# 5. Generate new key
# 6. Update .env.mcp.local:
export GREB_API_KEY="grb_NEW-KEY-HERE"
```

#### 3. Swiftzilla

```bash
# 1. Check Swiftzilla dashboard or contact support
# 2. Find old key: sk_live_UtXVNE...
# 3. Revoke old key
# 4. Generate new key
# 5. Update .env.mcp.local:
export SWIFTZILLA_API_KEY="sk_live_NEW-KEY-HERE"
```

#### 4. Reload Environment

```bash
# Option 1: Exit and re-enter directory (direnv auto-loads)
cd ..
cd "I Do Blueprint"

# Option 2: Manual reload
direnv reload

# Option 3: Manual source
source .env.mcp.local

# Verify keys are loaded
echo $OPENROUTER_API_KEY
echo $GREB_API_KEY
echo $SWIFTZILLA_API_KEY
```

#### 5. Test MCP Servers

```bash
# Test in Claude Desktop
# Try using each MCP server to verify they work with new keys
```

---

## Troubleshooting

### direnv not loading

**Symptom:** Environment variables not available

**Solutions:**
```bash
# 1. Check if direnv is installed
which direnv

# 2. Check if .envrc is allowed
direnv allow

# 3. Manually reload
direnv reload

# 4. Check .envrc syntax
cat .envrc
```

### MCP servers can't access keys

**Symptom:** MCP servers fail with authentication errors

**Solutions:**
```bash
# 1. Verify keys are in environment
env | grep -E "OPENROUTER|GREB|SWIFTZILLA"

# 2. Check .mcp.json uses environment variables
grep -E "API_KEY" .mcp.json
# Should show: "${OPENROUTER_API_KEY}" not hardcoded keys

# 3. Restart Claude Desktop
# Environment variables are loaded when Claude starts
```

### Pre-commit hook not running

**Symptom:** Commits succeed without security checks

**Solutions:**
```bash
# 1. Check if hook exists
ls -la .git/hooks/pre-commit

# 2. Check if executable
chmod +x .git/hooks/pre-commit

# 3. Test manually
.git/hooks/pre-commit

# 4. Check for errors
bash -x .git/hooks/pre-commit
```

### TruffleHog false positives

**Symptom:** Hook blocks legitimate commits

**Solutions:**
```bash
# 1. Check what TruffleHog found
trufflehog filesystem <file> --only-verified

# 2. If false positive, temporarily disable
git commit --no-verify -m "message"

# 3. Update hook to exclude specific patterns
# Edit .git/hooks/pre-commit
```

---

## Best Practices

### DO ✅

1. **Use direnv + .env.mcp.local**
   - Automatic loading
   - Project-specific
   - Secure

2. **Keep .envrc simple**
   - Just load .env.mcp.local
   - No secrets
   - Safe to commit

3. **Rotate keys regularly**
   - After exposure
   - Quarterly schedule
   - Document rotations

4. **Test after rotation**
   - Verify environment loading
   - Test MCP servers
   - Check functionality

5. **Document for team**
   - Provide .env.example
   - Update README
   - Share rotation process

### DON'T ❌

1. **Don't put keys in .envrc**
   - .envrc is often committed
   - Use .env.mcp.local instead

2. **Don't commit .env files**
   - Pre-commit hook prevents this
   - But be vigilant

3. **Don't share keys**
   - Each developer gets their own
   - Use secure channels if needed

4. **Don't skip pre-commit checks**
   - Use `--no-verify` sparingly
   - Investigate blocked commits

5. **Don't hardcode keys**
   - Always use environment variables
   - Never in .mcp.json or code

---

## Team Onboarding

### For New Developers

1. **Clone repository**
   ```bash
   git clone https://github.com/jelizica/I-Do-Blueprint.git
   cd "I Do Blueprint"
   ```

2. **Install direnv**
   ```bash
   brew install direnv
   
   # Add to ~/.zshrc
   eval "$(direnv hook zsh)"
   
   # Reload shell
   source ~/.zshrc
   ```

3. **Create .env.mcp.local**
   ```bash
   cp .env.example .env.mcp.local
   ```

4. **Get API keys**
   - OpenRouter: https://openrouter.ai/keys
   - Greb: https://greb.ai/
   - Swiftzilla: Contact team lead

5. **Update .env.mcp.local**
   ```bash
   # Edit with your keys
   nano .env.mcp.local
   ```

6. **Allow direnv**
   ```bash
   direnv allow
   ```

7. **Verify setup**
   ```bash
   echo $OPENROUTER_API_KEY
   # Should show your key
   ```

---

## Security Checklist

- [x] .env.mcp.local in .gitignore
- [x] .envrc loads .env.mcp.local
- [x] Pre-commit hook installed
- [x] TruffleHog scanning enabled
- [x] .env file blocking enabled
- [x] Config.plist warnings enabled
- [x] Git history scrubbed
- [ ] API keys rotated (NEXT STEP)
- [ ] Team onboarding documented
- [ ] Quarterly rotation scheduled

---

## Related Documentation

- **Git History Scrubbing:** `security/Git History Scrubbing Complete - December 2024.md`
- **TruffleHog Analysis:** `security/TruffleHog Security Scan - December 2024.md`
- **Best Practices:** `best_practices.md`
- **MCP Setup:** `MCP_SETUP.md`

---

## Maintenance

### Monthly
- [ ] Verify pre-commit hook is working
- [ ] Check for TruffleHog updates
- [ ] Review .gitignore effectiveness

### Quarterly
- [ ] Rotate all API keys
- [ ] Audit environment variable usage
- [ ] Update documentation

### Annually
- [ ] Full security audit
- [ ] Review and update practices
- [ ] Team training on security

---

**Status:** ✅ Fully configured and documented  
**Last Updated:** December 30, 2024  
**Next Action:** Rotate API keys
