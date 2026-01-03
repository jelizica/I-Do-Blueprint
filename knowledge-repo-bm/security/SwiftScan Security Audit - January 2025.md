---
title: SwiftScan Security Audit - January 2025
type: note
permalink: security/swift-scan-security-audit-january-2025
tags:
- security
- audit
- swiftscan
- semgrep
- ios-security
---

# SwiftScan Security Audit - January 2025

## Overview

Security scan performed on the I Do Blueprint macOS application using `swiftscan . --json`, which leverages Semgrep with iOS/Swift-specific security rules.

**Scan Date**: January 2025
**Tool**: SwiftScan (Semgrep-based)
**Version**: 1.146.0

## Scan Statistics

| Metric | Value |
|--------|-------|
| Total Files Scanned | 1,158 |
| Swift Files | 939 |
| Total Rules Applied | 346 |
| Pro Rules | 268 |
| Community Rules | 54 |
| Custom Rules | 24 |

## Findings Summary

| Severity | Count | Category |
|----------|-------|----------|
| WARNING | 36 | Various security concerns |
| Critical | 0 | None identified |

### Finding Categories

1. **Insecure Storage (UserDefaults)** - 14 findings
2. **Hardcoded Secrets/Keys** - 21 findings (mostly false positives)
3. **Keychain Without User Auth** - 1 finding

---

## Detailed Findings

### 1. Insecure Storage - UserDefaults Usage

**Severity**: WARNING (MEDIUM confidence)
**CWE**: CWE-311 (Missing Encryption of Sensitive Data)

#### Affected Files

**FeatureFlags.swift** (9 instances)
- Line 33: `UserDefaults.standard.set(value, forKey: key)`
- Line 61: `UserDefaults.standard.set(value, forKey: key)`
- Line 118: `UserDefaults.standard.set(flags, forKey: cacheKey)`
- Line 119: `UserDefaults.standard.set(Date(), forKey: cacheTimestampKey)`
- Line 187: `UserDefaults.standard.set(true, forKey: guestStoreV2Key)`
- Line 191: `UserDefaults.standard.set(false, forKey: guestStoreV2Key)`
- Line 201: `UserDefaults.standard.set(true, forKey: vendorStoreV2Key)`
- Line 205: `UserDefaults.standard.set(false, forKey: vendorStoreV2Key)`
- Line 341: `UserDefaults.standard.set(newId, forKey: key)` (device identifier)

**SessionManager.swift** (1 instance)
- Line 329: `UserDefaults.standard.set(encoded, forKey: recentCouplesKey)`

**BrandingSettingsManager.swift** (1 instance)
- Line 36: Custom branding settings stored in UserDefaults

#### Risk Assessment

**LOW RISK** - The data stored in UserDefaults is:
- Feature flag boolean values (non-sensitive)
- Cache timestamps (non-sensitive)
- Device identifiers (UUID, non-PII)
- Recent couples list (convenience, not security-critical)
- Branding preferences (non-sensitive)

#### Recommendation

**ACCEPT** - Document this as an intentional design decision. UserDefaults is appropriate for non-sensitive configuration data. Add code comments explaining the security rationale.

---

### 2. Hardcoded Secrets/Keys

**Severity**: WARNING (LOW-MEDIUM confidence)
**CWE**: CWE-798 (Use of Hard-coded Credentials), CWE-547 (Use of Hard-coded, Security-relevant Constants)

#### True Positives (Require Action)

**ResendEmailService.swift** (Line 22)
```swift
private let embeddedAPIKey = "re_5tuxAHLr_3LtMhuJ2de7d6Awh2aLyTjup"
```
- **Risk**: HIGH - API key exposed in source code
- **Action**: Review if this should be moved to Keychain or backend proxy
- **Beads Issue**: I Do Blueprint-2fz

**AppConfig.swift** (Line 25)
```swift
static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```
- **Risk**: ACCEPTED - This is the Supabase anonymous key, designed to be public
- **Action**: Document that this is intentionally client-side
- **Beads Issue**: I Do Blueprint-v9z

#### False Positives (Cache Keys)

The following are **NOT security issues** - they are cache key identifiers, not secrets:

