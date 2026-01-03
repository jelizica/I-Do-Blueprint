---
title: Shell Aliases and Functions Reference
type: note
permalink: ai-tools/shell-reference/aliases-and-functions
---

# Shell Aliases and Functions Reference

This document provides a reference for the shell aliases and functions used in the "I Do Blueprint" project.

## Supabase Aliases

```bash
alias sb='npx supabase'
alias sb-start='npx supabase start'
alias sb-stop='npx supabase stop'
alias sb-status='npx supabase status'
alias sb-reset='npx supabase db reset'
alias sb-push='npx supabase db push'
alias sb-pull='npx supabase db pull'
alias sb-gen-types='npx supabase gen types typescript --local > src/types/supabase.ts'
```

## Semgrep Custom Function

```bash
swiftscan() {
    semgrep --config ~/akabe1-semgrep-rules/ios/swift/ --config p/swift --config p/secrets "$@"
}
```

*   **Purpose**: Swift security scanning with custom rules + official rulesets
*   **Usage**: `swiftscan .` (scans current directory)

## MCP Shield Functions

```bash
mcpscan() {
    npx mcp-shield --claude-api-key "$ANTHROPIC_API_KEY" "$@"
}

mcpscan-all() {
    echo "=== Scanning Claude Desktop config ==="
    mcpscan --path "/Users/jessicaclark/Library/Application Support/Claude/claude_desktop_config.json"

    echo ""
    echo "=== Scanning Claude Code config ==="
    mcpscan --path "/Users/jessicaclark/.mcp.json"

    echo ""
    echo "=== Scanning I Do Blueprint config ==="
    mcpscan --path "/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint/.mcp.json"
}
```

*   **mcpscan**: Single MCP config scan with API key
*   **mcpscan-all**: Scans all three MCP configurations (Claude Desktop, Claude Code, Project-specific)

## Direnv Hook

```bash
eval "$(direnv hook zsh)"
```

*   **Purpose**: Auto-loads .envrc files when entering directories