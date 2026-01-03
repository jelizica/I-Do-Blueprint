---
title: GREB MCP - Semantic Code Search
type: note
permalink: ai-tools/code-intelligence/greb-mcp-semantic-code-search
---

# GREB MCP - Semantic Code Search

> **Natural language code search for your local codebase - faster and better than RAG**

## Overview

GREB MCP is an intelligent code search MCP server that enables AI coding assistants to search through local codebases using natural language queries. Unlike traditional grep or RAG-based solutions, GREB provides semantic understanding of code, returning the most relevant results ranked by precision—all without requiring indexing or setup.

**Agent Attachments:**
- ✅ **Qodo Gen** (MCP Server)
- ✅ **Claude Code** (MCP Server)
- ✅ **Claude Desktop** (MCP Server)
- ❌ CLI/Shell

---

## Key Features

### Core Capabilities

1. **Natural Language Search**
   - Describe what you're looking for in plain English
   - "Find authentication middleware"
   - "Show me all API endpoints"
   - "Where is the database connection setup?"

2. **High-Precision Results**
   - Smart ranking returns the most relevant code first
   - AI-powered understanding of intent
   - Automatic keyword and pattern extraction
   - File pattern matching (*.js, *.ts, etc.)

3. **No Indexing Required**
   - Search any codebase instantly without setup
   - No pre-processing or indexing step
   - Works on any directory immediately
   - Zero configuration needed

4. **Fast Performance**
   - Results in under 5 seconds even for large repositories
   - Optimized for real-time search
   - Better performance than RAG-based approaches
   - Lower token consumption than traditional grep

5. **Universal Compatibility**
   - Works with any MCP client
   - Claude Desktop, Claude Code, Cursor, Windsurf, Cline, Kiro
   - Simple API key-based authentication
   - Cross-platform support

---

## Why GREB vs. Traditional Approaches?

### GREB vs. Grep
| Feature | GREB | Traditional Grep |
|---------|------|------------------|
| **Search Type** | Semantic + Natural Language | Literal string matching |
| **Understanding** | Understands intent | No context |
| **Token Efficiency** | ~2x fewer tokens | Burns tokens on irrelevant matches |
| **Results Quality** | Ranked by relevance | All matches equal |
| **User Experience** | Natural language | Complex regex required |

### GREB vs. RAG (Retrieval-Augmented Generation)
| Feature | GREB | RAG-Based Solutions |
|---------|------|---------------------|
| **Setup Time** | Instant | Requires indexing |
| **Speed** | <5 seconds | Varies (indexing required) |
| **Accuracy** | High precision ranking | Embedding quality dependent |
| **Maintenance** | Zero | Re-indexing needed |
| **Token Usage** | Optimized | Can be inefficient |

---

## Installation

### Python Installation (Recommended)

```bash
pip install cheetah-greb
```

### Node.js Installation

```bash
npm install -g cheetah-greb
```

### API Key Setup

1. Go to **GREB Dashboard** → **API Keys**
2. Click **Create API Key**
3. Copy your API key (starts with `grb_`)
4. Set the API key in your MCP configuration

---

## Configuration

### Qodo Gen Configuration

Add to your Qodo Gen MCP configuration:

```json
{
  "mcpServers": {
    "greb-mcp": {
      "command": "greb-mcp",
      "env": {
        "GREB_API_KEY": "grb_your_api_key_here"
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
    "greb-mcp": {
      "command": "greb-mcp",
      "env": {
        "GREB_API_KEY": "grb_your_api_key_here"
      }
    }
  }
}
```

### Claude Desktop Configuration

Add to `~/Library/Application Support/Claude/claude_desktop_config.json` (Mac) or `%APPDATA%\Claude\claude_desktop_config.json` (Windows):

```json
{
  "mcpServers": {
    "greb-mcp": {
      "command": "greb-mcp",
      "env": {
        "GREB_API_KEY": "grb_your_api_key_here"
      }
    }
  }
}
```

### Node.js Version (Alternative)

If using the Node.js installation:

```json
{
  "mcpServers": {
    "greb-mcp": {
      "command": "greb-mcp-js",
      "env": {
        "GREB_API_KEY": "grb_your_api_key_here"
      }
    }
  }
}
```

---

## Available Tools

### `search_code` - Semantic Code Search

Search your codebase using natural language queries powered by AI.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | string | ✅ Yes | Natural language description of what to find |
| `directory` | string | ❌ No | Optional directory path to search (defaults to current project) |

**Query Structure:**

