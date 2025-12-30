#!/bin/bash
set -e

echo "Verifying project tooling..."

# GitHub CLI
if command -v gh &> /dev/null; then
  if gh auth status &> /dev/null; then
    echo "✓ GitHub CLI authenticated"
  else
    echo "✗ GitHub CLI not authenticated. Run: gh auth login"
    exit 1
  fi
else
  echo "⚠ GitHub CLI not installed. Run: brew install gh"
fi

# Xcode Command Line Tools
if command -v xcodebuild &> /dev/null; then
  echo "✓ Xcode Command Line Tools installed"
else
  echo "✗ Xcode Command Line Tools not installed. Run: xcode-select --install"
  exit 1
fi

# Supabase CLI
if command -v supabase &> /dev/null; then
  if supabase projects list &> /dev/null 2>&1; then
    echo "✓ Supabase CLI authenticated"
  else
    echo "✗ Supabase CLI not authenticated. Run: supabase login"
    exit 1
  fi
else
  echo "⚠ Supabase CLI not installed. Run: brew install supabase/tap/supabase"
fi

# Swift
if command -v swift &> /dev/null; then
  SWIFT_VERSION=$(swift --version | head -1)
  echo "✓ Swift installed: $SWIFT_VERSION"
else
  echo "✗ Swift not installed"
  exit 1
fi

echo ""
echo "Tooling verification complete!"
