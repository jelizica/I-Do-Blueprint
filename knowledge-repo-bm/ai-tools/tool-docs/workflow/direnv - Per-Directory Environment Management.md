---
title: direnv - Per-Directory Environment Management
type: note
permalink: ai-tools/workflow/direnv-per-directory-environment-management
tags:
- direnv
- environment-variables
- shell
- automation
- per-project-config
- 12factor
---

# direnv - Per-Directory Environment Management

**Website**: https://direnv.net/  
**Type**: Shell Extension  
**Purpose**: Automatic per-directory environment variable management  
**Command**: `direnv`  
**License**: MIT

---

## Overview

direnv is a **shell extension** that automatically loads and unloads environment variables based on your current directory. It augments existing shells (bash, zsh, fish, tcsh, elvish, PowerShell, murex, nushell) with the ability to manage project-specific environment variables without cluttering your global `~/.profile` or `~/.bashrc`.

### Core Philosophy

> "Unclutter your .profile"

direnv solves the problem of:
- **Global environment pollution** - No more permanent exports in shell configs
- **Project-specific configuration** - Each project gets its own environment
- **Automatic context switching** - Variables load/unload as you `cd` between projects
- **12-factor app compliance** - Perfect for managing secrets and configuration

---

## How It Works

### Execution Flow

```
1. You cd into a directory
2. direnv checks for .envrc file
3. If found and allowed, loads it into bash sub-shell
4. Captures all exported variables
5. Makes them available to your current shell
6. When you cd out, automatically unloads them
```

### Key Features

1. **Before each prompt** - direnv runs before every shell prompt
2. **Bash sub-shell** - Executes `.envrc` in isolated bash environment
3. **Diff capture** - Only exports variables that changed
4. **Fast execution** - Compiled to single static binary, unnoticeable latency
5. **Security model** - Requires explicit `direnv allow` before loading new files

---

## Installation

### macOS

```bash
# Homebrew
brew install direnv

# MacPorts
port install direnv
```

### Linux

```bash
# Ubuntu/Debian
apt install direnv

# Fedora
dnf install direnv

# Arch
pacman -S direnv

# From source
curl -sfL https://direnv.net/install.sh | bash
```

### Windows

```powershell
# Scoop
scoop install direnv

# Chocolatey
choco install direnv
```

---

## Shell Integration

### Bash

Add to `~/.bashrc`:

```bash
eval "$(direnv hook bash)"
```

**Important**: Place this **after** rvm, git-prompt, and other shell extensions that manipulate the prompt.

### Zsh

Add to `~/.zshrc`:

```bash
eval "$(direnv hook zsh)"
```

### Fish

Add to `$XDG_CONFIG_HOME/fish/config.fish`:

```fish
direnv hook fish | source
```

Fish supports 3 modes via `direnv_fish_mode`:

```fish
# Trigger on every arrow-based directory change (default)
set -g direnv_fish_mode eval_on_arrow

# Trigger only after arrow changes, before command execution
set -g direnv_fish_mode eval_after_arrow

# Trigger only at prompt (original behavior)
set -g direnv_fish_mode disable_arrow
```

### PowerShell

Add to your `$PROFILE`:

```powershell
Invoke-Expression "$(direnv hook pwsh)"
```

### Tcsh

Add to `~/.cshrc`:

```tcsh
eval `direnv hook tcsh`
```

### Elvish

```bash
# Setup
mkdir -p ~/.config/elvish/lib
direnv hook elvish > ~/.config/elvish/lib/direnv.elv
```

Add to `~/.config/elvish/rc.elv`:

```elvish
use direnv
```

### Murex

Add to `~/.murex_profile`:

```murex
direnv hook murex -> source
```

---

## Quick Start

### 1. Create Project with Environment Variables

```bash
# Create project directory
mkdir ~/my-project
cd ~/my-project

# Check that FOO is not set
echo ${FOO-nope}
# Output: nope

# Create .envrc file
echo 'export FOO=foo' > .envrc
# Output: .envrc is not allowed
```

### 2. Allow the .envrc File

```bash
# Security mechanism requires explicit permission
direnv allow .

# Output:
# direnv: reloading
# direnv: loading .envrc
# direnv export: +FOO
```

### 3. Verify Environment Variable

