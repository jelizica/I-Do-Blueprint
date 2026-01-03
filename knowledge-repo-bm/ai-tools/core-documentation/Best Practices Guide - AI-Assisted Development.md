---
title: Best Practices Guide - AI-Assisted Development
type: note
permalink: ai-tools/core-documentation/best-practices-guide-ai-assisted-development
tags:
- best-practices
- development
- workflow
- standards
- guidelines
---

# Best Practices Guide - AI-Assisted Development

**Purpose**: Establish proven patterns, workflows, and conventions for effective AI-assisted development in the I Do Blueprint project.

**Related Documentation**:
- [[ai-tools/core-documentation/architecture-overview|Architecture Overview]] - System architecture
- [[ai-tools/core-documentation/decision-matrix|Tool Decision Matrix]] - Tool selection
- [[ai-tools/core-documentation/performance-optimization|Performance & Optimization]] - Efficiency guidelines
- [[ai-tools/_index|AI Tools Master Index]] - Complete catalog

---

## Table of Contents

1. [Core Principles](#core-principles)
2. [Communication with AI Agents](#communication-with-ai-agents)
3. [Project Structure & Documentation](#project-structure--documentation)
4. [Version Control Practices](#version-control-practices)
5. [Task Management with Beads](#task-management-with-beads)
6. [Code Quality & Review](#code-quality--review)
7. [Security & Privacy](#security--privacy)
8. [Knowledge Management](#knowledge-management)
9. [Testing & Validation](#testing--validation)
10. [Common Pitfalls & Anti-Patterns](#common-pitfalls--anti-patterns)

---

## Core Principles

### 1. Humans Architect, AI Implements

**✅ Right Mindset**:
- You design system architecture and make business decisions
- You define requirements and acceptance criteria
- AI executes implementation details
- You review and approve all changes

**❌ Wrong Mindset**:
- "AI will design my entire system"
- "AI knows my business logic"
- "AI can make architectural decisions autonomously"

**Example**:
```
✅ Good delegation:
"Design a guest RSVP system with: email confirmation, dietary preferences,
plus-one support, deadline enforcement. Use Supabase for backend, SendGrid
for email. See memory://projects/i-do-blueprint/data-model for schema."

❌ Poor delegation:
"Build something for managing wedding guests"
```

### 2. Clarity Over Brevity

**Effective prompts are specific, not short**:

```
❌ Bad: "Fix the auth bug"

✅ Good: "The JWT token refresh in src/auth/refreshToken.swift fails 
with 401 when token expires <60s before API call. Use Narsil to find 
the refresh logic, then fix the timing issue so refresh happens 60s 
BEFORE expiry, not AT expiry. Add test coverage."
```

### 3. Trust but Verify

**Never deploy without review**:
- AI-generated code requires human review (every single line)
- Run tests before accepting changes
- Security scans are mandatory (`swiftscan .`)
- Verify against original requirements
- Check for business logic correctness

### 4. Incremental Progress with Checkpoints

**Break large tasks into verifiable steps**:

```bash
# ❌ Bad: One massive task
bd create "Build entire RSVP system" -p 1

# ✅ Good: Incremental with dependencies
bd create "Design RSVP database schema" -p 1 --id bd-001
bd create "Create migration SQL" -p 1 --deps blocks:bd-001
bd create "Generate TypeScript types" -p 2 --deps blocks:bd-002
bd create "Build API endpoints" -p 1 --deps blocks:bd-003
bd create "Write integration tests" -p 2 --deps blocks:bd-004
```

**Checkpoint after each step**:
1. Review code thoroughly
2. Run all tests
3. Commit to git with descriptive message
4. Document learnings in Basic Memory
5. Update Beads status

### 5. Context is King

**Provide context proactively**:
- Link to related Beads tasks: `See bd-abc for context`
- Reference Basic Memory notes: `Review memory://projects/i-do-blueprint/auth-design`
- Point to similar implementations: `Use Narsil to find existing email handlers`
- Attach design docs, tickets, ADRs

---

## Communication with AI Agents

### Writing Effective Prompts

#### Structure Your Requests

**Template**:
```
[GOAL] - What you want to accomplish
[CONTEXT] - Background information, related work
[CONSTRAINTS] - Limitations, requirements, non-negotiables
[EXAMPLES] - Similar implementations or reference code
[SUCCESS CRITERIA] - How to verify correctness
```

**Real Example**:
```
GOAL: Implement email confirmation for RSVP submissions

CONTEXT: 
- Using Supabase Edge Functions for backend
- Email service: SendGrid (API key in .envrc)
- RSVP data model: supabase/migrations/20250125_create_guests.sql
- Must integrate with existing RSVP flow

CONSTRAINTS:
- Handle send failures gracefully (retry 3x with exponential backoff)
- Email template: edge-functions/rsvp-confirmation/template.html
- No PII in logs (mask email addresses)
- 30-second timeout limit for edge functions

EXAMPLES:
- See edge-functions/welcome-email/ for similar pattern
- Use Narsil to find other SendGrid integrations

SUCCESS CRITERIA:
- Guest receives email <30 seconds after RSVP submission
- Email contains: guest name, event details, confirmation link
- Integration test passes: edge-functions/tests/rsvp-confirmation.test.ts
- Handles network failures without crashing
```

#### Multi-Step Workflows

**Use "Plan → Act → Reflect" pattern**:

```
Step 1 (PLAN):
"Before implementing, create a detailed plan for adding rate limiting 
to our API. Include: which endpoints need protection, storage mechanism 
(Redis vs Supabase), error responses (429 status), middleware integration 
points. Document plan in Basic Memory under projects/i-do-blueprint/rate-limiting."

Step 2 (ACT):
"Using the plan in memory://projects/i-do-blueprint/rate-limiting, implement 
the rate limiter. Start with middleware, then update routes. Use existing 
auth middleware pattern as reference."

Step 3 (REFLECT):
"Review the implementation. Did we handle edge cases (burst traffic, 
distributed instances)? Are tests comprehensive? Document any issues 
in Beads for follow-up. Update Basic Memory with actual implementation notes."
```

### Maintaining Context Across Sessions

#### Session Start Protocol

```javascript
// 1. Restore project context (last 7 days)
await memory.buildContext({
  url: "memory://projects/i-do-blueprint",
  depth: 1,
  timeframe: "7d",
  max_related: 10
});

// 2. Check active work (limit for context efficiency)
bd ready --limit 5 --brief

// 3. Review recent activity
await memory.recentActivity({
  project: "i-do-blueprint",
  timeframe: "3d"
});
```

#### Session End Protocol

```bash
# 1. Complete finished tasks
bd close bd-abc --reason "Implemented with passing tests"

# 2. Document learnings (if applicable)
# Write to Basic Memory for new patterns, solutions, gotchas

# 3. Sync all changes
bd sync
git push

# 4. Update blocked tasks with notes
bd update bd-xyz --status blocked --notes "Waiting for SendGrid API key from DevOps (ticket #456)"
```

---

## Project Structure & Documentation

### Essential Documentation Files

**AGENTS.md** (Root directory - AI instructions):
```markdown
# AI Agent Instructions for I Do Blueprint

## Project Overview
Wedding planning application built with SwiftUI (iOS) + Supabase (backend).
Guests can RSVP, view event details, submit dietary preferences, manage plus-ones.

## Development Workflow
1. **Task Tracking**: Use `bd` for ALL task management
2. **Security**: Run `swiftscan .` before EVERY commit (no exceptions)
3. **Documentation**: Document design decisions in Basic Memory (ai-tools/)
4. **Reference**: See ai-tools/README.md for complete tool catalog

## Key Commands
- `bd ready` - Find next unblocked task
- `bd show <id>` - View task details
- `sb-reset` - Reset local Supabase database
- `swiftscan .` - Swift security scanning (Semgrep)
- `sb-gen-types` - Generate TypeScript types from schema

## Project Structure
- `/app` - SwiftUI iOS application
- `/supabase/migrations` - Database schema (SQL)
- `/supabase/functions` - Edge functions (TypeScript)
- `/docs/architecture` - System diagrams (Structurizr DSL)
- `/docs/adrs` - Architectural Decision Records
- `/ai-tools` - AI development tool documentation

## Conventions
- Database: snake_case for columns
- Swift: PascalCase for types, camelCase for variables
- Git: Conventional commits (feat/fix/docs/refactor/test/chore)
- Tests: Required for all new features
- Security: NEVER commit .env files or API keys
```

**README.md** (Human-focused overview):
```markdown
# I Do Blueprint

Wedding planning application with guest management, RSVP tracking, and event coordination.

## Quick Start
1. Install dependencies: `npm install && pod install`
2. Start Supabase: `sb-start`
3. Generate types: `sb-gen-types`
4. Run app in Xcode

## Architecture
See docs/architecture/README.md for system design.
See ai-tools/README.md for AI development tools.

## Development
- Task tracking: Beads (`bd` command)
- Database: Supabase (local development via Docker)
- Testing: XCTest (Swift), Jest (TypeScript)
- CI/CD: GitHub Actions

## Documentation
- `/docs` - Human documentation
- `/ai-tools` - AI agent tool catalog
```

**ai-tools/README.md** (AI-focused):
```markdown
# AI Development Tools Catalog

Complete reference for AI development tools in the I Do Blueprint project.

## Tool Categories
- **Code Intelligence**: Narsil, GREB, Swiftzilla, ADR Analysis
- **Infrastructure**: Supabase, Code Guardian Studio
- **Security**: Semgrep, MCP Shield, Themis
- **Workflow**: Beads, direnv, sync-mcp-cfg
- **Knowledge**: Basic Memory
- **Orchestration**: Owlex, Agent Deck
- **Visualization**: Mermaid, Structurizr DSL

## Common Workflows
See integration-patterns/ for detailed workflows:
- Daily development routine
- Security scanning pipeline
- Session management protocol

## Tool Documentation
See tool-docs/ for comprehensive guides on each tool.
```

### Directory Structure Best Practices

```
I Do Blueprint/
├── .beads/                    # Beads database (git-tracked .jsonl)
│   ├── issues.jsonl           # Task data (version controlled)
│   └── beads.db               # SQLite cache (gitignored)
├── .envrc                     # Environment variables (direnv)
├── .mcp.json                  # MCP server configuration
├── AGENTS.md                  # AI agent instructions ⭐
├── README.md                  # Human overview
├── app/                       # SwiftUI iOS application
│   ├── Models/
│   ├── Views/
│   ├── ViewModels/
│   └── Services/
├── supabase/                  # Backend infrastructure
│   ├── migrations/            # SQL schema migrations
│   ├── functions/             # Edge functions (TypeScript)
│   ├── seed.sql               # Development test data
│   └── config.toml            # Supabase configuration
├── docs/                      # Human-readable documentation
│   ├── architecture/          # System design diagrams
│   │   ├── workspace.dsl      # Structurizr C4 models
│   │   └── exports/           # Generated diagrams
│   ├── adrs/                  # Architectural Decision Records
│   └── guides/                # Developer guides
├── ai-tools/                  # AI tool documentation ⭐
│   ├── README.md              # Tool catalog index
│   ├── tool-docs/             # Individual tool guides
│   │   ├── code-intelligence/
│   │   ├── infrastructure/
│   │   ├── security/
│   │   └── workflow/
│   ├── integration-patterns/  # Multi-tool workflows
│   ├── getting-started/       # Setup guides
│   ├── shell-reference/       # Shell aliases, scripts
│   └── core-documentation/    # Architecture, best practices
├── scripts/                   # Automation scripts
│   ├── security-check.sh      # Pre-commit security validation
│   ├── generate-diagrams.sh   # Structurizr diagram generation
│   └── verify-tooling.sh      # Development environment check
└── tests/                     # Test suites
    ├── unit/
    ├── integration/
    └── e2e/
```

### Documentation Principles

1. **Single Source of Truth**: Never duplicate information - link instead
2. **Link Liberally**: Use `[[wikilinks]]` in Basic Memory, relative paths in markdown
3. **Update on Change**: Documentation rots quickly - review quarterly, update on major changes
4. **AI-Readable Format**: Use Markdown with clear headers, structured consistently
5. **Examples Over Explanations**: Show actual code/commands, not just descriptions
6. **Context Over Completeness**: Provide enough context for AI to understand purpose

---

## Version Control Practices

### Commit Hygiene

**Granular, Focused Commits**:
```bash
# ❌ Bad: Massive commit mixing unrelated changes
git add -A
git commit -m "Updates"

# ✅ Good: Focused, atomic commits
git add -p  # Interactively stage specific chunks
git commit -m "feat: Add email confirmation to RSVP flow

- Create SendGrid email template with branding
- Implement edge function with retry logic (3 attempts)
- Add email_sent_at timestamp to guests table
- Update RSVP model to track confirmation status

Closes: bd-abc
Related: memory://projects/i-do-blueprint/email-design"
```

**Commit Message Format** (Conventional Commits):
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature for users
- `fix`: Bug fix
- `docs`: Documentation only
- `refactor`: Code restructuring (no functional change)
- `test`: Adding or updating tests
- `chore`: Maintenance (dependencies, config, build)
- `perf`: Performance improvement
- `style`: Code style/formatting (no logic change)

**Examples**:
```
feat(rsvp): Add dietary preference tracking
fix(auth): Correct token refresh timing issue
docs(api): Update API endpoint documentation
refactor(guest): Extract validation into separate module
test(rsvp): Add integration tests for email confirmation
chore(deps): Upgrade Supabase client to v2.45.0
```

**Footer Links**:
- `Closes: bd-xyz` - Links to Beads task
- `Fixes: #123` - Links to GitHub issue
- `Related: memory://path` - Links to design doc in Basic Memory
- `BREAKING CHANGE:` - Indicates breaking API changes

### Git Workflow

**Feature Development Flow**:
```bash
# 1. Create task in Beads with clear description
bd create "Add guest dietary preferences tracking" -p 1 --type feature --id bd-diet

# 2. Create feature branch (naming: type/brief-description)
git checkout -b feat/guest-dietary-prefs

# 3. Implement incrementally with AI assistance
# Make multiple focused commits as you progress
git commit -m "feat(guest): Add dietary_notes column to schema"
git commit -m "feat(guest): Create migration for dietary preferences"
git commit -m "feat(rsvp): Update RSVP form UI for dietary input"
git commit -m "test(guest): Add tests for dietary preference validation"

# 4. Before pushing - CRITICAL checks
swiftscan .           # Security scan (must pass)
npm test              # All tests must pass
bd doctor --fix       # Verify Beads health

# 5. Update Beads and sync
bd close bd-diet --reason "Implemented with tests passing"
bd sync

# 6. Push and create pull request
git push origin feat/guest-dietary-prefs
gh pr create --title "Add guest dietary preferences tracking" \
             --body "Closes: bd-diet

## Changes
- Added dietary_notes field to guests table
- Updated RSVP form UI
- Added validation for dietary input
- Comprehensive test coverage

## Testing
- Unit tests: ✅ All passing
- Integration tests: ✅ RSVP flow verified
- Security scan: ✅ No issues found"
```

### .gitignore Essentials

**CRITICAL - Never Commit These**:
```gitignore
# Secrets and API Keys (HIGHEST PRIORITY)
.env
.env.*
!.env.example        # Example file is OK
*.pem
*.key
*.p12
Config.plist         # Often contains API keys
secrets.json

# Supabase
.supabase/           # Local Supabase data
service_role_key     # Never commit service role key

# macOS & Xcode
.DS_Store
*.swp
DerivedData/
*.xcuserstate
xcuserdata/

# Dependencies
node_modules/
Pods/
.build/

# AI Tool Caches (optional - gitignore if large)
.beads/beads.db      # SQLite cache (keep issues.jsonl!)
.narsil/cache/       # Narsil parse cache
.basic-memory/index.db  # Basic Memory SQLite index

# Build Artifacts
*.app
*.ipa
build/
dist/
```

**Security Pre-Commit Hook** (`.git/hooks/pre-commit`):
```bash
#!/bin/bash
# Run security checks before allowing commit

# Check for accidentally staged secrets
if git diff --cached --name-only | grep -qE '\\.env$|secrets\\.'; then
    echo "❌ Error: Attempting to commit secrets file!"
    echo "Files: $(git diff --cached --name-only | grep -E '\\.env$|secrets\\.')"
    exit 1
fi

# Run security scan
echo "Running security scan..."
swiftscan . || {
    echo "❌ Security scan failed. Commit blocked."
    exit 1
}

# Check for hardcoded API keys
if git diff --cached | grep -iE '(api[_-]?key|secret[_-]?key|password)\s*=\s*["\'][^"\']+["\']'; then
    echo "⚠️  Warning: Possible hardcoded credentials detected"
    echo "Please review and use environment variables instead"
    exit 1
fi

echo "✅ Security checks passed"
```

---

## Task Management with Beads

### Task Granularity Guidelines

**Right-Sized Tasks** (2-8 hours of work):

```bash
# ❌ Too Large (Epic-level - needs breakdown)
bd create "Build complete guest management system" -p 1

# ❌ Too Small (Micro-task - not worth tracking)
bd create "Add import statement for SendGrid" -p 2
bd create "Rename variable from guestData to guest" -p 3

# ✅ Just Right (Clear, actionable, completable in one session)
bd create "Implement guest CRUD API endpoints" -p 1
bd create "Build guest list UI component with filtering" -p 2
bd create "Add email validation to RSVP form" -p 1
bd create "Write integration tests for guest creation flow" -p 2
```

**How to Break Down Large Tasks**:

```bash
# Start with epic
bd create "Epic: Complete Guest Management System" -p 1 --type epic --id bd-guest-epic

# Break into features
bd create "Backend: Guest CRUD API" -p 1 --parent bd-guest-epic --id bd-backend
bd create "Frontend: Guest List UI" -p 1 --parent bd-guest-epic --id bd-frontend
bd create "Feature: Email Notifications" -p 2 --parent bd-guest-epic

# Break features into tasks
bd create "Create guests table migration" -p 1 --parent bd-backend
bd create "Implement GET /guests endpoint" -p 1 --parent bd-backend
bd create "Implement POST /guests endpoint" -p 1 --parent bd-backend
bd create "Add request validation middleware" -p 2 --parent bd-backend

# Add dependencies
bd dep add bd-frontend bd-backend --type blocks
# Frontend blocked until backend API exists
```

### Using Dependencies Effectively

**Four Dependency Types**:

1. **blocks** - Hard blocker (cannot start until dependency completes)
   ```bash
   bd dep add ui-implementation api-endpoints --type blocks
   # UI absolutely cannot start until API exists
   ```

2. **related** - Soft association (contextual link, not blocking)
   ```bash
   bd dep add api-documentation api-implementation --type related
   # Docs should be updated but doesn't block API work
   ```

3. **parent-child** - Epic/subtask hierarchy
   ```bash
   bd create "Epic: OAuth Integration" --type epic --id bd-oauth
   bd create "Backend OAuth flow" --parent bd-oauth
   bd create "Frontend OAuth UI" --parent bd-oauth
   # Creates logical grouping
   ```

4. **discovered-from** - Found during work (links to discovery context)
   ```bash
   # While working on bd-rsvp-form, you discover validation bug
   bd create "Fix email validation regex" -p 0 --type bug --id bd-bugfix
   bd dep add bd-bugfix bd-rsvp-form --type discovered-from
   # Preserves context of how bug was found
   ```

### Priority Conventions

**I Do Blueprint Priority Scale**:

| Priority | Label | Use Case | Examples |
|----------|-------|----------|----------|
| **P0** | Blocker/Critical | Production breaks, security issues, data loss risk | SQL injection vulnerability, authentication bypass, data corruption |
| **P1** | High | Core features, important bugs affecting user experience | RSVP submission fails, email not sending, UI crash on guest list |
| **P2** | Medium | Enhancements, minor bugs, nice-to-haves | Improved filtering, better error messages, UI polish |
| **P3** | Low | Future improvements, backlog, technical debt | Code refactoring, documentation improvements, optimization ideas |

**Priority Assignment Rules**:
```bash
# Security issues = Always P0
bd create "Fix SQL injection in guest search" -p 0 --type bug

# Core features = Usually P1
bd create "Implement RSVP deadline enforcement" -p 1 --type feature

# Enhancements = Usually P2
bd create "Add guest photo upload capability" -p 2 --type feature

# Technical debt = Usually P3
bd create "Refactor guest service for better testability" -p 3 --type chore
```

### Task Lifecycle Management

**Status Flow**:
```
open → in_progress → (blocked?) → closed
   ↓         ↓           ↓
ready    working    paused
```

**Status Transitions**:

```bash
# 1. Find and claim ready work
bd ready --limit 5
bd update bd-abc --status in_progress --assignee "claude"

# 2. If you hit a blocker
bd update bd-abc --status blocked \
  --notes "Waiting for SendGrid API key approval from DevOps (Ticket #DEV-456, ETA: 2025-01-02)"

# 3. When unblocked
bd update bd-abc --status in_progress

# 4. On completion
bd close bd-abc --reason "Implemented with passing tests. Email confirmation working as expected."

# 5. If deferring (not now, maybe later)
bd update bd-abc --status deferred \
  --notes "Postponing until after MVP launch. Low priority feature."
```

**Using Notes Field Effectively**:

```bash
# ✅ Good notes - provide context and next steps
bd update bd-xyz --notes "Implemented retry logic. Need to add exponential backoff. See memory://projects/i-do-blueprint/retry-patterns for design."

bd update bd-abc --notes "Blocked: requires DESIGN decision on whether dietary preferences should be freeform text or predefined categories. Ping Jessica for input."

# ❌ Bad notes - vague or redundant
bd update bd-xyz --notes "working on it"
bd update bd-abc --notes "blocked"
```

---

## Code Quality & Review

### Pre-Commit Checklist

**Before Accepting ANY AI-Generated Code**:

- [ ] **Functionality**: Does it actually meet requirements? Test it manually.
- [ ] **Tests Exist**: Are there unit/integration tests?
- [ ] **Tests Pass**: Do ALL tests pass (not just new ones)?
- [ ] **Security**: Run `swiftscan .` - zero issues allowed
- [ ] **Performance**: Any obvious inefficiencies (N+1 queries, unnecessary loops)?
- [ ] **Maintainability**: Is code readable? Properly structured? Would another developer understand it?
- [ ] **Documentation**: Complex logic commented? Public APIs documented?
- [ ] **Error Handling**: Edge cases covered? Proper error messages?
- [ ] **Naming**: Clear, consistent variable/function/type names?
- [ ] **No Secrets**: No API keys, passwords, or PII hardcoded?

### Code Review Patterns

**Iterative Refinement Workflow**:

```
Round 1:
Human: "Implement user authentication with JWT tokens"
AI: [generates initial implementation]

Round 2:
Human: "Review feedback:
1. Missing rate limiting on login endpoint (DoS risk)
2. Password complexity not enforced (security requirement)
3. No tests for token refresh logic
4. Error messages expose too much detail (security)
Fix these issues."
AI: [refines implementation]

Round 3:
Human: "Better. Two more issues:
1. JWT secret should come from environment, not hardcoded
2. Add integration test for expired token scenario
Apply fixes."
AI: [final refinement]

Round 4:
Human: [Final review - accepts or continues]
```

**Asking Clarifying Questions** (without triggering changes):

```
❌ "Why did you use a singleton here?"
→ AI might interpret as "Don't use singleton" and refactor

✅ "Just a question: Why did you choose singleton pattern for AuthManager?"
→ AI explains reasoning without changing code

✅ "Before we proceed, can you explain the trade-offs between singleton vs dependency injection for this use case?"
→ AI provides analysis to inform your decision
```

### Testing Standards

**Required Test Coverage**:

1. **Unit Tests**: All business logic, utilities, helpers
   ```swift
   // ✅ Test pure functions
   func testEmailValidation() {
       XCTAssertTrue(Validator.isValidEmail("user@example.com"))
       XCTAssertFalse(Validator.isValidEmail("invalid"))
       XCTAssertFalse(Validator.isValidEmail(""))
   }
   ```

2. **Integration Tests**: API endpoints, database interactions
   ```typescript
   // ✅ Test full RSVP flow
   describe('RSVP Submission', () => {
     it('should create guest record and send confirmation email', async () => {
       const response = await request(app)
         .post('/api/rsvp')
         .send(validRSVPData);
       
       expect(response.status).toBe(201);
       
       // Verify database
       const guest = await supabase
         .from('guests')
         .select()
         .eq('email', validRSVPData.email)
         .single();
       expect(guest).toBeDefined();
       
       // Verify email sent (check mock)
       expect(sendGridMock).toHaveBeenCalledWith(
         expect.objectContaining({ to: validRSVPData.email })
       );
     });
   });
   ```

3. **Edge Case Tests**: Error conditions, boundary values
   ```swift
   func testRSVPWithPastDeadline() {
       let pastDate = Date().addingTimeInterval(-86400) // Yesterday
       XCTAssertThrowsError(try RSVPService.submit(deadline: pastDate))
   }
   ```

**Test-Driven Development with AI**:

```
Step 1: Write failing test first
Human: "Write a test for RSVP deadline validation. It should reject 
submissions after deadline and accept before deadline."

Step 2: Implement to make test pass
AI: [writes implementation]

Step 3: Verify and refine
Human: "Run tests. If failing, fix implementation (not the test)."
```

---

## Security & Privacy

### Security-First Development

**Non-Negotiable Rules**:

1. **Never Commit Secrets** - Use `.envrc` (gitignored) for all API keys, tokens, passwords
2. **Always Scan Before Commit** - `swiftscan .` must pass (no exceptions)
3. **Validate All Inputs** - Never trust user input or external APIs
4. **Use Prepared Statements** - Prevent SQL injection (Supabase handles this)
5. **Encrypt Sensitive Data** - Use Themis for client-side encryption if needed
6. **Principle of Least Privilege** - Use `anon` key, not `service_role` in client code

### Security Scanning Workflow

**Daily Security Checks**:
```bash
# Run before every commit (automated via pre-commit hook)
swiftscan .

# Output should show zero issues:
# ✅ No issues found in X files
```

**Weekly Security Audit**:
```bash
# Monday morning routine
mcpscan-all  # Audit all MCP server configurations

# Check for:
# - MCP servers requesting excessive permissions
# - Suspicious tool definitions
# - Outdated or unmaintained servers
```

**Before Production Deploy**:
```bash
# Comprehensive security checklist
swiftscan .                      # Swift code scan
semgrep --config p/secrets .     # Secret detection
bd create "Security audit" -p 0  # Manual review task

# Review:
# - Authentication/authorization logic
# - Data validation on all endpoints
# - Error messages (don't expose internals)
# - Rate limiting on public endpoints
# - CORS configuration
# - HTTPS enforcement
```

### Handling Sensitive Data

**Environment Variables** (`.envrc`):
```bash
# ✅ Good - secrets in environment
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="eyJhbGc..."  # Public anon key (safe)
export SENDGRID_API_KEY="SG.xxx..."    # Secret (never commit)

# Load in code:
let apiKey = ProcessInfo.processInfo.environment["SENDGRID_API_KEY"]!
```

**API Key Management**:
```swift
// ❌ Bad - hardcoded secret
let apiKey = "SG.abc123secretkey"

// ✅ Good - from environment
guard let apiKey = ProcessInfo.processInfo.environment["SENDGRID_API_KEY"] else {
    fatalError("SENDGRID_API_KEY environment variable not set")
}
```

**Logging Security**:
```swift
// ❌ Bad - logs PII
logger.info("User login: email=\(email), password=\(password)")

// ✅ Good - masked PII
logger.info("User login attempt: email=\(email.maskEmail())")

extension String {
    func maskEmail() -> String {
        let components = self.split(separator: "@")
        guard components.count == 2 else { return "***@***" }
        let username = components[0].prefix(2) + "***"
        return "\(username)@\(components[1])"
    }
}
// Logs: "us***@example.com"
```

---

## Knowledge Management

### When to Document in Basic Memory

**✅ Document These**:
- Complex bugs that took >2 hours to solve
- Non-obvious architectural decisions
- Performance optimization techniques
- Third-party API quirks/workarounds
- Team-specific coding patterns
- Debugging insights that aren't obvious from code

**❌ Don't Document These**:
- Standard language syntax (already in Swift docs)
- Common best practices (already well-documented online)
- Temporary workarounds (create Beads issue instead to track proper fix)
- Things that belong in code comments

### Effective Note-Taking

**Note Structure**:
```markdown
---
title: RSVP Email Delivery Optimization
type: note
tags: performance, email, optimization, supabase
---

# RSVP Email Delivery Optimization

## Problem
Email confirmations were taking 45+ seconds, causing user confusion
and timeout errors in Supabase Edge Functions (10s limit).

## Root Cause
Sending emails sequentially in a loop. For 100 guests = 100 sequential
API calls to SendGrid.

## Solution
Batched email sending using SendGrid's batch API. Groups of 100 emails
sent in single request.

## Implementation
```typescript
// Before: Sequential (45s for 100 emails)
for (const guest of guests) {
  await sendGrid.send({ to: guest.email, ... });
}

// After: Batched (8s for 100 emails)
const batch = guests.map(g => ({ to: g.email, ... }));
await sendGrid.sendMultiple(batch);
```

## Results
- Send time: 45s → 8s (82% reduction)
- Edge function timeouts: 0
- User experience: Immediate confirmation

## Related
- Improves: [[technical/email-system]]
- Uses: [[infrastructure/supabase-edge-functions]]
- Pattern: [[patterns/api-batching]]

## Tags
#performance #infrastructure #email
```

### Linking Knowledge

**Create Knowledge Graphs**:
```markdown
<!-- In email-system.md -->
Related systems:
- [[infrastructure/sendgrid-integration]]
- [[features/rsvp-confirmation]]
- [[learnings/email-delivery-optimization]]

<!-- Basic Memory automatically creates bidirectional links -->
```

### Knowledge Retrieval

**During Development**:
```javascript
// Before implementing feature, search for related knowledge
const context = await memory.searchNotes({
  query: "email sending optimization",
  project: "i-do-blueprint"
});

// Builds on past learnings instead of reinventing
```

---

## Testing & Validation

### Test Pyramid

**I Do Blueprint Test Strategy**:

```
         /\
        /E2E\ <-- Few (critical user flows)
       /------\
      / Integration \ <-- Some (API + DB)
     /--------------\
    /   Unit Tests    \ <-- Many (business logic)
   /------------------\
```

**Unit Tests** (60% of tests):
- Pure functions
- Business logic
- Utilities
- View models (SwiftUI)

**Integration Tests** (30% of tests):
- API endpoints
- Database operations
- External service mocks (SendGrid)

**E2E Tests** (10% of tests):
- Critical user paths only
- RSVP submission flow
- Guest list viewing

### AI-Assisted Testing

**Test Generation Workflow**:

```
Step 1: Human defines test cases
"Write tests for the guest dietary preferences feature:
1. Should accept valid preferences (vegetarian, vegan, gluten-free, allergies)
2. Should reject preferences >500 characters
3. Should sanitize HTML/script tags
4. Should handle emoji and international characters
5. Should update existing preferences on subsequent RSVP"

Step 2: AI generates tests
[AI creates comprehensive test suite]

Step 3: Human reviews test quality
- Are edge cases covered?
- Are assertions specific enough?
- Do tests actually test the right thing?

Step 4: Run and iterate
- Tests should fail initially (TDD)
- Implement feature to make tests pass
- Refine tests as needed
```

---

## Common Pitfalls & Anti-Patterns

### Anti-Pattern #1: Overcomplicating Simple Tasks

```
❌ Bad:
bd create "Fix typo in button label" -p 2
# Use ADR Analysis
# Use Code Guardian
# Document in Basic Memory
# Generate diagrams

✅ Good:
# Just fix it and commit
git commit -m "fix(ui): Correct spelling of 'Submit' button"
```

### Anti-Pattern #2: Bypassing Security

```
❌ Bad:
git commit -m "Quick fix" --no-verify  # Skips pre-commit hooks!

✅ Good:
swiftscan .  # Fix any issues
git commit -m "fix: Update validation logic"
```

### Anti-Pattern #3: Not Using Beads for Multi-Step Work

```
❌ Bad:
Human: "Build the entire guest management feature"
[AI works for 3 hours, context window fills]
[Agent loses track of what's done vs. what's remaining]

✅ Good:
bd create "Epic: Guest Management" --type epic
bd create "Backend API" --parent epic
bd create "Frontend UI" --parent epic
bd ready  # AI always knows next task
```

### Anti-Pattern #4: Ignoring Dependencies

```
❌ Bad:
bd create "Build UI" -p 1
bd create "Build API" -p 1
# Both show as "ready" but UI can't work without API!

✅ Good:
bd create "Build API" -p 1 --id api
bd create "Build UI" -p 1
bd dep add ui api --type blocks  # UI blocked until API done
bd ready  # Only shows API (UI won't appear until API closed)
```

### Anti-Pattern #5: Poor Context Preservation

```
❌ Bad:
# Spend 4 hours debugging OAuth issue
# Finally solve it
# Never document the solution
# Waste 4 hours again next month on same issue

✅ Good:
# After solving, document immediately
memory.writeNote({
  title: "OAuth Token Refresh Timing Issue",
  folder: "learnings/auth",
  content: "Token refresh must happen 60s BEFORE expiry 
            due to clock skew between client and server..."
});
```

### Anti-Pattern #6: Vague Requirements

```
❌ Bad:
"Make the app faster"
"Fix the bugs"
"Improve the UI"

✅ Good:
"Reduce RSVP form submission time from 3s to <1s by:
1. Batching database updates
2. Implementing optimistic UI updates
3. Deferring email sending to background job

Success criteria: Submit button to success message <1s"
```

### Anti-Pattern #7: Not Reviewing AI Code

```
❌ Bad:
AI generates code → immediate git commit → deploy to production

✅ Good:
AI generates code → thorough human review → tests → security scan → 
commit → staging deploy → final verification → production
```

---

## Quick Reference

### Daily Workflow Checklist

**Morning**:
- [ ] `bd ready --limit 5` - Check for ready tasks
- [ ] `bd blocked` - Review blockers
- [ ] Review Basic Memory for recent decisions

**During Work**:
- [ ] Use appropriate tools (Narsil for code, Supabase for DB, etc.)
- [ ] Update Beads status as you progress
- [ ] Document learnings in Basic Memory

**Before Commit**:
- [ ] `swiftscan .` - Security scan
- [ ] Run all tests
- [ ] Review changes (`git diff`)
- [ ] Meaningful commit message

**End of Day**:
- [ ] `bd close <id>` - Complete finished tasks
- [ ] `bd sync` - Sync Beads to git
- [ ] `git push` - Push code changes
- [ ] Update blocked tasks with notes

### Emergency Procedures

**Production Issue**:
```bash
# 1. Create P0 blocker immediately
bd create "PRODUCTION: Auth not working" -p 0 --type bug

# 2. Investigate with tools
# Use Narsil to find auth code
# Check Supabase logs
# Review recent commits

# 3. Apply hotfix
git checkout -b hotfix/auth-fix
# Fix issue
swiftscan .
git commit -m "hotfix: Fix authentication timeout issue"
git push

# 4. Document incident
# Write to Basic Memory under incidents/
# Include: root cause, fix, prevention
```

**Corrupted Beads Database**:
```bash
bd doctor --fix  # Auto-repair common issues

# If that fails:
cd .beads
git restore issues.jsonl  # Restore from git
bd sync  # Rebuild cache from JSONL
```

---

## Related Documentation

- **Architecture**: [[ai-tools/core-documentation/architecture-overview|Architecture Overview]]
- **Tool Selection**: [[ai-tools/core-documentation/decision-matrix|Tool Decision Matrix]]
- **Performance**: [[ai-tools/core-documentation/performance-optimization|Performance & Optimization]]
- **Setup**: [[ai-tools/getting-started/first-time-setup|First-Time Setup]]
- **Troubleshooting**: [[ai-tools/getting-started/troubleshooting|Troubleshooting Guide]]
- **Workflows**: [[ai-tools/integration-patterns/_index|Integration Patterns]]

---

**Last Updated**: 2025-12-30  
**Version**: 1.0  
**Maintainer**: Jessica Clark