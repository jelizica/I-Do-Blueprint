# GitHub Repository Cleanup Plan - REVISED & APPROVED

## Executive Summary

**Decisions Made:**
1. ✅ **Delete ALL documentation** - Delete entire `docs/` directory
2. ✅ **Delete ALL Semgrep rules** - Remove `.semgrep/` directory
3. ✅ **Delete ALL LLM Council scripts** - Remove all council-related scripts
4. ✅ **Scrub git history** - Remove sensitive files from all past commits
5. ✅ **Rewrite README.md** - Create clean, professional README focused on the app

**Current State:**
- **Total tracked files:** 1,435 files
- **App source files:** 1,011 files
- **Files to delete:** ~370 files (26% reduction)

**Target State:**
- **Final tracked files:** ~1,065 files (app + tests + configs + migrations + essential scripts)
- **Clean git history** - No sensitive files in any commits
- **Professional README** - App-focused documentation

---

## Files to Delete (Complete List)

### 🔴 AI Assistant Configurations (DELETE ALL)

**Beads (Issue Tracker) - 6.7 MB**
```
.beads/
```

**Claude Code**
```
.claude/
CLAUDE.md
.claude-env-setup.txt
```

**Code Guardian (CCG) - 376 KB**
```
.ccg/
AGENTS.md
```

**Gemini**
```
.gemini/
GEMINI.md
```

**Qodo**
```
.qodo/
.qodo-swiftzilla.sh
```

**MCP Servers**
```
.mcp.json
.mcp.json.example
.mcp-server-context.md
```

**Code Review Tools**
```
.coderabbit.yaml
.codacy/
```

**Obsidian**
```
.obsidian/
```

### 🔴 Knowledge Base & Documentation (DELETE ALL)

**Personal Knowledge Base - 2.1 MB**
```
knowledge-repo-bm/
knowledge/
```

**Documentation Directory - 1.5 MB**
```
docs/
```

**Root-level Development Documentation (22 files)**
```
API_KEY_ROTATION_GUIDE.md
ARCHITECTURE_IMPROVEMENT_PLAN.md
ARCHITECTURE_IMPROVEMENT_PLAN_FINAL.md
ARCHITECTURE_IMPROVEMENT_PLAN_REVISED.md
BASIC-MEMORY-AND-BEADS-GUIDE.md
CODEBASE_AUDIT_REPORT.md
CODEBASE_HEALTH_ANALYSIS.md
CONTEXT_ENGINEERING_SUMMARY.md
GIT_HISTORY_SCRUBBING_COMPLETE.md
LLM-COUNCIL.md
MCP_SETUP.md
SECURITY_ACTION_PLAN.md
SETTINGS_RESTRUCTURE_PROMPT.md
best_practices.md
macos-security-tools-guide.md
mcp_tools_info.md
trufflehog_analysis.md
trufflehog_results.json
```

### 🔴 Project Management & Session Tracking (DELETE ALL)

```
_project_specs/
```

### 🔴 Development Tooling & Caches (DELETE ALL)

```
.chunkhound.json
.trufflehogignore
agent.toml
.zshrc-additions
.envrc
.env.mcp.local
__pycache__/
claude-statusline/
.semgrep/
```

### 🔴 Development Logs & Temp Files (DELETE ALL)

```
logs/
temp.swift
tech-stack-analysis.txt
supabase/.temp/
```

### 🔴 IDE Configs (DELETE TRACKED FILES)

```
.vscode/settings.json
```

### 🔴 Scripts - Dev-Only Tools (DELETE)

```
Scripts/llm-council-query.py
Scripts/llm-council-query.sh
Scripts/llm-council-wrapper.sh
Scripts/council
Scripts/.council-examples.sh
Scripts/INSTALL.md
Scripts/QUICK-START.md
Scripts/README-llm-council.md
Scripts/generate-diagrams.sh
Scripts/enable-semgrep-pro.sh
```