```bash
# FOO is now loaded
echo ${FOO-nope}
# Output: foo

# Exit the project
cd ..
# Output: direnv: unloading

# FOO is automatically unset
echo ${FOO-nope}
# Output: nope
```

---

## The Standard Library (stdlib)

direnv provides a **standard library** of utility functions available in `.envrc` files.

### Common Functions

#### `PATH_add <path>`

Prepend a path to `$PATH`:

```bash
# Instead of: export PATH=$PWD/bin:$PATH
PATH_add bin

# Expands to absolute path and prepends
```

#### `path_add <varname> <path>`

Add to any PATH-like variable:

```bash
path_add PYTHONPATH lib/python
path_add LD_LIBRARY_PATH lib
```

#### `load_prefix <prefix_path>`

Load environment from a prefix (like `/usr/local`):

```bash
load_prefix /opt/myapp
# Adds /opt/myapp/bin to PATH
# Adds /opt/myapp/lib to LD_LIBRARY_PATH
# Adds /opt/myapp/include to CPATH
# Adds /opt/myapp/lib/pkgconfig to PKG_CONFIG_PATH
```

#### `layout <type>`

Set up language-specific environments:

```bash
# Python virtualenv
layout python

# Python with specific version
layout python python3.11

# Ruby
layout ruby

# Node.js
layout node

# Go
layout go
```

#### `use <program> [version]`

Use version managers:

```bash
# Use specific Node version (via nvm/nodenv)
use node 18.0.0

# Use specific Ruby version (via rvm/rbenv)
use ruby 3.2.0

# Use specific Python version (via pyenv)
use python 3.11.0
```

#### `dotenv [<dotenv_path>]`

Load `.env` file:

```bash
# Load .env from current directory
dotenv

# Load from specific path
dotenv config/.env.production
```

#### `source_env <path>`

Source another `.envrc`:

```bash
# Load shared configuration
source_env ../shared/.envrc

# Load environment-specific config
source_env .envrc.local
```

#### `watch_file <path>`

Reload when file changes:

```bash
# Reload when package.json changes
watch_file package.json

# Reload when any config file changes
watch_file config/*.yml
```

#### `source_up [<path>]`

Load `.envrc` from parent directory:

```bash
# Load parent .envrc
source_up

# Useful for monorepos with shared config
```

---

## Common Use Cases

### 1. Project-Specific API Keys

```bash
# .envrc
export AWS_ACCESS_KEY_ID=AKIA...
export AWS_SECRET_ACCESS_KEY=secret...
export DATABASE_URL=postgresql://localhost/mydb
```

### 2. Development vs Production

```bash
# .envrc
if [ "$USER" = "production" ]; then
  export ENV=production
  export DEBUG=false
else
  export ENV=development
  export DEBUG=true
fi
```

### 3. Python Virtual Environment

```bash
# .envrc
layout python python3.11
export PYTHONPATH=$PWD/src
```

### 4. Node.js Project

```bash
# .envrc
use node 18.0.0
PATH_add node_modules/.bin
export NODE_ENV=development
```

### 5. Go Project

```bash
# .envrc
layout go
export GOPATH=$PWD/.go
PATH_add bin
```

### 6. Docker Compose

```bash
# .envrc
export COMPOSE_PROJECT_NAME=myapp
export COMPOSE_FILE=docker-compose.yml:docker-compose.dev.yml
```

### 7. Multiple Environments

```bash
# .envrc
case "$ENVIRONMENT" in
  staging)
    export API_URL=https://staging.api.example.com
    ;;
  production)
    export API_URL=https://api.example.com
    ;;
  *)
    export API_URL=http://localhost:3000
    ;;
esac
```

---

## Advanced Features

### Custom Extensions

Create `~/.config/direnv/direnvrc` or `~/.config/direnv/lib/*.sh`:

```bash
# ~/.config/direnv/direnvrc

# Custom function to load secrets from 1Password
use_1password() {
  local item=$1
  export $(op item get "$item" --fields label=password --format=json | jq -r '.value')
}

# Custom function for Kubernetes context
use_kube_context() {
  local context=$1
  export KUBECONFIG=$HOME/.kube/config
  kubectl config use-context "$context"
}
```

Use in `.envrc`:

```bash
use_1password "my-api-keys"
use_kube_context "production"
```

