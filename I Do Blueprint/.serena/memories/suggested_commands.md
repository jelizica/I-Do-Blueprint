# I Do Blueprint - Suggested Commands

## Building and Running

### Build Project
```bash
# Build for Debug (development)
xcodebuild -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -configuration Debug build

# Build for Release (production)
xcodebuild -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -configuration Release build

# Build in Xcode (recommended)
⌘B (or Product → Build)
```

### Run Project
```bash
# Run in Xcode (recommended)
⌘R (or Product → Run)

# Minimum window size: 800x600
# Requires macOS 13.0+
```

## Testing

### Run All Tests
```bash
# Command line
xcodebuild test -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS'

# Xcode (recommended)
⌘U (or Product → Test)
```

### Run Specific Tests
```bash
# In Xcode: Click diamond icon next to test function/class

# Command line (example)
xcodebuild test -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS' -only-testing:I\ Do\ BlueprintTests/BudgetStoreV2Tests
```

### UI Tests
```bash
# Run UI tests
xcodebuild test -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS' -only-testing:I\ Do\ BlueprintUITests

# Xcode
⌘U on I Do BlueprintUITests target
```

## Development Tools

### Clean Build
```bash
# Xcode
⇧⌘K (or Product → Clean Build Folder)

# Command line
xcodebuild clean -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint"
```

### Package Resolution
```bash
# Reset and resolve Swift Package Manager dependencies
xcodebuild -resolvePackageDependencies -project "I Do Blueprint.xcodeproj"

# Or in Xcode: File → Packages → Reset Package Caches
# Then: File → Packages → Resolve Package Versions
```

### Logging Audit
```bash
# Audit debug logging (find excessive logging)
./Scripts/audit_logging.sh

# Target: <50 debug logs in production code
```

## Code Quality

### Format Code
- Use Xcode's built-in formatting (⌃I to re-indent)
- Follow SwiftLint rules (if configured)
- Use MARK comments for organization

### Run Static Analysis
```bash
# Xcode
Product → Analyze (⇧⌘B)
```

## macOS Utilities

### File Operations
```bash
# Find files
find . -name "*.swift" -type f

# Search content
grep -r "pattern" --include="*.swift" "I Do Blueprint"

# List directories
ls -la

# View file
cat filename.swift
```

### Git Operations
```bash
# Status
git status

# View changes
git diff

# Commit
git add .
git commit -m "message"

# Push
git push origin main
```

## Configuration

### Environment Setup
1. **Config.plist** - Contains Supabase credentials
   - `SUPABASE_URL`: Backend URL
   - `SUPABASE_ANON_KEY`: Anonymous API key

2. **Google OAuth** - Configure in Google Cloud Console
   - Create OAuth 2.0 credentials
   - Add redirect URI for macOS app

3. **Multi-tenant** - Each couple has unique `couple_id`

### Dependencies
```bash
# View installed packages
xcodebuild -project "I Do Blueprint.xcodeproj" -list

# Update packages (Xcode)
File → Packages → Update to Latest Package Versions
```

## Troubleshooting

### Common Issues
```bash
# "No such module" errors
# → Reset package caches and resolve dependencies

# Build failures
# → Clean build folder (⇧⌘K)
# → Delete derived data: ~/Library/Developer/Xcode/DerivedData

# Credentials errors
# → Check Config.plist has valid Supabase credentials
# → Check Google OAuth configuration
```

## Performance Profiling
```bash
# Xcode Instruments
⌘I (or Product → Profile)

# Common instruments:
# - Time Profiler (CPU usage)
# - Allocations (Memory usage)
# - Leaks (Memory leaks)
# - Network (API calls)
```

## Targets
- **I Do Blueprint** - Main application target
- **I Do BlueprintTests** - Unit and integration tests
- **I Do BlueprintUITests** - UI tests

## Schemes
- **I Do Blueprint** - Main scheme (use for building/testing)
- **MarkdownUI** - Dependency scheme
- **SwiftUICharts** - Dependency scheme