---

## Files to Keep (Essential App Files)

### ✅ App Source Code (1,011 files)
```
I Do Blueprint/
├── App/                    # Entry point
├── Assets.xcassets/        # Images, icons
├── Core/                   # Common utilities, auth, analytics
├── Design/                 # Design system
├── Domain/                 # Models, repositories, services
├── Resources/              # Lottie animations, sample data
├── Services/               # Stores, API clients, managers
├── Utilities/              # Helpers, logging, validation
└── Views/                  # SwiftUI views
```

### ✅ Tests (54 files)
```
I Do BlueprintTests/
I Do BlueprintUITests/
```

### ✅ Xcode Project
```
I Do Blueprint.xcodeproj/
Packages/
```

### ✅ Database & Backend
```
supabase/
├── functions/              # Edge functions
└── migrations/             # 51 SQL migrations
```

### ✅ Essential Scripts (5 files)
```
Scripts/
├── audit_logging.sh
├── convert_csv_to_xlsx.py
├── migrate-appcolors-to-semantic.py
├── migrate-colors.sh
└── migrate_print_to_logger.py
```

### ✅ Essential Configuration
```
.env.example
.gitattributes
.gitignore
.swiftlint.yml
apple-app-site-association
.github/workflows/tests.yml
README.md (will be rewritten)
```

---

## Execution Plan

### Phase 1: Pre-Cleanup Security Audit (CRITICAL)

**Scan for secrets before deletion:**

```bash
# 1. Scan beads interactions for secrets
echo "=== Scanning .beads/interactions.jsonl ==="
grep -i -E '(api[_-]?key|secret|password|token|credential|sk-|eyJ)' .beads/interactions.jsonl || echo "No matches found"

# 2. Check trufflehog results
echo "=== Checking trufflehog_results.json ==="
cat trufflehog_results.json | jq -r '.[] | select(.Verified == true) | .Description' 2>/dev/null || echo "No verified secrets"

# 3. Check CCG sessions
echo "=== Scanning .ccg/sessions/ ==="
grep -r -i -E '(api[_-]?key|secret|password|token|sk-|eyJ)' .ccg/sessions/ || echo "No matches found"

# 4. Check MCP configs
echo "=== Checking MCP configs ==="
grep -i -E '(key|secret|token|password)' .mcp.json 2>/dev/null || echo "File not found or no matches"
grep -i -E '(key|secret|token|password)' .env.mcp.local 2>/dev/null || echo "File not found or no matches"

# 5. Check session archives
echo "=== Scanning _project_specs/session/ ==="
grep -r -i -E '(api[_-]?key|secret|password|token|sk-|eyJ)' _project_specs/session/ || echo "No matches found"

# 6. Check knowledge repo
echo "=== Scanning knowledge-repo-bm/ ==="
grep -r -i -E '(api[_-]?key|secret|password|token|sk-|eyJ)' knowledge-repo-bm/ || echo "No matches found"

# 7. Check all markdown files
echo "=== Scanning root markdown files ==="
grep -i -E '(api[_-]?key|secret|password|token|sk-|eyJ)' *.md || echo "No matches found"

echo ""
echo "✅ Security audit complete"
echo "⚠️  Review output above for any matches"
echo "⚠️  If secrets found, they will be scrubbed in Phase 2"
```

**Action:** If secrets found, note the files for complete history scrubbing.

### Phase 2: Git History Scrubbing (Clean All Past Commits)

**Install BFG Repo Cleaner (if not installed):**

```bash
# macOS
brew install bfg

# Or download: https://rtyley.github.io/bfg-repo-cleaner/
```

**Create backup:**

```bash
# Backup current state
cd ..
cp -r "I Do Blueprint" "I Do Blueprint.backup"
cd "I Do Blueprint"
```

**Create files list for BFG:**

