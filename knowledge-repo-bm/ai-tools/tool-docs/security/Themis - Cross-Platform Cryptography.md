---
title: Themis - Cross-Platform Cryptography
type: note
permalink: ai-tools/security/themis-cross-platform-cryptography
tags:
- security
- cryptography
- encryption
- swift
- ios
- keychain
- data-protection
- cross-platform
---

# Themis - Cross-Platform Cryptography

> **High-level cryptographic framework for secure data storage and messaging across 14 platforms with unified APIs**

## Overview

Themis is an open-source, cross-platform cryptographic library designed to make implementing strong encryption accessible to developers. It provides ready-made building blocks ("cryptosystems") for common security use cases like encrypting data at rest, secure messaging, and session-oriented encrypted communication—all while hiding the complex cryptographic details behind simple, hard-to-misuse APIs.

**Agent Attachments:**
- ❌ Qodo Gen (not applicable)
- ❌ Claude Code (not applicable)
- ❌ Claude Desktop (not applicable)
- ❌ CLI/Shell (not applicable)
- ✅ **Xcode/SPM** (Swift Package Manager dependency)

---

## Key Features

### Core Cryptosystems

1. **Secure Cell**: Multi-mode cryptographic container for data at rest
   - **Use Case**: Encrypt files, database records, API keys, session tokens
   - **Modes**: Seal, Token Protect, Context Imprint
   - **Algorithms**: AES-256-GCM, AES-256-CTR, KDF
   - **Features**: Random salt/IV, authenticated encryption, key derivation

2. **Secure Message**: Encrypted messaging for point-to-point communication
   - **Use Case**: Send encrypted & signed data between parties
   - **Modes**: Encrypt, Sign, Sign+Encrypt
   - **Algorithms**: ECC + ECDSA / RSA + PSS + PKCS#7
   - **Features**: Prevents MITM, forward secrecy (with key rotation)

3. **Secure Session**: Session-oriented encrypted data exchange
   - **Use Case**: Socket encryption, session security, high-level messaging
   - **Algorithms**: ECDH key agreement, ECC & AES encryption
   - **Features**: Forward secrecy, perfect forward secrecy, session binding

4. **Secure Comparator**: Zero-knowledge proof-based authentication
   - **Use Case**: Compare secrets without revealing them, password authentication
   - **Algorithms**: Zero-knowledge proofs (SRP-like)
   - **Features**: No secret transmission, secure equality check

---

## Platform Support

### Supported Languages & Platforms

**14 Platforms Total:**
- **Swift** (iOS, macOS) ✅
- **Objective-C** (iOS, macOS)
- **Java** (Android, Desktop Java)
- **Kotlin** (Android)
- **JavaScript** (Node.js)
- **React Native** (iOS & Android)
- **Python**
- **Ruby**
- **PHP**
- **C++**
- **Go**
- **Rust**
- **WebAssembly (WASM)**
- **Google Chrome Extension**

### CPU Architectures

- x86_64 / i386
- ARM (including Apple Silicon / ARM64)
- Various Android architectures

### Operating Systems

- **macOS** (10.12+)
- **iOS** (10.0+)
- **Linux**: Debian (9, 10), CentOS (7, 8), Ubuntu (16.04, 18.04, 20.04)
- **Android**
- **Windows** (via cross-compilation)

---

## Installation for Swift

### Swift Package Manager (Recommended)

Add Themis to your `Package.swift` or use Xcode's SPM integration:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/cossacklabs/themis.git", from: "0.15.0")
]
```

**Xcode Integration:**
1. File → Add Packages...
2. Enter: `https://github.com/cossacklabs/themis`
3. Select version/branch
4. Add to target

### CocoaPods

```ruby
# Podfile
pod 'themis', '~> 0.15'
```

### Carthage

```
# Cartfile
github "cossacklabs/themis" ~> 0.15
```

---

## Secure Cell: Encrypting Data at Rest

### Overview

Secure Cell is the **primary tool for I Do Blueprint** to encrypt sensitive data before storing it locally or in Supabase. It provides three modes optimized for different use cases.

### Modes

