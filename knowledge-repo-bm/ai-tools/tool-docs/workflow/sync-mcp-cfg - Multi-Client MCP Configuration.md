---
title: sync-mcp-cfg - Multi-Client MCP Configuration
type: note
permalink: ai-tools/workflow/sync-mcp-cfg-multi-client-mcp-configuration
tags:
- sync-mcp-cfg
- mcp
- configuration
- multi-client
- claude
- cursor
- vscode
- gemini
- opencode
---

# sync-mcp-cfg - Multi-Client MCP Configuration

**Repository**: https://github.com/jgrichardson/sync-mcp-cfg  
**Type**: Python CLI Tool  
**Purpose**: Manage and synchronize Model Context Protocol (MCP) server configurations across multiple AI clients  
**Command**: `sync-mcp-cfg`  
**License**: MIT

---

## Overview

sync-mcp-cfg is a powerful tool to **manage and synchronize MCP server configurations** across different AI coding tools. Instead of manually copying server configurations between Claude Desktop, Claude Code, Cursor, VS Code, Gemini CLI, and OpenCode, sync-mcp-cfg provides a unified interface to add, remove, and sync servers across all your tools.

### Core Philosophy

> "One configuration, many clients"

sync-mcp-cfg solves the problem of:
- **Configuration drift** - Keeping servers in sync across multiple tools
- **Manual duplication** - Copy-pasting server configs between JSON files
- **Error-prone updates** - Forgetting to update a client when adding a server
- **Backup management** - Automatic backups before any changes

---

## Supported Clients

| Client | Status | Configuration Location |
|--------|--------|------------------------|
| **Claude Code CLI** | ✅ | `~/.claude.json` |
| **Claude Desktop** | ✅ | `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS)<br>`%APPDATA%/Claude/claude_desktop_config.json` (Windows)<br>`~/.config/Claude/claude_desktop_config.json` (Linux) |
| **Cursor** | ✅ | `~/.cursor/mcp.json` |
| **VS Code Copilot** | ✅ | `~/Library/Application Support/Code/User/settings.json` (macOS)<br>`%APPDATA%/Code/User/settings.json` (Windows)<br>`~/.config/Code/User/settings.json` (Linux) |
| **Gemini CLI** | ✅ | `~/.gemini/settings.json` (global)<br>`.gemini/settings.json` (local) |
| **OpenCode** | ✅ | `~/.config/opencode/config.json` (global)<br>`./opencode.json` (project) |

---

## Installation

### From Source (Current Method)

```bash
git clone https://github.com/jgrichardson/sync-mcp-cfg.git
cd sync-mcp-cfg
pip install -e .
```

### Development Installation

```bash
git clone https://github.com/jgrichardson/sync-mcp-cfg.git
cd sync-mcp-cfg
pip install -e ".[dev]"
```

### Requirements

- Python 3.9 or higher
- One or more supported MCP clients installed

---

## Quick Start

### 1. Initialize Configuration

```bash
sync-mcp-cfg init
```

Creates `~/.config/sync-mcp-cfg/config.json` with default settings.

### 2. Check Client Status

```bash
sync-mcp-cfg status
```

Shows which clients are detected and their configuration paths.

### 3. Add an MCP Server

```bash
# Add filesystem server
sync-mcp-cfg add filesystem npx \
  --args "-y" \
  --args "@modelcontextprotocol/server-filesystem" \
  --args "/path/to/directory" \
  --clients claude-code --clients cursor

# Add with environment variables
sync-mcp-cfg add weather-api node \
  --args "/path/to/weather-server.js" \
  --env "API_KEY=your-key-here" \
  --description "Weather information server"
```

### 4. List Configured Servers

```bash
# List all servers
sync-mcp-cfg list

# List servers for specific client
sync-mcp-cfg list --client claude-code

# Detailed view
sync-mcp-cfg list --detailed
```

### 5. Sync Between Clients

```bash
# Sync all servers from Claude Code to Cursor
sync-mcp-cfg sync --from claude-code --to cursor

# Sync to multiple clients
sync-mcp-cfg sync --from claude-desktop --to claude-code --to cursor --to vscode

# Sync specific servers
sync-mcp-cfg sync --from claude-desktop --to claude-code \
  --servers filesystem --servers weather-api

# Dry run to see what would be synced
sync-mcp-cfg sync --from cursor --to opencode --dry-run
```

### 6. Remove Servers

```bash
# Remove from specific clients
sync-mcp-cfg remove filesystem --clients claude-code

