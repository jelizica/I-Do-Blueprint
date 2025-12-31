# Security Tools for Your macOS App: Complete Guide

A comprehensive guide to four security tools for protecting your vibecoded macOS application, focusing on tools that work with VS Code, Claude Code, terminal CLI, or as Swift packages.

---

## 1. Semgrep + Swift Security Rules

### What It Is
Semgrep is a fast, open-source static analysis tool that finds bugs and enforces code standards. It uses pattern-matching rules that look like the code you write—no complex DSLs or regex wrestling required.

### Why It's Worthy for Your macOS App

- **Swift Support**: Semgrep has experimental (now GA for Pro) support for Swift, making it one of the few SAST tools that actually understands Swift syntax
- **Speed**: Analyzes thousands of lines per second
- **Custom Rules**: Write your own rules for patterns specific to your wedding planning app
- **MCP Integration**: Official Semgrep MCP server works directly with Claude Code
- **Free Tier**: Community Edition is fully open source (LGPL 2.1)

### Security Issues It Detects in Swift/macOS

The akabe1-semgrep-rules collection specifically covers:

| Category | What It Finds |
|----------|---------------|
| **Crypto Issues** | Weak encryption, hardcoded keys, insecure algorithms |
| **Storage Issues** | Insecure data storage, plaintext secrets |
| **Keychain Settings** | Misconfigured keychain access |
| **SQL Injection** | Core Data / SQLite injection vulnerabilities |
| **XXE Issues** | XML External Entity attacks |
| **WebView Issues** | JavaScript injection, insecure WebView configs |
| **Log Injection** | Sensitive data in logs |
| **Certificate Pinning** | Missing or improper SSL pinning |
| **Biometric Auth** | Weak biometric authentication implementation |

### A Note on iOS vs macOS Rules

The akabe1 rules are labeled "ios/swift" but **most Swift security rules apply to both iOS and macOS** because:

- SwiftUI code is identical across platforms
- Crypto APIs (CommonCrypto, CryptoKit) are the same
- Keychain APIs work the same way
- Network security (URLSession, ATS) is shared
- Data storage patterns (UserDefaults, Core Data, file encryption) are identical

**iOS-specific rules that won't apply to macOS apps:**
- `UIWebView` issues (macOS uses `WKWebView` differently)
- iOS-specific biometric APIs
- iOS App Transport Security specifics
- Clipboard/pasteboard rules specific to iOS

These iOS-only rules will simply **not match** anything in your macOS codebase—they won't cause false positives, they just won't fire.

**There are currently no dedicated macOS-specific Semgrep rule sets available.** The best approach is to combine multiple rule sources (see Running Scans below).

### Installation

**Option 1: Homebrew (Recommended for macOS)**
```bash
brew install semgrep
```

**Option 2: pip**
```bash
pip install semgrep
```

**Option 3: Docker**
```bash
docker pull semgrep/semgrep
```

### Setting Up Swift Security Rules

**Where to clone the rules:**

The Swift rules can be cloned anywhere—they're just YAML files that Semgrep reads. Choose one of these locations:

**Option A: In your home directory (recommended for personal use)**
```bash
cd ~
git clone https://github.com/akabe1/akabe1-semgrep-rules.git
```

**Option B: In a dedicated tools folder**
```bash
mkdir -p ~/Developer/security-tools
cd ~/Developer/security-tools
git clone https://github.com/akabe1/akabe1-semgrep-rules.git
```

**Option C: Inside your project (version-controlled with your app)**
```bash
cd /path/to/YourProject
git clone https://github.com/akabe1/akabe1-semgrep-rules.git .semgrep-rules
```

**Clone OWASP MASTG rules (additional mobile security rules):**
```bash
cd ~/Developer/security-tools  # or wherever you put the other rules
git clone https://github.com/insideapp-oss/mobile-application-security-rules.git
```

**Verify it works:**
```bash
# See what rules are available
ls ~/akabe1-semgrep-rules/ios/swift/
```

**Optional: Create an alias for easier scanning**

Add this to your `~/.zshrc` or `~/.bashrc`:
```bash
alias swiftscan="semgrep --config ~/akabe1-semgrep-rules/ios/swift/ --config p/swift --config p/secrets"
```

Then reload your shell and run:
```bash
swiftscan /path/to/YourProject
# or from your project directory:
swiftscan .
```

### Running Scans

**Recommended: Combined scan (best coverage for macOS Swift apps)**
```bash
semgrep --config p/swift --config p/secrets --config ~/akabe1-semgrep-rules/ios/swift/ /path/to/YourProject
```

