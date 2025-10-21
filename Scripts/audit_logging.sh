#!/bin/bash

# Logging Audit Script
# Identifies excessive debug logging patterns across the codebase

echo "🔍 Auditing logging statements..."
echo ""

# Find all debug logs
echo "📊 Debug log count:"
DEBUG_COUNT=$(grep -r "logger\.debug" --include="*.swift" "I Do Blueprint" | wc -l | tr -d ' ')
echo "  Total: $DEBUG_COUNT"
echo ""

# Find logs in loops (potential performance issue)
echo "⚠️  Potential logs in loops:"
grep -B5 "logger\." --include="*.swift" "I Do Blueprint" | grep -E "(for|while|forEach)" -A5 | grep "logger\." | wc -l | tr -d ' '
echo ""

# Find redundant log patterns
echo "🔄 Redundant log patterns:"
echo "  'Fetching' logs:"
grep -r "logger\.debug.*Fetching" --include="*.swift" "I Do Blueprint" | wc -l | tr -d ' '
echo "  'Loading' logs:"
grep -r "logger\.debug.*Loading" --include="*.swift" "I Do Blueprint" | wc -l | tr -d ' '
echo "  'Loaded' logs:"
grep -r "logger\.debug.*Loaded" --include="*.swift" "I Do Blueprint" | wc -l | tr -d ' '
echo "  'Cached' logs:"
grep -r "logger\.debug.*Cached" --include="*.swift" "I Do Blueprint" | wc -l | tr -d ' '
echo "  'Cache hit' logs:"
grep -r "logger\.debug.*Cache hit" --include="*.swift" "I Do Blueprint" | wc -l | tr -d ' '
echo "  'Creating' logs:"
grep -r "logger\.debug.*Creating" --include="*.swift" "I Do Blueprint" | wc -l | tr -d ' '
echo "  'Updating' logs:"
grep -r "logger\.debug.*Updating" --include="*.swift" "I Do Blueprint" | wc -l | tr -d ' '
echo "  'Deleting' logs:"
grep -r "logger\.debug.*Deleting" --include="*.swift" "I Do Blueprint" | wc -l | tr -d ' '
echo "  'Saving' logs:"
grep -r "logger\.debug.*Saving" --include="*.swift" "I Do Blueprint" | wc -l | tr -d ' '
echo ""

# Find placeholder warnings
echo "⚠️  Placeholder warnings:"
grep -r "logger\.warning.*Placeholder" --include="*.swift" "I Do Blueprint" | wc -l | tr -d ' '
echo ""

# Repository-specific counts
echo "📁 Debug logs by repository:"
for file in "I Do Blueprint/Domain/Repositories/Live"/*.swift; do
    if [ -f "$file" ]; then
        count=$(grep "logger\.debug" "$file" | wc -l | tr -d ' ')
        if [ "$count" -gt 0 ]; then
            echo "  $(basename "$file"): $count"
        fi
    fi
done
echo ""

# Store-specific counts
echo "📁 Debug logs by store:"
for file in "I Do Blueprint/Services/Stores"/*.swift; do
    if [ -f "$file" ]; then
        count=$(grep "logger\.debug" "$file" | wc -l | tr -d ' ')
        if [ "$count" -gt 0 ]; then
            echo "  $(basename "$file"): $count"
        fi
    fi
done
echo ""

# View-specific counts
echo "📁 Debug logs in views:"
VIEW_COUNT=$(find "I Do Blueprint/Views" -name "*.swift" -exec grep -l "logger\.debug" {} \; | wc -l | tr -d ' ')
echo "  Files with debug logs: $VIEW_COUNT"
echo ""

echo "✅ Audit complete"
echo ""
echo "🎯 Reduction targets:"
echo "  Current: $DEBUG_COUNT debug logs"
echo "  Target: <50 debug logs (85% reduction)"
echo "  To remove: ~$((DEBUG_COUNT - 50)) logs"
