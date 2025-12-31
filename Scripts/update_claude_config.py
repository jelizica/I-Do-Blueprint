#!/usr/bin/env python3
"""
Update .claude.json to use environment variables instead of hardcoded API keys.
This script removes sensitive data and replaces it with ${VARIABLE} references.
"""

import json
import sys
from pathlib import Path

def update_claude_config():
    """Update .claude.json to use environment variable references."""
    
    config_path = Path.home() / ".claude.json"
    
    if not config_path.exists():
        print(f"❌ Error: {config_path} not found")
        sys.exit(1)
    
    # Read current config
    with open(config_path, 'r') as f:
        config = json.load(f)
    
    # Track changes
    changes_made = []
    
    # Update global MCP servers
    if "mcpServers" in config:
        # ADR Analysis Server
        if "adr-analysis" in config["mcpServers"]:
            if "env" in config["mcpServers"]["adr-analysis"]:
                if "OPENROUTER_API_KEY" in config["mcpServers"]["adr-analysis"]["env"]:
                    old_value = config["mcpServers"]["adr-analysis"]["env"]["OPENROUTER_API_KEY"]
                    if not old_value.startswith("${"):
                        config["mcpServers"]["adr-analysis"]["env"]["OPENROUTER_API_KEY"] = "${OPENROUTER_API_KEY}"
                        changes_made.append("adr-analysis: OPENROUTER_API_KEY")
        
        # Greb MCP
        if "greb-mcp" in config["mcpServers"]:
            if "env" in config["mcpServers"]["greb-mcp"]:
                if "GREB_API_KEY" in config["mcpServers"]["greb-mcp"]["env"]:
                    old_value = config["mcpServers"]["greb-mcp"]["env"]["GREB_API_KEY"]
                    if not old_value.startswith("${"):
                        config["mcpServers"]["greb-mcp"]["env"]["GREB_API_KEY"] = "${GREB_API_KEY}"
                        changes_made.append("greb-mcp: GREB_API_KEY")
        
        # Swiftzilla - API key is in args, not env
        if "swiftzilla" in config["mcpServers"]:
            if "args" in config["mcpServers"]["swiftzilla"]:
                args = config["mcpServers"]["swiftzilla"]["args"]
                for i, arg in enumerate(args):
                    if arg == "--api-key" and i + 1 < len(args):
                        if not args[i + 1].startswith("${"):
                            args[i + 1] = "${SWIFTZILLA_API_KEY}"
                            changes_made.append("swiftzilla: SWIFTZILLA_API_KEY (in args)")
        
        # Predev
        if "predev" in config["mcpServers"]:
            if "headers" in config["mcpServers"]["predev"]:
                if "Authorization" in config["mcpServers"]["predev"]["headers"]:
                    auth_header = config["mcpServers"]["predev"]["headers"]["Authorization"]
                    if auth_header.startswith("Bearer ") and not "${" in auth_header:
                        config["mcpServers"]["predev"]["headers"]["Authorization"] = "Bearer ${PREDEV_API_KEY}"
                        changes_made.append("predev: PREDEV_API_KEY (in Authorization header)")
    
    # Update project-specific MCP servers
    if "projects" in config:
        for project_path, project_config in config["projects"].items():
            if "mcpServers" in project_config:
                # ADR Analysis in project
                if "adr-analysis" in project_config["mcpServers"]:
                    if "env" in project_config["mcpServers"]["adr-analysis"]:
                        if "OPENROUTER_API_KEY" in project_config["mcpServers"]["adr-analysis"]["env"]:
                            old_value = project_config["mcpServers"]["adr-analysis"]["env"]["OPENROUTER_API_KEY"]
                            if not old_value.startswith("${"):
                                project_config["mcpServers"]["adr-analysis"]["env"]["OPENROUTER_API_KEY"] = "${OPENROUTER_API_KEY}"
                                changes_made.append(f"Project {project_path}: adr-analysis OPENROUTER_API_KEY")
    
    if not changes_made:
        print("✅ No hardcoded API keys found - config already uses environment variables")
        return
    
    # Write updated config
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2)
    
    print("✅ Successfully updated .claude.json")
    print("\n📝 Changes made:")
    for change in changes_made:
        print(f"   • {change}")
    
    print("\n⚠️  IMPORTANT: You must now set these environment variables in ~/.zshrc:")
    print("   export OPENROUTER_API_KEY=\"your-new-key-here\"")
    print("   export GREB_API_KEY=\"your-new-key-here\"")
    print("   export SWIFTZILLA_API_KEY=\"your-new-key-here\"")
    print("   export PREDEV_API_KEY=\"your-new-key-here\"")
    print("\n🔄 Then reload your shell: source ~/.zshrc")

if __name__ == "__main__":
    update_claude_config()
