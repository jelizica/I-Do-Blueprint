---
title: ADR Analysis Server - Architectural Decisions & Deployment Intelligence
type: note
permalink: ai-tools/code-intelligence/adr-analysis-server-architectural-decisions-deployment-intelligence
---

# ADR Analysis Server - Architectural Decisions & Deployment Intelligence

> **AI-powered architectural insights that return real analysis, not just prompts**

## Overview

ADR Analysis Server is a sophisticated Model Context Protocol (MCP) server that provides AI coding assistants with deep architectural intelligence. Unlike traditional tools that simply generate prompts, this server returns actual analysis results - generating Architectural Decision Records (ADRs), detecting technology stacks, validating deployments, and linking architectural decisions to specific code implementations.

**Agent Attachments:**
- ✅ **Qodo Gen** (MCP Server)
- ✅ **Claude Code** (MCP Server)
- ✅ **Claude Desktop** (MCP Server)
- ✅ **Cursor** (MCP Server)
- ❌ CLI/Shell

---

## The Problem It Solves

### Why Traditional AI Fails at Architecture

AI coding assistants struggle with architectural context:

1. **No Architectural Memory**
   - Forgets decisions made in previous sessions
   - Can't track the "why" behind code choices
   - Suggests patterns inconsistent with project decisions

2. **Implicit Decisions Go Undocumented**
   - Technology choices made but never written down
   - Architectural patterns emerge organically without documentation
   - Future developers don't understand original reasoning

3. **Deployment Validation Gaps**
   - No systematic way to validate deployment readiness
   - Test failures don't block deployments automatically
   - Mock vs. production code detection is manual

**ADR Analysis Server Solves This:**
- Automatically generates ADRs from code analysis
- Creates ADRs from requirements documents (PRD.md)
- Links architectural decisions to specific code files
- Validates deployments with zero-tolerance for test failures
- Distinguishes mock code from production code

---

## Key Features

### Core Capabilities

1. **AI-Powered Architectural Analysis**
   - Immediate insights via OpenRouter.ai integration
   - 95% confidence scoring on analysis results
   - Technology stack detection across any programming language
   - Architectural pattern identification

2. **Comprehensive ADR Management**
   - Generate ADRs from existing code
   - Create ADRs from requirements (PRD.md → ADRs)
   - Suggest ADRs for implicit architectural decisions
   - Maintain and update ADRs as code evolves

3. **Smart Code Linking**
   - AI-powered keyword extraction from ADRs
   - Find code files that implement specific decisions
   - Uses both ripgrep (fast text search) and AI analysis
   - Configurable result limits and search depth

4. **Security & Compliance**
   - Automatic secret detection in code
   - Content masking for sensitive information
   - Local processing (zero-trust model)
   - Security recommendations based on code analysis

5. **Test-Driven Development Integration**
   - Two-phase TDD workflow with ADR linking
   - Validation of test coverage
   - Test-to-ADR relationship tracking
   - Deployment blocking on test failures

6. **Deployment Readiness Validation**
   - Zero-tolerance test validation (hard blocking)
   - Deployment history tracking
   - Mock vs. production code detection
   - Build verification automation

7. **Multi-Project Support**
   - Analyze multiple projects with custom configurations
   - Project-specific ADR directories
   - Shared architectural patterns across projects

---

## Installation

### Quick Install (Recommended)

```bash
# Global installation
npm install -g mcp-adr-analysis-server

# Or use npx (no installation required)
npx mcp-adr-analysis-server
```

### RHEL 9/10 Systems

```bash
# Special installer for Red Hat Enterprise Linux
curl -sSL https://raw.githubusercontent.com/tosin2013/mcp-adr-analysis-server/main/scripts/install-rhel.sh | bash
```

### From Source

```bash
git clone https://github.com/tosin2013/mcp-adr-analysis-server.git
cd mcp-adr-analysis-server
npm install
npm run build
npm test  # Ensure >80% test coverage passes
```

