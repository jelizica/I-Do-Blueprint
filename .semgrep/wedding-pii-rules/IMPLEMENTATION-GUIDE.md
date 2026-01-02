# Wedding PII Detection Rules - Implementation Guide

## Quick Start

### Installation Check

```bash
# Verify Semgrep is installed
semgrep --version

# If not installed
brew install semgrep
# or
pip install semgrep
```

### Run First Scan

```bash
# From project root
cd "/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint"

# Run all wedding PII rules
semgrep --config .semgrep/wedding-pii-rules/ "I Do Blueprint/"

# Run specific rule
semgrep --config .semgrep/wedding-pii-rules/pii_logging_detection.yaml "I Do Blueprint/"

# Save results to file
semgrep --config .semgrep/wedding-pii-rules/ "I Do Blueprint/" --json > pii-scan-results.json
```

## Understanding the Results

### Example Finding

```
I Do Blueprint/Services/Stores/GuestStoreV2.swift
❯❯❱ semgrep.wedding-pii-rules.wedding-pii-logging

    This wedding planning application is logging Personally Identifiable Information (PII)...

    245┆ logger.info("Guest updated: \(guest.firstName) \(guest.lastName)")
```

**What this means:**
- **File**: `GuestStoreV2.swift`
- **Line**: 245
- **Issue**: Logging guest first name and last name (PII) to console
- **Risk**: Names appear in application logs, accessible to developers, may leak in crash reports
- **Fix**: Replace with: `logger.info("Guest updated", metadata: ["guestId": "\(guest.id)"])`

### Severity Levels

| Severity | Meaning | Action Required |
|----------|---------|-----------------|
| **ERROR** | Critical PII exposure | **Must fix before production** |
| **WARNING** | Potential PII issue | **Review and address if applicable** |
| **INFO** | Best practice suggestion | Consider improving |

## Common Fixes

### 1. PII Logging (ERROR)

**❌ Before:**
```swift
logger.info("Updated guest: \(guest.firstName) \(guest.email)")
logger.error("Failed to save vendor: \(vendor.contactName)")
print("Guest dietary restrictions: \(guest.dietaryRestrictions)")
```

**✅ After:**
```swift
logger.info("Guest updated", metadata: ["guestId": "\(guest.id.uuidString)"])
logger.error("Failed to save vendor", metadata: ["vendorId": "\(vendor.id)"])
logger.debug("Dietary data processed") // Debug only, stripped in production
```

### 2. Insecure Storage (ERROR)

**❌ Before:**
```swift
UserDefaults.standard.set(guest.email, forKey: "lastGuestEmail")
let guestData = try JSONEncoder().encode(guests)
try guestData.write(to: fileURL) // Unencrypted disk write
```

**✅ After:**
```swift
// Don't persist PII locally - fetch from Supabase on-demand
// Use RepositoryCache for memory-only caching
await RepositoryCache.shared.set("guests_\(tenantId)", value: guests, ttl: 60)

// For session data, use Keychain (already handled by SessionManager)
```

### 3. Health Data Exposure (WARNING)

**❌ Before:**
```swift
analytics.track("guest_rsvp", properties: [
    "dietary": guest.dietaryRestrictions,
    "accessibility": guest.accessibilityNeeds
])

let csv = guests.map { "\($0.name),\($0.email),\($0.dietaryRestrictions)" }
```

**✅ After:**
```swift
// Scrub health data from analytics
analytics.track("guest_rsvp", properties: [
    "hasDietaryRestrictions": !guest.dietaryRestrictions.isNilOrEmpty,
    "hasAccessibilityNeeds": !guest.accessibilityNeeds.isNilOrEmpty
    // No actual values sent
])

// Add export warning
func exportGuestList() {
    showAlert(
        title: "Health Data Warning",
        message: "This export contains dietary restrictions and accessibility needs (health information). Encrypt before sharing.",
        actions: [
            ("Cancel", .cancel),
            ("Export Encrypted", .default) { encryptAndExport() },
            ("Export Unencrypted", .destructive) { exportPlaintext() }
        ]
    )
}
```

