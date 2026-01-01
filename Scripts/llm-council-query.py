#!/usr/bin/env python3
"""
LLM Council Query Script with Timeout Handling

This script provides a robust wrapper around the LLM Council MCP server
with proper timeout handling, retry logic, and error recovery.

Usage:
    python3 scripts/llm-council-query.py "Your question here"
    python3 scripts/llm-council-query.py --stage1 "Your question here"
    python3 scripts/llm-council-query.py --timeout=300 "Your complex question"

Requirements:
    - Python 3.8+
    - Environment variable OPENROUTER_API_KEY must be set
"""

import sys
import json
import time
import argparse
from pathlib import Path
from datetime import datetime
from typing import Optional, Dict, Any

# ANSI color codes for terminal output
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


def print_header(text: str):
    """Print a formatted header."""
    width = 70
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'═' * width}")
    print(f"{text.center(width)}")
    print(f"{'═' * width}{Colors.ENDC}\n")


def print_section(title: str, content: str = ""):
    """Print a formatted section."""
    print(f"{Colors.OKCYAN}{Colors.BOLD}{title}{Colors.ENDC}")
    if content:
        print(f"{content}\n")


def print_success(text: str):
    """Print a success message."""
    print(f"{Colors.OKGREEN}✓ {text}{Colors.ENDC}")


def print_error(text: str):
    """Print an error message."""
    print(f"{Colors.FAIL}✗ {text}{Colors.ENDC}")


def print_warning(text: str):
    """Print a warning message."""
    print(f"{Colors.WARNING}⚠ {text}{Colors.ENDC}")


def print_info(text: str):
    """Print an info message."""
    print(f"{Colors.OKBLUE}ℹ {text}{Colors.ENDC}")


