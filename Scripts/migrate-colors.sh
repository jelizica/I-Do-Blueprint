#!/bin/bash

# Color System Migration Script
# Helps migrate legacy color patterns to Blush Romance semantic colors
# Usage: ./Scripts/migrate-colors.sh [scan|migrate|verify]

set -e

PROJECT_ROOT="/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint"
VIEWS_DIR="$PROJECT_ROOT/I Do Blueprint/Views"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to scan for legacy patterns
scan_legacy_patterns() {
    print_header "Scanning for Legacy Color Patterns"
    
    echo ""
    echo "1. Dashboard Quick Actions (Legacy):"
    echo "   Files using AppColors.Dashboard.*"
    grep -r "AppColors\.Dashboard\." "$VIEWS_DIR" --include="*.swift" | wc -l | xargs echo "   Found:"
    
    echo ""
    echo "2. Guest Status Colors (Legacy):"
    echo "   Files using AppColors.Guest.*"
    grep -r "AppColors\.Guest\." "$VIEWS_DIR" --include="*.swift" | wc -l | xargs echo "   Found:"
    
    echo ""
    echo "3. Hardcoded Opacity Values:"
    echo "   .opacity(0.05) instances:"
    grep -r "\.opacity(0\.05)" "$VIEWS_DIR" --include="*.swift" | wc -l | xargs echo "   Found:"
    echo "   .opacity(0.1) instances:"
    grep -r "\.opacity(0\.1)" "$VIEWS_DIR" --include="*.swift" | wc -l | xargs echo "   Found:"
    echo "   .opacity(0.15) instances:"
    grep -r "\.opacity(0\.15)" "$VIEWS_DIR" --include="*.swift" | wc -l | xargs echo "   Found:"
    echo "   .opacity(0.5) instances:"
    grep -r "\.opacity(0\.5)" "$VIEWS_DIR" --include="*.swift" | wc -l | xargs echo "   Found:"
    
    echo ""
    echo "4. Semantic Color Usage (New):"
    echo "   Files using SemanticColors.*"
    grep -r "SemanticColors\." "$VIEWS_DIR" --include="*.swift" | wc -l | xargs echo "   Found:"
    echo "   Files using QuickActions.*"
    grep -r "QuickActions\." "$VIEWS_DIR" --include="*.swift" | wc -l | xargs echo "   Found:"
    echo "   Files using Opacity.*"
    grep -r "Opacity\." "$VIEWS_DIR" --include="*.swift" | wc -l | xargs echo "   Found:"
    
    echo ""
    print_success "Scan complete!"
}

# Function to list files needing migration
list_migration_targets() {
    print_header "Files Needing Migration"
    
    echo ""
    echo "Dashboard Quick Actions:"
    grep -l "AppColors\.Dashboard\." "$VIEWS_DIR"/**/*.swift 2>/dev/null || echo "   None found"
    
    echo ""
    echo "Guest Status Colors:"
    grep -l "AppColors\.Guest\." "$VIEWS_DIR"/**/*.swift 2>/dev/null || echo "   None found"
    
    echo ""
    echo "Top 10 files with most hardcoded opacity:"
    grep -r "\.opacity(0\." "$VIEWS_DIR" --include="*.swift" | cut -d: -f1 | sort | uniq -c | sort -rn | head -10
}

# Function to create backup
create_backup() {
    print_header "Creating Backup"
    
    BACKUP_DIR="$PROJECT_ROOT/.color-migration-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    cp -r "$VIEWS_DIR" "$BACKUP_DIR/"
    
    print_success "Backup created at: $BACKUP_DIR"
}

# Function to migrate Dashboard colors
migrate_dashboard_colors() {
    print_header "Migrating Dashboard Quick Actions"
    
    FILE="$VIEWS_DIR/Dashboard/Components/QuickActionsBar.swift"
    
    if [ ! -f "$FILE" ]; then
        print_error "File not found: $FILE"
        return 1
    fi
    
    print_warning "Creating backup..."
    cp "$FILE" "$FILE.backup"
    
    # Replace Dashboard colors with QuickActions
    sed -i '' 's/AppColors\.Dashboard\.taskAction/QuickActions.task/g' "$FILE"
    sed -i '' 's/AppColors\.Dashboard\.noteAction/QuickActions.note/g' "$FILE"
    sed -i '' 's/AppColors\.Dashboard\.eventAction/QuickActions.event/g' "$FILE"
    sed -i '' 's/AppColors\.Dashboard\.guestAction/QuickActions.guest/g' "$FILE"
    
    print_success "Dashboard colors migrated!"
    print_warning "Backup saved to: $FILE.backup"
}