### Combining with .env Files

```bash
# .envrc
# Load stdlib functions
dotenv

# Then add custom exports
export CUSTOM_VAR=value
```

### Conditional Loading

```bash
# .envrc
# Only load in development
if [ "$USER" != "production" ]; then
  export DEBUG=true
  export LOG_LEVEL=debug
fi

# Load secrets only if file exists
if [ -f .env.local ]; then
  dotenv .env.local
fi
```

### Integration with Version Managers

```bash
# .envrc
# Use asdf for version management
use asdf

# Or specific versions
use asdf nodejs 18.0.0
use asdf ruby 3.2.0
use asdf python 3.11.0
```

---

## Security Best Practices

### 1. Never Commit .envrc with Secrets

```bash
# .gitignore
.envrc
.env
.env.local
```

### 2. Use Template Files

```bash
# Commit .envrc.template
# .envrc.template
export API_KEY=your-key-here
export DATABASE_URL=postgresql://localhost/mydb

# Users copy and fill in real values
cp .envrc.template .envrc
direnv allow
```

### 3. Use Secret Management Tools

```bash
# .envrc
# Load from 1Password
export API_KEY=$(op item get "my-api" --fields label=password)

# Load from AWS Secrets Manager
export DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id prod/db --query SecretString --output text)

# Load from HashiCorp Vault
export TOKEN=$(vault kv get -field=token secret/myapp)
```

### 4. Audit .envrc Files

```bash
# Review before allowing
cat .envrc

# Allow only if safe
direnv allow
```

---

## Commands Reference

### Core Commands

```bash
# Allow .envrc to execute
direnv allow [PATH_TO_RC]

# Revoke permission
direnv deny [PATH_TO_RC]

# Edit .envrc and auto-allow on save
direnv edit [PATH_TO_RC]

# Execute command with .envrc loaded
direnv exec DIR COMMAND [...ARGS]

# Show diff of environment changes
direnv export SHELL

# Trigger manual reload
direnv reload

# Show debug status
direnv status

# Display available stdlib functions
direnv stdlib

# Show version
direnv version

# Remove old allowed files
direnv prune

# Show help
direnv help
```

---

## Configuration

### `~/.config/direnv/direnv.toml`

```toml
[global]
# Disable hints
disable_stdin = false

# Warn on .envrc changes
warn_timeout = "5s"

# Custom stdlib location
load_dotenv = true

[whitelist]
# Auto-allow specific directories
prefix = [
  "/home/user/projects",
  "/opt/work"
]

# Auto-allow exact paths
exact = [
  "/home/user/trusted-project"
]
```

---

## Environment Variables

### `XDG_CONFIG_HOME`

Default: `$HOME/.config`

Location for direnv configuration files.

### `XDG_DATA_HOME`

Default: `$HOME/.local/share`

Location for direnv data files (allowed list).

---

## Files

### `$XDG_CONFIG_HOME/direnv/direnv.toml`

Main configuration file.

### `$XDG_CONFIG_HOME/direnv/direnvrc`

Custom bash code loaded before every `.envrc`.

### `$XDG_CONFIG_HOME/direnv/lib/*.sh`

Third-party extensions loaded before every `.envrc`.

### `$XDG_DATA_HOME/direnv/allow`

Records which `.envrc` files have been allowed.

---

## Integration with Other Tools

### Docker

```bash
# .envrc
export DOCKER_HOST=unix:///var/run/docker.sock
export COMPOSE_PROJECT_NAME=${PWD##*/}
```

### Kubernetes

```bash
# .envrc
export KUBECONFIG=$PWD/.kube/config
export KUBE_NAMESPACE=development
```

### Terraform

```bash
# .envrc
export TF_VAR_environment=development
export TF_VAR_region=us-west-2
```

### AWS

```bash
# .envrc
export AWS_PROFILE=development
export AWS_REGION=us-west-2
export AWS_DEFAULT_REGION=us-west-2
```

### Google Cloud

```bash
# .envrc
export GOOGLE_APPLICATION_CREDENTIALS=$PWD/service-account.json
export GOOGLE_CLOUD_PROJECT=my-project
```

---

## Troubleshooting

### Issue: direnv not loading

