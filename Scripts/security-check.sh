#!/bin/bash
set -e

echo "🔒 Running comprehensive security checks..."
echo ""

# Check .env is not staged
if git diff --cached --name-only | grep -E '^\.env$|^\.env\.' | grep -v '\.example$'; then
  echo "ERROR: .env file is staged for commit!"
  exit 1
fi

# Check for Config.plist (contains secrets)
if git diff --cached --name-only | grep -E 'Config\.plist$'; then
  echo "ERROR: Config.plist should not be committed (contains secrets)!"
  exit 1
fi

# Check for common secret patterns in Swift files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.swift$')
if [ -n "$STAGED_FILES" ]; then
  if echo "$STAGED_FILES" | xargs grep -l -E '(apiKey|secretKey|password|token)\s*=\s*"[A-Za-z0-9]{20,}"' 2>/dev/null; then
    echo "WARNING: Possible hardcoded secrets found in Swift files - please verify"
    echo "Secrets should be in Config.plist or Keychain, not hardcoded!"
  fi
fi

# Check for service_role keys (should never be in client)
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)
if [ -n "$STAGED_FILES" ]; then
  if echo "$STAGED_FILES" | xargs grep -l -E 'service_role' 2>/dev/null; then
    echo "ERROR: service_role key found! This should NEVER be in client code!"
    exit 1
  fi
fi

# Check .gitignore exists and has critical entries
if [ ! -f ".gitignore" ]; then
  echo "WARNING: No .gitignore found"
else
  if ! grep -q "Config.plist" .gitignore; then
    echo "WARNING: Config.plist not in .gitignore"
  fi
  if ! grep -q "\.env" .gitignore; then
    echo "WARNING: .env not in .gitignore"
  fi
fi

# Run Semgrep Pro with custom PII tracking rules
echo ""
echo "🔍 Running Semgrep Pro (SAST + PII Tracking)..."
if [ -d ".semgrep/rules" ]; then
  # Run with custom PII rules + Pro rules
  semgrep scan \
    --config .semgrep/rules \
    --config auto \
    --pro \
    --exclude "*.test.swift" \
    --exclude "Tests/" \
    --exclude "I Do BlueprintTests/" \
    --quiet \
    || echo "⚠️  Semgrep found security issues (see above)"
else
  # Run with Pro rules only
  semgrep scan \
    --config auto \
    --pro \
    --exclude "*.test.swift" \
    --exclude "Tests/" \
    --exclude "I Do BlueprintTests/" \
    --quiet \
    || echo "⚠️  Semgrep found security issues (see above)"
fi

echo ""
echo "✅ All security checks complete!"