### 4. Hardcoded PII (ERROR)

**❌ Before:**
```swift
let testGuest = Guest(
    firstName: "John",
    lastName: "Doe",
    email: "john.doe@gmail.com",
    phone: "415-555-1234"
)

let sampleVendor = Vendor(contactName: "Jane Smith", email: "jane@vendor.com")
```

**✅ After:**
```swift
// Use factory methods with random/placeholder data
let testGuest = Guest.makeTest(
    firstName: "Test",
    email: "test-\(UUID().uuidString)@example.com",
    phone: "555-0100" // Clearly fake
)

// Or use descriptive placeholders
let sampleVendor = Vendor.makeTest(
    contactName: "Sample Vendor \(Int.random(in: 1...100))",
    email: "vendor@example.com"
)
```

## Integration with Existing Workflow

### 1. Add to `scripts/security-check.sh`

Edit `scripts/security-check.sh` to include PII detection:

```bash
#!/bin/bash

echo "🔒 Running security checks..."

# Existing Semgrep scan
echo "📋 Running Semgrep general security scan..."
swiftscan "I Do Blueprint/"

# NEW: Add PII detection
echo "🔍 Running wedding-specific PII detection..."
semgrep --config .semgrep/wedding-pii-rules/ "I Do Blueprint/" --max-target-bytes=5MB

# Existing TruffleHog scan
echo "🔑 Running TruffleHog secret scan..."
trufflehog filesystem "I Do Blueprint/" --exclude-paths=.trufflehogignore

echo "✅ Security checks complete!"
```

### 2. Add to SwiftLint

Update `.swiftlint.yml` to complement Semgrep rules:

```yaml
custom_rules:
  no_pii_in_print:
    name: "No PII in print statements"
    regex: 'print\(.*\.(firstName|lastName|email|phone|address|dietary)'
    message: "Never use print() for PII (use AppLogger.debug in #if DEBUG)"
    severity: error

  no_guest_vendor_logging:
    name: "No direct Guest/Vendor object logging"
    regex: 'logger\.(info|error|warning).*".*\\((?:guest|vendor)\\)'
    message: "Don't log entire Guest/Vendor objects (use Semgrep for detailed detection)"
    severity: warning
```

### 3. Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash

echo "🔍 Running PII detection on staged Swift files..."

# Get staged Swift files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.swift$')

if [ -z "$STAGED_FILES" ]; then
    echo "✅ No Swift files staged, skipping PII check"
    exit 0
fi

# Run Semgrep on staged files only
for file in $STAGED_FILES; do
    echo "Checking: $file"
    semgrep --config .semgrep/wedding-pii-rules/pii_logging_detection.yaml "$file" --quiet
    if [ $? -ne 0 ]; then
        echo "❌ PII detected in $file - commit blocked"
        echo "Run: semgrep --config .semgrep/wedding-pii-rules/ '$file' for details"
        exit 1
    fi
done

echo "✅ No PII issues found in staged files"
exit 0
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

### 4. CI/CD Integration (GitHub Actions)

Create `.github/workflows/pii-detection.yml`:

```yaml
name: PII Detection

on:
  pull_request:
    paths:
      - '**.swift'
  push:
    branches:
      - main

jobs:
  pii-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install Semgrep
        run: pip install semgrep

      - name: Run PII Detection
        run: |
          semgrep --config .semgrep/wedding-pii-rules/ \
                  "I Do Blueprint/" \
                  --sarif --output semgrep-pii.sarif \
                  --max-target-bytes=5MB

      - name: Upload SARIF to GitHub Security
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: semgrep-pii.sarif
          category: pii-detection

      - name: Fail on ERROR findings
        run: |
          ERRORS=$(semgrep --config .semgrep/wedding-pii-rules/ \
                           "I Do Blueprint/" \
                           --json | jq '[.results[] | select(.extra.severity == "ERROR")] | length')
          if [ "$ERRORS" -gt 0 ]; then
            echo "❌ Found $ERRORS ERROR-level PII issues"
            exit 1
          fi
          echo "✅ No ERROR-level PII issues found"
```

