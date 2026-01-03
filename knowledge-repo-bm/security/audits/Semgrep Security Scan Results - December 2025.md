---
title: Semgrep Security Scan Results - December 2025
type: note
permalink: security/audits/semgrep-security-scan-results-december-2025
tags:
- security
- semgrep
- audit
- 2025-12
---

# Semgrep Security Scan Results - December 2025

## Scan Summary

**Date**: 2025-12-30
**Tool**: swiftscan (Semgrep wrapper for Swift)
**Command**: `swiftscan . --json`
**Total Findings**: 115

## Severity Breakdown

| Severity | Count | Description |
|----------|-------|-------------|
| CRITICAL (ERROR) | 1 | Exposed Stripe API key |
| HIGH | 90 | Hardcoded secrets (many false positives) |
| MEDIUM | 18 | Insecure storage patterns |
| LOW | 6 | Other security concerns |

## Critical Issues

### 1. Exposed Stripe API Key (CRITICAL)
- **File**: `.mcp.json:77`
- **Finding**: `detected-stripe-api-key`
- **CWE**: CWE-798 (Use of Hard-coded Credentials)
- **Beads Issue**: `I Do Blueprint-ty2`
- **Action Required**: IMMEDIATE - Rotate key in Stripe Dashboard

### 2. Hardcoded API Keys in AppConfig.swift (HIGH)
- **File**: `Core/Configuration/AppConfig.swift`
- **Lines**: 40 (supabaseAnonKey), 62 (resendAPIKey)
- **Beads Issue**: `I Do Blueprint-oq3`
- **Note**: Supabase anon key is intentionally public; Resend key needs protection

## Medium Priority Issues

### 3. UserDefaults Insecure Storage
- **Files**: 
  - `FeatureFlags.swift` (12 instances)
  - `BrandingSettingsManager.swift` (2 instances)
  - `SessionManager.swift` (1 instance)
- **CWE**: CWE-311 (Missing Encryption of Sensitive Data)
- **Beads Issues**: `I Do Blueprint-0tz`, `I Do Blueprint-g58`

### 4. Keychain Security Gaps
- **File**: `SessionManager.swift:262-273`
- **Issues**:
  - Uses `kSecAttrAccessibleAfterFirstUnlock` without `ThisDeviceOnly`
  - Missing user authentication requirement
- **Beads Issue**: `I Do Blueprint-cvy`

## False Positives (To Suppress)

### Cache Key Strings (~50 findings)
The following patterns are flagged as "hardcoded secrets" but are actually cache identifiers:
- `budget_categories`
- `gifts_received`
- `money_owed`
- `vendor_types_all`
- `budget_summary`
- `tax_rates`
- `collaboration_roles`

**Files Affected**:
- `BudgetCategoryDataSource.swift`
- `GiftsAndOwedDataSource.swift`
- `LiveBudgetRepository.swift`
- `LiveVendorRepository.swift`
- `CollaborationPermissionService.swift`

**Beads Issue**: `I Do Blueprint-7em`

## Beads Issue Tracking

| Issue ID | Title | Priority | Status |
|----------|-------|----------|--------|
| I Do Blueprint-2uo | Epic: Review all 115 findings | P1 | open |
| I Do Blueprint-ty2 | CRITICAL: Stripe API key | P0 | open |
| I Do Blueprint-oq3 | HIGH: AppConfig keys | P1 | open |
| I Do Blueprint-0tz | HIGH: FeatureFlags UserDefaults | P1 | open |
| I Do Blueprint-cvy | MEDIUM: Keychain protection | P2 | open |
| I Do Blueprint-m8m | MEDIUM: GoogleAuth keychain | P2 | open |
| I Do Blueprint-g58 | MEDIUM: BrandingSettings | P2 | open |
| I Do Blueprint-7em | LOW: False positives | P3 | open |

## Remediation Recommendations

### Immediate (P0)
1. Rotate Stripe API key
2. Remove `.mcp.json` from git or move secrets to environment

### Short-term (P1)
1. Move Resend API key to Config.plist or Keychain
2. Evaluate FeatureFlags storage - consider if flags need encryption
3. Document which keys are intentionally public

### Medium-term (P2)
1. Update Keychain usage to use `ThisDeviceOnly` suffix
2. Add biometric/passcode requirement for sensitive keychain items
3. Review all UserDefaults usage for sensitive data

### Long-term (P3)
1. Configure Semgrep to suppress cache key false positives
2. Add pre-commit hook for security scanning
3. Document security patterns in best_practices.md

## Related Documentation

- [[security/keychain-best-practices]] - Keychain security patterns
- [[architecture/stores/feature-flags]] - FeatureFlags architecture
- [[security/secrets-management]] - Secrets management strategy

## References

- [OWASP MASTG - iOS Data Storage](https://mas.owasp.org/MASTG/iOS/0x06d-Testing-Data-Storage/)
- [CWE-798: Hard-coded Credentials](https://cwe.mitre.org/data/definitions/798.html)
- [CWE-311: Missing Encryption](https://cwe.mitre.org/data/definitions/311.html)
