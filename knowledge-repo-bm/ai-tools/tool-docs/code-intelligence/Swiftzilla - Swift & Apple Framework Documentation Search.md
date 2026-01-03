---
title: Swiftzilla - Swift & Apple Framework Documentation Search
type: note
permalink: ai-tools/code-intelligence/swiftzilla-swift-apple-framework-documentation-search
---

# Swiftzilla - Swift & Apple Framework Documentation Search

> **Stop your AI agent from hallucinating Swift code - RAG API built for Apple Development**

## Overview

Swiftzilla is a specialized RAG (Retrieval-Augmented Generation) API and MCP server that provides AI coding assistants with instant access to 100,000+ pages of official Apple documentation, Swift API guidelines, WWDC transcripts, and Swift Evolution proposals. Unlike general-purpose LLMs that struggle with Swift 6.0 nuances and latest framework updates, Swiftzilla ensures your AI agent always has current, accurate Apple development knowledge.

**Agent Attachments:**
- ✅ **Qodo Gen** (MCP Server)
- ✅ **Claude Code** (MCP Server)
- ✅ **Claude Desktop** (MCP Server)
- ✅ **Cursor** (MCP Server)
- ✅ **Windsurf** (MCP Server)
- ✅ **VS Code Copilot** (MCP Server)
- ❌ CLI/Shell

---

## The Problem Swiftzilla Solves

### Why General-Purpose LLMs Fail at Swift Development

General purpose models like Claude, GPT, and Gemini struggle with:

1. **Outdated Context**
   - Training data cuts off before latest WWDC announcements
   - Missing Swift 6.0 features and updates
   - Unaware of deprecated APIs and replacements

2. **Hallucinated APIs**
   - Suggests methods that don't exist
   - Recommends deprecated modifiers
   - Invents non-existent SwiftUI view properties

3. **Broken Views**
   - SwiftUI previews crash due to invalid modifiers
   - Uses removed UIKit patterns
   - Applies incompatible framework combinations

**Example of LLM Hallucinations:**

```swift
// ❌ WRONG: General LLM Output
// Error: 'navigationBarTitle' was deprecated in iOS 16.0
.navigationBarTitle("Home")

// Hallucination: This modifier doesn't exist
.standardStyle(.prominent)
```

**Swiftzilla Prevents This:**

```swift
// ✅ CORRECT: Swiftzilla-Enhanced Output
// Uses current iOS 16+ API
.navigationTitle("Home")

// Real API from official docs
.buttonStyle(.bordered)
.controlSize(.large)
```

---

## Key Features

### Core Capabilities

1. **Complete Apple Documentation Index**
   - 100,000+ pages of official Apple Developer Documentation
   - Swift API Design Guidelines (comprehensive)
   - Full framework coverage: SwiftUI, UIKit, AppKit, Foundation, CoreData, ARKit, Metal, Core ML, Vision

2. **WWDC Knowledge Base**
   - Searchable transcripts from all WWDC sessions
   - Knowledge directly from Apple framework engineers
   - Latest best practices and patterns

3. **Swift Evolution Proposals**
   - All Swift Evolution proposals (SEPs)
   - Track language feature evolution
   - Understanding of Swift 6.0 concurrency, macros, ownership

4. **Daily Index Updates**
   - Sources re-indexed daily
   - New beta APIs within 24 hours of release
   - Always current with Apple's latest documentation

5. **MCP Native Standard**
   - Supports both SSE and STDIO transports
   - Works out-of-the-box with any MCP-compatible agent
   - Zero configuration required

---

## Installation & Setup

### Getting API Access

1. **Sign Up**
   - Go to https://swiftzilla.dev/
   - Login with GitHub
   - Choose your tier (Free or Developer Pass)

2. **Get API Key**
   - Access your dashboard
   - Copy your MCP configuration

### Free Tier

```
✓ 50 Deep RAG Queries/Day
✓ Periodic Index Updates
✓ Full documentation access
✓ Perfect for testing and small projects
```

### Developer Pass ($3/month)