## Handling False Positives

### Method 1: Inline Suppression

```swift
// nosemgrep: wedding-pii-logging
logger.debug("Guest email for debugging: \(guest.email)") // Only in DEBUG builds
```

### Method 2: File Exclusion

Add to `.semgrep.yml` in project root:

```yaml
exclude:
  - "**/Tests/**"
  - "**/Helpers/ModelBuilders.swift"  # Test data factories
  - "**/*Preview.swift"                # SwiftUI previews
  - "**/*+TestData.swift"              # Test extensions
```

### Method 3: Rule-Specific Exclusions

Edit the rule file to add exclusions:

```yaml
patterns:
  - pattern: $LOGGER.info("...\($GUEST.email)...")
  - pattern-not-inside: |
      #if DEBUG
      ...
      #endif
  - pattern-not-inside: |
      // Test data only
      ...
```

## Monitoring & Metrics

### Track PII Issues Over Time

```bash
# Run scan and save results
semgrep --config .semgrep/wedding-pii-rules/ \
        "I Do Blueprint/" \
        --json > "pii-scan-$(date +%Y%m%d).json"

# Count findings by severity
jq '[.results[] | .extra.severity] | group_by(.) | map({severity: .[0], count: length})' \
   pii-scan-*.json
```

### Generate Report

```bash
# HTML report
semgrep --config .semgrep/wedding-pii-rules/ \
        "I Do Blueprint/" \
        --html --output=pii-report.html

# Open in browser
open pii-report.html
```

## Common Questions

### Q: Why am I getting so many findings?

**A:** This is expected on first run. The app was built before PII rules existed. Prioritize:
1. **ERROR** findings first (critical issues)
2. **WARNING** findings in production code
3. Test files can be excluded

### Q: Can I exclude test files globally?

**A:** Yes, create `.semgrep.yml`:
```yaml
exclude:
  - "**/Tests/**"
  - "**/*Tests.swift"
```

### Q: Is Semgrep safe for my codebase?

**A:** Yes. Semgrep only reads your code (static analysis). It doesn't execute anything or send data to external servers (unless you use Semgrep Cloud, which is optional).

### Q: How does this compare to SwiftLint?

**A:** Complementary tools:
- **SwiftLint**: Code style, best practices
- **Semgrep**: Security vulnerabilities, PII detection, complex patterns

Use both for comprehensive coverage.

### Q: What about akabe1-semgrep-rules?

**A:** These wedding-specific rules **supplement** akabe1's iOS rules:
- **akabe1-semgrep-rules**: General iOS security (crypto, keychain, SQL injection)
- **wedding-pii-rules**: Wedding app PII (guest data, health info, vendor contacts)

Run both:
```bash
semgrep --config .semgrep/wedding-pii-rules/ \
        --config ~/akabe1-semgrep-rules/ios/swift/ \
        "I Do Blueprint/"
```

## Next Steps

1. **Run first scan**: `semgrep --config .semgrep/wedding-pii-rules/ "I Do Blueprint/"`
2. **Fix ERROR findings**: Start with `pii_logging_detection.yaml` results
3. **Add pre-commit hook**: Prevent new PII issues
4. **Integrate CI/CD**: Block PRs with PII violations
5. **Document in Basic Memory**: Store PII incidents for team learning

## Resources

- [Semgrep Documentation](https://semgrep.dev/docs/)
- [Writing Custom Rules](https://semgrep.dev/docs/writing-rules/overview/)
- [GDPR Compliance Guide](https://www.protecto.ai/blog/personal-data-and-pii-a-guide-to-data-privacy-under-gdpr/)
- [Project README](.semgrep/wedding-pii-rules/README.md)

## Support

For questions or issues with these rules:
1. Check [README.md](.semgrep/wedding-pii-rules/README.md) first
2. Review example patterns in rule files
3. Test rules individually to isolate issues
4. Document findings in Basic Memory for future reference
