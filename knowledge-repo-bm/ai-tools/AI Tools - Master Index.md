---
title: AI Tools - Master Index
type: note
permalink: ai-tools/_index
---

# AI Tools - Master Index

This is the central hub for all AI tool documentation in the "I Do Blueprint" project. This guide provides a consolidated overview, categorization, and quick reference for all development tools, ensuring they are easy to find, understand, and use by both human developers and AI agents.

## Table of Contents

1.  [Tool Categories](#tool-categories)
2.  [Tool Matrix](#tool-matrix)
3.  [Integration Patterns](#integration-patterns)
4.  [Quick Start](#quick-start)

---

## Tool Categories

The tools are organized into logical categories based on their primary function.

*   **[Code Intelligence](./code-intelligence/)**: Tools for code analysis, understanding, and navigation.
*   **[Infrastructure](./infrastructure/)**: Tools for managing backend services, databases, and code quality infrastructure.
*   **[Security](./security/)**: Tools for security scanning, vulnerability detection, and cryptography.
*   **[Workflow](./workflow/)**: Tools for task tracking, environment management, and configuration synchronization.
*   **[Knowledge](./knowledge/)**: Tools for knowledge management and persistent memory.
*   **[Orchestration](./orchestration/)**: Tools for coordinating multiple AI agents.
*   **[Visualization](./visualization/)**: Tools for creating architecture diagrams.
*   **[Shell Reference](./shell-reference/)**: Documentation for shell aliases and project scripts.
*   **[Integration Patterns](./integration-patterns/)**: Guides on how tools work together in common workflows.
*   **[Quick Start](./quick-start/)**: Guides for getting started with essential tools.

---

## Tool Matrix

| Tool | Category | Primary Use Case | Agent Attachment |
|---|---|---|---|
| **Narsil MCP** | Code Intelligence | Deep code understanding (76+ tools) | Qodo Gen, Claude Code |
| **ADR Analysis Server** | Code Intelligence | Architectural decisions & deployment validation | Qodo Gen, Claude Code |
| **Code Guardian Studio** | Infrastructure | Code quality, automated fixes, and safety | Qodo Gen, Claude Code |
| **Greb MCP** | Code Intelligence | Semantic code search | Qodo Gen, Claude Code |
| **Swiftzilla** | Code Intelligence | Swift documentation search | Qodo Gen, Claude Code |
| **Supabase** | Infrastructure | Database, Migrations, Edge Functions | Qodo Gen, Claude Code, CLI Aliases |
| **MCP Shield** | Security | MCP server security auditing | Qodo Gen, Claude Code, Shell Functions |
| **Beads (MCP & CLI)** | Workflow | Git-backed task tracking | Qodo Gen (MCP), Claude Code (Plugin), CLI |
| **Owlex** | Orchestration | Multi-agent coordination | Qodo Gen, Claude Code |
| **Basic Memory** | Knowledge | Local-first knowledge graphs | Qodo Gen, Claude Code, Claude Desktop, CLI |
| **Semgrep** | Security | Swift security scanning (SAST/SCA) | CLI/Shell (`swiftscan`) |
| **Beads Viewer** | Workflow | Graph-aware task visualization | CLI (`bv`) |
| **Sync MCP Config** | Workflow | MCP config synchronization | CLI |
| **Direnv** | Workflow | Environment variable management | Shell Hook |
| **Agent Deck** | Orchestration | Agent session management | CLI/Shell |
| **Mermaid & Structurizr** | Visualization | Architecture diagrams | CLI/Shell (scripts) |
| **Themis** | Security | Cross-platform cryptography | Xcode (SPM) |

---
## Integration Patterns

*   **[Daily Workflow](./integration-patterns/daily-workflow.md)**: Proven daily patterns for using these tools effectively.
*   **[Session Protocol](./integration-patterns/session-protocol.md)**: How to start and end work sessions, ensuring context is maintained.
*   **[Security Workflow](./integration-patterns/security-workflow.md)**: Combining security tools for a robust scanning process.

---

## Quick Start

*   **[Essential Setup](./quick-start/essential-setup.md)**: First-time installation and configuration for core tools.
*   **[Configuration Examples](./quick-start/configuration-examples.md)**: Complete configuration examples for various clients and projects.