```
✓ Unlimited RAG API Queries
✓ Periodic Index Updates
✓ Priority Request Handling
✓ Cancel anytime
```

---

## Configuration

### Qodo Gen Configuration

Add to your Qodo Gen MCP configuration:

```json
{
  "mcpServers": {
    "swiftzilla": {
      "command": "npx",
      "args": ["-y", "@swiftzilla/mcp-server"],
      "env": {
        "SWIFTZILLA_API_KEY": "your_api_key_here"
      }
    }
  }
}
```

### Claude Code Configuration

Add to `~/.mcp.json` or project-specific `.mcp.json`:

```json
{
  "mcpServers": {
    "swiftzilla": {
      "command": "npx",
      "args": ["-y", "@swiftzilla/mcp-server"],
      "env": {
        "SWIFTZILLA_API_KEY": "your_api_key_here"
      }
    }
  }
}
```

### Claude Desktop Configuration

Add to `~/Library/Application Support/Claude/claude_desktop_config.json` (Mac):

```json
{
  "mcpServers": {
    "swiftzilla": {
      "command": "npx",
      "args": ["-y", "@swiftzilla/mcp-server"],
      "env": {
        "SWIFTZILLA_API_KEY": "your_api_key_here"
      }
    }
  }
}
```

### Cursor Configuration

Add to `.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "swiftzilla": {
      "command": "npx",
      "args": ["-y", "@swiftzilla/mcp-server"],
      "env": {
        "SWIFTZILLA_API_KEY": "your_api_key_here"
      }
    }
  }
}
```

### Windsurf Configuration

Add to your Windsurf MCP configuration:

```json
{
  "mcpServers": {
    "swiftzilla": {
      "command": "npx",
      "args": ["-y", "@swiftzilla/mcp-server"],
      "env": {
        "SWIFTZILLA_API_KEY": "your_api_key_here"
      }
    }
  }
}
```

---

## Available Tools

### `search_swift_docs` - Swift Documentation Search

Search official Swift documentation and API guidelines.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | string | ✅ Yes | Search query for Swift docs |
| `framework` | string | ❌ No | Specific framework filter (e.g., "SwiftUI", "Combine") |
| `version` | string | ❌ No | Swift/iOS version (e.g., "Swift 6.0", "iOS 18") |

**Examples:**

```typescript
// Find best practices for Swift functions
search_swift_docs({ 
  query: "What is the best practice to write swift functions?"
})

// Returns comprehensive Swift API Guidelines
{
  "source": "Swift API Design Guidelines",
  "content": "Naming: Use clear and precise parameter names...",
  "examples": ["func greet(person: String, from hometown: String)"],
  "reference": "https://swift.org/documentation/api-design-guidelines/"
}

// Find SwiftUI state management
search_swift_docs({ 
  query: "State vs Binding in SwiftUI",
  framework: "SwiftUI"
})

// Find Swift 6 concurrency
search_swift_docs({ 
  query: "Actors in Swift 6",
  version: "Swift 6.0"
})
```

### `search_wwdc` - WWDC Session Search

Search WWDC session transcripts for framework knowledge.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | string | ✅ Yes | Search query for WWDC content |
| `year` | number | ❌ No | Specific WWDC year filter |
| `framework` | string | ❌ No | Framework focus |

**Examples:**

```typescript
// Find Observation framework info
search_wwdc({ 
  query: "Observation Framework",
  year: 2023
})

// Find Task Group patterns
search_wwdc({ 
  query: "Task Groups"
})

// Find latest SwiftUI updates
search_wwdc({ 
  query: "SwiftUI updates",
  year: 2024,
  framework: "SwiftUI"
})
```

### `search_swift_evolution` - Swift Evolution Proposals

Search Swift Evolution proposals (SEPs) by number or keyword.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | string | ✅ Yes | SEP number (SE-XXXX) or keyword search |
| `status` | string | ❌ No | Filter by status (e.g., "implemented", "accepted") |

**Examples:**

