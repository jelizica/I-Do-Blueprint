#!/usr/bin/env python3
"""
AppColors to SemanticColors Migration Script
============================================

This script automates the migration from AppColors to SemanticColors
based on established patterns from Sessions 8-16.

Usage:
    python3 Scripts/migrate-appcolors-to-semantic.py [--dry-run] [--file PATH]

Options:
    --dry-run    Show what would be changed without modifying files
    --file PATH  Process only a specific file instead of all files

Patterns Implemented:
    - Text colors: textPrimary, textSecondary
    - Action colors: primary → primaryAction
    - Opacity mappings: 0.05 → verySubtle, 0.1 → subtle, 0.3 → light, 0.5/0.6 → medium, 0.9 → strong
    - Skips: AppColors.Budget.* (budget-specific colors)
"""

import os
import re
import sys
import argparse
from pathlib import Path
from dataclasses import dataclass
from typing import List, Tuple, Optional

# ============================================================================
# CONFIGURATION
# ============================================================================

PROJECT_ROOT = Path(__file__).parent.parent
VIEWS_DIR = PROJECT_ROOT / "I Do Blueprint" / "Views"

# Files/patterns to skip (domain-specific colors that should NOT be migrated)
SKIP_PATTERNS = [
    "AppColors.Budget.",  # Budget-specific colors - don't migrate
    "AppColors.Vendor.",  # Vendor-specific colors - don't migrate
    "AppColors.Guest.",   # Guest-specific colors - don't migrate
    "AppColors.Avatar.",  # Avatar-specific colors - don't migrate
    "AppColors.Task.",    # Task-specific colors - don't migrate
]

# ============================================================================
# REPLACEMENT RULES
# ============================================================================

@dataclass
class ReplacementRule:
    """A single replacement rule with pattern and replacement."""
    name: str
    pattern: str
    replacement: str
    description: str

