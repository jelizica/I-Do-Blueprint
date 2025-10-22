#!/usr/bin/env python3
"""
Comprehensive script to migrate all print statements to AppLogger
"""

import re
import os
import sys
from pathlib import Path

# Mapping of file patterns to logger categories
LOGGER_MAPPINGS = {
    'Repository': 'AppLogger.repository',
    'Store': 'AppLogger.general',
    'View': 'AppLogger.ui',
    'Auth': 'AppLogger.auth',
    'Dashboard': 'AppLogger.ui',
    'Tenant': 'AppLogger.auth',
    'Vendor': 'AppLogger.ui',
    'Document': 'AppLogger.storage',
}

def get_logger_for_file(filepath):
    """Determine appropriate logger based on file path"""
    path_str = str(filepath)
    
    if 'Repository' in path_str:
        return 'AppLogger.repository'
    elif 'Store' in path_str:
        return 'AppLogger.general'
    elif 'Auth' in path_str or 'Tenant' in path_str:
        return 'AppLogger.auth'
    elif 'Dashboard' in path_str or 'View' in path_str:
        return 'AppLogger.ui'
    elif 'Document' in path_str:
        return 'AppLogger.storage'
    else:
        return 'AppLogger.general'

def should_remove_print(line):
    """Determine if a print statement should be removed (placeholder actions)"""
    placeholders = [
        'Add Task', 'New Note', 'Add Event', 'Add Guest',
        'Call action', 'Email action', 'Schedule action', 'Share action',
        'View details tapped', 'Browse vendors tapped', 'Venue tapped',
        'Retry tapped', 'Dismissed', 'Generate mood board',
        'Selected mood board', 'Selected chart', 'Selected palette',
        'Search submitted', 'Importing', 'Saved guest', 'Saved expense',
        'Saved category', 'Updated expense', 'Saved:', 'Saved vendor'
    ]
    
    for placeholder in placeholders:
        if placeholder in line:
            return True
    return False

def migrate_file(filepath):
    """Migrate print statements in a single file"""
    try:
        with open(filepath, 'r') as f:
            content = f.read()
        
        original_content = content
        logger_name = get_logger_for_file(filepath)
        
        # Check if logger already exists
        has_logger = 'private let logger' in content or 'let logger' in content
        
        # Track if we made changes
        changes_made = False
        lines = content.split('\n')
        new_lines = []
        
        for i, line in enumerate(lines):
            # Skip if it's a placeholder print that should be removed
            if 'print(' in line and should_remove_print(line):
                # Comment it out instead of removing
                new_lines.append(line.replace('print(', '// TODO: Implement action - print('))
                changes_made = True
                continue
            
            # Migrate debug prints with emoji
            if 'print("🔵' in line:
                new_line = re.sub(r'print\("🔵[^"]*\]\s*([^"]+)"\)', r'logger.debug("\1")', line)
                if new_line != line:
                    new_lines.append(new_line)
                    changes_made = True
                    continue
            
            # Migrate success prints
            if 'print("✅' in line:
                new_line = re.sub(r'print\("✅[^"]*\]\s*([^"]+)"\)', r'logger.info("\1")', line)
                if new_line != line:
                    new_lines.append(new_line)
                    changes_made = True
                    continue
            
            # Migrate error prints
            if 'print("❌' in line:
                new_line = re.sub(r'print\("❌[^"]*\]\s*([^"]+)"\)', r'logger.error("\1")', line)
                if new_line != line:
                    new_lines.append(new_line)
                    changes_made = True
                    continue
            
            # Migrate warning prints
            if 'print("⚠️' in line:
                new_line = re.sub(r'print\("⚠️[^"]*\]\s*([^"]+)"\)', r'logger.warning("\1")', line)
                if new_line != line:
                    new_lines.append(new_line)
                    changes_made = True
                    continue
            
            new_lines.append(line)
        
        if changes_made:
            content = '\n'.join(new_lines)
            
            # Add logger if needed and changes were made
            if not has_logger and changes_made:
                # Find appropriate place to add logger
                if '@MainActor' in content:
                    content = content.replace(
                        '@MainActor\nfinal class',
                        f'@MainActor\nfinal class'
                    )
                    # Add after class declaration
                    content = re.sub(
                        r'(class\s+\w+[^{]*\{)',
                        r'\1\n    private let logger = ' + logger_name,
                        content,
                        count=1
                    )
                elif 'struct ' in content and 'View' in content:
                    # For views, add as a static property
                    content = re.sub(
                        r'(struct\s+\w+[^{]*\{)',
                        r'\1\n    private let logger = ' + logger_name,
                        content,
                        count=1
                    )
            
            with open(filepath, 'w') as f:
                f.write(content)
            
            return True
        
        return False
        
    except Exception as e:
        print(f"Error processing {filepath}: {e}")
        return False

def main():
    if len(sys.argv) < 2:
        print("Usage: migrate_all_prints.py <directory>")
        sys.exit(1)
    
    root_dir = Path(sys.argv[1])
    
    # Find all Swift files
    swift_files = list(root_dir.rglob('*.swift'))
    
    # Filter out test files and generated files
    swift_files = [f for f in swift_files if 'Test' not in str(f) and 'Generated' not in str(f)]
    
    migrated_count = 0
    
    for filepath in swift_files:
        if migrate_file(filepath):
            migrated_count += 1
            print(f"✅ Migrated {filepath.name}")
    
    print(f"\n✅ Migration complete: {migrated_count} files updated")

if __name__ == '__main__':
    main()