```typescript
// Find specific SEP
search_swift_evolution({ 
  query: "SE-0296"  // Async/await proposal
})

// Search by topic
search_swift_evolution({ 
  query: "concurrency",
  status: "implemented"
})

// Find macro proposals
search_swift_evolution({ 
  query: "macros"
})
```

### `search_apple_docs` - Framework Documentation Search

Search specific Apple framework documentation.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | string | ✅ Yes | Documentation search query |
| `framework` | string | ✅ Yes | Framework name (SwiftUI, UIKit, AppKit, Foundation, etc.) |
| `platform` | string | ❌ No | Platform filter (iOS, macOS, watchOS, tvOS, visionOS) |

**Examples:**

```typescript
// Find SwiftUI View modifiers
search_apple_docs({ 
  query: "navigation modifiers",
  framework: "SwiftUI",
  platform: "iOS"
})

// Find Foundation date handling
search_apple_docs({ 
  query: "Date formatting",
  framework: "Foundation"
})

// Find AppKit window management
search_apple_docs({ 
  query: "NSWindow configuration",
  framework: "AppKit",
  platform: "macOS"
})
```

---

## Query Patterns & Use Cases

### SwiftUI Development

```typescript
// Finding correct modifiers
search_swift_docs({ 
  query: "How to create a navigation stack in iOS 16+",
  framework: "SwiftUI"
})

// State management
search_swift_docs({ 
  query: "When to use @State vs @Binding vs @StateObject",
  framework: "SwiftUI"
})

// Layout questions
search_swift_docs({ 
  query: "LazyVGrid vs LazyHGrid performance",
  framework: "SwiftUI"
})

// Animations
search_swift_docs({ 
  query: "withAnimation vs animation modifier",
  framework: "SwiftUI"
})
```

### Swift Concurrency

```typescript
// Actor usage
search_swift_docs({ 
  query: "When to use actors vs classes",
  version: "Swift 6.0"
})

// Async/await patterns
search_swift_docs({ 
  query: "async let parallel tasks"
})

// Task groups
search_swift_docs({ 
  query: "withTaskGroup structured concurrency"
})
```

### UIKit & AppKit

```typescript
// View controllers
search_apple_docs({ 
  query: "UIViewController lifecycle",
  framework: "UIKit"
})

// Table views
search_apple_docs({ 
  query: "UITableView diffable data source",
  framework: "UIKit"
})

// macOS windows
search_apple_docs({ 
  query: "NSWindow sheets and popovers",
  framework: "AppKit"
})
```

### Core Data & Persistence

```typescript
// Core Data setup
search_apple_docs({ 
  query: "NSPersistentContainer initialization",
  framework: "CoreData"
})

// Fetch requests
search_apple_docs({ 
  query: "NSFetchRequest predicates",
  framework: "CoreData"
})

// SwiftData (new)
search_swift_docs({ 
  query: "SwiftData vs Core Data",
  version: "iOS 17"
})
```

---

## I Do Blueprint Use Cases

### 1. SwiftUI View Best Practices

```typescript
// Find correct navigation patterns
search_swift_docs({ 
  query: "NavigationStack best practices",
  framework: "SwiftUI",
  platform: "iOS"
})

// Learn proper Form usage
search_swift_docs({ 
  query: "Form validation patterns in SwiftUI"
})

// Understand List performance
search_swift_docs({ 
  query: "List vs ForEach performance in large datasets"
})
```

### 2. Supabase Integration with Swift

```typescript
// Find network best practices
search_swift_docs({ 
  query: "URLSession async await patterns"
})

// Learn JSON decoding
search_swift_docs({ 
  query: "Codable custom key strategies"
})

// Understand error handling
search_swift_docs({ 
  query: "Result type error handling"
})
```

### 3. Event Management Features

```typescript
// Date handling
search_apple_docs({ 
  query: "DateFormatter locale-aware formatting",
  framework: "Foundation"
})

// Calendar integration
search_apple_docs({ 
  query: "EventKit calendar permissions",
  framework: "EventKit"
})

// Notifications
search_apple_docs({ 
  query: "UNUserNotificationCenter scheduling",
  framework: "UserNotifications"
})
```

