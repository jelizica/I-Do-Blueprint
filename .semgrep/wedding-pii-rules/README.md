# Wedding Planning App - Custom Semgrep PII Detection Rules

## Overview

These custom Semgrep rules are designed specifically for wedding planning applications to detect and prevent **Personally Identifiable Information (PII)** security vulnerabilities. They complement the existing [akabe1-semgrep-rules](https://github.com/akabe1/akabe1-semgrep-rules) with wedding-specific patterns.

## Why Wedding Apps Need Specialized PII Rules

Wedding planning applications collect uniquely sensitive data:

1. **Guest Information**: Names, emails, phone numbers, physical addresses (500+ guests typical)
2. **Health Data**: Dietary restrictions (allergies, medical conditions), accessibility needs (disabilities)
3. **Vendor Contacts**: Business contact information, contracts, payment details
4. **Relationship Data**: Family relationships, social connections, wedding party roles

Under **GDPR Article 9**, health-related data (dietary restrictions, accessibility needs) requires **explicit consent** and enhanced protection. U.S. state laws (2024) now classify dietary and wellness data as "consumer health data" requiring encryption.

## Rules Included

### 1. `pii_logging_detection.yaml` - Critical PII Logging Prevention

**Severity**: ERROR
**CWE**: CWE-532 (Insertion of Sensitive Information into Log File)

Detects logging of PII to console, files, or crash reporting systems:
- Guest names, emails, phone numbers
- Dietary restrictions (health data)
- Addresses, accessibility needs
- Vendor contact information

**Example Violations**:
```swift
❌ logger.info("Guest updated: \(guest.firstName) \(guest.email)")
❌ print("RSVP from \(guest.fullName) - phone: \(guest.phone)")
❌ logger.error("Failed for \(vendor.contactName)", metadata: ["email": vendor.email])
```

**Remediation**:
```swift
✅ logger.info("Guest updated", metadata: ["guestId": "\(guest.id.uuidString)"])
✅ logger.debug("RSVP status: \(rsvpStatus)") // Debug only, stripped in production
```

### 2. `pii_insecure_storage.yaml` - Unencrypted PII Storage

**Severity**: ERROR
**CWE**: CWE-311 (Missing Encryption of Sensitive Data)

Detects storing PII in insecure locations:
- UserDefaults (unencrypted, accessible via backups)
- NSKeyedArchiver without encryption
- Plist files containing guest/vendor data
- FileManager writing PII to disk

**Example Violations**:
```swift
❌ UserDefaults.standard.set(guest.email, forKey: "guestEmail")
❌ let data = try NSKeyedArchiver.archivedData(withRootObject: guestList)
❌ try guestData.write(to: fileURL) // Unencrypted disk write
```

**Remediation**:
```swift
✅ // Use Supabase (encrypted at rest) - fetch on-demand
✅ // Use RepositoryCache (memory-only, TTL-based)
✅ // Use Keychain for sensitive tokens (SessionManager already does this)
```

### 3. `health_data_exposure.yaml` - Health-Related PII Protection

**Severity**: WARNING
**CWE**: CWE-359 (Exposure of Private Personal Information)

Detects exposure of health-related data without consent/warnings:
- Dietary restrictions (allergies, medical conditions)
- Accessibility needs (disabilities, medical equipment)
- Preparation notes (may contain health info)

**Example Violations**:
```swift
❌ analytics.track("guest_updated", properties: ["dietary": guest.dietaryRestrictions])
❌ let csv = guests.map { "\($0.name),\($0.dietaryRestrictions)" } // Export without warning
❌ Sentry.captureMessage("Failed: \(guest.accessibilityNeeds)")
```

**Remediation**:
```swift
✅ // Add consent check before accessing health fields
if userConsentedToHealthData {
    process(guest.dietaryRestrictions)
}

✅ // Scrub health data from crash reports
Sentry.configureScope { scope in
    scope.setContext("guest", value: ["id": guest.id]) // No PII
}

✅ // Show export warning
showAlert("This file contains dietary restrictions (health data). Encrypt before sharing.")
```

### 4. `pii_hardcoded_data.yaml` - Hardcoded PII Detection

**Severity**: ERROR
**CWE**: CWE-798 (Use of Hard-coded Credentials)

Detects hardcoded PII in source code (test data, examples):
- Hardcoded email addresses (non-example.com)
- Hardcoded phone numbers (realistic formats)
- Hardcoded guest/vendor names
- Hardcoded addresses, dietary restrictions

**Example Violations**:
```swift
❌ let testGuest = Guest(firstName: "John", lastName: "Doe", email: "john.doe@gmail.com")
❌ let phone = "415-555-1234" // Real-looking phone number
❌ Vendor(contactName: "Jane Smith", email: "jane@vendor.com")
```

**Remediation**:
```swift
✅ Guest.makeTest(email: "test-\(UUID().uuidString)@example.com")
✅ let phone = "555-0100" // Clearly fake (555 prefix)
✅ Vendor.makeTest(contactName: "Sample Vendor \(Int.random(in: 1...100))")
```

### 5. `pii_export_unencrypted.yaml` - Insecure Export Detection

**Severity**: WARNING
**CWE**: CWE-311 (Missing Encryption of Sensitive Data)

Detects exporting PII to unencrypted formats without warnings:
- CSV/Excel export without encryption
- JSON export with PII
- Share sheet without warnings
- Google Sheets API uploads

**Example Violations**:
```swift
❌ let csv = guests.map { "\($0.name),\($0.email)" }.joined(separator: "\n")
❌ try csvData.write(to: fileURL) // No encryption warning
❌ googleSheetsAPI.append(values: [guest.name, guest.email, guest.dietary])
```

**Remediation**:
```swift
✅ showExportWarning("Export 127 guests with email/dietary info?")
✅ // Offer encrypted export option
✅ logExport(userId: userId, recordCount: guests.count, timestamp: Date())
✅ // Add "Exclude Health Data" toggle
```

## Usage

### Running Rules Individually

```bash
# Run specific rule
semgrep --config .semgrep/wedding-pii-rules/pii_logging_detection.yaml "I Do Blueprint/"

# Run all wedding PII rules
semgrep --config .semgrep/wedding-pii-rules/ "I Do Blueprint/"

# Combine with akabe1-semgrep-rules (iOS Swift rules)
semgrep --config .semgrep/wedding-pii-rules/ \
        --config ~/akabe1-semgrep-rules/ios/swift/ \
        "I Do Blueprint/"
```

### Running with swiftscan Wrapper

The project already has a `swiftscan` wrapper (see `scripts/security-check.sh`):

```bash
# Run all security scans (includes Semgrep)
./scripts/security-check.sh

# Or directly
swiftscan "I Do Blueprint/"
```

### CI/CD Integration

Add to `.github/workflows/security.yml`:

```yaml
- name: Run Semgrep PII Detection
  run: |
    semgrep --config .semgrep/wedding-pii-rules/ \
            --config ~/akabe1-semgrep-rules/ios/swift/ \
            --sarif --output semgrep-results.sarif \
            "I Do Blueprint/"

- name: Upload SARIF to GitHub Security
  uses: github/codeql-action/upload-sarif@v2
  with:
    sarif_file: semgrep-results.sarif
```

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
echo "Running PII detection on staged Swift files..."
git diff --cached --name-only --diff-filter=ACM | grep '\.swift$' | while read file; do
  semgrep --config .semgrep/wedding-pii-rules/ "$file" || exit 1
done
```

## Integration with Existing Tools

### 1. SwiftLint Integration

Add to `.swiftlint.yml`:

```yaml
custom_rules:
  no_pii_in_logs:
    regex: 'logger\.(info|error|warning).*\.(firstName|lastName|email|phone|address)'
    message: "Do not log PII (use Semgrep for detailed detection)"
    severity: error
```

### 2. Sentry Error Scrubbing

Already configured in `SentryService.swift`:

```swift
options.beforeSend = { event in
    // Scrub PII from error messages
    event.message = event.message?.replacingOccurrences(
        of: #"[\w\.-]+@[\w\.-]+\.\w+"#,
        with: "[EMAIL_REDACTED]",
        options: .regularExpression
    )
    return event
}
```

### 3. Basic Memory MCP Server

Document PII incidents in knowledge base:

```bash
# Log PII finding for future reference
mcp__basic-memory__write_note(
  title: "PII Logging Found in GuestStore",
  folder: "security/incidents",
  project: "i-do-blueprint",
  content: "Semgrep detected guest email logging in GuestStore.swift:245"
)
```

## False Positive Handling

### Excluding Test Files

Add to `.semgrep.yml`:

```yaml
exclude:
  - "**/Tests/**"
  - "**/Helpers/ModelBuilders.swift"  # Test data factories
  - "**/*Preview.swift"                # SwiftUI previews
```

### Suppressing Specific Findings

```swift
// nosemgrep: wedding-pii-logging
logger.debug("Guest email for debugging: \(guest.email)") // Only in DEBUG
```

## Compliance Mapping

| Rule | GDPR Article | CWE | OWASP 2021 | State Laws (2024) |
|------|--------------|-----|------------|-------------------|
| pii_logging_detection | Art. 5, 32 | CWE-532 | A09 | WA My Health My Data Act |
| pii_insecure_storage | Art. 32 | CWE-311 | A02 | CCPA, NV SB370 |
| health_data_exposure | Art. 9 | CWE-359 | A01 | CT SB3, WA MHMDA |
| pii_hardcoded_data | Art. 32 | CWE-798 | A07 | GDPR, CCPA |
| pii_export_unencrypted | Art. 32 | CWE-311 | A02 | GDPR, CCPA |

## References

### PII & GDPR Compliance (2024)
- [What is PII? - TechTarget](https://www.techtarget.com/searchsecurity/definition/personally-identifiable-information-PII)
- [Personal Data and PII: GDPR Guide - Protecto.ai](https://www.protecto.ai/blog/personal-data-and-pii-a-guide-to-data-privacy-under-gdpr/)
- [PII Compliance Checklist 2025 - Sentra](https://www.sentra.io/learn/pii-compliance-checklist)

### Health Data Privacy (2024)
- [Six Current Data Privacy Challenges - American Bar Association](https://www.americanbar.org/groups/health_law/resources/esource/2024-november/six-current-data-privacy-challenges/)
- [Navigating Data Privacy in Healthcare - EY](https://www.ey.com/en_us/insights/health/navigating-data-privacy-evolution-in-health-care)
- [Health Privacy Developments 2025 - Global Policy Watch](https://www.globalpolicywatch.com/2024/12/health-privacy-developments-to-watch-in-2025/)

### iOS Security Best Practices
- [OWASP MASTG - iOS Data Storage](https://mas.owasp.org/MASTG/iOS/0x06d-Testing-Data-Storage/)
- [Apple Security Guide - Keychain](https://support.apple.com/guide/security/keychain-data-protection-secb0694df1a/web)

### Wedding App Privacy Context
- [Technology in Modern Weddings - Privacy Concerns](https://www.paraisofashionfair.com/expert-wedding-tips/technology-in-modern-weddings/)

## License

These rules are released under the same license as the parent project. Based on patterns from [akabe1-semgrep-rules](https://github.com/akabe1/akabe1-semgrep-rules) (GNU GPL v3).

## Author

I Do Blueprint Security Team
Generated: 2026-01-01
Project: I Do Blueprint Wedding Planning App