GREB automatically extracts:
- **Primary terms**: Main keywords (e.g., "authentication", "middleware", "jwt")
- **Code patterns**: Function names and patterns (e.g., `authenticate(`, `isAuthenticated`)
- **File patterns**: File type filters (e.g., `*.js`, `*.ts`)
- **Intent**: Overall search goal

**Examples:**

```typescript
// Find authentication logic
search_code({ 
  query: "find authentication middleware"
})

// Returns:
{
  "keywords": {
    "primary_terms": ["authentication", "middleware", "jwt"],
    "code_patterns": ["authenticate(", "isAuthenticated"],
    "file_patterns": ["*.js", "*.ts"],
    "intent": "find auth middleware implementation"
  },
  "results": [
    {
      "file": "src/middleware/auth.ts",
      "line": 15,
      "snippet": "export const authenticate = (req, res, next) => {",
      "relevance_score": 0.95
    }
  ]
}

// Find all API endpoints
search_code({ 
  query: "find all API endpoints"
})

// Find database connection
search_code({ 
  query: "look for database connection setup",
  directory: "/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint"
})

// Find error handling patterns
search_code({ 
  query: "search for error handling patterns"
})

// Find user validation
search_code({ 
  query: "find where user validation happens"
})
```

---

## Natural Language Query Patterns

### Finding Functions/Methods

```typescript
// Authentication & Authorization
"find authentication middleware"
"show me user login functions"
"where is the password validation?"

// API & Routes
"find all API endpoints"
"show me REST API routes"
"find GraphQL resolvers"

// Database
"find database connection setup"
"show me Supabase queries"
"where are the database migrations?"

// Utilities
"find utility functions for date formatting"
"show me helper functions"
"find validators"
```

### Finding Patterns & Logic

```typescript
// Error Handling
"search for error handling patterns"
"find try-catch blocks"
"show me error logging"

// Validation
"find where user validation happens"
"show me input sanitization"
"find form validators"

// State Management
"find state management setup"
"show me Redux actions"
"where is the context provider?"

// Configuration
"find configuration files"
"show me environment setup"
"where are the constants?"
```

### Finding Components & Classes

```typescript
// React/SwiftUI Components
"find the event detail view"
"show me guest list components"
"find all form components"

// Classes & Models
"find the Guest model"
"show me the Event class"
"find ViewModel classes"

// Services
"find the authentication service"
"show me API client setup"
"find the Supabase service"
```

---

## I Do Blueprint Use Cases

### 1. Finding SwiftUI Views

```typescript
// Find specific views
search_code({ 
  query: "find EventDetailView",
  directory: "/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint"
})

// Find all view components
search_code({ 
  query: "find all SwiftUI views with Guest in the name"
})

// Find form views
search_code({ 
  query: "find form views for creating events"
})
```

### 2. Supabase Integration Search

```typescript
// Find Supabase client setup
search_code({ 
  query: "find Supabase client initialization"
})

// Find database queries
search_code({ 
  query: "find all Supabase database queries"
})

// Find authentication flow
search_code({ 
  query: "find Supabase authentication functions"
})

// Find real-time subscriptions
search_code({ 
  query: "find Supabase real-time subscription setup"
})
```

### 3. RSVP Logic Discovery

```typescript
// Find RSVP handling
search_code({ 
  query: "find RSVP acceptance and decline logic"
})

// Find guest response tracking
search_code({ 
  query: "find where guest responses are stored"
})

// Find RSVP notifications
search_code({ 
  query: "find RSVP notification functions"
})
```

### 4. Model & Data Structure Search

```typescript
// Find data models
search_code({ 
  query: "find the Guest data model"
})

// Find event structure
search_code({ 
  query: "find Event struct or model definition"
})

// Find Supabase table schemas
search_code({ 
  query: "find database table definitions"
})
```

### 5. Error Handling & Validation

```typescript
// Find input validation
search_code({ 
  query: "find email validation functions"
})

// Find error handling
search_code({ 
  query: "find error handling for network requests"
})

// Find form validation
search_code({ 
  query: "find form validation logic"
})
```

### 6. API & Endpoint Discovery

```typescript
// Find API routes
search_code({ 
  query: "find all API endpoints"
})

// Find Edge Functions
search_code({ 
  query: "find Supabase Edge Functions"
})

// Find API client
search_code({ 
  query: "find HTTP client configuration"
})
```

---

## Usage Patterns in AI Assistants

### In Claude Code

```
Use greb mcp to find authentication middleware
Use greb mcp to find all API endpoints  
Use greb mcp to look for database connection setup
Use greb mcp to find where user validation happens
Use greb mcp to search for error handling patterns
```

