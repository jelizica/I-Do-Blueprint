#!/bin/bash
# Repository Cleanup Execution Script
# Based on: GITHUB_REPO_CLEANUP_PLAN.md
# WARNING: This script rewrites git history. Review the plan first!

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}GitHub Repository Cleanup Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check we're in the right directory
if [ ! -f "GITHUB_REPO_CLEANUP_PLAN.md" ]; then
    echo -e "${RED}ERROR: GITHUB_REPO_CLEANUP_PLAN.md not found${NC}"
    echo "Run this script from the project root directory"
    exit 1
fi

# Check if BFG is installed
if ! command -v bfg &> /dev/null; then
    echo -e "${YELLOW}BFG Repo Cleaner not found. Installing via Homebrew...${NC}"
    brew install bfg
fi

echo -e "${YELLOW}⚠️  WARNING: This script will:${NC}"
echo -e "${YELLOW}1. Rewrite git history (removes sensitive files from all commits)${NC}"
echo -e "${YELLOW}2. Delete 370+ files from the repository${NC}"
echo -e "${YELLOW}3. Require force push to remote${NC}"
echo -e "${YELLOW}4. Break collaborators' local repositories${NC}"
echo ""
read -p "Have you read GITHUB_REPO_CLEANUP_PLAN.md? (yes/no): " confirm_read