This gives you:
- Official Semgrep Swift rules (`p/swift`)
- Secrets detection (`p/secrets`)
- Community Swift security rules (iOS-labeled but mostly applicable to macOS)

**Scan your entire project with just the community rules:**
```bash
# Using akabe1 Swift rules (adjust path based on where you cloned)
semgrep --config ~/akabe1-semgrep-rules/ios/swift/ /path/to/YourProject

# Using OWASP mobile rules
semgrep --config ~/Developer/security-tools/mobile-application-security-rules/rules/ /path/to/YourProject

# Using official Semgrep Swift rules only
semgrep --config p/swift /path/to/YourProject

# Scan for secrets only
semgrep --config p/secrets /path/to/YourProject
```

**Scan a single file:**
```bash
semgrep --config ~/akabe1-semgrep-rules/ios/swift/crypto-weak-algorithm.yaml MyEncryption.swift
```

**Output to JSON for processing:**
```bash
semgrep --config p/swift . --json > security-report.json
```

### Claude Code / MCP Integration

**Add Semgrep MCP to Claude Code:**
```bash
claude mcp add semgrep -- uvx semgrep-mcp
```

**Or with environment token for Pro features:**
```bash
claude mcp add-json semgrep '{
  "command": "uvx",
  "args": ["semgrep-mcp"],
  "env": {
    "SEMGREP_APP_TOKEN": "<your-token>"
  }
}'
```

**Claude Desktop config** (`~/Library/Application Support/Claude/claude_desktop_config.json`):
```json
{
  "mcpServers": {
    "semgrep": {
      "command": "uvx",
      "args": ["semgrep-mcp"]
    }
  }
}
```

### Example Workflow
```bash
# 1. Navigate to your project
cd /path/to/IDoBlueprint

# 2. Run a comprehensive security scan
semgrep --config p/swift --config p/secrets --config akabe1-semgrep-rules/ios/swift/ .

# 3. Output to JSON for processing
semgrep --config p/swift . --json > security-report.json
```

### Links
- **GitHub**: https://github.com/semgrep/semgrep
- **Swift Rules (akabe1)**: https://github.com/akabe1/akabe1-semgrep-rules
- **OWASP Mobile Rules**: https://github.com/insideapp-oss/mobile-application-security-rules
- **Semgrep MCP Server**: https://github.com/semgrep/mcp
- **Swift Documentation**: https://semgrep.dev/docs/languages/swift
- **Rule Registry**: https://semgrep.dev/r

---

## 2. MCP-Scan (Invariant Labs)

### What It Is
MCP-Scan is a security scanning tool that protects your MCP (Model Context Protocol) connections from vulnerabilities. Since you're using multiple MCPs with Claude Code and Claude Desktop, this tool scans those MCP servers for malicious behavior.

### Why It's Worthy

- **Protects Your AI Workflow**: Scans all your installed MCP servers for hidden attacks
- **Detects Supply Chain Attacks**: Catches malicious MCP servers before they compromise your system
- **Runtime Monitoring**: Can run as a proxy to monitor all MCP traffic in real-time
- **Tool Pinning**: Detects if MCP tools change after you approved them (rug pull attacks)
- **No API Key Required**: Basic scanning works without external services

### Security Issues It Detects

| Vulnerability | Description |
|---------------|-------------|
| **Tool Poisoning** | Hidden malicious instructions embedded in MCP tool descriptions |
| **MCP Rug Pulls** | Unauthorized changes to MCP tools after initial approval |
| **Cross-Origin Escalation** | One MCP server trying to hijack tools from another server |
| **Prompt Injection** | Malicious instructions in tool descriptions that trick the AI |
| **Data Exfiltration** | Tools designed to steal sensitive data via hidden parameters |
| **Tool Shadowing** | Malicious tools masquerading as legitimate ones |

### Installation

**Recommended: Run via uvx (no install needed)**
```bash
uvx mcp-scan@latest
```

**Or install globally:**
```bash
pip install mcp-scan
```

### Running Scans

**Scan all your MCP configurations:**
```bash
uvx mcp-scan@latest
```

This automatically discovers configs in:
- `~/Library/Application Support/Claude/` (Claude Desktop)
- `~/.codeium/windsurf/` (Windsurf)
- `~/.cursor/` (Cursor)
- `~/.vscode/` (VS Code)

**Scan specific config files (paths are positional arguments, no flag needed):**
```bash
# Single file
uvx mcp-scan@latest inspect "/path/to/your/mcp.json"

# Multiple files
uvx mcp-scan@latest inspect \
  "/Users/you/project/mcp.json" \
  "/Users/you/.claude.json" \
  "/Users/you/Library/Application Support/Claude/claude_desktop_config.json"
```