---

## Configuration

### Prerequisites

1. **Get OpenRouter API Key**
   - Go to https://openrouter.ai/keys
   - Create an API key
   - Copy the key for configuration

2. **Set Up Environment Variables**

```bash
export OPENROUTER_API_KEY="your_openrouter_api_key_here"
export EXECUTION_MODE="full"  # Enable AI-powered analysis
export AI_MODEL="anthropic/claude-3-sonnet"  # Or other supported models
export PROJECT_PATH="/path/to/your/project"
export ADR_DIRECTORY="docs/adrs"  # Where ADRs are stored
export LOG_LEVEL="ERROR"  # Options: ERROR, WARN, INFO, DEBUG
```

### Qodo Gen Configuration

Add to your Qodo Gen MCP configuration:

```json
{
  "mcpServers": {
    "adr-analysis": {
      "command": "npx",
      "args": ["mcp-adr-analysis-server"],
      "env": {
        "PROJECT_PATH": "${workspaceFolder}",
        "ADR_DIRECTORY": "docs/adrs",
        "OPENROUTER_API_KEY": "your_key_here",
        "EXECUTION_MODE": "full",
        "LOG_LEVEL": "ERROR"
      }
    }
  }
}
```

### Claude Code Configuration

```bash
# Quick setup with Claude Code
claude mcp add-json "adr-analysis" '{
  "command":"npx",
  "args":["mcp-adr-analysis-server"],
  "env":{
    "PROJECT_PATH":"${workspaceFolder}",
    "ADR_DIRECTORY":"docs/adrs",
    "OPENROUTER_API_KEY":"your_key_here",
    "LOG_LEVEL":"ERROR"
  }
}'
```

Or add to `~/.mcp.json`:

```json
{
  "mcpServers": {
    "adr-analysis": {
      "command": "npx",
      "args": ["mcp-adr-analysis-server"],
      "env": {
        "PROJECT_PATH": "${workspaceFolder}",
        "ADR_DIRECTORY": "docs/adrs",
        "OPENROUTER_API_KEY": "your_key_here",
        "EXECUTION_MODE": "full",
        "LOG_LEVEL": "ERROR"
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
    "adr-analysis": {
      "command": "mcp-adr-analysis-server",
      "env": {
        "PROJECT_PATH": "/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint",
        "ADR_DIRECTORY": "docs/adrs",
        "OPENROUTER_API_KEY": "your_key_here",
        "EXECUTION_MODE": "full",
        "LOG_LEVEL": "ERROR"
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
    "adr-analysis": {
      "command": "npx",
      "args": ["mcp-adr-analysis-server"],
      "env": {
        "PROJECT_PATH": "${workspaceFolder}",
        "ADR_DIRECTORY": "docs/adrs",
        "OPENROUTER_API_KEY": "your_key_here",
        "LOG_LEVEL": "ERROR"
      }
    }
  }
}
```

### Optional: Enhanced Web Research (Firecrawl)

For comprehensive architectural analysis with web research:

```bash
# Option 1: Cloud service (recommended)
export FIRECRAWL_ENABLED="true"
export FIRECRAWL_API_KEY="fc-your-api-key-here"

# Option 2: Self-hosted
export FIRECRAWL_ENABLED="true"
export FIRECRAWL_BASE_URL="http://localhost:3000"

# Option 3: Disabled (default - server works without web search)
# No configuration needed
```

**Benefits of Firecrawl:**
- Real-time architectural research
- Enhanced ADR generation with industry best practices
- Intelligent web scraping for architecture patterns

---

## Available Tools (23 MCP Tools)

### ADR Generation & Management

#### `analyzeProjectEcosystem` - Comprehensive Project Analysis

Analyze entire codebase to detect technologies, patterns, and architectural decisions.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `projectPath` | string | ✅ Yes | Path to project root |
| `analysisType` | string | ❌ No | Analysis depth: 'quick', 'standard', 'comprehensive' (default) |