# Function to migrate Guest status colors
migrate_guest_colors() {
    print_header "Migrating Guest Status Colors"
    
    # Find all files using Guest colors
    FILES=$(grep -l "AppColors\.Guest\." "$VIEWS_DIR"/**/*.swift 2>/dev/null)
    
    if [ -z "$FILES" ]; then
        print_warning "No files found using AppColors.Guest.*"
        return 0
    fi
    
    for FILE in $FILES; do
        echo "Processing: $FILE"
        
        # Create backup
        cp "$FILE" "$FILE.backup"
        
        # Replace Guest colors with SemanticColors
        sed -i '' 's/AppColors\.Guest\.confirmed/SemanticColors.statusSuccess/g' "$FILE"
        sed -i '' 's/AppColors\.Guest\.declined/SemanticColors.statusWarning/g' "$FILE"
        sed -i '' 's/AppColors\.Guest\.pending/SemanticColors.statusPending/g' "$FILE"
        
        print_success "Migrated: $FILE"
    done
    
    print_warning "⚠️  IMPORTANT: Add icons to status indicators for color blind accessibility!"
    echo "   Example:"
    echo "   HStack {"
    echo "       Image(systemName: \"checkmark.circle.fill\")"
    echo "       Text(\"Confirmed\")"
    echo "           .foregroundColor(SemanticColors.statusSuccess)"
    echo "   }"
}

# Function to migrate opacity values
migrate_opacity_values() {
    print_header "Migrating Hardcoded Opacity Values"
    
    print_warning "This will migrate opacity values in Dashboard, Budget, and Guest views"
    print_warning "Press Enter to continue or Ctrl+C to cancel..."
    read
    
    # Target directories
    DIRS=(
        "$VIEWS_DIR/Dashboard"
        "$VIEWS_DIR/Budget"
        "$VIEWS_DIR/Guests"
    )
    
    for DIR in "${DIRS[@]}"; do
        if [ ! -d "$DIR" ]; then
            print_warning "Directory not found: $DIR"
            continue
        fi
        
        echo "Processing directory: $DIR"
        
        # Find all Swift files
        find "$DIR" -name "*.swift" -type f | while read FILE; do
            # Create backup
            cp "$FILE" "$FILE.backup"
            
            # Replace opacity values
            sed -i '' 's/\.opacity(0\.05)/\.opacity(Opacity.verySubtle)/g' "$FILE"
            sed -i '' 's/\.opacity(0\.1)/\.opacity(Opacity.subtle)/g' "$FILE"
            sed -i '' 's/\.opacity(0\.15)/\.opacity(Opacity.light)/g' "$FILE"
            sed -i '' 's/\.opacity(0\.5)/\.opacity(Opacity.medium)/g' "$FILE"
            sed -i '' 's/\.opacity(0\.95)/\.opacity(Opacity.strong)/g' "$FILE"
            
            echo "   Migrated: $FILE"
        done
    done
    
    print_success "Opacity values migrated!"
    print_warning "Backups saved with .backup extension"
}

