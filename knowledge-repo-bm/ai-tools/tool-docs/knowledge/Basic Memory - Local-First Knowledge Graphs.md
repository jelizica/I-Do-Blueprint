---
title: Basic Memory - Local-First Knowledge Graphs
type: note
permalink: ai-tools/knowledge/basic-memory-local-first-knowledge-graphs
tags:
- mcp
- knowledge-management
- local-first
- obsidian
- markdown
- knowledge-graph
- semantic-search
- ai-memory
---

# Basic Memory - Local-First Knowledge Graphs

## Overview

**Category**: Knowledge Management  
**Status**: ✅ Active - Core Knowledge Tool  
**Installation**: `uv tool install basic-memory`  
**MCP Command**: `uvx basic-memory mcp`  
**Repository**: https://github.com/basicmachines-co/basic-memory  
**Documentation**: https://docs.basicmemory.com  
**License**: AGPL v3  
**Agent Attachment**: Qodo Gen (MCP), Claude Code (MCP), Claude Desktop (MCP), CLI (all agents)

---

## What It Does

Basic Memory is a **local-first knowledge management system** that builds persistent semantic graphs from AI conversations. Unlike ephemeral chat histories or complex cloud-based solutions, it stores all knowledge as **standard Markdown files** with **explicit semantic relationships**, enabling both humans and AI to read, write, and navigate a shared knowledge base.

### Core Principles

1. **Local-First Architecture**
   - Complete data ownership - all files on your machine
   - Privacy by design - no cloud dependencies
   - Offline access - fully functional without internet
   - Future-proof - standard Markdown format
   - Version control ready - Git-compatible structure

2. **Human-AI Collaboration**
   - Bidirectional editing (Obsidian + AI)
   - Real-time sync between file changes and database
   - Shared understanding of file structure
   - Tool-agnostic - use any text editor

3. **Semantic Knowledge Graph**
   - Explicit relationships between notes
   - Context-aware AI responses
   - Type-safe relation types
   - Multi-hop concept discovery

---

## Architecture

### File-First Storage

```
~/basic-memory/                    # Default project location
├── entities/                      # Knowledge entities (notes)
│   ├── authentication-system.md
│   ├── database-schema.md
│   └── api-design.md
├── projects/                      # Project-specific knowledge
│   ├── i-do-blueprint/
│   └── work-notes/
└── .basic-memory/                 # System files
    ├── db.sqlite                  # Fast query index (secondary)
    ├── config.json                # Project configuration
    └── basic-memory.log           # Application logs
```

### Core Components

1. **Markdown Files**: Source of truth for all knowledge
2. **SQLite Database**: Fast secondary index for queries
3. **MCP Server**: Bridge between AI and knowledge base
4. **CLI Tools**: User control (sync, projects, telemetry)
5. **Sync Service**: Real-time file system monitoring

### Data Flow

```
User Conversation → LLM (Claude)
                     ↓
              MCP API Call (write_note)
                     ↓
            Markdown File Written
                     ↓
              SQLite Index Updated
                     ↓
         File Available to Human/AI
```

---

## Installation & Configuration

### Installation (via uv)

```bash
# Install Basic Memory
uv tool install basic-memory

# Verify installation
basic-memory --version
```

### Claude Desktop Configuration

Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "basic-memory": {
      "command": "uvx",
      "args": ["basic-memory", "mcp"]
    }
  }
}
```

### Claude Code Configuration

Edit `~/.mcp.json` or project `.mcp.json`:

```json
{
  "mcpServers": {
    "basic-memory": {
      "command": "uvx",
      "args": ["basic-memory", "mcp"]
    }
  }
}
```

### Project-Specific Configuration

Use a specific project instead of default:

```json
{
  "mcpServers": {
    "basic-memory": {
      "command": "uvx",
      "args": ["basic-memory", "mcp", "--project", "i-do-blueprint"]
    }
  }
}
```

---

## Markdown Structure

### Entity Format

```markdown
---
title: Authentication System
permalink: authentication-system
type: note
tags: 
  - security
  - backend
  - oauth
---

# Authentication System

## Observations
- [Implementation] Uses OAuth 2.0 with JWT tokens
- [Security] Implements PKCE flow for mobile clients
- [Performance] Token refresh rate: 15 minutes
- [context:i-do-blueprint] Decision made in sprint planning Q4 2025