# Remove from all clients
sync-mcp-cfg remove weather-api --force
```

---

## Core Concepts

### 1. Global vs Project Configuration

sync-mcp-cfg supports two configuration levels:

**Global Configuration** (`~/.config/sync-mcp-cfg/config.json`):
- Personal development servers
- Synced across all tools
- User-wide settings

**Project Configuration** (`.mcp.json` in project root):
- Project-specific servers
- Version controlled with your project
- Takes priority over global config

### 2. Configuration Hierarchy

```
Tool Configs (Auto-discovered)
    ↑
Project Config (.mcp.json)
    ↑
Global Config (~/.config/sync-mcp-cfg/config.json)
```

### 3. Backup & Restore

Automatic backups are created before any destructive operation:

**Backup Locations**:
- Claude Code: `~/.claude/backups/`
- Claude Desktop: `~/Library/Application Support/Claude/backups/` (macOS)
- Cursor: `~/.cursor/backups/`
- VS Code: Global settings backup
- Gemini CLI: `~/.gemini/backups/` (global) or `.gemini/backups/` (local)
- OpenCode: `~/.config/opencode/backups/` (global) or `./backups/` (project)

---

## Client-Specific Features

### Gemini CLI Support

Gemini CLI has unique configuration requirements:

```bash
# Add server with Gemini-specific features
sync-mcp-cfg add gemini-fs npx \
  -a "-y" -a "@modelcontextprotocol/server-filesystem" -a "/tmp" \
  --clients gemini-cli \
  --description "Filesystem server for Gemini CLI"
```

**Key Features**:
- **Trust control**: `trust` field for automatic tool execution approval
- **Working directory**: `cwd` field for stdio servers
- **Timeout configuration**: Configurable timeout values (default: 600,000ms)
- **HTTP URLs**: Special support for `httpUrl` field for HTTP servers

**Example Gemini CLI Configuration**:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"],
      "trust": true,
      "timeout": 600000,
      "cwd": "/workspace"
    }
  }
}
```

### OpenCode Support

OpenCode uses a unique configuration format:

```bash
# Add local server for OpenCode
sync-mcp-cfg add opencode-fs npx \
  -a "-y" -a "@modelcontextprotocol/server-filesystem" -a "/tmp" \
  --clients opencode \
  --description "Filesystem server for OpenCode"

# Add remote SSE server
sync-mcp-cfg add context7 "" \
  --type sse --url "https://mcp.context7.ai/v1" \
  --clients opencode \
  --description "Context7 remote MCP server"
```

**OpenCode Configuration Format**:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "filesystem": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-filesystem", "/path"],
      "environment": { "PATH_ROOT": "/workspace" },
      "enabled": true
    },
    "context7": {
      "type": "remote",
      "url": "https://mcp.context7.ai/v1",
      "enabled": true
    }
  }
}
```

**Server Types**:
- `stdio` → OpenCode `{"type": "local", "command": [...]}`
- `sse` → OpenCode `{"type": "remote", "url": "..."}`
- `http` → OpenCode `{"type": "remote", "url": "..."}`

---

## Common Use Cases

### Adding Popular MCP Servers

```bash
# Filesystem server
sync-mcp-cfg add filesystem npx \
  -a "-y" -a "@modelcontextprotocol/server-filesystem" -a "/Users/username/Documents"

# Sequential thinking server
sync-mcp-cfg add sequential-thinking npx \
  -a "-y" -a "@modelcontextprotocol/server-sequential-thinking"

# GitHub server
sync-mcp-cfg add github npx \
  -a "-y" -a "@modelcontextprotocol/server-github" \
  -e "GITHUB_PERSONAL_ACCESS_TOKEN=your-token"

# Brave search server
sync-mcp-cfg add brave-search npx \
  -a "-y" -a "@modelcontextprotocol/server-brave-search" \
  -e "BRAVE_API_KEY=your-key"

# Supabase MCP server
sync-mcp-cfg add supabase npx \
  -a "-y" -a "@modelcontextprotocol/server-supabase" \
  -e "SUPABASE_URL=your-url" \
  -e "SUPABASE_ANON_KEY=your-key"
```

### Batch Operations

```bash
# Sync all servers to all clients
sync-mcp-cfg sync --from claude-desktop \
  --to claude-code --to cursor --to vscode --to gemini-cli --to opencode

# List servers in JSON format for scripting
sync-mcp-cfg list --format json > mcp-servers.json

# Add server to all available clients
sync-mcp-cfg add universal-server npx -a "-y" -a "some-mcp-server"

# Sync with backup and overwrite protection
sync-mcp-cfg sync --from vscode --to opencode --backup --overwrite
```

### Project-Specific Configuration

```bash
# Initialize project config
sync-mcp-cfg init