# Direct color mappings (no opacity)
DIRECT_MAPPINGS = [
    # Text colors
    ReplacementRule(
        name="textPrimary",
        pattern=r"AppColors\.textPrimary(?!\.)",
        replacement="SemanticColors.textPrimary",
        description="Primary text color"
    ),
    ReplacementRule(
        name="textSecondary",
        pattern=r"AppColors\.textSecondary(?!\.)",
        replacement="SemanticColors.textSecondary",
        description="Secondary text color"
    ),
    ReplacementRule(
        name="textTertiary",
        pattern=r"AppColors\.textTertiary(?!\.)",
        replacement="SemanticColors.textTertiary",
        description="Tertiary text color"
    ),
    
    # Action colors
    ReplacementRule(
        name="primary_action",
        pattern=r"AppColors\.primary(?!\.)",
        replacement="SemanticColors.primaryAction",
        description="Primary action color"
    ),
    ReplacementRule(
        name="secondary_action",
        pattern=r"AppColors\.secondary(?!\.)",
        replacement="SemanticColors.secondaryAction",
        description="Secondary action color"
    ),
    ReplacementRule(
        name="accent",
        pattern=r"AppColors\.accent(?!\.)",
        replacement="SemanticColors.accent",
        description="Accent color"
    ),
    
    # Status colors
    ReplacementRule(
        name="success",
        pattern=r"AppColors\.success(?!\.)",
        replacement="SemanticColors.success",
        description="Success color"
    ),
    ReplacementRule(
        name="warning",
        pattern=r"AppColors\.warning(?!\.)",
        replacement="SemanticColors.warning",
        description="Warning color"
    ),
    ReplacementRule(
        name="error",
        pattern=r"AppColors\.error(?!\.)",
        replacement="SemanticColors.error",
        description="Error color"
    ),
    ReplacementRule(
        name="info",
        pattern=r"AppColors\.info(?!\.)",
        replacement="SemanticColors.info",
        description="Info color"
    ),
    
    # Light variants
    ReplacementRule(
        name="errorLight",
        pattern=r"AppColors\.errorLight(?!\.)",
        replacement="SemanticColors.errorLight",
        description="Light error color"
    ),
    ReplacementRule(
        name="successLight",
        pattern=r"AppColors\.successLight(?!\.)",
        replacement="SemanticColors.successLight",
        description="Light success color"
    ),
    ReplacementRule(
        name="warningLight",
        pattern=r"AppColors\.warningLight(?!\.)",
        replacement="SemanticColors.warningLight",
        description="Light warning color"
    ),
    ReplacementRule(
        name="infoLight",
        pattern=r"AppColors\.infoLight(?!\.)",
        replacement="SemanticColors.infoLight",
        description="Light info color"
    ),
    
    # Background colors
    ReplacementRule(
        name="background",
        pattern=r"AppColors\.background(?!\.)",
        replacement="SemanticColors.background",
        description="Background color"
    ),
    ReplacementRule(
        name="backgroundSecondary",
        pattern=r"AppColors\.backgroundSecondary(?!\.)",
        replacement="SemanticColors.backgroundSecondary",
        description="Secondary background color"
    ),
    ReplacementRule(
        name="cardBackground",
        pattern=r"AppColors\.cardBackground(?!\.)",
        replacement="SemanticColors.cardBackground",
        description="Card background color"
    ),
    
    # Border/Divider colors
    ReplacementRule(
        name="border",
        pattern=r"AppColors\.border(?!\.)",
        replacement="SemanticColors.border",
        description="Border color"
    ),
    ReplacementRule(
        name="divider",
        pattern=r"AppColors\.divider(?!\.)",
        replacement="SemanticColors.divider",
        description="Divider color"
    ),
    
    # Shadow colors
    ReplacementRule(
        name="shadowLight",
        pattern=r"AppColors\.shadowLight(?!\.)",
        replacement="SemanticColors.shadowLight",
        description="Light shadow color"
    ),
    ReplacementRule(
        name="shadow",
        pattern=r"AppColors\.shadow(?!\.)",
        replacement="SemanticColors.shadow",
        description="Shadow color"
    ),
    
    # Interactive states
    ReplacementRule(
        name="hover",
        pattern=r"AppColors\.hover(?!\.)",
        replacement="SemanticColors.hover",
        description="Hover state color"
    ),
    ReplacementRule(
        name="pressed",
        pattern=r"AppColors\.pressed(?!\.)",
        replacement="SemanticColors.pressed",
        description="Pressed state color"
    ),
    ReplacementRule(
        name="disabled",
        pattern=r"AppColors\.disabled(?!\.)",
        replacement="SemanticColors.disabled",
        description="Disabled state color"
    ),
    ReplacementRule(
        name="selected",
        pattern=r"AppColors\.selected(?!\.)",
        replacement="SemanticColors.selected",
        description="Selected state color"
    ),
]

# Opacity mappings - these need special handling
OPACITY_MAPPINGS = {
    "0.05": "Opacity.verySubtle",
    "0.08": "Opacity.verySubtle",  # Close to 0.05
    "0.1": "Opacity.subtle",
    "0.15": "Opacity.subtle",      # Close to 0.1
    "0.2": "Opacity.subtle",       # Close to 0.1
    "0.25": "Opacity.light",       # Close to 0.3
    "0.3": "Opacity.light",
    "0.4": "Opacity.light",        # Close to 0.3
    "0.5": "Opacity.medium",
    "0.6": "Opacity.medium",
    "0.7": "Opacity.medium",       # Close to 0.6
    "0.8": "Opacity.strong",       # Close to 0.9
    "0.9": "Opacity.strong",
}

# Colors that support opacity mappings
COLORS_WITH_OPACITY = [
    ("textPrimary", "SemanticColors.textPrimary"),
    ("textSecondary", "SemanticColors.textSecondary"),
    ("textTertiary", "SemanticColors.textTertiary"),
    ("primary", "SemanticColors.primaryAction"),
    ("secondary", "SemanticColors.secondaryAction"),
    ("accent", "SemanticColors.accent"),
    ("success", "SemanticColors.success"),
    ("warning", "SemanticColors.warning"),
    ("error", "SemanticColors.error"),
    ("info", "SemanticColors.info"),
    ("background", "SemanticColors.background"),
    ("border", "SemanticColors.border"),
    ("divider", "SemanticColors.divider"),
]

# ============================================================================
# MIGRATION LOGIC
# ============================================================================

@dataclass
class MigrationResult:
    """Result of a single file migration."""
    file_path: Path
    replacements_made: int
    skipped_instances: List[Tuple[int, str, str]]  # (line_num, line_content, reason)
    errors: List[str]