**Example:**

```typescript
// Comprehensive analysis
analyzeProjectEcosystem({
  projectPath: '/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint',
  analysisType: 'comprehensive'
})

// Returns:
{
  "technologies": {
    "frontend": ["Next.js", "React", "TypeScript", "SwiftUI"],
    "backend": ["Supabase", "PostgreSQL"],
    "deployment": ["Vercel"],
    "testing": ["Jest", "XCTest"]
  },
  "patterns": [
    "Server Components",
    "API Routes",
    "Supabase RLS"
  ],
  "suggestedADRs": [
    {
      "title": "Use Supabase for Backend",
      "decision": "Adopt Supabase for database and authentication",
      "confidence": 0.95,
      "rationale": "Found 47 Supabase client usages across codebase"
    }
  ]
}
```

#### `generateAdrsFromPrd` - ADRs from Requirements

Generate architectural decision records from a Product Requirements Document.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `prdPath` | string | ✅ Yes | Path to PRD.md or requirements document |
| `outputDirectory` | string | ✅ Yes | Where to save generated ADRs (e.g., 'docs/adrs') |
| `generateTodos` | boolean | ❌ No | Also create todo.md with implementation tasks (default: false) |

**Example:**

```typescript
// Generate ADRs from PRD
generateAdrsFromPrd({
  prdPath: 'docs/PRD.md',
  outputDirectory: 'docs/adrs',
  generateTodos: true
})

// Creates files:
// docs/adrs/001-authentication-strategy.md
// docs/adrs/002-database-selection.md
// docs/adrs/003-frontend-framework.md
// docs/todo.md (implementation tasks)
```

#### `suggestAdr` - Suggest ADR for Code Pattern

Analyze code and suggest an ADR for an implicit architectural decision.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `codePattern` | string | ✅ Yes | Code snippet or pattern to analyze |
| `context` | string | ❌ No | Additional context about the code |

**Example:**

```typescript
// Suggest ADR for authentication pattern
suggestAdr({
  codePattern: `
    const supabase = createClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
  `,
  context: "Server-side authentication setup"
})

// Returns suggested ADR:
{
  "title": "Use Supabase for Authentication",
  "decision": "Adopt Supabase Auth with service role key for server-side operations",
  "consequences": [...],
  "alternatives": ["NextAuth.js", "Auth0", "Custom JWT"],
  "confidence": 0.92
}
```

### Smart Code Linking

#### `findRelatedCode` - Link ADRs to Code

Find code files that implement a specific architectural decision.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `adrPath` | string | ✅ Yes | Path to ADR file |
| `decisionText` | string | ✅ Yes | Specific decision to find code for |
| `projectPath` | string | ✅ Yes | Project root path |
| `options` | object | ❌ No | Search configuration |

**Options:**
- `useAI`: boolean - Use AI-powered keyword extraction (default: true)
- `useRipgrep`: boolean - Use fast text search (default: true)
- `maxFiles`: number - Limit results (default: 10)
- `fileExtensions`: string[] - Filter by extension (default: all)

**Example:**

```typescript
// Find code implementing JWT authentication
findRelatedCode(
  'docs/adrs/001-auth-system.md',
  'We will implement JWT authentication with Express middleware',
  '/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint',
  {
    useAI: true,
    useRipgrep: true,
    maxFiles: 10,
    fileExtensions: ['.ts', '.tsx', '.js']
  }
})

// Returns:
{
  "relatedFiles": [
    {
      "path": "src/middleware/auth.ts",
      "relevance": 0.95,
      "matches": ["JWT", "authenticate", "middleware"],
      "snippets": ["export const authenticate = async (req, res, next) => {"]
    },
    {
      "path": "src/lib/jwt.ts",
      "relevance": 0.88,
      "matches": ["JWT", "sign", "verify"],
      "snippets": ["export function signToken(payload) {"]
    }
  ]
}
```

