# Repository Cleanup - Summary & Next Steps

## ✅ What's Been Done

1. **Comprehensive Cleanup Plan Created**
   - Detailed analysis in [GITHUB_REPO_CLEANUP_PLAN.md](GITHUB_REPO_CLEANUP_PLAN.md)
   - Identifies all 370+ files to delete
   - Provides step-by-step execution plan
   - Includes security audit procedures

2. **New README.md Written**
   - Professional, app-focused documentation
   - Clear setup instructions
   - Comprehensive feature list
   - Architecture overview
   - Contributing guidelines

3. **Automated Cleanup Script Created**
   - Interactive script: [Scripts/cleanup-repo.sh](Scripts/cleanup-repo.sh)
   - Handles all 8 phases automatically
   - Includes safety checks and confirmations
   - Creates backup before proceeding

## 📊 Cleanup Impact

### Files
- **Before:** 1,435 tracked files
- **After:** ~1,065 tracked files
- **Reduction:** 370 files (26%)

### Categories Removed
- AI assistant configs (`.beads/`, `.ccg/`, `.claude/`, `.gemini/`, `.qodo/`)
- Personal knowledge base (`knowledge-repo-bm/`, `_project_specs/`)
- Development documentation (22 root `.md` files, entire `docs/` directory)
- Security scan results (`trufflehog_results.json`)
- Development logs and temp files
- Non-essential scripts (LLM Council, diagram generation)
- Semgrep rules (`.semgrep/`)

### What's Preserved
- ✅ All app source code (1,011 files)
- ✅ All tests (54 files)
- ✅ Xcode project configuration
- ✅ Database migrations (51 migrations)
- ✅ Essential scripts (5 production utilities)
- ✅ Core configuration files

## 🚀 Next Steps - Choose Your Approach

### Option 1: Automated Cleanup (Recommended)

**Run the automated script:**

```bash
./Scripts/cleanup-repo.sh
```

**The script will:**
1. Run security audit
2. Create backup at `../I Do Blueprint.backup`
3. Scrub git history with BFG
4. Remove all tracked files
5. Update .gitignore
6. Commit changes
7. Verify cleanup
8. Prompt for force push

**Time:** ~10-15 minutes (mostly git history scrubbing)

### Option 2: Manual Execution

**Follow the detailed plan:**

1. Open [GITHUB_REPO_CLEANUP_PLAN.md](GITHUB_REPO_CLEANUP_PLAN.md)
2. Execute each phase manually
3. Copy/paste commands from the plan

**Time:** ~30-45 minutes

## ⚠️  Important Warnings

### Before Running Cleanup

1. **Review Security Audit Results**
   - Check for secrets in files being deleted
   - Ensure no production credentials are committed

2. **Backup Your Work**
   - Script creates backup automatically
   - Or manually: `cp -r "../I Do Blueprint" "../I Do Blueprint.backup"`

3. **Notify Collaborators**
   - Git history will be rewritten
   - Everyone must delete and re-clone repository

### After Cleanup Pushed

**All collaborators MUST:**

```bash
# 1. Backup local changes
git stash

# 2. Delete local repository
cd ..
rm -rf "I Do Blueprint"

# 3. Fresh clone
git clone <repository-url>

# 4. DO NOT try to pull/merge
```

## 📋 Pre-Execution Checklist

- [ ] Read [GITHUB_REPO_CLEANUP_PLAN.md](GITHUB_REPO_CLEANUP_PLAN.md) completely
- [ ] Reviewed new [README.md](README.md)
- [ ] Verified BFG is installed: `brew install bfg`
- [ ] Committed any pending work
- [ ] Ready to rewrite git history
- [ ] Ready to notify collaborators
- [ ] Backup plan in place

## 🔐 Security Considerations

### High-Priority Files to Audit

Before executing cleanup, manually check these for secrets:

1. **`.beads/interactions.jsonl`** - AI conversation logs
2. **`trufflehog_results.json`** - Security scan results
3. **`.ccg/memory.db`** - Development history
4. **`.mcp.json`** - MCP server configs
5. **`.env.mcp.local`** - Local environment config

**Audit Command:**
```bash
# Check for common secret patterns
grep -r -i -E '(api[_-]?key|secret|password|token|sk-|eyJ)' \
  .beads/ .ccg/ .mcp.json .env.mcp.local _project_specs/ knowledge-repo-bm/ \
  2>/dev/null | grep -v ".git"
```

## 📁 Final Repository Structure

After cleanup, your repository will contain:

```
I Do Blueprint/
├── .github/workflows/tests.yml   # CI/CD
├── I Do Blueprint/               # App source (1,011 files)
├── I Do BlueprintTests/          # Unit tests (54 files)
├── I Do BlueprintUITests/        # UI tests
├── I Do Blueprint.xcodeproj/    # Xcode project
├── Scripts/                      # 5 essential scripts
├── supabase/
│   ├── functions/                # Edge functions
│   └── migrations/               # 51 database migrations
├── .env.example
├── .gitattributes
├── .gitignore                    # Updated with exclusions
├── .swiftlint.yml
├── apple-app-site-association
└── README.md                     # New app-focused README

Total: ~1,065 files (down from 1,435)
```

## 🎯 Success Criteria

After cleanup and push, verify:

- [ ] Repository builds successfully: `xcodebuild build ...`
- [ ] Tests pass: `xcodebuild test ...`
- [ ] File count: ~1,065 tracked files
- [ ] No sensitive files: `git ls-files | grep -E '(\.beads|\.mcp\.json|trufflehog)'` returns nothing
- [ ] CI/CD passes on GitHub
- [ ] Repository size reduced significantly

## 🆘 Troubleshooting

### If Something Goes Wrong

**Restore from backup:**
```bash
cd ..
rm -rf "I Do Blueprint"
cp -r "I Do Blueprint.backup" "I Do Blueprint"
cd "I Do Blueprint"
```

**Reset last commit (if not pushed):**
```bash
git reset --hard HEAD~1
```

**Undo force push (dangerous):**
```bash
# Only if absolutely necessary and you have the old commit SHA
git reset --hard <old-commit-sha>
git push --force-with-lease origin main
```

### Common Issues

**BFG not found:**
```bash
brew install bfg
```

**Permission denied on script:**
```bash
chmod +x Scripts/cleanup-repo.sh
```

**Files still appearing in history:**
```bash
# Re-run BFG commands from the plan
# Then: git reflog expire --expire=now --all
#       git gc --prune=now --aggressive
```

## 📞 Need Help?

If you encounter issues:

1. **Review the detailed plan:** [GITHUB_REPO_CLEANUP_PLAN.md](GITHUB_REPO_CLEANUP_PLAN.md)
2. **Check the backup:** `../I Do Blueprint.backup`
3. **Restore if needed:** See troubleshooting section above

## 🎉 After Successful Cleanup

1. **Notify collaborators** of git history rewrite
2. **Verify CI/CD pipeline** passes
3. **Test app functionality** locally
4. **Update project documentation** if needed
5. **Delete backup** after confirming everything works: `rm -rf "../I Do Blueprint.backup"`

---

**Ready to proceed?**

Run the automated script:
```bash
./Scripts/cleanup-repo.sh
```

Or follow the manual plan in [GITHUB_REPO_CLEANUP_PLAN.md](GITHUB_REPO_CLEANUP_PLAN.md).

---

**Generated:** 2026-01-03
**Status:** READY TO EXECUTE