def should_skip_line(line: str) -> Optional[str]:
    """Check if a line should be skipped. Returns reason if skip, None otherwise."""
    for pattern in SKIP_PATTERNS:
        if pattern in line:
            return f"Contains {pattern} (domain-specific color)"
    return None

def apply_direct_mappings(line: str) -> Tuple[str, int]:
    """Apply direct color mappings to a line. Returns (new_line, count)."""
    count = 0
    for rule in DIRECT_MAPPINGS:
        matches = len(re.findall(rule.pattern, line))
        if matches > 0:
            line = re.sub(rule.pattern, rule.replacement, line)
            count += matches
    return line, count

def apply_opacity_mapping(line: str) -> Tuple[str, int, List[str]]:
    """
    Apply opacity mappings to a line.
    Returns (new_line, count, unhandled_patterns).
    """
    count = 0
    unhandled = []
    
    # Pattern: AppColors.colorName.opacity(X.XX)
    # Replace with: SemanticColors.colorName.opacity(Opacity.level)
    
    # Handle textPrimary with opacity
    for opacity_val, opacity_const in OPACITY_MAPPINGS.items():
        pattern = rf"AppColors\.textPrimary\.opacity\({opacity_val}\)"
        if re.search(pattern, line):
            line = re.sub(pattern, f"SemanticColors.textPrimary.opacity({opacity_const})", line)
            count += 1
    
    # Handle textSecondary with opacity
    for opacity_val, opacity_const in OPACITY_MAPPINGS.items():
        pattern = rf"AppColors\.textSecondary\.opacity\({opacity_val}\)"
        if re.search(pattern, line):
            line = re.sub(pattern, f"SemanticColors.textSecondary.opacity({opacity_const})", line)
            count += 1
    
    # Handle primary with opacity
    for opacity_val, opacity_const in OPACITY_MAPPINGS.items():
        pattern = rf"AppColors\.primary\.opacity\({opacity_val}\)"
        if re.search(pattern, line):
            line = re.sub(pattern, f"SemanticColors.primaryAction.opacity({opacity_const})", line)
            count += 1
    
    # Check for any remaining AppColors.*.opacity patterns that weren't handled
    remaining_opacity = re.findall(r"AppColors\.\w+\.opacity\([\d.]+\)", line)
    for pattern in remaining_opacity:
        if "SemanticColors" not in line or pattern in line:
            unhandled.append(pattern)
    
    return line, count, unhandled

def migrate_line(line: str, line_num: int) -> Tuple[str, int, Optional[Tuple[int, str, str]]]:
    """
    Migrate a single line.
    Returns (new_line, replacement_count, skipped_info or None).
    """
    # Check if line should be skipped
    skip_reason = should_skip_line(line)
    if skip_reason and "AppColors" in line:
        return line, 0, (line_num, line.strip(), skip_reason)
    
    # Check if line contains AppColors at all
    if "AppColors" not in line:
        return line, 0, None
    
    total_count = 0
    
    # Apply direct mappings first
    line, direct_count = apply_direct_mappings(line)
    total_count += direct_count
    
    # Apply opacity mappings
    line, opacity_count, unhandled = apply_opacity_mapping(line)
    total_count += opacity_count
    
    # Check for any remaining AppColors that weren't handled
    if "AppColors" in line:
        # Extract the specific pattern that wasn't handled
        remaining = re.findall(r"AppColors\.\w+(?:\.\w+)*(?:\([^)]*\))?", line)
        for pattern in remaining:
            if "SemanticColors" not in pattern:
                return line, total_count, (line_num, line.strip(), f"Unhandled pattern: {pattern}")
    
    return line, total_count, None

def migrate_file(file_path: Path, dry_run: bool = False) -> MigrationResult:
    """Migrate a single file."""
    result = MigrationResult(
        file_path=file_path,
        replacements_made=0,
        skipped_instances=[],
        errors=[]
    )
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        result.errors.append(f"Failed to read file: {e}")
        return result
    
    new_lines = []
    for i, line in enumerate(lines, 1):
        new_line, count, skipped = migrate_line(line, i)
        new_lines.append(new_line)
        result.replacements_made += count
        if skipped:
            result.skipped_instances.append(skipped)
    
    # Write back if not dry run and changes were made
    if not dry_run and result.replacements_made > 0:
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.writelines(new_lines)
        except Exception as e:
            result.errors.append(f"Failed to write file: {e}")
    
    return result

