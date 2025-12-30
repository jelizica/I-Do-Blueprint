# Scripts Directory

This directory contains utility scripts for project maintenance and development tasks.

## Script Inventory

### Active Utility Scripts

#### `convert_csv_to_xlsx.py`
**Purpose:** Converts CSV sample files to XLSX format for Excel import testing.

**Usage:**
```bash
python3 Scripts/convert_csv_to_xlsx.py
```

**Requirements:**
```bash
pip3 install openpyxl
```

**What it does:**
- Converts `SampleGuestList.csv` → `SampleGuestList.xlsx`
- Converts `SampleVendorList.csv` → `SampleVendorList.xlsx`
- Applies formatting (bold headers, auto-width columns)
- Useful when updating sample data files

**When to use:**
- After modifying CSV sample files
- When adding new sample data columns
- Before testing Excel import functionality

---

#### `audit_logging.sh`
**Purpose:** Audits the codebase for logging patterns and compliance.

**Usage:**
```bash
./Scripts/audit_logging.sh
```

**What it does:**
- Scans Swift files for print statements
- Checks for proper AppLogger usage
- Reports files that need logging migration

---

#### `security-check.sh`
**Purpose:** Performs security checks on the codebase.

**Usage:**
```bash
./Scripts/security-check.sh
```

**What it does:**
- Scans for hardcoded secrets
- Checks for insecure patterns
- Validates security best practices

---

#### `verify-tooling.sh`
**Purpose:** Verifies that required development tools are installed.

**Usage:**
```bash
./Scripts/verify-tooling.sh
```

**What it does:**
- Checks for Xcode installation
- Verifies Swift version
- Confirms SwiftLint availability
- Validates other required tools

---

#### `tokens_codemod.swift`
**Purpose:** Swift-based code transformation tool for token/design system migrations.

**Usage:**
```bash
swift Scripts/tokens_codemod.swift
```

**What it does:**
- Migrates hardcoded colors to design system tokens
- Updates spacing values to use design system constants
- Ensures consistency with `Design/DesignSystem.swift`

---

### One-Time Migration Scripts (Historical)

These scripts were used for one-time migrations and are kept for reference. They should not be run on the current codebase.

#### `migrate_all_prints.py` ⚠️ HISTORICAL
**Purpose:** Comprehensive migration of print statements to AppLogger.

**Status:** ✅ Migration completed. This script was used to migrate the entire codebase from print statements to structured logging with AppLogger.

**What it did:**
- Migrated debug prints (`🔵`) to `logger.debug()`
- Migrated success prints (`✅`) to `logger.info()`
- Migrated error prints (`❌`) to `logger.error()`
- Migrated warning prints (`⚠️`) to `logger.warning()`
- Added appropriate logger instances to classes
- Commented out placeholder action prints

**Do not run:** The codebase has already been migrated. Running this script again may cause issues.

---

#### `migrate_print_to_logger.py` ⚠️ HISTORICAL
**Purpose:** Single-file migration of print statements to AppLogger.

**Status:** ✅ Migration completed. This was a precursor to `migrate_all_prints.py` and was used for targeted file migrations.

**What it did:**
- Migrated print statements in a single file
- Added logger property if missing
- Replaced emoji-prefixed prints with logger calls

**Do not run:** Use `migrate_all_prints.py` pattern if new migrations are needed, or better yet, write code with AppLogger from the start.

---

## Script Maintenance Guidelines

### Adding New Scripts

When adding a new script:

1. **Choose the right language:**
   - **Swift:** For code transformations, AST manipulation, or tight Xcode integration
   - **Shell:** For simple file operations, git operations, or tool orchestration
   - **Python:** For data processing, CSV/Excel operations, or complex text transformations

2. **Follow naming conventions:**
   - Use kebab-case: `my-script-name.sh`
   - Use descriptive names: `convert-csv-to-xlsx.py` not `convert.py`
   - Add file extension: `.sh`, `.py`, `.swift`

3. **Make scripts executable:**
   ```bash
   chmod +x Scripts/my-script.sh
   ```

4. **Add shebang line:**
   ```bash
   #!/usr/bin/env bash
   # or
   #!/usr/bin/env python3
   # or
   #!/usr/bin/env swift
   ```

5. **Document in this README:**
   - Add to appropriate section (Active or Historical)
   - Include purpose, usage, requirements
   - Explain when to use it

6. **Add error handling:**
   - Check for required tools/dependencies
   - Validate input parameters
   - Provide helpful error messages

### Deprecating Scripts

When a script is no longer needed:

1. Move it to the "Historical" section of this README
2. Add ⚠️ warning and explanation
3. Document what it did and why it's no longer needed
4. Consider deleting if truly obsolete (after team review)

### Script Best Practices

1. **Idempotency:** Scripts should be safe to run multiple times
2. **Dry-run mode:** Consider adding `--dry-run` flag for preview
3. **Logging:** Use clear output with emoji for status (✅ ❌ ⚠️)
4. **Exit codes:** Return 0 for success, non-zero for errors
5. **Documentation:** Keep this README up to date

---

## Common Tasks

### Updating Sample Data Files

```bash
# 1. Edit CSV files in Resources/
vim "I Do Blueprint/Resources/SampleGuestList.csv"

# 2. Convert to XLSX
python3 Scripts/convert_csv_to_xlsx.py

# 3. Verify files were created
ls -lh "I Do Blueprint/Resources/"*.xlsx
```

### Running Security Checks

```bash
# Run all security checks
./Scripts/security-check.sh

# Check specific patterns
grep -r "TODO.*security" "I Do Blueprint/"
```

### Verifying Development Environment

```bash
# Check all required tools
./Scripts/verify-tooling.sh

# Check specific tool
which swiftlint
xcodebuild -version
```

---

## Troubleshooting

### Python Scripts

**Error: `ModuleNotFoundError: No module named 'openpyxl'`**
```bash
pip3 install openpyxl
```

**Error: `Permission denied`**
```bash
chmod +x Scripts/script-name.py
```

### Shell Scripts

**Error: `command not found`**
- Ensure script is executable: `chmod +x Scripts/script-name.sh`
- Run with explicit interpreter: `bash Scripts/script-name.sh`

### Swift Scripts

**Error: `swift: command not found`**
- Ensure Xcode Command Line Tools are installed:
  ```bash
  xcode-select --install
  ```

---

## Future Improvements

Potential script additions or improvements:

1. **Swift-based CSV converter:** Replace Python script with Swift using CoreXLSX
2. **Automated test runner:** Script to run specific test suites
3. **Code metrics:** Generate complexity reports
4. **Dependency updater:** Check for outdated Swift packages
5. **Documentation generator:** Auto-generate API docs from code

---

**Last Updated:** December 2025  
**Maintained By:** Development Team
