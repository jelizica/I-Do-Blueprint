#!/bin/bash
#
# Enable Semgrep Team Tier (Free)
# Run this once to authenticate and enable Pro Engine
#

set -e

echo "🔐 Enabling Semgrep Team Tier (Free)"
echo ""
echo "This will:"
echo "  ✅ Enable Pro Engine with cross-function analysis"
echo "  ✅ Access 600+ Pro security rules"
echo "  ✅ Add Swift-specific vulnerability detection"
echo "  ✅ Enable secrets scanning"
echo ""
echo "You'll be redirected to login with GitHub/GitLab/Google"
echo ""
read -p "Press Enter to continue..."

# Login to Semgrep
semgrep login

echo ""
echo "✅ Semgrep Team tier enabled!"
echo ""
echo "Next steps:"
echo "  1. Run './Scripts/security-check.sh' to test"
echo "  2. The Pro Engine is now active for all scans"
echo ""