### In Claude Desktop

```
Search my codebase for the EventDetailView
Find all Supabase queries in the project
Show me where RSVP logic is implemented
Find the Guest model definition
Look for authentication functions
```

### In Cursor/Windsurf

```
@greb find authentication middleware
@greb search for database migrations
@greb find all form components
@greb look for error handlers
```

---

## Performance & Token Efficiency

### Token Savings vs. Traditional Grep

Based on benchmarks with Claude Code:

| Approach | Tokens Used | Result Quality |
|----------|-------------|----------------|
| **GREB MCP** | ~X tokens | High precision, ranked results |
| **Traditional Grep** | ~2X tokens | Many irrelevant matches, no ranking |

GREB finds relevant code in fewer queries because:
1. **Semantic understanding** - finds what you mean, not just what you say
2. **Smart ranking** - most relevant results first
3. **Intent extraction** - understands the goal of your search
4. **No trial and error** - fewer follow-up searches needed

---

## Architecture

### How GREB Works

```
┌─────────────────────┐
│   AI Assistant      │
│  (Claude/Cursor)    │
└──────────┬──────────┘
           │
           │ MCP Protocol
           │
┌──────────▼──────────┐
│    GREB MCP         │
│    Server           │
└──────────┬──────────┘
           │
           │ Natural Language Query
           │
┌──────────▼──────────┐
│  GREB AI Engine     │
│  • Intent Analysis  │
│  • Keyword Extract  │
│  • Pattern Match    │
│  • Smart Ranking    │
└──────────┬──────────┘
           │
           │ Optimized Search
           │
┌──────────▼──────────┐
│   Local Codebase    │
│   /your/project     │
└─────────────────────┘
```

### Key Components

1. **Intent Analysis**: Understands what you're trying to find
2. **Keyword Extraction**: Identifies primary search terms automatically
3. **Pattern Matching**: Finds code patterns and function signatures
4. **Smart Ranking**: Returns results ordered by relevance
5. **File Filtering**: Automatically selects relevant file types

---

## Why Choose GREB for I Do Blueprint?

1. **Swift Support**: Natural language queries work across Swift, TypeScript, and any language
2. **No Setup**: Instantly search the codebase without indexing
3. **Fast**: Results in under 5 seconds, even for large SwiftUI projects
4. **Semantic Understanding**: Find "event creation flow" even if code uses different terms
5. **Token Efficient**: Uses ~50% fewer tokens than traditional grep workflows
6. **Multi-Language**: Works seamlessly across Swift (iOS), TypeScript (Next.js), and SQL
7. **Intent-Based**: Understands "find authentication" vs "find auth middleware" differently

---

## Best Practices

### Writing Effective Queries

**Good:**
- "find authentication middleware" (clear intent)
- "show me database connection setup" (specific goal)
- "find form validation for email input" (precise context)

**Less Effective:**
- "auth" (too vague)
- "find code" (no intent)
- "show me everything about users" (too broad)

### Query Tips

1. **Be specific about intent**: "find where RSVP responses are saved" vs "find RSVP"
2. **Mention the type**: "find EventViewModel class" vs "find event view"
3. **Include context**: "find Supabase authentication functions" vs "find auth"
4. **Use natural language**: Describe what you're looking for as you would to a colleague

---

## Comparison with Related Tools

| Tool | Type | Best For |
|------|------|----------|
| **GREB MCP** | Semantic local search | Natural language queries on local codebase |
| **Narsil MCP** | AST-based analysis | Deep code intelligence, security scanning |
| **Basic Memory** | Knowledge graphs | Long-term project knowledge, documentation |
| **Swiftzilla** | Documentation search | Swift API documentation lookup |

**Use Together:**
- Use GREB for quick "find X in my code" queries
- Use Narsil for comprehensive code analysis and security
- Use Basic Memory for storing architectural decisions
- Use Swiftzilla for Swift API documentation

---

## Links & Resources

- **Official Website**: https://grebmcp.com
- **Cheetah AI Dashboard**: https://greb.cheetahai.co (for API keys)
- **PyPI Package**: https://pypi.org/project/cheetah-greb/
- **NPM Package**: https://www.npmjs.com/package/cheetah-greb
- **Glama Directory**: https://glama.ai/mcp/servers/@VaibhavRaina/GREB-MCP

---

## License

MIT License

---

## Support

For issues, questions, or feature requests:
- Visit the GREB Dashboard for API key management
- Check the Glama directory for updates and community feedback