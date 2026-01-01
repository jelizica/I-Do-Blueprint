# Security Scanning Setup

## Overview

This project uses **Semgrep Pro (free Team tier)** for comprehensive security scanning, including:
- ✅ SAST (Static Application Security Testing)
- ✅ PII/Privacy tracking
- ✅ Secrets detection
- ✅ Swift-specific vulnerability detection
- ✅ 600+ Pro security rules
- ✅ Cross-function data flow analysis

## Setup Complete ✅

The security scanning is already configured and ready to use!

## Quick Start

### Run Security Checks

```bash
# Run all security checks (recommended before commits)
./Scripts/security-check.sh
```

This will:
1. Check for staged `.env` files
2. Check for `Config.plist` in commits
3. Detect hardcoded secrets in Swift files
4. Check for `service_role` keys (should never be in client)
5. Verify `.gitignore` has critical entries
6. **Run Semgrep Pro with custom PII tracking rules**

### Semgrep Pro Features

#### Custom PII Tracking Rules

Located in `.semgrep/rules/pii-tracking.yaml`, these rules detect:

- **Guest PII exposure** - Email, phone, names in logs
- **Database queries without RLS** - Missing `couple_id` filters
- **UUID conversion bugs** - `.uuidString` in queries (causes case mismatch)
- **Keychain security** - Insecure accessibility levels
- **Hardcoded secrets** - API keys, tokens in code
- **Privacy Manifest** - Required Reason API usage
- **Sensitive data in errors** - PII in exception messages

#### Run Semgrep Standalone

```bash
# Full scan with Pro Engine + custom rules
semgrep scan --config .semgrep/rules --config auto --pro

# Only custom PII rules
semgrep scan --config .semgrep/rules

# Only Pro rules (no custom)
semgrep scan --config auto --pro

# Specific file
semgrep scan --config .semgrep/rules path/to/file.swift

# JSON output for CI/CD
semgrep scan --config auto --pro --json -o results.json
```

## What Was Installed

### 1. Semgrep Pro Engine (v1.146.0)
- **Cost**: FREE (Team tier)
- **Location**: Authenticated via `semgrep login`
- **Binary**: `/opt/homebrew/Cellar/semgrep/1.146.0/libexec/lib/python3.14/site-packages/semgrep/bin/semgrep-core-proprietary`

### 2. Custom PII Tracking Rules
- **Location**: `.semgrep/rules/pii-tracking.yaml`
- **Rules count**: 10 custom rules
- **Focus**: Privacy, GDPR compliance, Supabase RLS, Swift best practices

### 3. MobSFScan
- ❌ **Not installed** (Python 3.14 incompatibility)
- **Alternative**: Semgrep Pro covers Swift security comprehensively

## Custom Rules Explained

### Guest PII Detection

```yaml
# Detects guest PII in logs/prints
- id: guest-email-exposure
  message: Guest email (PII) logged or printed
```

### Missing RLS Filters

```yaml
# Detects database queries without couple_id filter
- id: missing-couple-id-filter
  message: Database query without couple_id filter (multi-tenancy violation)
```

### UUID Conversion Bug

```yaml
# Detects UUID.uuidString in queries (causes case mismatch)
- id: uuid-to-string-conversion
  message: UUID converted to string for query (use UUID directly)
```

### Keychain Security

```yaml
# Detects non-secure keychain accessibility
- id: insecure-keychain-accessibility
  message: Must use kSecAttrAccessibleWhenUnlockedThisDeviceOnly
```

## CI/CD Integration

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
./Scripts/security-check.sh
```

### GitHub Actions

```yaml
name: Security Scan
on: [push, pull_request]

jobs:
  semgrep:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Semgrep
        run: brew install semgrep

      - name: Login to Semgrep
        run: semgrep login
        env:
          SEMGREP_APP_TOKEN: ${{ secrets.SEMGREP_APP_TOKEN }}

      - name: Install Pro Engine
        run: semgrep install-semgrep-pro

      - name: Run Security Scan
        run: ./Scripts/security-check.sh
```

## Interpreting Results

### Example Output

```
🔒 Running comprehensive security checks...

🔍 Running Semgrep Pro (SAST + PII Tracking)...

┌───────────────────┐
│ 375 Code Findings │
└───────────────────┘

❯❯❱ semgrep.rules.guest-email-exposure
    Guest email (PII) logged or printed

    path/to/file.swift:45
      print(guest.email)  // ❌ Remove this
```

### Severity Levels

- 🔴 **ERROR** - Must fix (blocks commit in strict mode)
- 🟡 **WARNING** - Should fix (privacy/security concern)
- 🔵 **INFO** - FYI (e.g., Privacy Manifest requirements)

### Common Findings

#### 1. Supabase Anon Key Detected

```
❯❯❱ generic.secrets.security.detected-jwt-token
    JWT token detected in AppConfig.swift
```

**Action**: ✅ **Safe to ignore** - Supabase anon keys are public and protected by RLS

#### 2. UserDefaults Usage

```
❯❯❱ semgrep.rules.required-reason-api-usage
    Using Required Reason API. Ensure Privacy Manifest documents this usage.
```

**Action**: 📝 Ensure `PrivacyInfo.xcprivacy` includes NSPrivacyAccessedAPICategoryUserDefaults

#### 3. Missing couple_id Filter

```
❯❯❱ semgrep.rules.missing-couple-id-filter
    Database query without couple_id filter (multi-tenancy violation)
```

**Action**: 🔴 **Fix immediately** - Add `.eq("couple_id", value: tenantId)` to query

## Suppressing False Positives

### In Code (Inline)

```swift
// nosemgrep: semgrep.rules.guest-email-exposure
print(guest.email)  // OK: This is for debugging only
```

### In Configuration

Edit `.semgrep/rules/pii-tracking.yaml`:

```yaml
- id: guest-email-exposure
  pattern: print($GUEST.email)
  paths:
    exclude:
      - "DebugHelpers/"  # Exclude debug code
```

## Maintenance

### Update Semgrep

```bash
brew upgrade semgrep
semgrep install-semgrep-pro  # Update Pro Engine
```

### Update Pro Rules

Rules are automatically updated when you run `semgrep scan` with `--config auto`.

### Add Custom Rules

Edit `.semgrep/rules/pii-tracking.yaml` and add new rules following the existing pattern.

## Troubleshooting

### "API token not found"

```bash
semgrep logout
semgrep login
semgrep install-semgrep-pro
```

### "Pro Engine not installed"

```bash
semgrep install-semgrep-pro
```

### "Rule validation error"

Check `.semgrep/rules/pii-tracking.yaml` for YAML syntax errors.

### Too many false positives

Adjust rule severity or add exclusions (see "Suppressing False Positives" above).

## Resources

- **Semgrep Docs**: https://semgrep.dev/docs
- **Swift Rules**: https://semgrep.dev/p/swift
- **Pro Engine**: https://semgrep.dev/products/pro-engine
- **Custom Rules**: https://semgrep.dev/docs/writing-rules/overview

## Summary

✅ **Installed**: Semgrep Pro Engine v1.146.0 (free Team tier)
✅ **Custom Rules**: 10 PII/privacy tracking rules
✅ **Integration**: Added to `Scripts/security-check.sh`
✅ **Coverage**: 1361 rules scanning 899 Swift files
✅ **Cost**: $0 (free Team tier)

**Run before every commit**: `./Scripts/security-check.sh`
