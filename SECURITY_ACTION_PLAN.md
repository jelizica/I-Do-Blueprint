# Security Action Plan - API Key Remediation

**Date:** December 30, 2024  
**Priority:** HIGH  
**Estimated Time:** 30-60 minutes

---

## Quick Summary

TruffleHog found **3 API keys** in your git history (not Stripe - they're for MCP servers):
- OpenRouter API key (AI routing)
- Greb API key (code search)
- Swiftzilla API key (Swift docs)

**Good news:** You already fixed the code (commit 04bc1d27) ✅  
**Remaining work:** Rotate keys + scrub git history

---

## Action Checklist

### Step 1: Rotate API Keys (15 minutes)

#### [ ] OpenRouter
1. Go to: https://openrouter.ai/keys
2. Find key starting with: `sk-or-v1-39a5d293...`
3. Click "Revoke" or "Delete"
4. Generate new key
5. Update `.env.mcp.local`:
   ```bash
   export OPENROUTER_API_KEY="<new-key-here>"
   ```

#### [ ] Greb
1. Go to: https://greb.ai/ (or check your account dashboard)
2. Find key starting with: `grb_7wUw-FX6g...`
3. Revoke old key
4. Generate new key
5. Update `.env.mcp.local`:
   ```bash
   export GREB_API_KEY="<new-key-here>"
   ```

#### [ ] Swiftzilla
1. Check Swiftzilla dashboard or contact support
2. Find key starting with: `sk_live_UtXVNE...`
3. Revoke old key
4. Generate new key
5. Update `.env.mcp.local`:
   ```bash
   export SWIFTZILLA_API_KEY="<new-key-here>"
   ```

#### [ ] Test New Keys
```bash
# Source the updated file
source .env.mcp.local

# Verify they're set
echo $OPENROUTER_API_KEY
echo $GREB_API_KEY
echo $SWIFTZILLA_API_KEY

# Test MCP servers work (optional)
# Try using them in Claude Desktop
```

---

### Step 2: Scrub Git History (20-30 minutes)

**WARNING:** This rewrites git history. Coordinate with team if not working solo!

#### Option A: BFG Repo-Cleaner (Recommended - Faster)

```bash
# 1. Backup first!
cd ~/Development/nextjs-projects
cp -r "I Do Blueprint" "I Do Blueprint.backup"

# 2. Install BFG (if not installed)
brew install bfg

# 3. Create file with keys to remove
cd "I Do Blueprint"
cat > keys-to-remove.txt << 'EOF'
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
grb_7wUw-FX6gLi4vuY1ye7bljB4Gaeve4esWLvPaom_1OaoqEcq
sk_live_UtXVNEldbV1ly0OuhwMhuVMUWNq-gg0ipLU7ytGKwz4
EOF

# 4. Run BFG (replaces keys with ***REMOVED***)
bfg --replace-text keys-to-remove.txt

# 5. Clean up git
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# 6. Verify keys are gone
git log --all -S "sk-or-v1-39a5d293" --oneline
# Should return nothing!

# 7. Force push to GitHub
git push origin --force --all
git push origin --force --tags

# 8. Clean up
rm keys-to-remove.txt
```

#### Option B: git-filter-repo (Alternative)

```bash
# 1. Backup first!
cd ~/Development/nextjs-projects
cp -r "I Do Blueprint" "I Do Blueprint.backup"

# 2. Install git-filter-repo
pip install git-filter-repo

# 3. Create replacement file
cd "I Do Blueprint"
cat > replacements.txt << 'EOF'
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==>***REMOVED-OPENROUTER-KEY***
grb_7wUw-FX6gLi4vuY1ye7bljB4Gaeve4esWLvPaom_1OaoqEcq==>***REMOVED-GREB-KEY***
sk_live_UtXVNEldbV1ly0OuhwMhuVMUWNq-gg0ipLU7ytGKwz4==>***REMOVED-SWIFTZILLA-KEY***
EOF

# 4. Run filter-repo
git filter-repo --replace-text replacements.txt

# 5. Re-add remote (filter-repo removes it)
git remote add origin https://github.com/jelizica/I-Do-Blueprint.git

# 6. Force push
git push origin --force --all
git push origin --force --tags

# 7. Clean up
rm replacements.txt
```

---

### Step 3: Verify & Clean Up (5 minutes)

#### [ ] Verify Keys Are Gone
```bash
# Search for old keys in history
git grep "sk-or-v1-39a5d293" $(git rev-list --all)
git grep "grb_7wUw-FX6g" $(git rev-list --all)
git grep "sk_live_UtXVNE" $(git rev-list --all)

# All should return nothing!
```

#### [ ] Check GitHub
1. Go to: https://github.com/jelizica/I-Do-Blueprint
2. Check recent commits - should see force push
3. Go to: https://github.com/jelizica/I-Do-Blueprint/security
4. Check "Secret scanning alerts" - mark as resolved if any exist

#### [ ] Clean Up Backup (if everything works)
```bash
# Only after verifying everything works!
rm -rf ~/Development/nextjs-projects/"I Do Blueprint.backup"
```

---

### Step 4: Prevention (10 minutes)

#### [ ] Add Pre-commit Hook
```bash
cd "I Do Blueprint"

# Create pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
echo "🔍 Scanning for secrets..."
trufflehog git file://. --since-commit HEAD --only-verified --fail
if [ $? -ne 0 ]; then
    echo "❌ Secret detected! Commit blocked."
    exit 1
fi
echo "✅ No secrets found"
EOF

chmod +x .git/hooks/pre-commit
```

#### [ ] Update Documentation
Add to `SECURITY.md`:
```markdown
## API Key Management

- Never commit API keys to git
- Use `.env.mcp.local` for local development (gitignored)
- Rotate keys immediately if exposed
- Use pre-commit hooks to prevent accidental commits
```

---

## If You're Working with a Team

**BEFORE scrubbing history:**

1. **Notify team:**
   ```
   Subject: Git history rewrite - API key cleanup

   I'm rewriting git history to remove exposed API keys.
   
   Please:
   1. Push all work by [TIME]
   2. After rewrite, delete local repo and re-clone
   3. I'll share new API keys separately
   
   Timeline:
   - [TIME]: Last push
   - [TIME]: History rewrite
   - [TIME]: Safe to re-clone
   ```

2. **After scrubbing:**
   - Share new API keys securely (1Password, encrypted message)
   - Verify everyone re-cloned successfully

---

## If Working Solo

You can proceed immediately! Just make sure:
- [ ] You have backups
- [ ] You're okay with force pushing
- [ ] You understand commit hashes will change

---

## Troubleshooting

### "BFG not found"
```bash
brew install bfg
```

### "git-filter-repo not found"
```bash
pip install git-filter-repo
```

### "Force push rejected"
```bash
# If you have branch protection, temporarily disable it on GitHub:
# Settings > Branches > Edit branch protection rule > Uncheck "Include administrators"
```

### "Keys still in history"
```bash
# Make sure you ran git gc
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Then search again
git log --all -S "sk-or-v1-39a5d293"
```

---

## Questions?

- **How long will this take?** 30-60 minutes total
- **Will I lose code?** No, only keys are removed from history
- **Can I undo this?** Yes, if you kept the backup
- **Do I need to tell my team?** Only if others have cloned the repo
- **What if I skip history scrubbing?** Keys remain accessible in GitHub history

---

## Status Tracking

- [ ] Step 1: Rotate API keys (15 min)
- [ ] Step 2: Scrub git history (20-30 min)
- [ ] Step 3: Verify & clean up (5 min)
- [ ] Step 4: Prevention (10 min)

**Total Time:** 30-60 minutes  
**Priority:** HIGH  
**Difficulty:** Medium

---

## After Completion

Update this checklist in Basic Memory:
- Document completion date
- Note any issues encountered
- Update security documentation
- Schedule next security audit (quarterly)

**Good luck! 🔒**