# Add project-specific server
sync-mcp-cfg add database npx \
  -a "-y" -a "@modelcontextprotocol/server-postgres" \
  -e "DATABASE_URL=postgresql://localhost/myapp"

# Sync to all tools
sync-mcp-cfg sync --from claude-desktop --to claude-code --to cursor
```

---

## Commands Reference

### Global Options

```bash
--verbose, -v      # Enable verbose output
--no-color         # Disable colored output
--help             # Show help message
```

### Core Commands

#### `init`

Initialize configuration:

```bash
sync-mcp-cfg init
```

#### `status`

Show client status:

```bash
sync-mcp-cfg status
sync-mcp-cfg status --verbose
```

#### `add`

Add MCP server:

```bash
sync-mcp-cfg add <name> <command> \
  --args <arg> \
  --env <key=value> \
  --clients <client> \
  --description <text>
```

**Parameters**:
- `name`: Server name (required)
- `command`: Executable command (required)
- `--args, -a`: Command arguments (repeatable)
- `--env, -e`: Environment variables as `KEY=value` (repeatable)
- `--clients`: Target clients (repeatable, default: all)
- `--description`: Server description (optional)

#### `remove`

Remove MCP server:

```bash
sync-mcp-cfg remove <name> \
  --clients <client> \
  --force
```

**Parameters**:
- `name`: Server name (required)
- `--clients`: Target clients (optional, default: all)
- `--force`: Skip confirmation (optional)

#### `list`

List MCP servers:

```bash
sync-mcp-cfg list \
  --client <client> \
  --detailed \
  --format <json|yaml|table>
```

**Parameters**:
- `--client`: Filter by client (optional)
- `--detailed`: Show full details (optional)
- `--format`: Output format (optional, default: table)

#### `sync`

Sync servers between clients:

```bash
sync-mcp-cfg sync \
  --from <client> \
  --to <client> \
  --servers <name> \
  --backup \
  --overwrite \
  --dry-run
```

**Parameters**:
- `--from`: Source client (required)
- `--to`: Target client(s) (repeatable, required)
- `--servers`: Specific servers to sync (repeatable, optional)
- `--backup`: Create backup before sync (optional)
- `--overwrite`: Overwrite existing servers (optional)
- `--dry-run`: Preview changes without applying (optional)

#### `backup`

Manual backup:

```bash
sync-mcp-cfg backup --client <client>
```

#### `restore`

Restore from backup:

```bash
sync-mcp-cfg restore --client <client> --backup <path>
```

---

## Configuration

### Global Configuration

`~/.config/sync-mcp-cfg/config.json`:

```json
{
  "auto_backup": true,
  "backup_retention_days": 30,
  "validate_servers": true,
  "default_sync_target": ["claude-code", "cursor"]
}
```

### Project Configuration

`.mcp.json` in project root:

```json
{
  "mcpServers": {
    "project-db": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "postgresql://localhost/myapp"
      }
    }
  }
}
```

---

## Best Practices

### 1. Use Global Config for Personal Servers

```bash
# Personal development tools
sync-mcp-cfg add filesystem npx \
  -a "-y" -a "@modelcontextprotocol/server-filesystem" -a "$HOME/Documents"
```

### 2. Use Project Config for Team Servers

```bash
# Project-specific database server
sync-mcp-cfg add project-db npx \
  -a "-y" -a "@modelcontextprotocol/server-postgres"

# Commit .mcp.json to version control
git add .mcp.json
git commit -m "Add MCP server configuration"
```

### 3. Always Backup Before Major Changes

```bash
# Manual backup
sync-mcp-cfg backup --client claude-desktop

# Or use --backup flag
sync-mcp-cfg sync --from claude-desktop --to cursor --backup
```

### 4. Use Dry Run for Safety

```bash
# Preview changes
sync-mcp-cfg sync --from claude-desktop --to cursor --dry-run

# Review output, then apply
sync-mcp-cfg sync --from claude-desktop --to cursor
```

### 5. Keep Secrets Out of Version Control

```bash
# .gitignore
.mcp.json
.env
.env.local

# Use template instead
.mcp.json.template
```

---

## Troubleshooting

### Issue: Client not detected

```bash
# Check if client is installed
sync-mcp-cfg status

# Verify configuration path exists
ls ~/.claude.json  # Claude Code
ls ~/.cursor/mcp.json  # Cursor
```

### Issue: Permission errors

```bash
# Check file permissions
ls -la ~/.config/sync-mcp-cfg/