### Deployment & Testing

#### `validateDeployment` - Deployment Readiness Check

Validate that project is ready for deployment with zero-tolerance for test failures.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `projectPath` | string | ✅ Yes | Project root path |
| `strictMode` | boolean | ❌ No | Hard block on any test failure (default: true) |

**Example:**

```typescript
// Validate deployment readiness
validateDeployment({
  projectPath: '/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint',
  strictMode: true
})

// Returns:
{
  "ready": false,
  "blockers": [
    {
      "type": "test_failure",
      "message": "3 tests failing in EventViewModel.test.swift",
      "severity": "critical"
    },
    {
      "type": "mock_code_in_production",
      "message": "MockSupabaseClient.ts detected in src/",
      "severity": "critical"
    }
  ],
  "warnings": [
    {
      "type": "missing_adr",
      "message": "No ADR for Supabase RLS policy decisions"
    }
  ]
}
```

#### `detectMockCode` - Find Mock/Test Code in Production

Identify mock implementations that shouldn't be in production builds.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `projectPath` | string | ✅ Yes | Project root path |
| `productionPaths` | string[] | ❌ No | Directories considered production (default: ['src', 'lib']) |

**Example:**

```typescript
// Detect mock code in production directories
detectMockCode({
  projectPath: '/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint',
  productionPaths: ['src', 'lib', 'components']
})

// Returns:
{
  "mockFilesFound": [
    {
      "path": "src/mocks/MockSupabaseClient.ts",
      "reason": "Mock implementation found in production directory",
      "severity": "critical"
    },
    {
      "path": "src/lib/testUtils.ts",
      "reason": "Test utilities in production code",
      "severity": "warning"
    }
  ]
}
```

### Security & Compliance

#### `checkSecurityIssues` - Security Analysis

Scan codebase for security issues and provide masking recommendations.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `projectPath` | string | ✅ Yes | Project root path |
| `checkTypes` | string[] | ❌ No | Types to check: ['secrets', 'sql_injection', 'xss', 'hardcoded_keys'] |

**Example:**

```typescript
// Check for security issues
checkSecurityIssues({
  projectPath: '/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint',
  checkTypes: ['secrets', 'hardcoded_keys']
})

// Returns:
{
  "issues": [
    {
      "type": "hardcoded_secret",
      "file": "src/config.ts",
      "line": 12,
      "severity": "critical",
      "content": "const API_KEY = 'sk-proj-...'",
      "recommendation": "Move to environment variable"
    }
  ],
  "maskingRecommendations": [
    "Use environment variables for all API keys",
    "Implement .env file with .gitignore",
    "Use dotenv package for configuration"
  ]
}
```

### Rule Generation & Compliance

#### `extractArchitecturalRules` - Generate Rules from ADRs

Extract architectural compliance rules from existing ADRs and code patterns.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `adrDirectory` | string | ✅ Yes | Path to ADR directory |
| `projectPath` | string | ✅ Yes | Project root path |

**Example:**

```typescript
// Extract rules from ADRs
extractArchitecturalRules({
  adrDirectory: 'docs/adrs',
  projectPath: '/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint'
})

// Returns:
{
  "rules": [
    {
      "rule": "All database queries must use Supabase RLS",
      "source": "docs/adrs/002-database-security.md",
      "enforcement": "mandatory",
      "validation": "Check for direct SQL queries bypassing RLS"
    },
    {
      "rule": "Authentication must use Supabase Auth, not custom JWT",
      "source": "docs/adrs/001-authentication.md",
      "enforcement": "mandatory",
      "validation": "No custom JWT signing/verification code"
    }
  ]
}
```

---

## I Do Blueprint Use Cases

### 1. Documenting Initial Architecture Decisions

