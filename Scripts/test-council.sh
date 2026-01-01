#!/bin/bash
# Quick test to verify council installation

echo "Testing LLM Council Scripts..."
echo ""

# Test 1: Check scripts exist
echo "✓ Checking scripts..."
if [ -f "scripts/council" ]; then
    echo "  ✓ scripts/council exists"
else
    echo "  ✗ scripts/council missing"
    exit 1
fi

if [ -f "scripts/llm-council-wrapper.sh" ]; then
    echo "  ✓ scripts/llm-council-wrapper.sh exists"
else
    echo "  ✗ scripts/llm-council-wrapper.sh missing"
    exit 1
fi

# Test 2: Check executability
echo ""
echo "✓ Checking permissions..."
if [ -x "scripts/council" ]; then
    echo "  ✓ scripts/council is executable"
else
    echo "  ✗ scripts/council not executable"
    echo "    Run: chmod +x scripts/council"
    exit 1
fi

# Test 3: Test help output
echo ""
echo "✓ Testing help output..."
./scripts/council --help > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "  ✓ Help command works"
else
    echo "  ✗ Help command failed"
    exit 1
fi

# Test 4: Check environment
echo ""
echo "✓ Checking environment..."
if [ -n "$OPENROUTER_API_KEY" ]; then
    echo "  ✓ OPENROUTER_API_KEY is set"
else
    echo "  ⚠ OPENROUTER_API_KEY not set (required for actual queries)"
    echo "    Set with: export OPENROUTER_API_KEY=\"your-key\""
fi

# Test 5: Check alias setup
echo ""
echo "✓ Checking aliases..."
if command -v council &> /dev/null; then
    echo "  ✓ 'council' alias is installed"
else
    echo "  ℹ 'council' alias not installed (optional)"
    echo "    See scripts/INSTALL.md for setup"
fi

# Summary
echo ""
echo "========================================="
echo "✅ Installation Test Complete"
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. Set OPENROUTER_API_KEY if not already set"
echo "  2. Optional: Install aliases (see scripts/INSTALL.md)"
echo "  3. Try a test query:"
echo "     ./scripts/council --stage1 \"test question\""
echo ""
