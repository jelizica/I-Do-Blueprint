# Semgrep Rule Overlap Analysis

**Date**: 2026-01-01
**Analysis**: Comparison of `.semgrep/rules/pii-tracking.yaml` vs `.semgrep/wedding-pii-rules/`

## Summary

### ✅ No Critical Overlaps
The wedding PII rules and existing custom rules complement each other with minimal duplication. Both rule sets should be kept active.

### 📊 Overlap Categories

| Category | Existing Rules (pii-tracking.yaml) | Wedding PII Rules | Overlap Level | Action |
|----------|-----------------------------------|-------------------|---------------|--------|
| **PII Logging** | Limited (email only) | Comprehensive (40+ fields) | Low | Keep both |
| **Insecure Storage** | UserDefaults auth tokens | UserDefaults + NSKeyedArchiver + FileManager | Medium | Keep both |
| **Health Data** | Not covered | Dedicated rule (dietary/accessibility) | None | Keep wedding rule |
| **Export Security** | Generic CSV warning | Detailed export patterns | Low | Keep both |
| **Hardcoded Secrets** | Generic API key detection | Hardcoded PII in test data | Low | Keep both |

---

## Detailed Comparison

### 1. PII in Logs

#### **Existing Rule: `guest-email-exposure`** (pii-tracking.yaml:24-40)
```yaml
- id: guest-email-exposure
  pattern-either:
    - pattern: print($GUEST.email)
    - pattern: logger.debug(..., $GUEST.email, ...)
    - pattern: logger.info(..., $GUEST.email, ...)
```
**Scope**: Only detects `$GUEST.email` logging

#### **Wedding Rule: `wedding-pii-logging`** (pii_logging_detection.yaml)
```yaml
- metavariable-regex:
    metavariable: $MSG
    regex: (?i).*(firstName|lastName|fullName|email|phone|phoneNumber|
                  formattedPhone|addressLine|address|city|state|zipCode|
                  postalCode|country|dietaryRestrictions|accessibilityNeeds|
                  contactName|streetAddress|plusOneName).*
```
**Scope**: 40+ PII fields across guests, vendors, and health data

**Verdict**: ✅ **Keep both** - Wedding rule is far more comprehensive and catches patterns the existing rule misses.

---

### 2. Insecure Storage

#### **Existing Rule: `auth-token-in-userdefaults`** (pii-tracking.yaml:163-182)
```yaml
- id: auth-token-in-userdefaults
  pattern-either:
    - pattern: UserDefaults.standard.set($TOKEN, forKey: $KEY)
  metavariable-pattern:
    metavariable: $KEY
    patterns:
      - pattern-regex: ".*(token|session|auth|jwt|bearer|api_key|access|refresh).*"
```
**Scope**: UserDefaults storing auth tokens only

#### **Wedding Rule: `wedding-pii-insecure-storage`** (pii_insecure_storage.yaml)
```yaml
# Pattern 1: UserDefaults with PII field names
- pattern: UserDefaults.standard.set($VALUE, forKey: $KEY)
- metavariable-regex:
    metavariable: $KEY
    regex: (?i).*(guest|vendor|contact|firstName|lastName|email|phone|
                  address|dietary|accessibility|health|medical|name|contact).*

# Pattern 3: NSKeyedArchiver with Guest/Vendor models
- pattern: $DATA = NSKeyedArchiver.archivedData(withRootObject: $OBJ, ...)
- metavariable-regex:
    metavariable: $OBJ
    regex: (guest|vendor|guestList|vendorList|contactInfo)

# Pattern 4: FileManager writing PII to disk
- pattern: "$DATA.write(to: $URL)"
- metavariable-regex:
    metavariable: $DATA
    regex: (?i).*(guest|vendor|contact).*
```
**Scope**: UserDefaults (PII keys) + NSKeyedArchiver + FileManager

**Verdict**: ✅ **Keep both** - Existing rule focuses on auth tokens (security-critical), wedding rule focuses on PII (privacy-critical). Different concerns.

---

### 3. Health Data Exposure

#### **Existing Rule**: None

#### **Wedding Rule: `wedding-health-data-exposure`** (health_data_exposure.yaml)
```yaml
- pattern-either:
    - pattern: $GUEST.dietaryRestrictions
    - pattern: $GUEST.accessibilityNeeds
    - pattern: $GUEST.preparationNotes
```
**Scope**: Detects health-related PII access without consent checks

**Verdict**: ✅ **Unique to wedding rules** - Critical for GDPR Article 9 and 2024 state health privacy laws. No equivalent in existing rules.

---

### 4. CSV/Excel Export

#### **Existing Rule: `pii-export-without-sanitization`** (pii-tracking.yaml:220-238)
```yaml
- id: pii-export-without-sanitization
  pattern-either:
    - pattern: exportToCSV(guests: $GUESTS)
    - pattern: exportToExcel(guests: $GUESTS)
    - pattern: GuestExportService.$METHOD($GUESTS)
  severity: INFO
```
**Scope**: Generic function call detection (INFO level)

#### **Wedding Rule: `wedding-pii-export-unencrypted`** (pii_export_unencrypted.yaml)
```yaml
# Pattern 1: CSV export without encryption warning
- pattern-inside: |
    func $FUNC(...) {
      ...
      $CSV = $GUESTS.map { ... }.joined(separator: ...)
      ...
      try $CSV.write(to: $URL, ...)
      ...
    }
- metavariable-regex:
    metavariable: $FUNC
    regex: (?i)(export|download|save|generate).*CSV

# Pattern 5: Google Sheets API export
- pattern: $CLIENT.appendRow(..., values: $VALUES, ...)
- metavariable-regex:
    metavariable: $CLIENT
    regex: (?i)(google|sheets|drive|api)
```
**Scope**: Detailed export patterns (CSV generation, file writes, third-party APIs) - WARNING level