| Mode | Use Case | Authentication Tag | Data Overhead |
|------|----------|-------------------|---------------|
| **Seal** | General encryption (files, API keys) | Included | ~60 bytes |
| **Token Protect** | Database records (separate auth token) | Separate | ~20 bytes |
| **Context Imprint** | Format-preserving encryption | Via context | 0 bytes |

---

### Seal Mode (Recommended for I Do Blueprint)

**Best for**: API keys, session tokens, files, general-purpose encryption

```swift
import themis

// Generate encryption key (store in Keychain)
let encryptionKey = TSGenerateSymmetricKey()!

// Create Secure Cell
let cell = TSCellSeal(key: encryptionKey)!

// Encrypt data
let plaintext = "Supabase API Key: sk-abc123".data(using: .utf8)!
let encrypted = try cell.encrypt(plaintext, context: nil)

// Decrypt data
let decrypted = try cell.decrypt(encrypted, context: nil)
let recoveredText = String(data: decrypted, encoding: .utf8)
```

**Key Features:**
- Authentication tag included in ciphertext
- Single encrypted blob
- Tamper detection built-in
- No additional storage needed

---

### Token Protect Mode

**Best for**: Database records where encrypted value and auth token are stored separately

```swift
import themis

let key = TSGenerateSymmetricKey()!
let cell = TSCellTokenProtect(key: key)!

// Encrypt (returns encrypted message + token)
let plaintext = "Guest name: John Doe".data(using: .utf8)!
let result = try cell.encrypt(plaintext, context: nil)

// Store separately in database:
// - result.encrypted → encrypted_value column
// - result.token → auth_token column

// Decrypt (requires both encrypted + token)
let decrypted = try cell.decrypt(result.encrypted, token: result.token, context: nil)
```

**Use Cases:**
- Encrypting database fields with separate auth token column
- Searchable encryption (encrypt search terms, store token)
- Where minimal ciphertext size is critical

---

### Context Imprint Mode

**Best for**: Format-preserving encryption (maintain data format)

```swift
import themis

let key = TSGenerateSymmetricKey()!
let cell = TSCellContextImprint(key: key)!

// Context is REQUIRED (cannot be nil)
let context = "user-id-123".data(using: .utf8)!
let plaintext = "1234-5678-9012-3456".data(using: .utf8)!

let encrypted = try cell.encrypt(plaintext, context: context)
let decrypted = try cell.decrypt(encrypted, context: context)
```

**Use Cases:**
- Credit card tokenization
- Phone number masking
- Format-preserving encryption where output must match input length

**⚠️ Warning**: No authentication tag! Vulnerable to tampering if context is not protected.

---

## Integration with iOS Keychain

### Storing Encryption Keys Securely

Themis encryption keys should be stored in the iOS Keychain:

```swift
import Security
import themis

// Generate encryption key
let encryptionKey = TSGenerateSymmetricKey()!

// Store in Keychain
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "themis-encryption-key",
    kSecValueData as String: encryptionKey,
    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
]

let status = SecItemAdd(query as CFDictionary, nil)
guard status == errSecSuccess else {
    fatalError("Failed to store key in Keychain")
}

// Retrieve from Keychain
let retrieveQuery: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "themis-encryption-key",
    kSecReturnData as String: true
]

var item: CFTypeRef?
let retrieveStatus = SecItemCopyMatching(retrieveQuery as CFDictionary, &item)
guard retrieveStatus == errSecSuccess,
      let keyData = item as? Data else {
    fatalError("Failed to retrieve key from Keychain")
}

// Use retrieved key
let cell = TSCellSeal(key: keyData)!
```

---

## Secure Message: Point-to-Point Encryption

### Overview

Secure Message encrypts messages between two parties (client ↔ server, user ↔ user) with optional signing.

### Modes

1. **Encrypt Mode**: Symmetric encryption with pre-shared key
2. **Sign Mode**: Message signing for authenticity
3. **Encrypt + Sign Mode**: Full confidentiality and authenticity

---

### Encrypt Mode (Symmetric)