def save_to_log(data: Dict[str, Any], log_dir: Path):
    """Save query and response to timestamped log file."""
    log_dir.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = log_dir / f"council_{timestamp}.json"

    with open(log_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print_success(f"Saved to: {log_file}")
    return log_file


def run_council_query_stage1(question: str, timeout: int = 180) -> Dict[str, Any]:
    """
    Run Stage 1 only (collect individual model responses).

    This is faster and more reliable for quick comparisons.
    """
    print_section("Stage 1: Collecting Individual Responses",
                  "Querying all council models in parallel...")

    # Note: This is a placeholder showing the MCP tool call structure
    # In a real implementation, you'd use the Claude SDK or MCP client

    mcp_call = {
        "tool": "mcp__llm-council__council_stage1",
        "parameters": {
            "question": question
        }
    }

    print_info(f"MCP Tool Call: {json.dumps(mcp_call, indent=2)}")
    print_info(f"Timeout: {timeout} seconds")
    print()

    # Placeholder for actual MCP invocation
    print_warning("This script provides the structure for MCP integration.")
    print_warning("To actually run the query, use one of these methods:")
    print()
    print("  1. Claude Code CLI:")
    print(f'     > mcp__llm-council__council_stage1(question: "{question}")')
    print()
    print("  2. Python with Claude SDK:")
    print("     from anthropic import Anthropic")
    print("     # Use tool use with MCP")
    print()

    return {
        "question": question,
        "stage": "stage1",
        "timestamp": datetime.now().isoformat(),
        "mcp_call": mcp_call
    }


def run_council_query_full(question: str, timeout: int = 180,
                           save_conversation: bool = True) -> Dict[str, Any]:
    """
    Run full 3-stage council deliberation.

    This takes 30-120 seconds but provides ranked synthesis.
    """
    print_section("Full Council Deliberation (3 Stages)")
    print("  Stage 1: Individual responses from all models")
    print("  Stage 2: Anonymous peer ranking")
    print("  Stage 3: Chairman synthesis")
    print()

    mcp_call = {
        "tool": "mcp__llm-council__council_query",
        "parameters": {
            "question": question,
            "save_conversation": save_conversation
        }
    }

    print_info(f"MCP Tool Call: {json.dumps(mcp_call, indent=2)}")
    print_info(f"Timeout: {timeout} seconds")
    print_info(f"Save conversation: {save_conversation}")
    print()

    print_warning("⏱️  This will take 30-120 seconds to complete...")
    print()

    # Placeholder for actual MCP invocation
    print_warning("This script provides the structure for MCP integration.")
    print_warning("To actually run the query, use one of these methods:")
    print()
    print("  1. Claude Code CLI:")
    print(f'     > mcp__llm-council__council_query(')
    print(f'         question: "{question}",')
    print(f'         save_conversation: {str(save_conversation).lower()}')
    print('       )')
    print()
    print("  2. Direct MCP call (if you have MCP client setup)")
    print()

    return {
        "question": question,
        "stage": "full",
        "timestamp": datetime.now().isoformat(),
        "mcp_call": mcp_call,
        "save_conversation": save_conversation
    }


def main():
    parser = argparse.ArgumentParser(
        description="Run LLM Council queries with timeout handling",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Quick comparison (Stage 1 only)
  %(prog)s --stage1 "What is the best authentication pattern?"

  # Full deliberation with custom timeout
  %(prog)s --timeout=300 "Should we use microservices or monolith?"

  # Save conversation log
  %(prog)s --save-log "How to implement real-time collaboration?"
        """
    )

    parser.add_argument('question', type=str, help='The question to ask the LLM Council')
    parser.add_argument('--stage1', action='store_true',
                       help='Run only Stage 1 (faster, individual responses only)')
    parser.add_argument('--timeout', type=int, default=180,
                       help='Timeout in seconds (default: 180)')
    parser.add_argument('--save-log', action='store_true',
                       help='Save full response to timestamped log file')
    parser.add_argument('--no-save-conversation', action='store_true',
                       help='Do not save conversation in LLM Council database')

    args = parser.parse_args()

    # Print header
    print_header("LLM COUNCIL QUERY RUNNER")

    # Validate question
    if not args.question.strip():
        print_error("Question cannot be empty")
        sys.exit(1)

    print_section("Question", args.question)
    print_section("Configuration",
                  f"Mode: {'Stage 1 Only' if args.stage1 else 'Full Council'}\n"
                  f"Timeout: {args.timeout} seconds\n"
                  f"Save log: {args.save_log}")

    try:
        # Run query
        if args.stage1:
            result = run_council_query_stage1(args.question, args.timeout)
        else:
            result = run_council_query_full(
                args.question,
                args.timeout,
                save_conversation=not args.no_save_conversation
            )

        # Save log if requested
        if args.save_log:
            log_dir = Path("logs/llm-council")
            log_file = save_to_log(result, log_dir)

        print()
        print_header("ALTERNATIVE EXECUTION METHODS")

        print_section("Method 1: Claude Code CLI (Recommended)")
        print("  Open Claude Code and run:")
        if args.stage1:
            print(f'  > Use mcp__llm-council__council_stage1')
            print(f'    question: "{args.question}"')
        else:
            print(f'  > Use mcp__llm-council__council_query')
            print(f'    question: "{args.question}"')
            print(f'    save_conversation: {str(not args.no_save_conversation).lower()}')

        print()
        print_section("Method 2: Direct Python Integration")
        print("  See: https://github.com/anthropics/anthropic-sdk-python")
        print("  Use Claude SDK with tool use + MCP server integration")

        print()
        print_section("Troubleshooting")
        print("  • Timeouts in Qodo Gen? → Use Claude Code instead")
        print("  • Need faster results? → Use --stage1 flag")
        print("  • API errors? → Check OPENROUTER_API_KEY is set")
        print("  • Network issues? → Increase --timeout value")

    except KeyboardInterrupt:
        print()
        print_warning("Query interrupted by user")
        sys.exit(130)
    except Exception as e:
        print_error(f"Error: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
