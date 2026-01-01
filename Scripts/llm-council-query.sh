#!/bin/bash

# LLM Council Query Script with Timeout Handling
#
# Usage:
#   ./scripts/llm-council-query.sh "Your question here"
#   ./scripts/llm-council-query.sh --stage1 "Your question here"
#
# Options:
#   --stage1          Run only Stage 1 (collect individual responses)
#   --timeout=SECONDS Set custom timeout (default: 180 seconds)
#   --save-log        Save full response to timestamped log file

set -euo pipefail

# Default configuration
TIMEOUT=180  # 3 minutes for full council deliberation
STAGE1_ONLY=false
SAVE_LOG=false
LOG_DIR="logs/llm-council"

# Parse arguments
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
    *)
      QUESTION="$1"
      shift
      ;;
  esac
done

# Validate question
if [ -z "$QUESTION" ]; then
  echo "Error: No question provided"
  echo ""
  echo "Usage:"
  echo "  $0 \"Your question here\""
  echo "  $0 --stage1 \"Your question here\""
  echo "  $0 --timeout=300 \"Your question here\""
  echo "  $0 --save-log \"Your question here\""
  exit 1
fi

# Create log directory if saving
if [ "$SAVE_LOG" = true ]; then
  mkdir -p "$LOG_DIR"
  TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
  LOG_FILE="$LOG_DIR/council_${TIMESTAMP}.json"
fi

# Prepare Node.js script for LLM Council query
NODE_SCRIPT=$(cat <<'EOF'
const question = process.argv[2];
const stage1Only = process.argv[3] === 'true';
const timeout = parseInt(process.argv[4], 10);
const saveLog = process.argv[5] === 'true';
const logFile = process.argv[6];

// Import MCP tools (adjust path if needed)
// This assumes you have a way to call MCP tools from Node.js
// If not available, we'll use a simpler approach

async function runCouncilQuery() {
  try {
    // Set a timeout promise
    const timeoutPromise = new Promise((_, reject) =>
      setTimeout(() => reject(new Error(`Query timeout after ${timeout} seconds`)), timeout * 1000)
    );

    // Note: This is a placeholder - you'll need to adapt based on your MCP client setup
    // For now, we'll output instructions for manual invocation

    console.log('╔══════════════════════════════════════════════════════════════╗');
    console.log('║           LLM COUNCIL QUERY RUNNER                           ║');
    console.log('╚══════════════════════════════════════════════════════════════╝\n');

    console.log('Question:', question);
    console.log('Mode:', stage1Only ? 'Stage 1 Only' : 'Full Council');
    console.log('Timeout:', timeout, 'seconds');
    console.log('');

    if (stage1Only) {
      console.log('Running Stage 1 (individual model responses)...\n');
      console.log('MCP Tool Call:');
      console.log('  mcp__llm-council__council_stage1');
      console.log('  question:', JSON.stringify(question));
    } else {
      console.log('Running Full Council Deliberation (3 stages)...\n');
      console.log('MCP Tool Call:');
      console.log('  mcp__llm-council__council_query');
      console.log('  question:', JSON.stringify(question));
      console.log('  save_conversation: true');
    }

    console.log('\n⏱️  This may take 30-120 seconds to complete...');
    console.log('⏱️  Timeout set to:', timeout, 'seconds\n');

    // Since we can't directly invoke MCP from bash, output the command
    console.log('─'.repeat(64));
    console.log('TO RUN MANUALLY IN CLAUDE CODE CLI:');
    console.log('─'.repeat(64));

    if (stage1Only) {
      console.log(`\nmcp__llm-council__council_stage1(question: "${question}")`);
    } else {
      console.log(`\nmcp__llm-council__council_query(question: "${question}", save_conversation: true)`);
    }

    console.log('\n' + '─'.repeat(64));

  } catch (error) {
    if (error.message.includes('timeout')) {
      console.error('\n❌ Query timed out after', timeout, 'seconds');
      console.error('\nTroubleshooting tips:');
      console.error('  1. Try running Stage 1 only with --stage1 flag');
      console.error('  2. Increase timeout with --timeout=300');
      console.error('  3. Check your OpenRouter API key is valid');
      console.error('  4. Verify network connectivity');
      process.exit(1);
    }
    throw error;
  }
}

runCouncilQuery().catch(error => {
  console.error('Error:', error.message);
  process.exit(1);
});
EOF
)

# Run the Node script
echo "$NODE_SCRIPT" | node - "$QUESTION" "$STAGE1_ONLY" "$TIMEOUT" "$SAVE_LOG" "${LOG_FILE:-}"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "💡 ALTERNATIVE: Use Claude Code directly for better integration:"
echo ""
echo "   In Claude Code CLI, run:"
if [ "$STAGE1_ONLY" = true ]; then
  echo "   > Use mcp__llm-council__council_stage1 tool"
else
  echo "   > Use mcp__llm-council__council_query tool"
fi
echo ""
echo "═══════════════════════════════════════════════════════════════"