### 4. RSVP & Guest Management

```typescript
// Data modeling
search_swift_docs({ 
  query: "struct vs class for data models"
})

// Array operations
search_swift_docs({ 
  query: "filter map reduce collection operations"
})

// SwiftUI lists
search_swift_docs({ 
  query: "List selection and editing",
  framework: "SwiftUI"
})
```

### 5. Authentication & Security

```typescript
// Keychain usage
search_apple_docs({ 
  query: "Keychain secure storage",
  framework: "Security"
})

// Biometric authentication
search_apple_docs({ 
  query: "LocalAuthentication Face ID Touch ID",
  framework: "LocalAuthentication"
})

// Secure networking
search_swift_docs({ 
  query: "URLSession TLS security"
})
```

### 6. macOS App Development

```typescript
// Window management
search_apple_docs({ 
  query: "NSWindow programmatic positioning",
  framework: "AppKit",
  platform: "macOS"
})

// Menu bar
search_apple_docs({ 
  query: "NSMenu dynamic items",
  framework: "AppKit"
})

// Document-based apps
search_apple_docs({ 
  query: "NSDocument lifecycle",
  framework: "AppKit"
})
```

---

## Swiftzilla vs. General-Purpose AI

### Example Comparison

**Prompt:** "What is the best practice to write swift functions?"

#### General-Purpose AI (Without Swiftzilla)

```
Response: Functions in Swift should be clear and concise...
[Generic programming advice, not Swift-specific]

⚠️ Limited Swift Knowledge
⚠️ Lacks Deep Context
⚠️ No official guidelines
⚠️ May suggest outdated patterns
```

#### Swiftzilla-Enhanced AI

```
Response: According to the Swift API Design Guidelines:

1. Naming: 
   ✓ Use clear, precise parameter names
   ✓ Prefer method and function names that make use sites form grammatical phrases
   
2. Parameter Labels:
   ✓ func greet(person: String, from hometown: String)
   ✓ Choose parameter names to serve documentation
   
3. Argument Labels:
   ✓ Omit needless words
   ✓ Compensate for weak type information
   
Reference: Swift API Design Guidelines (official)

✅ Official Apple Documentation
✅ Swift 6.0 Compliant
✅ Current Best Practices
✅ Real Code Examples
```

---

## Performance & Token Efficiency

### Deep RAG vs. Traditional RAG

Swiftzilla uses "Deep RAG" which:
- Searches through 100,000+ documentation pages
- Returns ranked, relevant results with context
- Cites official sources
- Provides code examples from Apple

**Benefits:**
1. **Accuracy**: No hallucinations, only official Apple content
2. **Currency**: Daily updates ensure latest API knowledge
3. **Depth**: WWDC transcripts provide engineer insights
4. **Completeness**: Covers all Apple frameworks and platforms

---

## Architecture

### How Swiftzilla Works

```
┌─────────────────────┐
│   AI Assistant      │
│  (Claude/Cursor)    │
└──────────┬──────────┘
           │
           │ MCP Protocol
           │
┌──────────▼──────────┐
│  Swiftzilla MCP     │
│    Server           │
└──────────┬──────────┘
           │
           │ RAG API Request
           │
┌──────────▼──────────┐
│ Swiftzilla Engine   │
│ • Vector Search     │
│ • Semantic Ranking  │
│ • Source Citation   │
│ • Code Extraction   │
└──────────┬──────────┘
           │
           │ Indexed Sources
           │
┌──────────▼──────────┐
│ Documentation DB    │
│ • Apple Docs        │
│ • Swift Guidelines  │
│ • WWDC Transcripts  │
│ • Swift Evolution   │
└─────────────────────┘
```

### Indexed Sources

1. **Apple Developer Documentation** (~100,000+ pages)
   - SwiftUI, UIKit, AppKit
   - Foundation, CoreData, CloudKit
   - ARKit, RealityKit, Metal
   - Core ML, Vision, NaturalLanguage
   - All iOS, macOS, watchOS, tvOS, visionOS frameworks