**Inspect tools without verification (works offline, no API needed):**
```bash
uvx mcp-scan@latest inspect
```

**Inspect with detailed output:**
```bash
uvx mcp-scan@latest inspect --pretty full
```

**Run completely locally (requires OpenAI API key):**
```bash
OPENAI_API_KEY=your-key uvx mcp-scan@latest --local-only
```

### Troubleshooting

**API Timeout / 503 Errors:**

If you see "Could not reach analysis server: 503 - Service Unavailable", the Invariant Labs backend is temporarily down. Your options:

1. **Use inspect mode** (no API needed):
   ```bash
   uvx mcp-scan@latest inspect
   ```

2. **Enable verbose logging** to see what's happening:
   ```bash
   uvx mcp-scan@latest --verbose --print-errors
   ```

3. **Increase server timeout** (if your MCP servers are slow to start):
   ```bash
   uvx mcp-scan@latest --server-timeout 60
   ```

4. **Use local-only mode** (requires OpenAI API key):
   ```bash
   OPENAI_API_KEY=your-key uvx mcp-scan@latest --local-only
   ```

5. **Use MCP-Shield instead** while their server is down:
   ```bash
   npx mcp-shield --claude-api-key YOUR_ANTHROPIC_API_KEY
   ```

**"File does not exist" errors:**

These are normal for MCP clients you don't use (Cursor, VS Code, etc.). The scan will still work for configs that do exist. To avoid the noise, scan only specific paths:
```bash
uvx mcp-scan@latest inspect "/path/to/your/actual/config.json"
```

### Command Reference

```bash
# Get help
uvx mcp-scan@latest --help
uvx mcp-scan@latest inspect --help

# Key flags
--verbose              # Detailed logging
--print-errors         # Show full error tracebacks
--server-timeout N     # Seconds to wait for MCP servers (default: 10)
--json                 # Output as JSON for processing
--local-only           # Run locally without Invariant API (needs OPENAI_API_KEY)
--pretty full          # Detailed output format for inspect
```

### Proxy Mode (Runtime Monitoring)

Run MCP-Scan as a proxy to monitor all MCP traffic in real-time:

```bash
uvx --with "mcp-scan[proxy]" mcp-scan@latest proxy
```

This intercepts and analyzes all MCP traffic, applying guardrails like:
- PII detection
- Secrets detection
- Tool restrictions
- Custom policies

### Managing Trusted Tools (Whitelisting)

```bash
# View current whitelist
uvx mcp-scan@latest whitelist

# Add a tool to whitelist
uvx mcp-scan@latest whitelist tool "tool_name" "hash_value"

# Reset whitelist
uvx mcp-scan@latest whitelist --reset
```

### Example Output
```
Scanning "/Users/jess/Library/Application Support/Claude/claude_desktop_config.json"
Found 3 servers:
  ├── ● obsidian-mcp (8 tools)
  │   ├── ✓ create-note — Verified and secure
  │   ├── ✓ search-vault — Verified and secure
  │   └── ... (6 more tools verified)
  ├── ● supabase-mcp (12 tools)
  │   └── ✓ All tools verified
  └── ● beads (15 tools)
      └── ✓ All tools verified

✅ No vulnerabilities detected
```

### Links
- **GitHub**: https://github.com/invariantlabs-ai/mcp-scan
- **PyPI**: https://pypi.org/project/mcp-scan/
- **Documentation**: https://explorer.invariantlabs.ai/docs/mcp-scan/
- **Blog Post**: https://invariantlabs.ai/blog/introducing-mcp-scan

---

## 3. Themis (Cossack Labs)

### What It Is
Themis is an open-source, high-level cryptographic library designed for developers who need secure data storage and messaging without being cryptography experts. It's recommended by OWASP MASVS for mobile platforms.

### Why It's Worthy for Your macOS App

- **Easy-to-Use Crypto**: Handles complex cryptography so you don't make mistakes
- **Secure Storage**: Perfect for encrypting wedding guest data, vendor contacts, passwords
- **OWASP Recommended**: Specifically recommended for mobile/desktop app security
- **Swift Native**: Full Swift support via SwiftThemis wrapper
- **Apple Silicon Support**: Native ARM64 support for M1/M2/M3 Macs
- **Production Tested**: Used by healthcare, fintech, and messaging apps

### What It Provides