# Function to verify migration
verify_migration() {
    print_header "Verifying Migration"
    
    echo ""
    echo "Checking for remaining legacy patterns..."
    
    DASHBOARD_COUNT=$(grep -r "AppColors\.Dashboard\." "$VIEWS_DIR" --include="*.swift" 2>/dev/null | wc -l | xargs)
    GUEST_COUNT=$(grep -r "AppColors\.Guest\." "$VIEWS_DIR" --include="*.swift" 2>/dev/null | wc -l | xargs)
    OPACITY_05=$(grep -r "\.opacity(0\.05)" "$VIEWS_DIR" --include="*.swift" 2>/dev/null | wc -l | xargs)
    OPACITY_1=$(grep -r "\.opacity(0\.1)" "$VIEWS_DIR" --include="*.swift" 2>/dev/null | wc -l | xargs)
    OPACITY_15=$(grep -r "\.opacity(0\.15)" "$VIEWS_DIR" --include="*.swift" 2>/dev/null | wc -l | xargs)
    
    echo ""
    if [ "$DASHBOARD_COUNT" -eq 0 ]; then
        print_success "No legacy Dashboard colors found"
    else
        print_warning "Found $DASHBOARD_COUNT legacy Dashboard color usages"
    fi
    
    if [ "$GUEST_COUNT" -eq 0 ]; then
        print_success "No legacy Guest colors found"
    else
        print_warning "Found $GUEST_COUNT legacy Guest color usages"
    fi
    
    if [ "$OPACITY_05" -eq 0 ] && [ "$OPACITY_1" -eq 0 ] && [ "$OPACITY_15" -eq 0 ]; then
        print_success "No hardcoded opacity values found (in migrated directories)"
    else
        print_warning "Found hardcoded opacity values:"
        echo "   .opacity(0.05): $OPACITY_05"
        echo "   .opacity(0.1): $OPACITY_1"
        echo "   .opacity(0.15): $OPACITY_15"
    fi
    
    echo ""
    echo "Checking for new semantic color usage..."
    
    SEMANTIC_COUNT=$(grep -r "SemanticColors\." "$VIEWS_DIR" --include="*.swift" 2>/dev/null | wc -l | xargs)
    QUICKACTIONS_COUNT=$(grep -r "QuickActions\." "$VIEWS_DIR" --include="*.swift" 2>/dev/null | wc -l | xargs)
    OPACITY_ENUM_COUNT=$(grep -r "Opacity\." "$VIEWS_DIR" --include="*.swift" 2>/dev/null | wc -l | xargs)
    
    echo ""
    if [ "$SEMANTIC_COUNT" -gt 0 ]; then
        print_success "Found $SEMANTIC_COUNT SemanticColors usages"
    else
        print_warning "No SemanticColors usages found"
    fi
    
    if [ "$QUICKACTIONS_COUNT" -gt 0 ]; then
        print_success "Found $QUICKACTIONS_COUNT QuickActions usages"
    else
        print_warning "No QuickActions usages found"
    fi
    
    if [ "$OPACITY_ENUM_COUNT" -gt 0 ]; then
        print_success "Found $OPACITY_ENUM_COUNT Opacity enum usages"
    else
        print_warning "No Opacity enum usages found"
    fi
}

# Function to restore from backup
restore_backup() {
    print_header "Restoring from Backup"
    
    echo "Available backups:"
    ls -1 "$PROJECT_ROOT"/.color-migration-backup-* 2>/dev/null || {
        print_error "No backups found"
        exit 1
    }
    
    echo ""
    echo "Enter backup directory name to restore (or 'cancel'):"
    read BACKUP_NAME
    
    if [ "$BACKUP_NAME" = "cancel" ]; then
        print_warning "Restore cancelled"
        exit 0
    fi
    
    BACKUP_PATH="$PROJECT_ROOT/$BACKUP_NAME"
    
    if [ ! -d "$BACKUP_PATH" ]; then
        print_error "Backup not found: $BACKUP_PATH"
        exit 1
    fi
    
    print_warning "This will overwrite current Views directory. Continue? (yes/no)"
    read CONFIRM
    
    if [ "$CONFIRM" != "yes" ]; then
        print_warning "Restore cancelled"
        exit 0
    fi
    
    rm -rf "$VIEWS_DIR"
    cp -r "$BACKUP_PATH/Views" "$PROJECT_ROOT/I Do Blueprint/"
    
    print_success "Restored from: $BACKUP_PATH"
}

# Main script
case "${1:-scan}" in
    scan)
        scan_legacy_patterns
        ;;
    list)
        list_migration_targets
        ;;
    backup)
        create_backup
        ;;
    migrate-dashboard)
        create_backup
        migrate_dashboard_colors
        verify_migration
        ;;
    migrate-guest)
        create_backup
        migrate_guest_colors
        verify_migration
        ;;
    migrate-opacity)
        create_backup
        migrate_opacity_values
        verify_migration
        ;;
    migrate-all)
        create_backup
        migrate_dashboard_colors
        migrate_guest_colors
        migrate_opacity_values
        verify_migration
        ;;
    verify)
        verify_migration
        ;;
    restore)
        restore_backup
        ;;
    *)
        echo "Usage: $0 {scan|list|backup|migrate-dashboard|migrate-guest|migrate-opacity|migrate-all|verify|restore}"
        echo ""
        echo "Commands:"
        echo "  scan              - Scan for legacy color patterns"
        echo "  list              - List files needing migration"
        echo "  backup            - Create backup of Views directory"
        echo "  migrate-dashboard - Migrate Dashboard quick action colors"
        echo "  migrate-guest     - Migrate Guest status colors"
        echo "  migrate-opacity   - Migrate hardcoded opacity values"
        echo "  migrate-all       - Run all migrations"
        echo "  verify            - Verify migration completion"
        echo "  restore           - Restore from backup"
        exit 1
        ;;
esac
