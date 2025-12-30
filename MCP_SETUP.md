# MCP Server Configuration Setup

## Security Notice

⚠️ **IMPORTANT**: Never commit `.mcp.json` with real API keys to version control!

The `.mcp.json` file contains sensitive API keys and should remain in your local environment only. It's already added to `.gitignore`.

## Initial Setup

1. **Copy the example configuration**:
   ```bash
   cp .mcp.json.example .mcp.json
   ```

2. **Set up environment variables**:

   **Option A: Use the local environment file (Recommended for this project)**
   ```bash
   # Load environment variables from the secure local file
   source .env.mcp.local
   ```

   To make this automatic when you start Claude Code, add to your shell profile (`~/.zshrc` or `~/.bash_profile`):
   ```bash
   # Auto-load MCP environment variables when in project directory
   if [ -f "$PWD/.env.mcp.local" ]; then
       source "$PWD/.env.mcp.local"
   fi
   ```

   **Option B: Set up environment variables** in your shell profile (`~/.zshrc` or `~/.bash_profile`):
   ```bash
   # MCP Server API Keys
   export OPENROUTER_API_KEY="your-openrouter-api-key-here"
   export GREB_API_KEY="your-greb-api-key-here"
   export SWIFTZILLA_API_KEY="your-swiftzilla-api-key-here"
   export PROJECT_PATH="/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint"
   ```

3. **Reload your shell**:
   ```bash
   source ~/.zshrc  # or source ~/.bash_profile
   ```

4. **Verify environment variables**:
   ```bash
   echo $OPENROUTER_API_KEY
   echo $GREB_API_KEY
   echo $SWIFTZILLA_API_KEY
   ```

## Required API Keys

### OpenRouter API Key
- **Service**: adr-analysis MCP server
- **Get Key**: https://openrouter.ai/
- **Used for**: Architecture decision record analysis

### Greb API Key
- **Service**: greb-mcp code search
- **Get Key**: https://greb.ai/
- **Used for**: AI-powered code search

### Swiftzilla API Key
- **Service**: swiftzilla MCP server
- **Get Key**: Contact Swiftzilla support
- **Used for**: Swift-specific tooling and analysis

## Alternative: Local .env File (Optional)

If you prefer using a `.env` file:

1. Create `.env` in project root:
   ```bash
   OPENROUTER_API_KEY=your-openrouter-api-key-here
   GREB_API_KEY=your-greb-api-key-here
   SWIFTZILLA_API_KEY=your-swiftzilla-api-key-here
   PROJECT_PATH=/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint
   ```

2. Load it before running MCP servers:
   ```bash
   source .env
   ```

## Troubleshooting

### Environment variables not loading
- Ensure you've reloaded your shell after adding variables
- Check that variables are exported (use `export` keyword)
- Verify with `printenv | grep API_KEY`

### MCP servers not connecting
- Verify API keys are valid and not expired
- Check that PROJECT_PATH points to the correct directory
- Ensure MCP server commands are in your PATH

## Security Best Practices

1. ✅ Keep `.mcp.json` in `.gitignore` (already configured)
2. ✅ Keep `.env.mcp.local` in `.gitignore` (covered by `.env.*` pattern)
3. ✅ Use environment variables for all secrets (implemented)
4. ✅ Rotate API keys periodically
5. ✅ Never share API keys in screenshots or logs
6. ✅ Use `.mcp.json.example` as a template for team members

## Files Protected by .gitignore

- ✅ `.mcp.json` - MCP server configuration with environment variable references
- ✅ `.env.mcp.local` - Your actual API keys (covered by `.env.*`)
- ✅ `.env`, `.env.*` - Any environment files
- ✅ `Config.plist` - App configuration secrets