```typescript
// Generate ADRs from the project PRD
generateAdrsFromPrd({
  prdPath: 'docs/WeddingPlanningApp_PRD.md',
  outputDirectory: 'docs/adrs',
  generateTodos: true
})

// Creates ADRs for:
// - Database choice (Supabase)
// - Authentication strategy
// - Frontend framework (Next.js + SwiftUI)
// - Real-time features approach
// - File storage solution
```

### 2. Analyzing Existing Codebase

```typescript
// Comprehensive analysis of I Do Blueprint
analyzeProjectEcosystem({
  projectPath: '/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint',
  analysisType: 'comprehensive'
})

// Discovers:
// - Technologies: Next.js, Swift, Supabase, PostgreSQL
// - Patterns: Server Components, RLS, real-time subscriptions
// - Suggests ADRs for undocumented decisions
```

### 3. Linking Database Decisions to Code

```typescript
// Find code implementing Supabase RLS policies
findRelatedCode(
  'docs/adrs/002-database-security.md',
  'All data access must use Row Level Security policies',
  '/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint',
  {
    useAI: true,
    fileExtensions: ['.ts', '.sql']
  }
})

// Returns files with RLS policy definitions and usage
```

### 4. Pre-Deployment Validation

```typescript
// Validate before deploying to production
validateDeployment({
  projectPath: '/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint',
  strictMode: true
})

// Checks:
// - All tests passing
// - No mock code in production directories
// - Security issues resolved
// - ADRs documented for major decisions
```

### 5. Security Audit

```typescript
// Check for security issues in wedding app
checkSecurityIssues({
  projectPath: '/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint',
  checkTypes: ['secrets', 'sql_injection', 'xss']
})

// Finds:
// - Hardcoded API keys
// - Potential SQL injection points
// - Missing input sanitization
```

### 6. Architectural Compliance

```typescript
// Extract and validate architectural rules
extractArchitecturalRules({
  adrDirectory: 'docs/adrs',
  projectPath: '/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint'
})

// Then validate code against rules:
// - All DB access uses Supabase client
// - No custom authentication code
// - Real-time features use Supabase subscriptions
```

---

## Architecture

### Project Structure

```
mcp-adr-analysis-server/
├── src/
│   ├── index.ts              # Main MCP server entry
│   ├── tools/                # 23 MCP tool implementations
│   ├── resources/            # MCP resource implementations
│   ├── prompts/              # MCP prompt implementations
│   ├── types/                # TypeScript interfaces & schemas
│   ├── utils/                # Utility functions and helpers
│   └── cache/                # Intelligent caching system
├── docs/
│   ├── adrs/                 # Architectural Decision Records
│   ├── research/             # Research findings and templates
│   └── NPM_PUBLISHING.md     # Publishing guide
├── tests/                    # >80% test coverage
├── .github/workflows/        # CI/CD automation
└── scripts/                  # Build and deployment scripts
```

### How It Works

```
┌─────────────────────┐
│   AI Assistant      │
│  (Claude/Cursor)    │
└──────────┬──────────┘
           │
           │ MCP Protocol
           │
┌──────────▼──────────┐
│ ADR Analysis Server │
│    (23 Tools)       │
└──────────┬──────────┘
           │
           ├─────────────────────┐
           │                     │
┌──────────▼──────────┐ ┌────────▼────────────┐
│  OpenRouter.ai      │ │ Local Analysis      │
│  (AI Analysis)      │ │ • Tree-sitter AST   │
│  • ADR Generation   │ │ • ripgrep Search    │
│  • Pattern Detection│ │ • Security Scanning │
└─────────────────────┘ └─────────────────────┘
           │                     │
           └─────────┬───────────┘
                     │
          ┌──────────▼──────────┐
          │   Your Codebase     │
          │ • docs/adrs/        │
          │ • src/              │
          │ • tests/            │
          └─────────────────────┘
```

### Technology Stack