if [[ ! $confirm_read =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${RED}❌ Please read GITHUB_REPO_CLEANUP_PLAN.md first${NC}"
    exit 1
fi

echo ""
read -p "Are you SURE you want to proceed? (type 'DELETE' to confirm): " confirm_delete

if [ "$confirm_delete" != "DELETE" ]; then
    echo -e "${RED}❌ Cleanup cancelled${NC}"
    exit 1
fi

# Phase 1: Security Audit
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Phase 1: Security Audit${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "${YELLOW}Scanning for secrets...${NC}"

# Scan beads interactions
echo "=== Scanning .beads/interactions.jsonl ==="
grep -i -E '(api[_-]?key|secret|password|token|credential|sk-|eyJ)' .beads/interactions.jsonl 2>/dev/null || echo "No matches found"

# Check trufflehog results
echo "=== Checking trufflehog_results.json ==="
cat trufflehog_results.json 2>/dev/null | jq -r '.[] | select(.Verified == true) | .Description' 2>/dev/null || echo "No verified secrets"

# Check CCG sessions
echo "=== Scanning .ccg/sessions/ ==="
grep -r -i -E '(api[_-]?key|secret|password|token|sk-|eyJ)' .ccg/sessions/ 2>/dev/null || echo "No matches found"

# Check MCP configs
echo "=== Checking MCP configs ==="
grep -i -E '(key|secret|token|password)' .mcp.json 2>/dev/null || echo "File not found or no matches"
grep -i -E '(key|secret|token|password)' .env.mcp.local 2>/dev/null || echo "File not found or no matches"

echo ""
echo -e "${GREEN}✅ Security audit complete${NC}"
echo ""
read -p "Any secrets found above? Review before continuing. Press Enter to continue..."

# Create backup
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Creating Backup${NC}"
echo -e "${BLUE}========================================${NC}"

cd ..
if [ -d "I Do Blueprint.backup" ]; then
    echo -e "${YELLOW}Removing old backup...${NC}"
    rm -rf "I Do Blueprint.backup"
fi

echo -e "${YELLOW}Creating backup at: ../I Do Blueprint.backup${NC}"
cp -r "I Do Blueprint" "I Do Blueprint.backup"
echo -e "${GREEN}✅ Backup created${NC}"

cd "I Do Blueprint"

# Phase 2: Git History Scrubbing
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Phase 2: Git History Scrubbing${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "${YELLOW}Scrubbing folders from git history...${NC}"

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

echo -e "${YELLOW}Scrubbing files from git history...${NC}"

# Delete individual files from all commits
bfg --delete-files "trufflehog_results.json" --no-blob-protection .
bfg --delete-files ".mcp.json" --no-blob-protection .
bfg --delete-files "temp.swift" --no-blob-protection .

echo -e "${YELLOW}Cleaning up repository...${NC}"
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo -e "${GREEN}✅ Git history scrubbed${NC}"

# Verify
echo ""
echo -e "${YELLOW}Verifying history is clean...${NC}"
git log --all --full-history -- .beads/ 2>&1 | grep "fatal: unrecognized argument" && echo "✅ .beads/ not found in history" || echo "⚠️  .beads/ may still be in history"
git log --all --full-history -- trufflehog_results.json 2>&1 | grep "fatal: unrecognized argument" && echo "✅ trufflehog_results.json not found in history" || echo "⚠️  trufflehog_results.json may still be in history"

# Phase 3: Remove Files from Working Directory
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Phase 3: Removing Files${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "${YELLOW}Removing tracked files...${NC}"

# This will continue even if some files don't exist
set +e

# Directories
git rm -r .beads 2>/dev/null
git rm -r .ccg 2>/dev/null
git rm -r .claude 2>/dev/null
git rm -r .gemini 2>/dev/null
git rm -r .qodo 2>/dev/null
git rm -r .obsidian 2>/dev/null
git rm -r .codacy 2>/dev/null
git rm -r .semgrep 2>/dev/null
git rm -r .vscode 2>/dev/null
git rm -r knowledge-repo-bm 2>/dev/null
git rm -r knowledge 2>/dev/null
git rm -r docs 2>/dev/null
git rm -r _project_specs 2>/dev/null
git rm -r logs 2>/dev/null
git rm -r claude-statusline 2>/dev/null
git rm -r __pycache__ 2>/dev/null

# Root markdown files
git rm AGENTS.md 2>/dev/null
git rm API_KEY_ROTATION_GUIDE.md 2>/dev/null
git rm ARCHITECTURE_IMPROVEMENT_PLAN.md 2>/dev/null
git rm ARCHITECTURE_IMPROVEMENT_PLAN_FINAL.md 2>/dev/null
git rm ARCHITECTURE_IMPROVEMENT_PLAN_REVISED.md 2>/dev/null
git rm BASIC-MEMORY-AND-BEADS-GUIDE.md 2>/dev/null
git rm CLAUDE.md 2>/dev/null
git rm CODEBASE_AUDIT_REPORT.md 2>/dev/null
git rm CODEBASE_HEALTH_ANALYSIS.md 2>/dev/null
git rm CONTEXT_ENGINEERING_SUMMARY.md 2>/dev/null
git rm GEMINI.md 2>/dev/null
git rm GIT_HISTORY_SCRUBBING_COMPLETE.md 2>/dev/null
git rm LLM-COUNCIL.md 2>/dev/null
git rm MCP_SETUP.md 2>/dev/null
git rm SECURITY_ACTION_PLAN.md 2>/dev/null
git rm SETTINGS_RESTRUCTURE_PROMPT.md 2>/dev/null
git rm best_practices.md 2>/dev/null
git rm macos-security-tools-guide.md 2>/dev/null
git rm mcp_tools_info.md 2>/dev/null
git rm trufflehog_analysis.md 2>/dev/null
git rm trufflehog_results.json 2>/dev/null

# Config files
git rm .claude-env-setup.txt 2>/dev/null
git rm .coderabbit.yaml 2>/dev/null
git rm .env.mcp.local 2>/dev/null
git rm .envrc 2>/dev/null
git rm .mcp.json 2>/dev/null
git rm .mcp.json.example 2>/dev/null
git rm .mcp-server-context.md 2>/dev/null
git rm .qodo-swiftzilla.sh 2>/dev/null
git rm .trufflehogignore 2>/dev/null
git rm .zshrc-additions 2>/dev/null
git rm .chunkhound.json 2>/dev/null
git rm agent.toml 2>/dev/null

# Temp files
git rm temp.swift 2>/dev/null
git rm tech-stack-analysis.txt 2>/dev/null

# Supabase temp
git rm -r supabase/.temp 2>/dev/null

# Scripts
git rm Scripts/llm-council-query.py 2>/dev/null
git rm Scripts/llm-council-query.sh 2>/dev/null
git rm Scripts/llm-council-wrapper.sh 2>/dev/null
git rm Scripts/council 2>/dev/null
git rm Scripts/.council-examples.sh 2>/dev/null
git rm Scripts/INSTALL.md 2>/dev/null
git rm Scripts/QUICK-START.md 2>/dev/null
git rm Scripts/README-llm-council.md 2>/dev/null
git rm Scripts/generate-diagrams.sh 2>/dev/null
git rm Scripts/enable-semgrep-pro.sh 2>/dev/null

set -e

echo -e "${GREEN}✅ Files removed from git tracking${NC}"

# Phase 4: Update .gitignore
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Phase 4: Updating .gitignore${NC}"
echo -e "${BLUE}========================================${NC}"

# Append to .gitignore
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
# Cleanup Plan & Script
# ========================================
GITHUB_REPO_CLEANUP_PLAN.md
Scripts/cleanup-repo.sh
EOF

git add .gitignore

echo -e "${GREEN}✅ .gitignore updated${NC}"

# Phase 5: Commit
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Phase 5: Committing Changes${NC}"
echo -e "${BLUE}========================================${NC}"

# README should already be written
git add README.md

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

echo -e "${GREEN}✅ Changes committed${NC}"

# Phase 6: Verification
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Phase 6: Verification${NC}"
echo -e "${BLUE}========================================${NC}"

echo "=== Final File Count ==="
FILE_COUNT=$(git ls-files | wc -l | tr -d ' ')
echo "$FILE_COUNT files tracked (expected: ~1,065)"

echo ""
echo "=== App Source Files ==="
APP_COUNT=$(git ls-files "I Do Blueprint/" | wc -l | tr -d ' ')
echo "$APP_COUNT app source files (expected: ~1,011)"

echo ""
echo "=== Test Files ==="
TEST_COUNT=$(git ls-files "I Do BlueprintTests/" "I Do BlueprintUITests/" | wc -l | tr -d ' ')
echo "$TEST_COUNT test files (expected: ~54)"

echo ""
echo "=== Database Migrations ==="
MIG_COUNT=$(git ls-files "supabase/migrations/" | wc -l | tr -d ' ')
echo "$MIG_COUNT migrations (expected: 51)"

echo ""
echo "=== Security Check ==="
if git ls-files | grep -E '(\.beads|\.ccg|\.mcp\.json|trufflehog|knowledge-repo|_project_specs)' > /dev/null; then
    echo -e "${RED}⚠️  WARNING: Sensitive files still tracked!${NC}"
else
    echo -e "${GREEN}✅ No sensitive files found${NC}"
fi

echo ""
echo "=== Repository Size ==="
du -sh .git

echo ""
echo -e "${GREEN}✅ Verification complete!${NC}"

# Phase 7: Push
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Phase 7: Push to Remote${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "${YELLOW}⚠️  FINAL WARNING: This will rewrite remote git history${NC}"
echo -e "${YELLOW}⚠️  All collaborators must delete and re-clone the repository${NC}"
echo ""
read -p "Ready to force push to origin/main? (yes/no): " confirm_push

if [[ $confirm_push =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${YELLOW}Force pushing to origin/main...${NC}"
    git push --force-with-lease origin main
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✅ Repository cleanup complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${GREEN}✅ Git history scrubbed${NC}"
    echo -e "${GREEN}✅ ${FILE_COUNT} files now tracked (down from 1,435)${NC}"
    echo -e "${GREEN}✅ Remote updated${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  Important: Notify all collaborators to:${NC}"
    echo -e "${YELLOW}1. Backup local changes${NC}"
    echo -e "${YELLOW}2. Delete local repository${NC}"
    echo -e "${YELLOW}3. Fresh clone from remote${NC}"
else
    echo ""
    echo -e "${YELLOW}❌ Push cancelled${NC}"
    echo -e "${YELLOW}Changes are committed locally but NOT pushed to remote${NC}"
    echo ""
    echo "To push later, run:"
    echo "  git push --force-with-lease origin main"
    echo ""
    echo "To undo local changes:"
    echo "  git reset --hard HEAD~1"
    echo "  Restore from backup: ../I Do Blueprint.backup"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Cleanup Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo "✅ Backup created: ../I Do Blueprint.backup"
echo "✅ Files tracked: $FILE_COUNT (was 1,435)"
echo "✅ App source preserved: $APP_COUNT files"
echo "✅ Tests preserved: $TEST_COUNT files"
echo "✅ Migrations preserved: $MIG_COUNT files"
echo ""
