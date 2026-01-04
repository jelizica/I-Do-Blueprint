# Testing Quick Reference

## 🚦 Current Active Workflow

**File:** [`.github/workflows/tests.yml`](workflows/tests.yml)

**What Runs:**
- ✅ Build verification
- ✅ Accessibility tests (non-blocking)

**Status:** Minimal CI (won't block bad code, but won't fail either)

---

## 🎯 One-Liner Commands

### Switch to Robust CI (Recommended)

```bash
mv .github/workflows/tests.yml .github/workflows/tests-minimal.yml.backup && \
mv .github/workflows/tests-robust.yml .github/workflows/tests.yml && \
git add .github/workflows/ && \
git commit -m "feat: Enable production-grade CI with security gates" && \
git push
```

### Disable All Tests

```bash
rm .github/workflows/tests.yml && \
git add .github/workflows/ && \
git commit -m "ci: Temporarily disable CI" && \
git push
```

### Test Locally Before Pushing

```bash
# Build
xcodebuild build -scheme "I Do Blueprint" -destination 'platform=macOS'

# Accessibility tests
xcodebuild test -scheme "I Do Blueprint" -destination 'platform=macOS' \
  -only-testing:I_Do_BlueprintTests/Accessibility

# Check for secrets
grep -r "sk-" --include="*.swift" "I Do Blueprint/" || echo "✅ No API keys"
grep -r "service_role" --include="*.swift" "I Do Blueprint/" || echo "✅ No service keys"
```

---

## 📊 Workflow Comparison

| Feature | Minimal (`tests.yml`) | Robust (`tests-robust.yml`) |
|---------|----------------------|----------------------------|
| Build check | ✅ Yes | ✅ Yes |
| Accessibility tests | ⚠️ Non-blocking | ✅ Blocking |
| Security scans | ❌ No | ✅ Yes |
| Secret detection | ❌ No | ✅ Yes |
| Coverage reporting | ❌ No | ❌ No (intentional) |
| Speed | ⚡ 5-10 min | 🐢 15-20 min |
| **Blocks bad code** | ❌ No | ✅ Yes |

---

## 🔥 Emergency: CI Is Blocking My Push

### Quick Fix (Temporary)

Make tests non-blocking:

```bash
# Edit .github/workflows/tests.yml
# Add this to failing step:
  continue-on-error: true
```

### Proper Fix

1. Check what failed: Look at GitHub Actions logs
2. Fix the issue locally
3. Test locally before pushing
4. Push again

---

## 📚 Full Documentation

See [docs/CI-CD-TESTING-GUIDE.md](../docs/CI-CD-TESTING-GUIDE.md) for:
- Detailed explanations
- Troubleshooting guide
- Migration path
- Best practices
