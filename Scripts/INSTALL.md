# LLM Council Scripts Installation

## Quick Setup (Recommended)

### Option 1: Shell Aliases (Most Convenient)

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
# LLM Council shortcuts
alias council='~/Development/nextjs-projects/I\ Do\ Blueprint/scripts/council'
alias council1='~/Development/nextjs-projects/I\ Do\ Blueprint/scripts/council --stage1'
alias council-full='~/Development/nextjs-projects/I\ Do\ Blueprint/scripts/council --timeout=300'
alias council-help='~/Development/nextjs-projects/I\ Do\ Blueprint/scripts/council --help'
```

Then reload:
```bash
source ~/.zshrc
```

### Option 2: Source Project Aliases

Add to your `~/.zshrc`:
```bash
# Source I Do Blueprint council shortcuts (when in project directory)
alias load-council='source ~/Development/nextjs-projects/I\ Do\ Blueprint/.zshrc-additions'
```

Then in the project directory:
```bash
load-council
```

### Option 3: Add to PATH

Add to your `~/.zshrc`:
```bash
export PATH="$HOME/Development/nextjs-projects/I Do Blueprint/scripts:$PATH"
```

Then reload and use directly:
```bash
council "Your question"
```

## Usage After Installation

### Basic Commands

```bash
# Full council deliberation
council "Should we use SQLite or PostgreSQL?"

# Stage 1 only (faster)
council1 "What is the best caching strategy?"

# Extended timeout for complex questions
council-full "Design a microservices architecture for wedding planning"

# Save to log
council --save-log "Important architecture decision"

# Help
council-help
```

### Advanced Options

```bash
# Custom models
council --models="openai/gpt-5.1,anthropic/claude-opus-4" "Your question"

# Custom chairman
council --chairman="anthropic/claude-opus-4" "Your question"

# Combine options
council --stage1 --save-log "Quick comparison with logging"
```

## Verification

Test the installation:

```bash
# Should show help
council --help

# Should show colorful output
council1 "test"
```

## Environment Setup

Ensure you have the OpenRouter API key:

```bash
# Add to ~/.zshrc or ~/.bashrc
export OPENROUTER_API_KEY="your-key-here"
```

Get your key from: https://openrouter.ai/keys

## For Other Projects

To use these scripts in other projects:

1. Copy the `scripts/` directory to your project
2. Update the paths in your shell aliases
3. Or create symlinks:
   ```bash
   ln -s ~/Development/nextjs-projects/I\ Do\ Blueprint/scripts/council ~/bin/council
   ```

## Uninstall

Remove from `~/.zshrc`:
```bash
# Remove aliases or PATH additions
# Then:
source ~/.zshrc
```

## Troubleshooting

### "command not found: council"
- Run `source ~/.zshrc` after adding aliases
- Check the path to the script is correct
- Ensure script is executable: `chmod +x scripts/council`

### "Permission denied"
```bash
chmod +x scripts/council
chmod +x scripts/llm-council-wrapper.sh
```

### Timeouts Still Occurring
- Use `council1` for faster queries
- Increase timeout: `council --timeout=300`
- Use Claude Code CLI directly (most reliable)

## For AI Assistants

When an AI assistant needs to run LLM Council:

1. **Recommend the short command:**
   ```
   council "question here"
   ```

2. **For faster queries:**
   ```
   council1 "question here"
   ```

3. **For complex questions:**
   ```
   council-full "question here"
   ```

4. **Direct MCP call (most reliable):**
   ```
   mcp__llm-council__council_query(
     question: "question here",
     save_conversation: true
   )
   ```

The scripts are designed to be easily discoverable and memorable.