def find_swift_files_with_appcolors(directory: Path) -> List[Path]:
    """Find all Swift files containing AppColors."""
    files = []
    for swift_file in directory.rglob("*.swift"):
        try:
            content = swift_file.read_text(encoding='utf-8')
            if "AppColors." in content:
                files.append(swift_file)
        except Exception:
            pass
    return files

def count_appcolors_instances(file_path: Path) -> int:
    """Count AppColors instances in a file."""
    try:
        content = file_path.read_text(encoding='utf-8')
        return len(re.findall(r"AppColors\.", content))
    except Exception:
        return 0

# ============================================================================
# MAIN
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Migrate AppColors to SemanticColors"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be changed without modifying files"
    )
    parser.add_argument(
        "--file",
        type=str,
        help="Process only a specific file"
    )
    parser.add_argument(
        "--list-files",
        action="store_true",
        help="List all files with AppColors and their instance counts"
    )
    parser.add_argument(
        "--output-skipped",
        type=str,
        help="Output skipped instances to a file (e.g., skipped.md)"
    )
    args = parser.parse_args()
    
    print("=" * 70)
    print("AppColors → SemanticColors Migration Script")
    print("=" * 70)
    print()
    
    if args.list_files:
        print("Files containing AppColors:")
        print("-" * 70)
        files = find_swift_files_with_appcolors(VIEWS_DIR)
        files.sort(key=lambda f: count_appcolors_instances(f), reverse=True)
        total = 0
        for f in files:
            count = count_appcolors_instances(f)
            total += count
            rel_path = f.relative_to(PROJECT_ROOT)
            print(f"  {count:3d} instances: {rel_path}")
        print("-" * 70)
        print(f"Total: {total} instances in {len(files)} files")
        return
    
    if args.file:
        file_path = Path(args.file)
        if not file_path.is_absolute():
            file_path = PROJECT_ROOT / file_path
        files = [file_path]
        if not files[0].exists():
            print(f"Error: File not found: {args.file}")
            sys.exit(1)
    else:
        files = find_swift_files_with_appcolors(VIEWS_DIR)
    
    if args.dry_run:
        print("DRY RUN MODE - No files will be modified")
        print()
    
    total_replacements = 0
    total_skipped = []
    files_modified = 0
    
    for file_path in files:
        before_count = count_appcolors_instances(file_path)
        if before_count == 0:
            continue
        
        result = migrate_file(file_path, dry_run=args.dry_run)
        
        if result.replacements_made > 0:
            files_modified += 1
            rel_path = file_path.relative_to(PROJECT_ROOT)
            print(f"✓ {rel_path}")
            print(f"  Replaced: {result.replacements_made} instances")
            total_replacements += result.replacements_made
        
        if result.skipped_instances:
            for line_num, line_content, reason in result.skipped_instances:
                total_skipped.append((file_path, line_num, line_content, reason))
        
        if result.errors:
            for error in result.errors:
                print(f"  ✗ Error: {error}")
    
    print()
    print("=" * 70)
    print("SUMMARY")
    print("=" * 70)
    print(f"Files processed: {len(files)}")
    print(f"Files modified: {files_modified}")
    print(f"Total replacements: {total_replacements}")
    print(f"Skipped instances: {len(total_skipped)}")
    
    if total_skipped:
        print()
        print("=" * 70)
        print("SKIPPED INSTANCES (require manual review)")
        print("=" * 70)
        for file_path, line_num, line_content, reason in total_skipped:
            rel_path = file_path.relative_to(PROJECT_ROOT)
            print(f"\n📍 {rel_path}:{line_num}")
            print(f"   Reason: {reason}")
            print(f"   Line: {line_content[:100]}{'...' if len(line_content) > 100 else ''}")
    
    print()
    if args.dry_run:
        print("This was a DRY RUN. Run without --dry-run to apply changes.")
    else:
        print("Migration complete. Run 'xcodebuild build' to verify.")

if __name__ == "__main__":
    main()
