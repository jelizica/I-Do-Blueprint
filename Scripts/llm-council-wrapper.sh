#!/bin/bash

# LLM Council Wrapper for Claude Code
#
# This script demonstrates how to invoke LLM Council from command line
# and provides workarounds for timeout issues in Qodo Gen.
#
# Usage:
#   ./scripts/llm-council-wrapper.sh "Your question"
#   ./scripts/llm-council-wrapper.sh --stage1 "Quick question"
#   ./scripts/llm-council-wrapper.sh --help

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../logs/llm-council"
TIMEOUT=180  # 3 minutes default

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Functions
print_header() {
    local width=70
    echo ""
    echo -e "${CYAN}${BOLD}$(printf '═%.0s' $(seq 1 $width))${NC}"
    printf "${CYAN}${BOLD}%*s${NC}\n" $(((${#1}+$width)/2)) "$1"
    echo -e "${CYAN}${BOLD}$(printf '═%.0s' $(seq 1 $width))${NC}"
    echo ""
}

print_section() {
    echo -e "${BLUE}${BOLD}$1${NC}"
    [ -n "${2:-}" ] && echo -e "$2"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

show_help() {
    cat <<EOF
LLM Council Query Wrapper

USAGE:
    $0 [OPTIONS] "QUESTION"

OPTIONS:
    --stage1            Run only Stage 1 (individual model responses)
                        Faster, no ranking or synthesis

    --timeout=SECONDS   Set custom timeout (default: 180)
                        Full council may need 180-300 seconds

    --save-log          Save response to timestamped log file
                        Logs saved to: logs/llm-council/

    --chairman=MODEL    Specify chairman model (default: google/gemini-3-pro-preview)
                        Examples: openai/gpt-5.1, anthropic/claude-opus-4

    --models=LIST       Comma-separated list of council models
                        Example: "openai/gpt-5.1,anthropic/claude-sonnet-4.5"

    --help              Show this help message

EXAMPLES:
    # Quick comparison (Stage 1 only)
    $0 --stage1 "What is the best authentication pattern?"

    # Full deliberation with custom timeout
    $0 --timeout=300 "Should we use microservices or monolith?"

    # Custom models
    $0 --models="openai/gpt-5.1,anthropic/claude-opus-4" "Complex question"

TROUBLESHOOTING:
    • Timeouts in Qodo Gen?
      → Use this script or Claude Code CLI instead

    • Need faster results?
      → Use --stage1 flag (skips ranking and synthesis)

    • API errors?
      → Check OPENROUTER_API_KEY environment variable

    • Network issues?
      → Increase --timeout value (e.g., --timeout=300)

For more info: https://github.com/anthropics/claude-code
EOF
}

# Parse arguments
STAGE1_ONLY=false
SAVE_LOG=false
CHAIRMAN=""
MODELS=""
QUESTION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --stage1)
            STAGE1_ONLY=true
            shift
            ;;
        --timeout=*)
            TIMEOUT="${1#*=}"
            shift
            ;;
        --save-log)
            SAVE_LOG=true
            shift
            ;;
        --chairman=*)
            CHAIRMAN="${1#*=}"
            shift
            ;;
        --models=*)
            MODELS="${1#*=}"
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            QUESTION="$1"
            shift
            ;;
    esac
done

# Validate question
if [ -z "$QUESTION" ]; then
    print_error "No question provided"
    echo ""
    echo "Usage: $0 [OPTIONS] \"QUESTION\""
    echo "Run with --help for more information"
    exit 1
fi

# Create log directory if needed
if [ "$SAVE_LOG" = true ]; then
    mkdir -p "$LOG_DIR"
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    LOG_FILE="$LOG_DIR/council_${TIMESTAMP}.json"
fi

# Print header
print_header "LLM COUNCIL QUERY RUNNER"

# Show configuration
print_section "Question" "$QUESTION"

CONFIG="Mode: $([ "$STAGE1_ONLY" = true ] && echo "Stage 1 Only" || echo "Full Council")\n"
CONFIG+="Timeout: ${TIMEOUT} seconds\n"
CONFIG+="Save log: ${SAVE_LOG}"
[ -n "$CHAIRMAN" ] && CONFIG+="\nChairman: ${CHAIRMAN}"
[ -n "$MODELS" ] && CONFIG+="\nModels: ${MODELS}"