# Fix permissions
chmod 755 ~/.config/sync-mcp-cfg/
chmod 644 ~/.config/sync-mcp-cfg/config.json
```

### Issue: Sync conflicts

```bash
# Use --overwrite flag
sync-mcp-cfg sync --from claude-desktop --to cursor --overwrite

# Or resolve manually
sync-mcp-cfg list --client claude-desktop
sync-mcp-cfg list --client cursor
```

### Issue: Backup failures

```bash
# Check disk space
df -h

# Check backup directory permissions
ls -la ~/.claude/backups/

# Manual backup
sync-mcp-cfg backup --client claude-code
```

---

## Debug Mode

```bash
# Enable verbose output
sync-mcp-cfg --verbose status

# Check log files
tail -f ~/.local/share/sync-mcp-cfg/logs/sync-mcp-cfg.log
```

**Log Locations**:
- Linux/macOS: `~/.local/share/sync-mcp-cfg/logs/`
- Windows: `%LOCALAPPDATA%/sync-mcp-cfg/logs/`

---

## Extending Support

### Adding New Clients

The tool uses a plugin-based architecture. To add support for a new MCP client:

1. Create handler in `src/sync_mcp_cfg/clients/`
2. Extend `BaseClientHandler` class
3. Implement required methods
4. Register handler in `__init__.py`

**Example**:

```python
from .base import BaseClientHandler
from ..core.models import MCPServer

class NewClientHandler(BaseClientHandler):
    def load_servers(self) -> List[MCPServer]:
        # Implementation for loading servers
        pass

    def save_servers(self, servers: List[MCPServer]) -> None:
        # Implementation for saving servers
        pass
```

---

## Comparison with Alternatives

| Feature | sync-mcp-cfg | Manual Config | mcp-sync (ztripez) | sync-mcp (william-garden) |
|---------|--------------|---------------|-------------------|---------------------------|
| **Multi-Client** | ✅ 6 clients | ❌ Manual | ✅ Multiple | ✅ Multiple |
| **Backup** | ✅ Automatic | ❌ Manual | ⚠️ Limited | ⚠️ Limited |
| **Project Config** | ✅ Yes | ❌ No | ⚠️ Limited | ❌ No |
| **Gemini CLI** | ✅ Full support | ❌ Manual | ❌ No | ❌ No |
| **OpenCode** | ✅ Full support | ❌ Manual | ❌ No | ❌ No |
| **Validation** | ✅ Built-in | ❌ No | ⚠️ Basic | ⚠️ Basic |
| **Python** | ✅ Yes | N/A | ✅ Yes | ❌ Node.js |

---

## Related Tools

- **[Beads](./beads-git-backed-task-tracking.md)** - Git-backed task tracking
- **[Beads Viewer](./beads-viewer-graph-aware-task-visualization.md)** - Task visualization
- **[direnv](./direnv-per-directory-environment-management.md)** - Per-directory environment management

---

## Resources

- **Repository**: https://github.com/jgrichardson/sync-mcp-cfg
- **Issue Tracker**: https://github.com/jgrichardson/sync-mcp-cfg/issues
- **Contributing Guide**: https://github.com/jgrichardson/sync-mcp-cfg/blob/main/CONTRIBUTING.md
- **Security Policy**: https://github.com/jgrichardson/sync-mcp-cfg/blob/main/SECURITY.md
- **Gemini CLI Docs**: https://github.com/jgrichardson/sync-mcp-cfg/blob/main/docs/gemini-cli-example.md

---

## Quick Reference Card

```bash
# Installation
pip install -e .

# Setup
sync-mcp-cfg init                      # Initialize config
sync-mcp-cfg status                    # Check clients

# Add Servers
sync-mcp-cfg add <name> <cmd> -a <arg> -e <env>
sync-mcp-cfg add filesystem npx -a "-y" -a "@modelcontextprotocol/server-filesystem"

# List Servers
sync-mcp-cfg list                      # All servers
sync-mcp-cfg list --client claude-code # Specific client
sync-mcp-cfg list --detailed           # Full details

# Sync Servers
sync-mcp-cfg sync --from <src> --to <dst>
sync-mcp-cfg sync --from claude-desktop --to cursor --backup

# Remove Servers
sync-mcp-cfg remove <name> --clients <client>
sync-mcp-cfg remove <name> --force     # All clients

# Backup & Restore
sync-mcp-cfg backup --client <client>
sync-mcp-cfg restore --client <client> --backup <path>

# Supported Clients
claude-code, claude-desktop, cursor, vscode, gemini-cli, opencode
```

---

**Last Updated**: 2025-01-15  
**Version**: Based on jgrichardson/sync-mcp-cfg main branch  
**Status**: Production-ready, actively maintained  
**License**: MIT