## Relations
- implements [[Security Guidelines]]
- requires [[Database Schema]]
- relates_to [[API Design]]
- discovered_from [[Security Audit 2025]]
```

### Relationship Types

| Type | Purpose | Example |
|------|---------|---------|
| `implements` | Realization of concept/spec | [[Security Guidelines]] |
| `requires` | Hard dependency | [[Database Schema]] |
| `relates_to` | Soft association | [[API Design]] |
| `discovered_from` | Origin/source tracking | [[Security Audit 2025]] |
| `blocks` | Prevents progress | [[Bug Fix #123]] |
| `parent-child` | Hierarchical structure | [[Epic Story]] |

---

## MCP Tools Reference

### Core Tools

#### `write_note`
Create or update notes with automatic indexing.

**Parameters**:
- `title`: Note title (string)
- `content`: Markdown content (string)
- `folder`: Directory path (string)
- `note_type`: Default "note" (string)
- `tags`: Optional tags (array)
- `project`: Target project (optional string)

#### `read_note`
Read note by title or permalink.

#### `search_notes`
Full-text and semantic search across knowledge base.

**Search Types**:
- **text**: Full-text search (fastest)
- **semantic**: Embedding-based similarity
- **tag**: Tag-based filtering

#### `build_context`
Construct rich context from memory:// URLs.

**URL Patterns**:
```
memory://title                    # Single note
memory://folder/title             # Specific path
memory://permalink                # By permalink
memory://auth/implements/*        # Follow all "implements" relations
memory://*/Database Schema        # Find all notes relating to target
```

#### `recent_activity`
Track recent changes and activity.

#### `view_note`
View note as formatted artifact for better readability.

#### `edit_note`
Edit existing notes incrementally.

#### `move_note`
Move notes while maintaining database consistency.

#### `delete_note`
Delete notes from knowledge base.

#### `canvas`
Create Obsidian canvas visualizations.

---

## CLI Commands

### Project Management

```bash
# List all projects
basic-memory project list

# Create new project
basic-memory project create my-project ~/path/to/project

# Set default project
basic-memory project default my-project
```

### Sync Operations

```bash
# One-time sync (manual edits → database)
basic-memory sync

# Watch mode (real-time sync)
basic-memory sync --watch

# Sync specific project
basic-memory sync --project i-do-blueprint
```

### MCP Server

```bash
# Start MCP server (usually handled by Claude Desktop/Code)
basic-memory mcp

# Start with specific project
basic-memory mcp --project i-do-blueprint
```

---

## I Do Blueprint Use Cases

### 1. Architecture Decision Recording

Document key architecture decisions with full context and relationships.

### 2. API Design Documentation

Track API endpoints, authentication, validation, and relationships.

### 3. Security Implementation Notes

Document security implementations including Themis encryption, secure storage, and key management.

### 4. Development Workflow Documentation

Track pre-commit hooks, security checks, and automation scripts.

### 5. Testing Strategy

Document testing frameworks, coverage goals, CI/CD integration, and mock data strategies.

---

## Integration with Obsidian

### Obsidian Setup

1. **Install Obsidian**: Download from https://obsidian.md
2. **Open Basic Memory folder**: File → Open vault → Choose `~/basic-memory`
3. **Enable graph view**: View → Graph view

### Bi-Directional Sync

**Editing in Obsidian**:
1. Make changes to any .md file
2. Run `basic-memory sync` or have `sync --watch` running
3. Changes automatically indexed in SQLite
4. AI can access updated content immediately

**AI Creating Notes**:
1. Ask Claude to create a note via `write_note`
2. File appears in Obsidian vault instantly
3. Edit in Obsidian as needed
4. Sync picks up changes

---

## Resources

### Official Links

- **GitHub**: https://github.com/basicmachines-co/basic-memory
- **Documentation**: https://docs.basicmemory.com
- **Website**: https://basicmemory.com
- **Discord**: https://discord.gg/tyvKNccgqN

### Tutorials

- **User Guide**: https://docs.basicmemory.com/user-guide/
- **Integration Guides**: https://docs.basicmemory.com/integrations/
- **API Reference**: https://docs.basicmemory.com/api/

---

## Summary

Basic Memory is the **definitive local-first knowledge management solution** for AI-assisted development. It combines the **simplicity of Markdown** with the **power of semantic graphs**, enabling persistent memory across conversations while maintaining complete data ownership and privacy.

**Key Strengths**:
- 📁 Local Markdown files (human + AI readable)
- 🔗 Semantic relationship graphs
- 🔄 Bi-directional Obsidian sync
- 🔒 Complete privacy and data ownership
- 🚀 Fast SQLite-backed search
- 🛠️ Multiple projects support
- 💻 Works with all MCP-compatible agents

**Perfect for**:
- I Do Blueprint architecture documentation
- API design and decision tracking
- Security implementation notes
- Development workflow documentation
- Testing strategy and patterns

---

**Last Updated**: December 30, 2025  
**Version**: Current (1.0.0+)  
**I Do Blueprint Integration**: Active