- **Runtime**: Node.js 18+
- **Language**: TypeScript (strict mode)
- **MCP SDK**: Official Model Context Protocol SDK
- **AI Integration**: OpenRouter.ai (Claude, GPT, etc.)
- **Code Analysis**: Tree-sitter AST parsing
- **Search**: ripgrep + fast-glob
- **Testing**: Jest (>80% coverage)
- **Quality**: ESLint, pre-commit hooks
- **Security**: Automatic secret detection, content masking

---

## Why Choose ADR Analysis Server for I Do Blueprint?

1. **Wedding App Complexity**: Document decisions about RSVP logic, guest management, event workflows
2. **Multi-Platform**: Track architectural decisions across Next.js web app and SwiftUI iOS app
3. **Supabase Integration**: Generate ADRs for database schema, RLS policies, Edge Functions
4. **Security Critical**: Wedding apps handle personal data - security scanning is essential
5. **Deployment Confidence**: Zero-tolerance validation ensures no test failures in production
6. **Team Communication**: ADRs serve as documentation for collaborators and future you
7. **Technical Debt Prevention**: Document decisions now to prevent "why did we do this?" later

---

## Best Practices

### Writing Effective ADRs

ADRs should follow a standard format:

```markdown
# ADR-001: Use Supabase for Backend

## Status
Accepted

## Context
Need a backend solution for wedding planning app with:
- Real-time RSVP updates
- Secure guest data storage
- Authentication
- File uploads (photos)

## Decision
Use Supabase as the backend platform.

## Consequences
Positive:
- Real-time subscriptions built-in
- Row Level Security for data protection
- Authentication included
- Edge Functions for serverless compute

Negative:
- Vendor lock-in
- PostgreSQL-specific features only
- Learning curve for RLS policies

## Alternatives Considered
- Firebase (less SQL-friendly)
- AWS Amplify (more complex)
- Custom Node.js + PostgreSQL (more work)
```

### ADR Naming Convention

```
docs/adrs/
├── 001-database-choice.md
├── 002-authentication-strategy.md
├── 003-realtime-architecture.md
└── 004-file-storage-approach.md
```

### When to Create an ADR

Create ADRs for:
- Technology stack choices (frameworks, databases, libraries)
- Architectural patterns (authentication, state management)
- Security decisions (encryption, access control)
- Infrastructure choices (deployment, hosting)
- Breaking changes or major refactors

---

## Comparison with Related Tools

| Tool | Purpose | Best For |
|------|---------|----------|
| **ADR Analysis Server** | Architectural intelligence | ADR generation, deployment validation, architectural compliance |
| **Narsil MCP** | Code intelligence | Security scanning, call graphs, symbol search |
| **GREB MCP** | Semantic search | Finding code in your codebase |
| **Basic Memory** | Knowledge graphs | Long-term project knowledge |

**Use Together:**
- Use **ADR Analysis** for "Document this architectural decision"
- Use **Narsil** for "Find security issues in this implementation"
- Use **GREB** for "Where did I implement this pattern?"
- Use **Basic Memory** for "Remember our discussion about this feature"

---

## Links & Resources

- **GitHub Repository**: https://github.com/tosin2013/mcp-adr-analysis-server
- **Documentation**: https://tosin2013.github.io/mcp-adr-analysis-server/
- **Glama Directory**: https://glama.ai/mcp/servers/@tosin2013/mcp-adr-analysis-server
- **OpenRouter**: https://openrouter.ai/keys (for API keys)
- **MCP Specification**: https://modelcontextprotocol.io
- **Tutorial**: https://www.decisioncrafters.com/mcp-adr-analysis-server-ai-architecture-tutorial/

---

## License

MIT License - see LICENSE file for details

---

## Support & Community

- **Issues**: GitHub Issues
- **Questions**: GitHub Discussions
- **Tutorial**: Decision Crafters blog
- **CI/CD**: GitHub Actions automated testing

---

**Empowering AI assistants with deep architectural intelligence and decision-making capabilities.**