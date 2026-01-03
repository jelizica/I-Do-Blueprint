---
title: Semgrep - Swift Security Scanning (SAST/SCA)
type: note
permalink: ai-tools/security/semgrep-swift-security-scanning-sast-sca
tags:
- security
- sast
- sca
- static-analysis
- swift
- vulnerability-scanning
- owasp
- cli
---

# Semgrep - Swift Security Scanning (SAST/SCA)

> **Fast, open-source static analysis for finding bugs, detecting vulnerabilities, and enforcing secure coding standards**

## Overview

Semgrep is a lightweight static application security testing (SAST) and software composition analysis (SCA) tool that uses semantic analysis to find security vulnerabilities, bugs, and anti-patterns in source code. Unlike traditional SAST tools, Semgrep uses pattern-based rules that look like the source code itself—making it accessible to both security engineers and developers without requiring deep knowledge of abstract syntax trees or complex DSLs.

**Agent Attachments:**
- ❌ Qodo Gen
- ❌ Claude Code  
- ❌ Claude Desktop
- ✅ **CLI/Shell** (available to all AI agents via shell commands)

---

## Key Features

### Core Capabilities

1. **Static Application Security Testing (SAST)**
   - Detects OWASP Top 10 vulnerabilities
   - CWE Top 25 weakness coverage
   - Injection vulnerabilities (SQL, XSS, command injection, path traversal)
   - Cryptographic misuse detection
   - Hardcoded secrets discovery
   - Authentication and authorization flaws

2. **Software Composition Analysis (SCA)**
   - Dependency vulnerability scanning via OSV database
   - SBOM generation (Software Bill of Materials)
   - License compliance analysis
   - Reachability analysis (detect if vulnerable code paths are actually used)
   - Swift Package Manager (SwiftPM) support

3. **Secrets Detection**
   - API keys, tokens, and credentials
   - Semantic analysis beyond regex patterns
   - Entropy-based detection
   - Validation of discovered secrets

4. **Swift Language Support**
   - **General Availability (GA)** as of 2024
   - 94%+ parse rate for Swift code
   - 57 Pro rules for Swift vulnerabilities
   - Cross-file and cross-function analysis with Pro Engine
   - SwiftPM lockfile support for dependency scanning

5. **AI-Powered Analysis**
   - **Semgrep Assistant** uses GPT-4 to reduce false positives
   - Context-aware recommendations with reasoning
   - Auto-fix suggestions for common issues
   - Rule effectiveness analytics

---

## Supported Languages & Platforms

### Language Support

**Generally Available (GA)**: Swift, Python, JavaScript, TypeScript, Java, Go, Ruby, C, C++, C#, PHP, Kotlin, Scala, Rust

**Swift-Specific Features:**
- Full syntax support (94%+ parse rate)
- iOS/macOS framework-specific rules
- UIKit/SwiftUI security patterns
- Keychain and secure storage analysis
- OWASP Mobile Security Testing Guide (MSTG) coverage

### Package Managers (SCA)

- **Swift**: SwiftPM (Package.resolved)
- Also supports: npm, Maven, Gradle, pip, Cargo, Composer, RubyGems, and more

---

## Installation

### macOS Installation (Homebrew)

```bash
# Install Semgrep via Homebrew
brew install semgrep

# Verify installation
semgrep --version
```

### Alternative Installation Methods

```bash
# Via pip (Python)
pip install semgrep

# Via Docker
docker pull semgrep/semgrep

# Via npm
npm install -g @semgrep/cli
```

---

## Configuration

### Shell Alias (from ~/.zshrc)

I Do Blueprint uses a custom shell function `swiftscan()` for Swift-focused security scanning:

```bash
swiftscan() {
    semgrep --config ~/akabe1-semgrep-rules/ios/swift/ \
            --config p/swift \
            --config p/secrets \
            "$@"
}
```

**Usage:**
```bash
# Scan current directory
swiftscan .

# Scan specific file
swiftscan src/Auth/AuthManager.swift

# Scan with specific severity
swiftscan --severity ERROR .

# Generate JSON output
swiftscan --json -o results.json .
```

### Configuration Breakdown

The `swiftscan()` function combines three rule sources:

1. **Custom Rules** (`~/akabe1-semgrep-rules/ios/swift/`)
   - Community-maintained iOS/Swift security rules
   - OWASP Mobile Security Testing Guide (MSTG) coverage
   - akabe1's comprehensive Swift vulnerability patterns

2. **Official Swift Rules** (`p/swift`)
   - Semgrep's 57 Pro rules for Swift
   - Framework-specific analysis (UIKit, SwiftUI, Foundation)
   - iOS-specific vulnerability patterns

3. **Secrets Detection** (`p/secrets`)
   - API keys, tokens, credentials
   - Hardcoded passwords
   - Private keys (SSH, SSL, etc.)
   - OAuth tokens

---

## Rule Sources & Custom Rules

### Official Semgrep Rules

```bash
# Browse Semgrep Registry
open https://semgrep.dev/r

# Use official Swift rules
semgrep --config p/swift .

# Use OWASP Top 10 rules
semgrep --config p/owasp-top-ten .

# Use security rules
semgrep --config p/security-audit .
```

### Custom Rule Repositories

**1. akabe1-semgrep-rules** (Used in I Do Blueprint)
- **Repository**: https://github.com/akabe1/akabe1-semgrep-rules
- **Focus**: iOS/Swift mobile security
- **Coverage**: OWASP MSTG checklist for iOS
- **Maintained By**: Maurizio Siddu (@akabe1), IMQ Minded Security

**2. OWASP Mobile Application Security Rules**
- **Repository**: https://github.com/insideapp-oss/mobile-application-security-rules
- **Focus**: OWASP MASTG for iOS (Swift) and Android (Java, Kotlin)
- **Coverage**: Native mobile security patterns

### Location of Custom Rules

```bash
# I Do Blueprint custom rules location
~/akabe1-semgrep-rules/ios/swift/

# Typical structure
~/akabe1-semgrep-rules/
├── ios/
│   └── swift/
│       ├── authentication/
│       ├── cryptography/
│       ├── network/
│       ├── storage/
│       └── webview/
└── README.md
```

---

## Command Line Usage

### Basic Scanning

```bash
# Scan entire project
semgrep --config auto .

# Scan with specific config
semgrep --config p/swift .

# Scan single file
semgrep --config p/security-audit src/DatabaseManager.swift
```

### Advanced Options

```bash
# Scan with custom rules + official rules
semgrep --config ~/my-rules --config p/swift .

# Filter by severity
semgrep --config p/swift --severity ERROR .

# Exclude directories
semgrep --config p/swift --exclude '*/Tests/*' .

# Output formats
semgrep --json -o results.json .
semgrep --sarif -o results.sarif .
semgrep --junit-xml -o results.xml .

# Verbose output
semgrep --config p/swift --verbose .

# Autofix (where rules provide fixes)
semgrep --config p/swift --autofix .
```

### CI/CD Integration

```bash
# Scan in CI with fail on severity
semgrep ci --config auto --severity ERROR

# Scan only changed files in PR
semgrep ci --config p/swift

# Generate SBOM
semgrep --config p/supply-chain --json -o sbom.json .
```

---

## Semgrep AppSec Platform

### Features

1. **Centralized Management**
   - Dashboard for viewing findings across projects
   - Rule analytics and effectiveness tracking
   - Team collaboration and triage workflows

2. **Integration Capabilities**
   - GitHub, GitLab, Bitbucket PR comments
   - Jira, Slack notifications
   - CircleCI, GitHub Actions, Jenkins

3. **AI-Powered Triage**
   - Semgrep Assistant reduces false positives
   - Contextual explanations for findings
   - Auto-fix suggestions with reasoning

4. **Policy Enforcement**
   - Block builds on critical findings
   - Custom severity thresholds
   - Role-based access control

### Setup

```bash
# Login to Semgrep Cloud
semgrep login

# Run CI scan (sends results to dashboard)
semgrep ci

# Logout
semgrep logout
```

---

## Writing Custom Semgrep Rules

### Rule Structure

Semgrep rules are written in YAML and use pattern-based syntax that resembles source code:

```yaml
rules:
  - id: hardcoded-api-key
    pattern: |
      let apiKey = "$KEY"
    message: Hardcoded API key detected
    languages: [swift]
    severity: ERROR
    metadata:
      category: security
      cwe: "CWE-798: Use of Hard-coded Credentials"
      owasp: "A02:2021 - Cryptographic Failures"
```

### Advanced Patterns

```yaml
rules:
  - id: unsafe-url-loading
    patterns:
      - pattern: WKWebView().load(URLRequest(url: $URL))
      - pattern-not: WKWebView().load(URLRequest(url: URL(string: "https://...")!))
    message: Loading HTTP URL in WKWebView is insecure
    languages: [swift]
    severity: WARNING
```

### Playground for Testing

Test rules interactively: https://semgrep.dev/playground

---

## Swift-Specific Security Checks

### Authentication & Authorization

```bash
# Detect weak authentication
swiftscan --config ~/akabe1-semgrep-rules/ios/swift/authentication/ .
```

**Detects:**
- Weak password policies
- Insecure biometric authentication
- Missing session timeout
- Improper OAuth implementation

### Cryptography

```bash
# Detect cryptographic issues
swiftscan --config ~/akabe1-semgrep-rules/ios/swift/cryptography/ .
```

**Detects:**
- Weak encryption algorithms (MD5, SHA1, DES)
- Hardcoded encryption keys
- Insecure random number generation
- Improper IV/salt usage
- Missing HTTPS certificate pinning

### Secure Storage

```bash
# Detect storage vulnerabilities
swiftscan --config ~/akabe1-semgrep-rules/ios/swift/storage/ .
```

**Detects:**
- Unencrypted data in UserDefaults
- Missing Keychain encryption
- Insecure file permissions
- Logging sensitive data
- Clipboard leaks

### Network Security

```bash
# Detect network issues
swiftscan --config ~/akabe1-semgrep-rules/ios/swift/network/ .
```

**Detects:**
- HTTP instead of HTTPS
- Disabled SSL/TLS validation
- Insecure ATS (App Transport Security) configuration
- Man-in-the-middle vulnerabilities

---

## Supply Chain Security (SCA)

### Scanning Dependencies

```bash
# Scan Package.resolved for vulnerabilities
semgrep --config p/supply-chain .

# Generate SBOM
semgrep --config p/supply-chain --json -o sbom.json .
```

### Lockfile Support

Semgrep requires `Package.resolved` in the repository:

```
I Do Blueprint/
├── Package.swift
├── Package.resolved  # Required for SCA
└── Sources/
```

### OSV Database Integration

Semgrep uses the Open Source Vulnerabilities (OSV) database to detect known vulnerabilities in dependencies.

---

## Integration with I Do Blueprint Workflow

### Pre-Commit Hook

The `security-check.sh` script integrates Semgrep:

```bash
#!/bin/bash
# scripts/security-check.sh

# Run Semgrep security scan
echo "🔍 Running Semgrep security scan..."
swiftscan src/

# Check exit code
if [ $? -ne 0 ]; then
  echo "❌ Security issues detected. Please fix before committing."
  exit 1
fi

# Additional checks...
```

### Workflow Integration

```bash
# 1. Before committing code
swiftscan .

# 2. In CI/CD pipeline
semgrep ci --config auto --severity ERROR

# 3. Pre-deployment scan
swiftscan --severity ERROR src/
```

---

## I Do Blueprint Use Cases

### 1. Pre-Commit Security Checks

Scan code for vulnerabilities before committing to prevent security issues from entering the codebase.

```bash
# In pre-commit hook
swiftscan src/
```

### 2. Authentication & Authorization Review

Ensure proper authentication and authorization patterns in auth-related code.

```bash
# Scan auth module
swiftscan src/Auth/
```

### 3. Supabase Integration Security

Verify secure usage of Supabase client, API keys, and RLS policies.

```bash
# Scan database layer
swiftscan src/Database/ src/Models/
```

### 4. Secrets Detection

Prevent accidental commit of API keys, tokens, and credentials.

```bash
# Detect secrets
semgrep --config p/secrets .
```

### 5. OWASP Mobile Compliance

Ensure compliance with OWASP Mobile Security Testing Guide.

```bash
# Run OWASP MSTG checks
swiftscan --config ~/akabe1-semgrep-rules/ios/swift/ .
```