```bash
# Create list of files to delete from history
cat > /tmp/files-to-delete.txt << 'EOF'
.beads
.ccg
.claude
.gemini
.qodo
.obsidian
.codacy
.semgrep
.vscode
knowledge-repo-bm
knowledge
docs
_project_specs
logs
claude-statusline
__pycache__
AGENTS.md
API_KEY_ROTATION_GUIDE.md
ARCHITECTURE_IMPROVEMENT_PLAN.md
ARCHITECTURE_IMPROVEMENT_PLAN_FINAL.md
ARCHITECTURE_IMPROVEMENT_PLAN_REVISED.md
BASIC-MEMORY-AND-BEADS-GUIDE.md
CLAUDE.md
CODEBASE_AUDIT_REPORT.md
CODEBASE_HEALTH_ANALYSIS.md
CONTEXT_ENGINEERING_SUMMARY.md
GEMINI.md
GIT_HISTORY_SCRUBBING_COMPLETE.md
LLM-COUNCIL.md
MCP_SETUP.md
SECURITY_ACTION_PLAN.md
SETTINGS_RESTRUCTURE_PROMPT.md
best_practices.md
macos-security-tools-guide.md
mcp_tools_info.md
trufflehog_analysis.md
trufflehog_results.json
.claude-env-setup.txt
.coderabbit.yaml
.env.mcp.local
.envrc
.mcp.json
.mcp.json.example
.mcp-server-context.md
.qodo-swiftzilla.sh
.trufflehogignore
.zshrc-additions
.chunkhound.json
agent.toml
temp.swift
tech-stack-analysis.txt
Scripts/llm-council-query.py
Scripts/llm-council-query.sh
Scripts/llm-council-wrapper.sh
Scripts/council
Scripts/.council-examples.sh
Scripts/INSTALL.md
Scripts/QUICK-START.md
Scripts/README-llm-council.md
Scripts/generate-diagrams.sh
Scripts/enable-semgrep-pro.sh
EOF
```

**Run BFG to scrub history:**

```bash
# Delete folders from all commits
bfg --delete-folders .beads --no-blob-protection .
bfg --delete-folders .ccg --no-blob-protection .
bfg --delete-folders .claude --no-blob-protection .
bfg --delete-folders .gemini --no-blob-protection .
bfg --delete-folders .qodo --no-blob-protection .
bfg --delete-folders .obsidian --no-blob-protection .
bfg --delete-folders .codacy --no-blob-protection .
bfg --delete-folders .semgrep --no-blob-protection .
bfg --delete-folders .vscode --no-blob-protection .
bfg --delete-folders knowledge-repo-bm --no-blob-protection .
bfg --delete-folders knowledge --no-blob-protection .
bfg --delete-folders docs --no-blob-protection .
bfg --delete-folders _project_specs --no-blob-protection .
bfg --delete-folders logs --no-blob-protection .
bfg --delete-folders claude-statusline --no-blob-protection .
bfg --delete-folders __pycache__ --no-blob-protection .

# Delete individual files from all commits
bfg --delete-files "trufflehog_results.json" --no-blob-protection .
bfg --delete-files "*.md" --no-blob-protection .  # Will delete all .md in root
bfg --delete-files ".mcp.json" --no-blob-protection .
bfg --delete-files "temp.swift" --no-blob-protection .

# Clean up the repository
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo ""
echo "✅ Git history scrubbed"
echo "⚠️  Repository size should be significantly reduced"
```

**Verify history is clean:**

```bash
# Check if sensitive files exist in history
git log --all --full-history -- .beads/ || echo "✅ .beads/ not found in history"
git log --all --full-history -- trufflehog_results.json || echo "✅ trufflehog_results.json not found in history"
git log --all --full-history -- .mcp.json || echo "✅ .mcp.json not found in history"
```

### Phase 3: Remove Files from Working Directory

**Delete all tracked files:**