| File | Line | Key Name | Assessment |
|------|------|----------|------------|
| FeatureFlags.swift | 41 | `cacheKey` | Cache identifier |
| FeatureFlags.swift | 42 | `cacheTimestampKey` | Cache identifier |
| FeatureFlags.swift | 135-146 | Various feature flag keys | Configuration keys |
| FeatureFlags.swift | 334 | `deviceIdentifier` | Key name, not secret |
| BudgetCategoryDataSource.swift | 30 | `budget_categories` | Cache key |
| GiftsAndOwedDataSource.swift | 183, 317 | `gifts_received`, `money_owed` | Cache keys |
| LiveBudgetRepository.swift | 134, 584 | `budget_summary`, `tax_rates` | Cache keys |
| LiveVendorRepository.swift | 611 | `vendor_types_all` | Cache key |
| CollaborationPermissionService.swift | 103 | `collaboration_roles` | Cache key |
| SessionManager.swift | 68, 70, 71 | Keychain identifiers | Service identifiers |
| BrandingSettingsManager.swift | 20 | `CustomBranding` | UserDefaults key |

---

### 3. Keychain Without User Authentication

**Severity**: WARNING (MEDIUM confidence)
**CWE**: CWE-287 (Improper Authentication)
**OWASP**: MASVS-AUTH-3

#### Finding

**SessionManager.swift** (Line 250)
```swift
let status = SecItemAdd(query as CFDictionary, nil)
```

The Keychain operation does not require user authentication (biometric/passcode) before accessing stored items.

#### Risk Assessment

**MEDIUM RISK** - Session data stored in Keychain can be accessed without user verification. On a compromised device, this could allow unauthorized access to tenant selection data.

#### Recommendation

Consider adding `kSecAttrAccessControl` with appropriate flags:

```swift
let access = SecAccessControlCreateWithFlags(
    nil,
    kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
    .userPresence,  // Requires biometric or passcode
    nil
)

let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: keychainService,
    kSecAttrAccount as String: account,
    kSecValueData as String: data,
    kSecAttrAccessControl as String: access as Any  // Add this
]
```

**Beads Issue**: I Do Blueprint-ik5

---

## Action Items (Beads Issues)

### Priority 1 (High)
- [ ] **I Do Blueprint-2fz**: "Security Audit: Review Resend API key exposure in ResendEmailService.swift" - consider moving to Keychain or backend proxy

### Priority 2 (Medium)
- [ ] **I Do Blueprint-ik5**: "Security Audit: Add user authentication to Keychain operations in SessionManager" - add biometric/passcode requirements

### Priority 3 (Low)
- [ ] **I Do Blueprint-7mu**: "Security Audit: Evaluate UserDefaults usage for feature flags storage" - document as accepted risk
- [ ] **I Do Blueprint-v9z**: "Security Audit: Document Supabase anon key as intentional client-side key" - add code comments

---

## Security Architecture Notes

### What IS Secure

1. **Keychain Usage**: Session tokens and tenant IDs stored in Keychain (not UserDefaults)
2. **RLS Enforcement**: All database queries filtered by `couple_id` with Row Level Security
3. **No Service Role Key**: Only anon key in client code (service_role never exposed)
4. **Secure API Key Storage**: User-provided API keys (Google, Unsplash) stored in Keychain via `SecureAPIKeyManager`

### What Needs Attention

1. **Resend API Key**: Embedded in source code - evaluate risk vs. convenience
2. **Keychain Auth**: Consider biometric requirements for sensitive operations
3. **Documentation**: Security decisions should be documented in code comments

---

## References

- [OWASP MASTG - iOS Data Storage](https://mas.owasp.org/MASTG/iOS/0x06d-Testing-Data-Storage/)
- [OWASP MASTG - iOS Local Authentication](https://mas.owasp.org/MASTG/0x06f-Testing-Local-Authentication/)
- [CWE-311: Missing Encryption of Sensitive Data](https://cwe.mitre.org/data/definitions/311.html)
- [CWE-798: Use of Hard-coded Credentials](https://cwe.mitre.org/data/definitions/798.html)
- [CWE-287: Improper Authentication](https://cwe.mitre.org/data/definitions/287.html)

---

## Scan Command

```bash
swiftscan . --json
```

## Next Scan

Schedule quarterly security scans to track remediation progress and identify new issues.

---

**Last Updated**: January 2025
**Scan Tool**: SwiftScan (Semgrep v1.146.0)
**Auditor**: AI Security Analysis
