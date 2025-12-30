#!/bin/bash
# Generate architecture diagrams from Structurizr DSL
# Usage: ./scripts/generate-diagrams.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DSL="$PROJECT_ROOT/docs/architecture/workspace.dsl"
OUTPUT_DIR="$PROJECT_ROOT/docs/architecture/exports"

echo "🔧 Generating architecture diagrams..."
echo "   Workspace: $WORKSPACE_DSL"
echo "   Output: $OUTPUT_DIR"
echo ""

# Check if structurizr-cli is installed
if ! command -v structurizr-cli &> /dev/null; then
    echo "❌ Error: structurizr-cli not installed"
    echo "   Install with: brew install structurizr-cli"
    exit 1
fi

# Validate workspace file exists
if [ ! -f "$WORKSPACE_DSL" ]; then
    echo "❌ Error: Workspace file not found: $WORKSPACE_DSL"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Export diagrams
structurizr-cli export \
    -workspace "$WORKSPACE_DSL" \
    -format png \
    -output "$OUTPUT_DIR"

echo ""
echo "✅ Diagrams generated successfully!"
echo ""
echo "📊 Generated files:"
ls -lh "$OUTPUT_DIR"/*.png 2>/dev/null || echo "   (No PNG files found)"

echo ""
echo "💡 View diagrams:"
echo "   open $OUTPUT_DIR"