```bash
# Remove from git tracking (files remain locally until we delete them)
git rm -r .beads
git rm -r .ccg
git rm -r .claude
git rm -r .gemini
git rm -r .qodo
git rm -r .obsidian
git rm -r .codacy
git rm -r .semgrep
git rm -r .vscode
git rm -r knowledge-repo-bm
git rm -r knowledge
git rm -r docs
git rm -r _project_specs
git rm -r logs
git rm -r claude-statusline
git rm -r __pycache__

# Root-level documentation
git rm AGENTS.md
git rm API_KEY_ROTATION_GUIDE.md
git rm ARCHITECTURE_IMPROVEMENT_PLAN.md
git rm ARCHITECTURE_IMPROVEMENT_PLAN_FINAL.md
git rm ARCHITECTURE_IMPROVEMENT_PLAN_REVISED.md
git rm BASIC-MEMORY-AND-BEADS-GUIDE.md
git rm CLAUDE.md
git rm CODEBASE_AUDIT_REPORT.md
git rm CODEBASE_HEALTH_ANALYSIS.md
git rm CONTEXT_ENGINEERING_SUMMARY.md
git rm GEMINI.md
git rm GIT_HISTORY_SCRUBBING_COMPLETE.md
git rm LLM-COUNCIL.md
git rm MCP_SETUP.md
git rm SECURITY_ACTION_PLAN.md
git rm SETTINGS_RESTRUCTURE_PROMPT.md
git rm best_practices.md
git rm macos-security-tools-guide.md
git rm mcp_tools_info.md
git rm trufflehog_analysis.md
git rm trufflehog_results.json

# Config files
git rm .claude-env-setup.txt
git rm .coderabbit.yaml
git rm .env.mcp.local
git rm .envrc
git rm .mcp.json
git rm .mcp.json.example
git rm .mcp-server-context.md
git rm .qodo-swiftzilla.sh
git rm .trufflehogignore
git rm .zshrc-additions
git rm .chunkhound.json
git rm agent.toml

# Temp files
git rm temp.swift
git rm tech-stack-analysis.txt

# Supabase temp
git rm -r supabase/.temp

# Scripts (dev-only)
git rm Scripts/llm-council-query.py
git rm Scripts/llm-council-query.sh
git rm Scripts/llm-council-wrapper.sh
git rm Scripts/council
git rm Scripts/.council-examples.sh
git rm Scripts/INSTALL.md
git rm Scripts/QUICK-START.md
git rm Scripts/README-llm-council.md
git rm Scripts/generate-diagrams.sh
git rm Scripts/enable-semgrep-pro.sh

echo ""
echo "✅ Files removed from git tracking"
```

### Phase 4: Update .gitignore

```bash
# Append comprehensive exclusions to .gitignore
cat >> .gitignore << 'EOF'

# ========================================
# AI Assistant Configurations & State
# ========================================
.claude/
CLAUDE.md
.claude-env-setup.txt
.ccg/
AGENTS.md
.gemini/
GEMINI.md
.qodo/
.qodo-swiftzilla.sh
.mcp.json
.mcp-server-context.md
.coderabbit.yaml
.codacy/

# ========================================
# Issue Tracking & Knowledge Management
# ========================================
.beads/
knowledge-repo-bm/
knowledge/
.obsidian/

# ========================================
# Documentation & Planning (Dev-Only)
# ========================================
_project_specs/
docs/
BASIC-MEMORY-AND-BEADS-GUIDE.md
LLM-COUNCIL.md
MCP_SETUP.md
CODEBASE_*.md
ARCHITECTURE_IMPROVEMENT_*.md
CONTEXT_ENGINEERING_*.md
GIT_HISTORY_*.md
SECURITY_ACTION_PLAN.md
SETTINGS_RESTRUCTURE_PROMPT.md
best_practices.md
macos-security-tools-guide.md
mcp_tools_info.md
trufflehog_*.md
trufflehog_*.json
API_KEY_ROTATION_GUIDE.md

# ========================================
# Development Tooling & Caches
# ========================================
.chunkhound.json
.chunkhound/
.trufflehogignore
agent.toml
.zshrc-additions
.envrc

# ========================================
# Development Logs & Temp Files
# ========================================
logs/
temp.swift
tech-stack-analysis.txt
supabase/.temp/

# ========================================
# Scripts (Dev Tooling Only)
# ========================================
Scripts/llm-council*.py
Scripts/llm-council*.sh
Scripts/council
Scripts/.council-examples.sh
Scripts/INSTALL.md
Scripts/QUICK-START.md
Scripts/README-llm-council.md
Scripts/generate-diagrams.sh
Scripts/enable-semgrep-pro.sh

# ========================================
# Claude Statusline Plugin
# ========================================
claude-statusline/

# ========================================
# Semgrep Rules
# ========================================
.semgrep/

# ========================================
# This cleanup plan
# ========================================
GITHUB_REPO_CLEANUP_PLAN.md
EOF

echo ""
echo "✅ .gitignore updated"
```