```bash
# Check if hook is installed
echo $PROMPT_COMMAND  # bash
echo $precmd_functions  # zsh

# Reinstall hook
eval "$(direnv hook bash)"  # or zsh, fish, etc.
```

### Issue: .envrc not allowed

```bash
# Allow the file
direnv allow

# Or edit and auto-allow
direnv edit
```

### Issue: Changes not detected

```bash
# Force reload
direnv reload

# Check status
direnv status
```

### Issue: Slow shell startup

```bash
# direnv is fast, but .envrc might be slow
# Profile your .envrc
time bash .envrc

# Optimize expensive operations
# Cache results, avoid network calls
```

---

## Best Practices

### 1. Keep .envrc Simple

```bash
# ✅ Good: Simple, fast
export API_KEY=abc123
PATH_add bin

# ❌ Bad: Complex, slow
export API_KEY=$(curl -s https://api.example.com/key)
```

### 2. Use stdlib Functions

```bash
# ✅ Good: Use PATH_add
PATH_add bin

# ❌ Bad: Manual PATH manipulation
export PATH=$PWD/bin:$PATH
```

### 3. Document Your .envrc

```bash
# .envrc
# Development environment for MyApp
# Requires: Node.js 18+, PostgreSQL 14+

use node 18.0.0
export DATABASE_URL=postgresql://localhost/myapp_dev
export API_KEY=dev-key-123
```

### 4. Use .env for Secrets

```bash
# .envrc (committed)
dotenv .env.local

# .env.local (gitignored)
API_KEY=real-secret-key
DATABASE_PASSWORD=real-password
```

### 5. Test Before Committing

```bash
# Test .envrc in clean shell
bash -c 'source .envrc && env'

# Verify no errors
direnv allow
direnv reload
```

---

## Comparison with Alternatives

| Feature | direnv | dotenv | autoenv | asdf |
|---------|--------|--------|---------|------|
| **Auto-load** | ✅ Yes | ❌ No | ✅ Yes | ⚠️ Versions only |
| **Auto-unload** | ✅ Yes | ❌ No | ⚠️ Limited | N/A |
| **Security** | ✅ Explicit allow | ❌ No | ⚠️ Limited | N/A |
| **Speed** | ✅ Fast (compiled) | ✅ Fast | ⚠️ Slow (bash) | ✅ Fast |
| **Stdlib** | ✅ Rich | ❌ No | ❌ No | ⚠️ Limited |
| **Shell Support** | ✅ 8+ shells | ⚠️ Limited | ⚠️ Limited | ✅ Good |
| **Version Management** | ⚠️ Via stdlib | ❌ No | ❌ No | ✅ Core feature |

---

## Related Tools

- **[Beads](./beads-git-backed-task-tracking.md)** - Git-backed task tracking
- **[Beads Viewer](./beads-viewer-graph-aware-task-visualization.md)** - Task visualization
- **[sync-mcp-cfg](./sync-mcp-cfg-multi-client-mcp-configuration.md)** - MCP configuration sync

---

## Resources

- **Website**: https://direnv.net/
- **Documentation**: https://direnv.net/man/direnv.1.html
- **stdlib Reference**: https://direnv.net/man/direnv-stdlib.1.html
- **GitHub**: https://github.com/direnv/direnv
- **Wiki**: https://github.com/direnv/direnv/wiki

---

## Quick Reference Card

```bash
# Setup (one-time)
brew install direnv                    # Install
eval "$(direnv hook bash)"             # Add to ~/.bashrc

# Daily Usage
cd my-project                          # Auto-loads .envrc
direnv allow                           # Allow new/changed .envrc
direnv edit                            # Edit and auto-allow
direnv reload                          # Force reload
direnv deny                            # Revoke permission

# Common .envrc Patterns
export VAR=value                       # Set variable
PATH_add bin                           # Add to PATH
layout python                          # Python virtualenv
use node 18.0.0                        # Use Node 18
dotenv                                 # Load .env file
source_env ../shared/.envrc            # Load shared config

# Stdlib Functions
PATH_add, path_add, load_prefix, layout, use, dotenv,
source_env, source_up, watch_file, has, expand_path,
find_up, direnv_layout_dir, log_status, log_error
```

---

**Last Updated**: 2025-01-15  
**Version**: Based on direnv 2.34+  
**Status**: Production-ready, actively maintained  
**License**: MIT