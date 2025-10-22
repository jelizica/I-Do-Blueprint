#!/usr/bin/env python3
"""
Script to migrate print statements to AppLogger in Swift files
"""

import re
import sys

def migrate_prints_to_logger(content):
    """Replace print statements with AppLogger calls"""
    
    # Add logger property if not present
    if 'private let logger' not in content and 'actor LiveSettingsRepository' in content:
        content = content.replace(
            'actor LiveSettingsRepository: SettingsRepositoryProtocol {\n    private let supabase: SupabaseClient?',
            'actor LiveSettingsRepository: SettingsRepositoryProtocol {\n    private let supabase: SupabaseClient?\n    private let logger = AppLogger.repository'
        )
    
    # Pattern mappings for different print types
    replacements = [
        # Debug prints with emoji
        (r'print\("🔵 \[SettingsRepo\] ([^"]+)"\)', r'logger.debug("\1")'),
        # Success prints
        (r'print\("✅ \[SettingsRepo\] ([^"]+)"\)', r'logger.info("\1")'),
        # Error prints
        (r'print\("❌ \[SettingsRepo\] ([^"]+)"\)', r'logger.error("\1")'),
        # Warning prints
        (r'print\("⚠️ \[SettingsRepo\] ([^"]+)"\)', r'logger.warning("\1")'),
    ]
    
    for pattern, replacement in replacements:
        content = re.sub(pattern, replacement, content)
    
    return content

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: migrate_print_to_logger.py <file_path>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    migrated_content = migrate_prints_to_logger(content)
    
    with open(file_path, 'w') as f:
        f.write(migrated_content)
    
    print(f"✅ Migrated {file_path}")