### Phase 5: Create New README.md

**(See README.md creation in next artifact)**

### Phase 6: Commit & Force Push

```bash
# Stage all changes
git add .gitignore
git add README.md

# Commit cleanup
git commit -m "refactor: clean repository - remove development tooling and scrub history

Breaking Changes:
- Removed all AI assistant configurations and development tools
- Removed personal knowledge base and documentation
- Removed development logs, temp files, and session tracking
- Scrubbed git history to remove sensitive files from all commits

Repository now contains only:
- App source code and tests
- Xcode project files
- Database migrations
- Essential scripts (5 production utilities)
- Core configuration files
- Clean README focused on the app

IMPORTANT: Git history has been rewritten. All collaborators must:
1. Backup local changes
2. Delete local repository
3. Fresh clone from remote"

# Verify what's being tracked
echo ""
echo "=== Files now tracked by git ==="
git ls-files | wc -l
echo "files tracked"
echo ""

# Show clean status
git status

echo ""
echo "⚠️  BEFORE PUSHING: Review the commit and file count above"
echo "⚠️  Expected file count: ~1,065 files"
echo ""
read -p "Ready to force push? This will REWRITE remote history. (y/N): " confirm

if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    echo "Force pushing to origin/main..."
    git push --force-with-lease origin main
    echo ""
    echo "✅ Repository cleanup complete!"
    echo "✅ Git history scrubbed"
    echo "✅ Remote updated"
else
    echo "❌ Push cancelled. Review changes and run manually:"
    echo "   git push --force-with-lease origin main"
fi
```

### Phase 7: Verify Cleanup

```bash
# Check file count
echo "=== Final File Count ==="
git ls-files | wc -l
echo "files tracked (expected: ~1,065)"

# Verify app source intact
echo ""
echo "=== App Source Files ==="
git ls-files "I Do Blueprint/" | wc -l
echo "app source files (expected: ~1,011)"

# Verify tests intact
echo ""
echo "=== Test Files ==="
git ls-files "I Do BlueprintTests/" "I Do BlueprintUITests/" | wc -l
echo "test files (expected: ~54)"

# Check migrations
echo ""
echo "=== Database Migrations ==="
git ls-files "supabase/migrations/" | wc -l
echo "migrations (expected: 51)"

# Verify no sensitive files remain
echo ""
echo "=== Security Check ==="
git ls-files | grep -E '(\.beads|\.ccg|\.mcp\.json|trufflehog|knowledge-repo|_project_specs)' && echo "⚠️  WARNING: Sensitive files still tracked!" || echo "✅ No sensitive files found"

# Check repository size
echo ""
echo "=== Repository Size ==="
du -sh .git
echo ""

echo "✅ Verification complete!"
```

### Phase 8: Cleanup Local Files (Optional)

**After successful push, optionally delete local copies:**

