#!/bin/bash
#
# update-session-context.sh
# Automatically updates session context with current project state
#
# Usage:
#   ./Scripts/update-session-context.sh [template-name]
#
# Examples:
#   ./Scripts/update-session-context.sh coding-session
#   ./Scripts/update-session-context.sh debugging-session
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTEXT_FILE=".claude-context.md"
TEMPLATES_DIR="docs/context-templates"
BEADS_DB=".beads/beads.db"

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get current Beads task
get_current_beads_task() {
    if [ ! -f "$BEADS_DB" ]; then
        echo "No active Beads task"
        return
    fi
    
    if command_exists bd; then
        # Get in_progress tasks
        local task=$(bd list --status=in_progress 2>/dev/null | head -n 1)
        if [ -n "$task" ]; then
            echo "$task"
        else
            echo "No active Beads task"
        fi
    else
        echo "Beads not available"
    fi
}

# Function to get recent git commits
get_recent_commits() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git log --oneline --since="1 hour ago" 2>/dev/null || echo "No recent commits"
    else
        echo "Not a git repository"
    fi
}

# Function to get modified files
get_modified_files() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git status --short 2>/dev/null || echo "No changes"
    else
        echo "Not a git repository"
    fi
}

# Function to get current branch
get_current_branch() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git branch --show-current 2>/dev/null || echo "unknown"
    else
        echo "not-a-git-repo"
    fi
}

# Function to count Swift files
count_swift_files() {
    find "I Do Blueprint" -name "*.swift" 2>/dev/null | wc -l | tr -d ' '
}

# Function to create context from template
create_context_from_template() {
    local template_name=$1
    local template_file="$TEMPLATES_DIR/${template_name}-template.md"
    
    if [ ! -f "$template_file" ]; then
        print_error "Template not found: $template_file"
        echo ""
        echo "Available templates:"
        ls -1 "$TEMPLATES_DIR"/*-template.md 2>/dev/null | xargs -n 1 basename | sed 's/-template.md//'
        exit 1
    fi
    
    print_info "Creating context from template: $template_name"
    
    # Copy template
    cp "$template_file" "$CONTEXT_FILE"
    
    # Replace placeholders
    local timestamp=$(date "+%Y-%m-%d %H:%M %Z")
    local current_task=$(get_current_beads_task)
    local recent_commits=$(get_recent_commits)
    local modified_files=$(get_modified_files)
    local current_branch=$(get_current_branch)
    
    # Use sed to replace placeholders (macOS compatible)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS sed requires -i ''
        sed -i '' "s/\[Auto-update timestamp\]/$timestamp/" "$CONTEXT_FILE"
    else
        # Linux sed
        sed -i "s/\[Auto-update timestamp\]/$timestamp/" "$CONTEXT_FILE"
    fi
    
    print_success "Context file created: $CONTEXT_FILE"
    echo ""
    print_info "Auto-populated information:"
    echo "  • Timestamp: $timestamp"
    echo "  • Branch: $current_branch"
    echo "  • Current task: $current_task"
    echo ""
    print_warning "Please edit $CONTEXT_FILE to fill in remaining sections"
}

# Function to update existing context
update_existing_context() {
    if [ ! -f "$CONTEXT_FILE" ]; then
        print_error "No context file found: $CONTEXT_FILE"
        echo ""
        print_info "Create a new context with:"
        echo "  ./Scripts/update-session-context.sh [template-name]"
        exit 1
    fi
    
    print_info "Updating existing context: $CONTEXT_FILE"
    
    local timestamp=$(date "+%Y-%m-%d %H:%M %Z")
    local current_task=$(get_current_beads_task)
    local recent_commits=$(get_recent_commits)
    local modified_files=$(get_modified_files)
    local current_branch=$(get_current_branch)
    
    # Create backup
    cp "$CONTEXT_FILE" "${CONTEXT_FILE}.backup"
    
    # Update timestamp
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "1,5s/\*\*Last Updated\*\*:.*/\*\*Last Updated\*\*: $timestamp/" "$CONTEXT_FILE"
    else
        sed -i "1,5s/\*\*Last Updated\*\*:.*/\*\*Last Updated\*\*: $timestamp/" "$CONTEXT_FILE"
    fi
    
    print_success "Context updated with current timestamp"
    echo ""
    print_info "Current state:"
    echo "  • Timestamp: $timestamp"
    echo "  • Branch: $current_branch"
    echo "  • Current task: $current_task"
    echo "  • Modified files: $(echo "$modified_files" | wc -l | tr -d ' ') files"
    echo ""
    print_info "Backup saved to: ${CONTEXT_FILE}.backup"
}

# Function to show context summary
show_context_summary() {
    if [ ! -f "$CONTEXT_FILE" ]; then
        print_error "No context file found: $CONTEXT_FILE"
        exit 1
    fi
    
    print_info "Context Summary"
    echo ""
    
    # Extract key sections
    echo "📋 Current Goal:"
    grep -A 2 "## Current Goal" "$CONTEXT_FILE" | tail -n 1 || echo "  Not set"
    echo ""
    
    echo "✅ Completed Milestones:"
    grep "- \[x\]" "$CONTEXT_FILE" | head -n 3 || echo "  None yet"
    echo ""
    
    echo "🎯 Next Steps:"
    grep -A 3 "### Immediate" "$CONTEXT_FILE" | tail -n 3 || echo "  Not defined"
    echo ""
    
    echo "📊 Session Metrics:"
    local turns=$(grep "Turns so far" "$CONTEXT_FILE" | grep -o '[0-9]*' || echo "0")
    local files=$(grep "Files modified" "$CONTEXT_FILE" | grep -o '[0-9]*' || echo "0")
    echo "  • Turns: $turns"
    echo "  • Files modified: $files"
}

# Function to archive context
archive_context() {
    if [ ! -f "$CONTEXT_FILE" ]; then
        print_error "No context file found: $CONTEXT_FILE"
        exit 1
    fi
    
    local archive_dir=".context-archive"
    mkdir -p "$archive_dir"
    
    local timestamp=$(date "+%Y%m%d-%H%M%S")
    local archive_file="$archive_dir/context-$timestamp.md"
    
    mv "$CONTEXT_FILE" "$archive_file"
    
    print_success "Context archived to: $archive_file"
    echo ""
    print_info "Start a new session with:"
    echo "  ./Scripts/update-session-context.sh [template-name]"
}

# Main script
main() {
    local command=${1:-update}
    
    case $command in
        coding-session|test-generation|debugging-session|architecture-decision)
            create_context_from_template "$command"
            ;;
        update)
            update_existing_context
            ;;
        summary)
            show_context_summary
            ;;
        archive)
            archive_context
            ;;
        help|--help|-h)
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  coding-session         Create context from coding session template"
            echo "  test-generation        Create context from test generation template"
            echo "  debugging-session      Create context from debugging template"
            echo "  architecture-decision  Create context from architecture template"
            echo "  update                 Update existing context (default)"
            echo "  summary                Show context summary"
            echo "  archive                Archive current context and start fresh"
            echo "  help                   Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 coding-session      # Start new coding session"
            echo "  $0 update              # Update existing context"
            echo "  $0 summary             # Show current context summary"
            echo "  $0 archive             # Archive and start fresh"
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            echo "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