2. **Swift API Design Guidelines**
   - Official naming conventions
   - Parameter design rules
   - API design patterns

3. **WWDC Session Transcripts**
   - All years, all sessions
   - Searchable by keyword, framework, year
   - Engineer insights and best practices

4. **Swift Evolution Proposals**
   - All SE-XXXX proposals
   - Status tracking (accepted, implemented, rejected)
   - Language feature evolution

---

## Why Choose Swiftzilla for I Do Blueprint?

1. **Swift 6.0 Native**: No outdated Swift 5.x patterns
2. **SwiftUI Current**: Latest iOS 18/macOS 15 modifiers and views
3. **Concurrency Expert**: Proper async/await, actors, task groups
4. **No Hallucinations**: Only real APIs from official Apple docs
5. **WWDC Knowledge**: Learn patterns from Apple engineers
6. **macOS Expertise**: AppKit patterns for desktop app
7. **Daily Updates**: Always current with latest betas

---

## Best Practices

### Writing Effective Queries

**Good Queries:**
```typescript
// Specific, framework-focused
"NavigationStack best practices for iOS 16"
"Actor isolation in Swift 6.0"
"Form validation patterns in SwiftUI"
```

**Less Effective:**
```typescript
// Too vague
"navigation"
"forms"
"swift"
```

### Query Tips

1. **Mention the framework**: "SwiftUI", "UIKit", "Foundation"
2. **Include version when relevant**: "Swift 6.0", "iOS 18"
3. **Be specific about the API**: "URLSession async/await" not just "networking"
4. **Ask for patterns**: "best practices", "recommended approach"

---

## Comparison with Related Tools

| Tool | Purpose | Best For |
|------|---------|----------|
| **Swiftzilla** | Swift/Apple docs RAG | Official API documentation, best practices |
| **Narsil MCP** | Code intelligence | Local code analysis, security scanning |
| **GREB MCP** | Semantic search | Finding code in your codebase |
| **Apple Docs MCP** | Basic doc search | Simple API lookups |

**Use Together:**
- Use **Swiftzilla** for "How do I use X API correctly?"
- Use **GREB** for "Where did I implement X in my code?"
- Use **Narsil** for "Are there security issues in my implementation?"

---

## Frequently Asked Questions

**Q: Does this work with Cursor?**
A: Yes! Swiftzilla provides a standard Model Context Protocol (MCP) server that you can add directly to Cursor, Windsurf, Claude, or any MCP-compatible editor.

**Q: Is the documentation up to date?**
A: We re-index our sources daily. When Apple releases a new beta or updates their docs, Swiftzilla knows about it within 24 hours.

**Q: Can I cancel anytime?**
A: Absolutely. You can manage your subscription directly from the dashboard and cancel with one click.

**Q: What's the difference between Free and Developer Pass?**
A: Free tier gives you 50 queries/day, perfect for testing. Developer Pass ($3/mo) provides unlimited queries and priority request handling.

**Q: Does it cover Swift Evolution proposals?**
A: Yes! All Swift Evolution proposals (SE-XXXX) are indexed and searchable.

---

## Links & Resources

- **Official Website**: https://swiftzilla.dev/
- **GitHub Login**: https://swiftzilla.dev/auth/github/login
- **Ask AI Demo**: https://swiftzilla.dev/ask.html
- **Support**: https://n8n.chatinho.online/form/476bf99e-64d4-4b2b-9220-93ea81d4032e
- **Privacy Policy**: https://swiftzilla.dev/privacy.html
- **Terms**: https://swiftzilla.dev/terms.html

---

## Pricing

### Free Tier
- 50 Deep RAG Queries/Day
- Periodic Index Updates
- Full documentation access
- **Perfect for**: Testing and small projects

### Developer Pass - $3/month
- Unlimited RAG API Queries
- Periodic Index Updates
- Priority Request Handling
- Cancel anytime
- **Perfect for**: Professional development

---

## License & Terms

Built for developers by developers. 256-bit SSL secured.

© 2025 Swiftzilla. Built for the Agentic Future.