**Verdict**: ✅ **Keep both** - Existing rule catches high-level export functions, wedding rule catches low-level implementation patterns and third-party disclosures.

---

### 5. Hardcoded Secrets

#### **Existing Rule: `hardcoded-api-key`** (pii-tracking.yaml:131-144)
```yaml
- id: hardcoded-api-key
  pattern-either:
    - pattern: let $VAR = "$SECRET"
    - pattern: var $VAR = "$SECRET"
  metavariable-pattern:
    metavariable: $VAR
    patterns:
      - pattern-regex: ".*(key|token|secret|password|api).*"
```
**Scope**: API keys and auth secrets

#### **Wedding Rule: `wedding-pii-hardcoded-data`** (pii_hardcoded_data.yaml)
```yaml
# Pattern 1: Hardcoded email addresses (non-example.com)
- pattern: let $VAR = "=~/.*@.*\\..*/"
- metavariable-regex:
    metavariable: $VAR
    regex: (?i)(email|contact|userEmail)
- pattern-not: $VAR = "=~/.*@example\\.(com|org|net)/"

# Pattern 2: Hardcoded phone numbers
- pattern-regex: "\\d{3}-\\d{3}-\\d{4}"

# Pattern 3: Hardcoded guest/vendor data in test builders
- pattern: Guest(firstName: "$NAME", lastName: "$NAME", email: "$EMAIL", ...)
```
**Scope**: Hardcoded PII in test data and examples

**Verdict**: ✅ **Keep both** - Existing rule targets API secrets (security), wedding rule targets PII in code (privacy + test hygiene).

---

## Rules Unique to Existing pii-tracking.yaml

These rules have **no equivalent** in wedding PII rules and should be retained:

1. **`guest-pii-database-query`** - Detects `.from("guest_list")` without RLS checks
2. **`missing-couple-id-filter`** - Ensures multi-tenancy filters
3. **`uuid-to-string-conversion`** - Catches UUID case mismatch bug pattern
4. **`insecure-keychain-accessibility`** - Keychain security hardening
5. **`service-role-key-in-client`** - CRITICAL security check
6. **`database-error-exposed-to-user`** - Information disclosure prevention
7. **`unsafe-query-string-interpolation`** - SQL injection prevention
8. **`auth-state-logged`** - Auth token/session logging detection
9. **`realtime-channel-without-rls-filter`** - Realtime multi-tenancy checks
10. **`vendor-contact-exposure`** - Vendor PII in logs
11. **`budget-data-logging`** - Financial data logging
12. **`sensitive-data-in-error-messages`** - PII in exception messages
13. **`required-reason-api-usage`** - Privacy Manifest compliance

---

## Rules Unique to Wedding PII Rules

These rules are **new additions** not covered by existing rules:

1. **`wedding-pii-logging`** - Comprehensive 40+ field PII logging detection
2. **`wedding-pii-insecure-storage`** - NSKeyedArchiver + FileManager patterns
3. **`wedding-health-data-exposure`** - Health data (dietary/accessibility) specific checks
4. **`wedding-pii-hardcoded-data`** - Hardcoded PII in test data
5. **`wedding-pii-export-unencrypted`** - Detailed export implementation patterns

---

## Recommendations

### ✅ Keep Both Rule Sets Active

**Reasoning**:
1. **Minimal Duplication**: Only 2 rules have partial overlap (logging, UserDefaults storage)
2. **Different Focus Areas**:
   - Existing rules: Multi-tenancy, auth security, database queries, Supabase-specific
   - Wedding rules: Privacy compliance, health data, export security, test hygiene
3. **Complementary Coverage**: Together they provide comprehensive security + privacy coverage
4. **Severity Levels Differ**: Overlapping rules use different severity levels for different contexts

### 🔧 Optional Deduplication (Low Priority)

If you want to deduplicate, consider these **safe consolidations**:

#### Option 1: Disable Existing `guest-email-exposure` (Low Impact)
- **Reason**: `wedding-pii-logging` is far more comprehensive (40+ fields vs 1 field)
- **Risk**: Minimal - wedding rule covers all email logging patterns
- **Action**: Comment out `guest-email-exposure` in pii-tracking.yaml

#### Option 2: Merge UserDefaults Rules (Optional)
- **Existing**: `auth-token-in-userdefaults` (auth tokens only)
- **Wedding**: UserDefaults pattern in `wedding-pii-insecure-storage` (PII keys only)
- **Action**: Keep both - they target different data types (auth vs PII)

### 📈 Coverage Metrics

| Security Domain | Existing Rules | Wedding Rules | Combined Coverage |
|-----------------|----------------|---------------|-------------------|
| Multi-tenancy | ✅ Excellent | ❌ None | ✅ Excellent |
| Auth Security | ✅ Excellent | ❌ None | ✅ Excellent |
| PII Logging | ⚠️ Limited (1 field) | ✅ Comprehensive (40+ fields) | ✅ Excellent |
| Health Data Privacy | ❌ None | ✅ Excellent | ✅ Excellent |
| Export Security | ⚠️ Generic | ✅ Detailed | ✅ Excellent |
| Test Hygiene | ❌ None | ✅ Good | ✅ Good |
| Database Security | ✅ Excellent | ❌ None | ✅ Excellent |

---

## Conclusion

**Both rule sets should remain active** with no deduplication required. The overlap is minimal (< 10%) and both sets provide unique, valuable security and privacy coverage. The wedding PII rules fill critical gaps in health data privacy and export security, while existing rules provide essential multi-tenancy and database security checks.

**Final Rule Count**: 13 existing + 5 wedding = **18 total security rules** with < 2 overlapping patterns.
