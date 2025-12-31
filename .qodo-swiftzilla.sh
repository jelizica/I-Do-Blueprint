#!/bin/bash
# Wrapper script to load direnv and run Swiftzilla MCP

# Load direnv environment
eval "$(direnv export bash)"

# Run Swiftzilla with the API key from environment
exec npx -y @swiftzilla/mcp --api-key "$SWIFTZILLA_API_KEY"