print_section "Configuration" "$CONFIG"

# Build MCP tool call
if [ "$STAGE1_ONLY" = true ]; then
    TOOL_NAME="mcp__llm-council__council_stage1"
    PARAMS=$(cat <<EOF
{
  "question": "$QUESTION"$([ -n "$MODELS" ] && echo ",
  \"council_models\": [$(echo "$MODELS" | sed 's/,/", "/g' | sed 's/^/"/;s/$/"/'))]" || echo "")
}
EOF
)
else
    TOOL_NAME="mcp__llm-council__council_query"
    PARAMS=$(cat <<EOF
{
  "question": "$QUESTION",
  "save_conversation": true$([ -n "$CHAIRMAN" ] && echo ",
  \"chairman_model\": \"$CHAIRMAN\"" || echo "")$([ -n "$MODELS" ] && echo ",
  \"council_models\": [$(echo "$MODELS" | sed 's/,/", "/g' | sed 's/^/"/;s/$/"/'))]" || echo "")
}
EOF
)
fi

# Display MCP call
print_section "MCP Tool Call"
echo -e "${CYAN}Tool:${NC} $TOOL_NAME"
echo -e "${CYAN}Parameters:${NC}"
echo "$PARAMS" | sed 's/^/  /'
echo ""

# Execution instructions
print_header "EXECUTION INSTRUCTIONS"

print_section "Option 1: Claude Code CLI (Recommended)" \
"Open Claude Code terminal and paste:"

cat <<EOF
  mcp__llm-council__$([ "$STAGE1_ONLY" = true ] && echo "council_stage1" || echo "council_query")(
EOF

echo "$PARAMS" | grep -v '^{$' | grep -v '^}$' | sed 's/^  /    /' | sed 's/: /: /'

echo "  )"
echo ""

print_section "Option 2: Use This Wrapper with MCP Client" \
"If you have the Claude SDK or MCP client installed:"

echo "  # Install dependencies (if not already installed)"
echo "  # pip install anthropic mcp"
echo ""
echo "  # Run the Python wrapper"
echo "  python3 scripts/llm-council-query.py \\"
echo "    $([ "$STAGE1_ONLY" = true ] && echo "--stage1 \\" || echo "")"
echo "    $([ -n "$CHAIRMAN" ] && echo "--chairman=\"$CHAIRMAN\" \\" || echo "")"
echo "    $([ -n "$MODELS" ] && echo "--models=\"$MODELS\" \\" || echo "")"
echo "    \"$QUESTION\""
echo ""

# Troubleshooting
print_section "Troubleshooting Tips"

cat <<EOF
  ${YELLOW}Timeout Issues:${NC}
    • Full council takes 30-120 seconds
    • Increase timeout: --timeout=300
    • Use Stage 1 only: --stage1 (faster)

  ${YELLOW}API Errors:${NC}
    • Check OPENROUTER_API_KEY is set:
      export OPENROUTER_API_KEY="your-key-here"
    • Verify models are available on OpenRouter

  ${YELLOW}Network Issues:${NC}
    • Check internet connectivity
    • Try again in a few minutes
    • Use Stage 1 for simpler queries

  ${YELLOW}Qodo Gen Timeouts:${NC}
    • Use this script instead
    • Or use Claude Code CLI directly
    • Stage 1 is more reliable in constrained environments
EOF

echo ""

# Save log metadata if requested
if [ "$SAVE_LOG" = true ]; then
    cat > "$LOG_FILE" <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "question": "$QUESTION",
  "mode": "$([ "$STAGE1_ONLY" = true ] && echo "stage1" || echo "full")",
  "timeout": $TIMEOUT,
  "tool": "$TOOL_NAME",
  "parameters": $PARAMS,
  "note": "Log created by wrapper script. Actual response would be appended here."
}
EOF
    print_success "Log template saved to: $LOG_FILE"
    echo ""
fi

print_header "Ready to Execute"

print_info "Copy the command above into Claude Code CLI or use the Python wrapper."
print_warning "This script provides the structure. Actual execution requires MCP client."

echo ""