### 6. Dependency Vulnerability Scanning

Check Swift Package Manager dependencies for known vulnerabilities.

```bash
# SCA scan
semgrep --config p/supply-chain .
```

---

## Performance Benchmarks

| Operation | Performance |
|-----------|-------------|
| **Median CI Scan Time** | 10 seconds |
| **Average Scan Speed** | ~1,000 files/second |
| **Memory Usage** | Low (typically <500 MB) |
| **Incremental Scans** | Scans only changed files in PRs |

---

## Comparison with Other Tools

| Feature | Semgrep | SwiftLint | SonarQube |
|---------|---------|-----------|-----------|
| **Security Focus** | ✅ High | ❌ Low (style) | ✅ Medium |
| **Swift Support** | ✅ GA | ✅ Excellent | ⚠️ Limited |
| **Custom Rules** | ✅ Easy | ✅ Medium | ⚠️ Complex |
| **Speed** | ✅ Fast | ✅ Very Fast | ⚠️ Slow |
| **SCA** | ✅ Yes | ❌ No | ✅ Yes |
| **Price** | ✅ Free (OSS) | ✅ Free | ⚠️ Paid |

---

## Integration with Other Tools

**Complements:**
- **Narsil MCP**: Semgrep finds vulnerabilities, Narsil provides deep code intelligence
- **MCP Shield**: Semgrep scans app code, MCP Shield scans MCP server configurations
- **Themis**: Semgrep detects crypto misuse, Themis provides correct crypto implementations

**Use Together:**
- Run Semgrep before committing (`swiftscan .`)
- Run MCP Shield before deploying (`mcpscan-all`)
- Use Themis for actual cryptographic operations

---

## Resources

### Official Links

- **GitHub**: https://github.com/semgrep/semgrep
- **Documentation**: https://semgrep.dev/docs/
- **Semgrep Registry**: https://semgrep.dev/r
- **Playground**: https://semgrep.dev/playground
- **Swift Language Docs**: https://semgrep.dev/docs/languages/swift
- **AppSec Platform**: https://semgrep.dev/

### Custom Rule Repositories

- **akabe1-semgrep-rules**: https://github.com/akabe1/akabe1-semgrep-rules
- **OWASP Mobile Rules**: https://github.com/insideapp-oss/mobile-application-security-rules

### Tutorials & Guides

- **Swift Support Announcement**: https://semgrep.dev/blog/2022/announcing-swift-exp-support/
- **Swift GA Release**: https://semgrep.dev/products/product-updates/swift-ga/
- **IMQ Minded Security Blog**: https://blog.mindedsecurity.com/2024/04/semgrep-rules-for-ios-application.html
- **Harness Tutorial**: https://developer.harness.io/docs/security-testing-orchestration/sto-techref-category/semgrep/sast-scan-semgrep/

---

## Summary

Semgrep is the **essential SAST/SCA tool for I Do Blueprint security scanning**. It combines the simplicity of pattern-based rules with the power of semantic analysis, making it accessible to both security engineers and developers.

**Key Strengths**:
- 🎯 Simple pattern-based rules (no AST knowledge required)
- ⚡ Blazing fast (10s median CI scan time)
- 🛡️ Comprehensive Swift support (GA with 57 Pro rules)
- 🔍 OWASP Top 10 and CWE Top 25 coverage
- 📦 Supply chain analysis (SCA) with SwiftPM support
- 🤖 AI-powered false positive reduction
- 🆓 Free and open-source
- 🔧 Custom rule creation via simple YAML
- 🏃‍♂️ Fast iteration with Playground testing

**Perfect for I Do Blueprint**:
- Pre-commit security scanning (`swiftscan .`)
- Authentication/authorization review
- Supabase integration security
- Secrets detection
- OWASP Mobile compliance
- Dependency vulnerability scanning
- CI/CD security gates

**Unique Advantage**:
The `swiftscan()` shell function combines akabe1's community Swift rules + official Semgrep rules + secrets detection in a single command, providing comprehensive iOS security coverage tailored for Swift applications.

---

**Last Updated**: December 30, 2025  
**Version**: Current (Latest stable)  
**I Do Blueprint Integration**: Active (via swiftscan shell function)