```swift
import themis

// Generate shared symmetric key (distribute securely)
let sharedKey = TSGenerateSymmetricKey()!

// Sender encrypts
let message = "Wedding RSVP confirmed".data(using: .utf8)!
let encrypter = TSMessage(in: .ECMode, key: sharedKey)!
let encrypted = try encrypter.wrap(message)

// Receiver decrypts (with same shared key)
let decrypter = TSMessage(in: .ECMode, key: sharedKey)!
let decrypted = try decrypter.unwrap(encrypted)
```

---

### Encrypt + Sign Mode (Asymmetric)

```swift
import themis

// Generate key pairs for sender and receiver
let senderKeyPair = TSKeyGen(algorithm: .EC)!
let receiverKeyPair = TSKeyGen(algorithm: .EC)!

// Sender encrypts and signs
let message = "Guest count: 150".data(using: .utf8)!
let encrypter = TSMessage(in: .signVerifyMode,
                          privateKey: senderKeyPair.privateKey,
                          peerPublicKey: receiverKeyPair.publicKey)!
let encrypted = try encrypter.wrap(message)

// Receiver decrypts and verifies signature
let decrypter = TSMessage(in: .signVerifyMode,
                          privateKey: receiverKeyPair.privateKey,
                          peerPublicKey: senderKeyPair.publicKey)!
let decrypted = try decrypter.unwrap(encrypted)
```

**Use Cases:**
- Client-server communication
- User-to-user messaging
- API request/response encryption
- Prevents MITM attacks

---

## I Do Blueprint Use Cases

### 1. Encrypt Supabase API Keys

Store Supabase API keys encrypted on-device using Secure Cell + Keychain:

```swift
import themis

class SupabaseKeyManager {
    private let keychainKey = "themis-encryption-key"
    
    func encryptAndStore(apiKey: String) throws {
        // Get encryption key from Keychain
        guard let encryptionKey = retrieveKeychainKey() else {
            throw KeyError.notFound
        }
        
        // Encrypt API key
        let cell = TSCellSeal(key: encryptionKey)!
        let plaintext = apiKey.data(using: .utf8)!
        let encrypted = try cell.encrypt(plaintext, context: nil)
        
        // Store encrypted API key in UserDefaults (or file)
        UserDefaults.standard.set(encrypted, forKey: "encrypted-supabase-key")
    }
    
    func retrieveAndDecrypt() throws -> String {
        // Get encryption key from Keychain
        guard let encryptionKey = retrieveKeychainKey() else {
            throw KeyError.notFound
        }
        
        // Get encrypted API key
        guard let encrypted = UserDefaults.standard.data(forKey: "encrypted-supabase-key") else {
            throw KeyError.notFound
        }
        
        // Decrypt API key
        let cell = TSCellSeal(key: encryptionKey)!
        let decrypted = try cell.decrypt(encrypted, context: nil)
        return String(data: decrypted, encoding: .utf8)!
    }
}
```

---

### 2. Encrypt Guest Personal Data

Encrypt sensitive guest information before storing in Supabase:

```swift
struct EncryptedGuest {
    let id: UUID
    let encryptedName: Data
    let encryptedEmail: Data
    let encryptedPhone: Data
    
    static func encrypt(guest: Guest, key: Data) throws -> EncryptedGuest {
        let cell = TSCellSeal(key: key)!
        
        return EncryptedGuest(
            id: guest.id,
            encryptedName: try cell.encrypt(guest.name.data(using: .utf8)!, context: nil),
            encryptedEmail: try cell.encrypt(guest.email.data(using: .utf8)!, context: nil),
            encryptedPhone: try cell.encrypt(guest.phone.data(using: .utf8)!, context: nil)
        )
    }
    
    func decrypt(key: Data) throws -> Guest {
        let cell = TSCellSeal(key: key)!
        
        return Guest(
            id: id,
            name: String(data: try cell.decrypt(encryptedName, context: nil), encoding: .utf8)!,
            email: String(data: try cell.decrypt(encryptedEmail, context: nil), encoding: .utf8)!,
            phone: String(data: try cell.decrypt(encryptedPhone, context: nil), encoding: .utf8)!)
    }
}
```

---