```bash
# OPTIONAL: Delete local copies of removed files
# (They're already removed from git, but still exist on disk)

rm -rf .beads
rm -rf .ccg
rm -rf .claude
rm -rf .gemini
rm -rf .qodo
rm -rf .obsidian
rm -rf .codacy
rm -rf .semgrep
rm -rf .vscode
rm -rf knowledge-repo-bm
rm -rf knowledge
rm -rf docs
rm -rf _project_specs
rm -rf logs
rm -rf claude-statusline
rm -rf __pycache__

# Delete root markdown files
rm -f AGENTS.md API_KEY_ROTATION_GUIDE.md ARCHITECTURE_*.md
rm -f BASIC-MEMORY-AND-BEADS-GUIDE.md CLAUDE.md CODEBASE_*.md
rm -f CONTEXT_ENGINEERING_SUMMARY.md GEMINI.md GIT_HISTORY_*.md
rm -f LLM-COUNCIL.md MCP_SETUP.md SECURITY_ACTION_PLAN.md
rm -f SETTINGS_RESTRUCTURE_PROMPT.md best_practices.md
rm -f macos-security-tools-guide.md mcp_tools_info.md
rm -f trufflehog_*.md trufflehog_*.json

# Delete config files
rm -f .claude-env-setup.txt .coderabbit.yaml .env.mcp.local
rm -f .envrc .mcp.json .mcp.json.example .mcp-server-context.md
rm -f .qodo-swiftzilla.sh .trufflehogignore .zshrc-additions
rm -f .chunkhound.json agent.toml

# Delete temp files
rm -f temp.swift tech-stack-analysis.txt

# Delete scripts
rm -f Scripts/llm-council* Scripts/council Scripts/.council-examples.sh
rm -f Scripts/INSTALL.md Scripts/QUICK-START.md Scripts/README-llm-council.md
rm -f Scripts/generate-diagrams.sh Scripts/enable-semgrep-pro.sh

echo "✅ Local cleanup complete"
```

---

## Post-Cleanup Checklist

- [ ] Phase 1: Security audit completed
- [ ] Phase 2: Git history scrubbed with BFG
- [ ] Phase 3: Files removed from git tracking
- [ ] Phase 4: .gitignore updated
- [ ] Phase 5: New README.md created
- [ ] Phase 6: Changes committed and force-pushed
- [ ] Phase 7: Verification completed
- [ ] Phase 8: Local files deleted (optional)
- [ ] Repository size reduced
- [ ] No sensitive files in history
- [ ] App builds successfully
- [ ] Tests pass
- [ ] CI/CD pipeline works

---

## Important Notes

### ⚠️  For Collaborators

**After this cleanup is pushed, all collaborators MUST:**

1. **Backup any local changes:**
   ```bash
   git stash
   # or commit to a temporary branch
   ```

2. **Delete local repository:**
   ```bash
   cd ..
   rm -rf "I Do Blueprint"
   ```

3. **Fresh clone:**
   ```bash
   git clone <repository-url>
   ```

4. **DO NOT try to pull/merge** - git history has been rewritten

### ⚠️  Repository Size

- **Before cleanup:** ~15-20 MB (excluding .git)
- **After cleanup:** ~8-10 MB
- **.git directory:** Should shrink significantly after BFG + gc

### ✅ What's Preserved

- ✅ All app source code and functionality
- ✅ All tests and test infrastructure
- ✅ All database migrations
- ✅ Xcode project configuration
- ✅ Essential build scripts
- ✅ CI/CD pipeline
- ✅ SwiftLint configuration

### 🔴 What's Removed

- 🔴 All AI development tools and configurations
- 🔴 Personal knowledge base and documentation
- 🔴 Development session tracking
- 🔴 Security scan results
- 🔴 Development logs and temp files
- 🔴 Non-essential scripts

---

**Status:** APPROVED - READY TO EXECUTE
**Prepared:** 2026-01-03
**Last Updated:** 2026-01-03