| Cryptosystem | Use Case for Your App |
|--------------|----------------------|
| **Secure Cell** | Encrypt wedding guest data, vendor contracts, sensitive notes in local storage |
| **Secure Message** | Encrypt messages between your app and Supabase backend |
| **Secure Session** | Encrypted real-time sync with forward secrecy (if you add real-time features) |
| **Secure Comparator** | Zero-knowledge authentication (verify passwords without exposing them) |

### Installation

**Swift Package Manager (Recommended):**

Add to your `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/cossacklabs/themis", from: "0.15.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/cossacklabs/themis`
3. Select version 0.15.0 or later

**CocoaPods:**
```ruby
# In your Podfile
pod 'themis'
```

Then run:
```bash
pod install
```

**Carthage:**
```
# In your Cartfile
github "cossacklabs/themis"
```

Then run:
```bash
carthage update --use-xcframeworks
```

### Usage Examples for Your Wedding App

**1. Encrypting Guest Data (Secure Cell)**
```swift
import themis

// Generate a key (store this securely in Keychain)
let masterKey = TSGenerateSymmetricKey()!

// Create a cell for encryption
let cell = TSCellSeal(key: masterKey)!

// Encrypt guest information
let guestData = "John Smith, +1-555-0123, Table 5".data(using: .utf8)!
let encryptedData = try! cell.encrypt(guestData)

// Decrypt when needed
let decryptedData = try! cell.decrypt(encryptedData)
let guestInfo = String(data: decryptedData, encoding: .utf8)!
```

**2. Encrypting with Context (Extra Security)**
```swift
// Context ties encryption to specific data (e.g., guest ID)
let context = "guest_id_12345".data(using: .utf8)!
let encrypted = try! cell.encrypt(guestData, context: context)

// Must provide same context to decrypt
let decrypted = try! cell.decrypt(encrypted, context: context)
```

**3. Secure Message (Encrypt Data for Backend)**
```swift
// Generate key pair for your app
let appKeyPair = TSKeyGen(algorithm: .EC)!
let appPrivateKey = appKeyPair.privateKey!
let appPublicKey = appKeyPair.publicKey!

// Backend's public key (from your Supabase edge function)
let backendPublicKey: Data = // ... from backend

// Encrypt message to backend
let secureMessage = TSMessage(
    inEncryptModeWithPrivateKey: appPrivateKey,
    peerPublicKey: backendPublicKey
)!

let plaintext = "RSVP: Yes, 2 guests".data(using: .utf8)!
let encrypted = try! secureMessage.wrap(plaintext)

// Send `encrypted` to your backend
```

**4. Token-Based Encryption (Searchable)**
```swift
// Token Protect mode - metadata is separate from encrypted data
let tokenCell = TSCellToken(key: masterKey)!

let (encrypted, token) = try! tokenCell.encrypt(guestData)
// Store `encrypted` in database
// Store `token` separately (needed for decryption)

let decrypted = try! tokenCell.decrypt(encrypted, token: token)
```

### Integration with Your App

For your I Do Blueprint app, consider using Themis for:

1. **Local Encryption**: Encrypt sensitive wedding data before storing in Core Data or files
2. **Keychain Storage**: Store the Themis master key in macOS Keychain
3. **Backend Communication**: Encrypt sensitive RSVP data before sending to Supabase
4. **Export Security**: Encrypt exported guest lists or itineraries

### Links
- **GitHub**: https://github.com/cossacklabs/themis
- **Swift Documentation**: https://docs.cossacklabs.com/themis/languages/swift/
- **Installation Guide**: https://docs.cossacklabs.com/themis/languages/swift/installation/
- **Swift Examples**: https://github.com/cossacklabs/themis/tree/master/docs/examples/swift
- **Swift Package Index**: https://swiftpackageindex.com/cossacklabs/themis
- **CocoaPods**: https://cocoapods.org/pods/themis

---

## 4. MCP-Shield

### What It Is
MCP-Shield is a lightweight security scanner for MCP servers that detects vulnerabilities like tool poisoning attacks, data exfiltration channels, and cross-origin escalations. It's similar to MCP-Scan but with a simpler approach and optional Claude AI integration.

### Why It's Worthy

- **Simple One-Command Scan**: Just run `npx mcp-shield`
- **Claude AI Analysis**: Optional deeper analysis using Claude's understanding of attack patterns
- **Cross-Origin Detection**: Finds when one MCP server tries to manipulate another
- **No Installation Required**: Runs via npx
- **Client Spoofing Test**: Check if servers behave differently for different clients

### What It Detects