### 3. Encrypt Session Tokens

Encrypt authentication tokens before storing:

```swift
class SecureTokenStorage {
    private static let encryptionKey = retrieveOrCreateKey()
    
    static func store(token: String) throws {
        let cell = TSCellSeal(key: encryptionKey)!
        let encrypted = try cell.encrypt(token.data(using: .utf8)!, context: nil)
        
        UserDefaults.standard.set(encrypted, forKey: "encrypted-auth-token")
    }
    
    static func retrieve() throws -> String? {
        guard let encrypted = UserDefaults.standard.data(forKey: "encrypted-auth-token") else {
            return nil
        }
        
        let cell = TSCellSeal(key: encryptionKey)!
        let decrypted = try cell.decrypt(encrypted, context: nil)
        return String(data: decrypted, encoding: .utf8)
    }
}
```

---

### 4. Encrypt Local Database Fields

Use Token Protect mode for searchable encrypted database fields:

```swift
// Encrypt email for database storage
let key = TSGenerateSymmetricKey()!
let cell = TSCellTokenProtect(key: key)!

let email = "guest@example.com".data(using: .utf8)!
let result = try cell.encrypt(email, context: nil)

// Store in Core Data or SQLite
// - encrypted_value: result.encrypted
// - auth_token: result.token

// Later, to search:
let searchTerm = "guest@example.com".data(using: .utf8)!
let searchResult = try cell.encrypt(searchTerm, context: nil)

// Compare searchResult.encrypted with database values
// If match found, verify with token
```

---

### 5. Secure RSVP Data Transmission

Encrypt RSVP data before sending to Supabase:

```swift
class RSVPEncryption {
    func encryptRSVP(_ rsvp: RSVP, serverPublicKey: Data, clientPrivateKey: Data) throws -> Data {
        let message = try JSONEncoder().encode(rsvp)
        
        let secureMessage = TSMessage(in: .signVerifyMode,
                                      privateKey: clientPrivateKey,
                                      peerPublicKey: serverPublicKey)!
        
        return try secureMessage.wrap(message)
    }
    
    func decryptRSVP(_ encrypted: Data, clientPublicKey: Data, serverPrivateKey: Data) throws -> RSVP {
        let secureMessage = TSMessage(in: .signVerifyMode,
                                      privateKey: serverPrivateKey,
                                      peerPublicKey: clientPublicKey)!
        
        let decrypted = try secureMessage.unwrap(encrypted)
        return try JSONDecoder().decode(RSVP.self, from: decrypted)
    }
}
```

---

## Security Best Practices

### 1. Key Management

**DO:**
- ✅ Store encryption keys in iOS Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- ✅ Generate keys on-device (never transmit master keys)
- ✅ Use separate keys for different data types
- ✅ Rotate keys periodically

**DON'T:**
- ❌ Hardcode keys in source code
- ❌ Store keys in UserDefaults or plain files
- ❌ Reuse the same key for all data
- ❌ Transmit master keys over the network

---

### 2. Context Usage

**Seal Mode:**
- Context is optional but recommended
- Use user IDs, timestamps, or app-specific identifiers

**Token Protect Mode:**
- Context is optional
- Use for additional binding (e.g., user ID + record ID)

**Context Imprint Mode:**
- Context is REQUIRED
- Use protected context (e.g., authenticated user ID)

---

### 3. Error Handling

Always handle Themis errors properly:

```swift
do {
    let encrypted = try cell.encrypt(data, context: nil)
    // Success
} catch let error as TSErrorType {
    switch error {
    case .fail:
        print("Encryption failed")
    case .invalidParameter:
        print("Invalid input parameters")
    case .bufferTooSmall:
        print("Buffer size issue")
    default:
        print("Unknown error")
    }
}
```

---

### 4. Testing

Test encryption/decryption in unit tests:

```swift
func testSecureCell() throws {
    let key = TSGenerateSymmetricKey()!
    let cell = TSCellSeal(key: key)!
    
    let plaintext = "test data".data(using: .utf8)!
    let encrypted = try cell.encrypt(plaintext, context: nil)
    let decrypted = try cell.decrypt(encrypted, context: nil)
    
    XCTAssertEqual(plaintext, decrypted)
    XCTAssertNotEqual(plaintext, encrypted)
}
```

---

## Comparison with Other Cryptographic Solutions

| Feature | Themis | CryptoKit (Apple) | OpenSSL | RNCryptor |
|---------|--------|-------------------|---------|-----------|
| **Cross-Platform** | ✅ 14 platforms | ❌ Apple only | ✅ Yes | ❌ Limited |
| **High-Level API** | ✅ Simple | ✅ Simple | ❌ Complex | ✅ Simple |
| **Secure Cell** | ✅ Built-in | ❌ Manual | ❌ Manual | ✅ Similar |
| **Forward Secrecy** | ✅ Secure Session | ⚠️ Manual | ⚠️ Manual | ❌ No |
| **License** | ✅ Apache 2.0 | ❌ Proprietary | ✅ OpenSSL | ✅ MIT |
| **Active Development** | ✅ Yes | ✅ Yes | ✅ Yes | ❌ Inactive |

**When to use Themis:**
- Cross-platform apps (iOS + Android + backend)
- Need for high-level crypto abstractions
- Want battle-tested, audited crypto library
- Building end-to-end encryption

**When to use CryptoKit:**
- iOS 13+ only apps
- Want native Apple integration
- Using Swift natively

---

## Integration with Other Tools

**Complements:**
- **Semgrep**: Detects crypto misuse → Themis provides correct implementations
- **MCP Shield**: Detects config vulnerabilities → Themis encrypts sensitive MCP config data
- **Keychain**: Themis keys stored in Keychain for maximum security

**Workflow:**
1. Generate Themis encryption key → Store in Keychain
2. Encrypt sensitive data with Themis → Store encrypted data in Supabase
3. Semgrep scans code → Ensures Themis is used correctly
4. MCP Shield scans configs → Themis can encrypt MCP server credentials

---

## Resources

### Official Links

- **GitHub**: https://github.com/cossacklabs/themis
- **Documentation**: https://docs.cossacklabs.com/themis/
- **Swift Package Index**: https://swiftpackageindex.com/cossacklabs/themis
- **CocoaPods**: https://cocoapods.org/pods/themis
- **Swift Package Registry**: https://swiftpackageregistry.com/cossacklabs/themis

### Documentation

- **Swift Guide**: https://docs.cossacklabs.com/themis/languages/swift/
- **Swift Examples**: https://docs.cossacklabs.com/themis/languages/swift/examples/
- **Security**: https://docs.cossacklabs.com/themis/security/
- **Comparison**: https://docs.cossacklabs.com/themis/comparison/

### Cossack Labs Products

- **Acra**: Database encryption and protection
- **Hermes**: Secure communication layer

---

## Summary

Themis is the **essential cryptographic framework for I Do Blueprint** to implement secure data storage and transmission. Its high-level APIs make strong encryption accessible without requiring deep cryptographic expertise.

**Key Strengths**:
- 🔒 Battle-tested, production-grade crypto
- 🌍 Cross-platform (14+ languages/platforms)
- 🎯 Simple, hard-to-misuse APIs
- 📦 Multiple cryptosystems (Cell, Message, Session, Comparator)
- ✅ Security-audited by cryptographers
- 🔑 iOS Keychain integration
- 🆓 Open-source (Apache 2.0)
- 📱 Native Swift support via SPM

**Perfect for I Do Blueprint**:
- Encrypt Supabase API keys (Secure Cell + Keychain)
- Encrypt guest personal data (Secure Cell)
- Encrypt session tokens (Secure Cell)
- Encrypt database fields (Token Protect mode)
- Secure RSVP transmission (Secure Message)

**Unique Value**:
Unlike CryptoKit (Apple-only) or OpenSSL (low-level), Themis provides **cross-platform, high-level cryptographic building blocks** that work identically across iOS, Android, and backend—perfect for wedding app with future multi-platform support.

---

**Last Updated**: December 30, 2025  
**Version**: 0.15+ (Current stable)  
**I Do Blueprint Integration**: Active (via Swift Package Manager)