| Vulnerability | Description |
|---------------|-------------|
| **Hidden Instructions** | Secret commands embedded in tool descriptions |
| **Data Exfiltration** | Suspicious parameters that could leak data |
| **Tool Shadowing** | Tools trying to modify other tools' behavior |
| **Sensitive File Access** | Tools attempting to read `.env`, SSH keys, configs |
| **Cross-Origin Violations** | One server manipulating another server's tools |
| **Bait-and-Switch** | Servers that behave differently based on client identity |

### Installation

**Run directly (no install):**
```bash
npx mcp-shield
```

**Or install globally:**
```bash
npm install -g mcp-shield
```

### Running Scans

**Basic scan of all MCP configs:**
```bash
npx mcp-shield
```

**Scan with Claude AI analysis (recommended for thorough scan):**
```bash
npx mcp-shield --claude-api-key YOUR_ANTHROPIC_API_KEY
```

**Scan specific config:**
```bash
npx mcp-shield --path ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

**Test for client-specific behavior (bait-and-switch detection):**
```bash
npx mcp-shield --identify-as claude-desktop
```

**Exclude trusted servers:**
```bash
npx mcp-shield --safe-list "obsidian,github,supabase"
```

### Example Output

```
Scanning "/Users/jess/Library/Application Support/Claude/claude_desktop_config.json"
Found 4 servers:
  ├── ● obsidian-mcp (8 tools)
  │   └── ✓ All tools verified and secure
  ├── ● supabase-mcp (12 tools)
  │   └── ✓ All tools verified and secure
  ├── ● beads (15 tools)
  │   └── ✓ All tools verified and secure
  └── ● suspicious-server (3 tools)
      ├── ✗ getData — Prompt Injection detected [HIGH Risk]
      │   Issues:
      │     – Hidden instructions: <secret>
      │     – Sensitive file access: ~/.ssh
      │     – Potential exfiltration: metadata (string)
      └── ✗ sendReport — Tool Shadowing detected [HIGH Risk]

⚠️  Vulnerabilities Detected!

1. Server: suspicious-server
   Tool: getData
   Risk Level: HIGH
   AI Analysis: This tool attempts to covertly access SSH keys...
```

### When to Use MCP-Shield vs MCP-Scan

| Feature | MCP-Shield | MCP-Scan |
|---------|------------|----------|
| **One-line scan** | ✅ `npx mcp-shield` | ✅ `uvx mcp-scan@latest` |
| **Claude AI analysis** | ✅ Optional | ❌ Uses Invariant API |
| **Runtime proxy mode** | ❌ | ✅ |
| **Tool pinning/hashing** | ❌ | ✅ |
| **Custom guardrails** | ❌ | ✅ |
| **Local-only mode** | Via Claude | ✅ (with OpenAI key) |
| **Written in** | TypeScript | Python |

**Recommendation**: Use both! Run MCP-Shield for quick scans with AI analysis, and MCP-Scan for runtime monitoring and tool pinning.

### Links
- **GitHub**: https://github.com/riseandignite/mcp-shield
- **npm**: https://www.npmjs.com/package/mcp-shield

---

## Quick Reference: Daily Workflow

### Before Coding Session
```bash
# 1. Scan your MCP servers
uvx mcp-scan@latest
npx mcp-shield --claude-api-key $ANTHROPIC_API_KEY

# 2. If you added new MCPs, verify them
uvx mcp-scan@latest inspect
```

### During Development
```bash
# Scan your Swift code for security issues
semgrep --config p/swift --config akabe1-semgrep-rules/ios/swift/ /path/to/IDoBlueprint
```

### Before Commit/Release
```bash
# Comprehensive security scan
semgrep --config p/swift --config p/secrets --config akabe1-semgrep-rules/ios/swift/ . --json > security-report.json

# Check for any new MCP vulnerabilities
uvx mcp-scan@latest
```

### In Claude Code
Ask Claude:
- "Scan my code for security vulnerabilities using Semgrep"
- "Check if my Swift code has any crypto issues"
- "Review this file for security problems"

---

## Summary Table

| Tool | Purpose | Install | Run |
|------|---------|---------|-----|
| **Semgrep** | Scan Swift code for vulnerabilities | `brew install semgrep` | `semgrep --config p/swift .` |
| **MCP-Scan** | Scan/monitor MCP servers | None (uvx) | `uvx mcp-scan@latest` |
| **Themis** | Encrypt data in your app | Swift Package Manager | Import in Xcode |
| **MCP-Shield** | Quick MCP security audit | None (npx) | `npx mcp-shield` |
