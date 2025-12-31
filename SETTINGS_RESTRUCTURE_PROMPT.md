# I Do Blueprint Settings Restructure - Enhanced Prompt

## Task Overview
Analyze the I Do Blueprint macOS wedding planning app's settings tabs and restructure them into logical, nested groups that mirror the hierarchical organization of the "Global Settings - Overview" tab.

## Project Context

### Application Architecture
- **Platform:** macOS 13.0+ SwiftUI application
- **Architecture:** MVVM with Repository Pattern, Domain Services, Dependency Injection
- **Backend:** Supabase (PostgreSQL with Row Level Security)
- **Multi-tenancy:** All data scoped by `couple_id` for wedding isolation
- **State Management:** `@MainActor` stores with `@Published` properties via `AppStores.shared`

### Current Settings Structure

The app currently has **16 flat settings sections** in a sidebar navigation:

```swift
// From SettingsModels.swift
enum SettingsSection: String, CaseIterable {
    case global = "Global"              // ✅ HAS NESTED STRUCTURE (Overview, Wedding Events)
    case theme = "Theme"
    case budget = "Budget"
    case tasks = "Tasks"
    case vendors = "Vendors"
    case vendorCategories = "Categories"
    case guests = "Guests"
    case documents = "Documents"
    case collaboration = "Collaboration"
    case notifications = "Notifications"
    case links = "Links"
    case apiKeys = "API Keys"
    case account = "Account"
    case featureFlags = "Feature Flags"
    case danger = "Danger Zone"
}
```

**Only "Global" currently has nested subsections** (Overview, Wedding Events). All others are flat.

### Current Nested Structure Example (Global Settings)

The "Global" section demonstrates the target pattern:

```swift
enum GlobalSubsection: String, CaseIterable {
    case overview = "Overview"         // Partner names, currency, wedding date, timezone
    case weddingEvents = "Wedding Events"  // Multiple events (ceremony, reception, etc.)
}
```

**UI Pattern:**
- Sidebar uses `DisclosureGroup` for expandable parent sections
- Subsections indent 20px and show on selection
- Active subsection highlighted with accent color
- Detail view shows `NavigationTitle` like "Global - Overview"

## Detailed Settings Inventory

### 1. Global Settings (✅ Already Nested)
**Purpose:** Core wedding information and global preferences
- **Overview Subsection:**
  - Current Wedding (multi-tenant selection)
  - Partner 1 & 2 names (full + nickname)
  - Wedding Date (with TBD toggle)
  - Currency (used app-wide)
  - Timezone (affects all date display)
- **Wedding Events Subsection:**
  - Ceremony, Reception, Rehearsal Dinner, etc.
  - Event date, time, location

**Data Dependencies:** Partner names → used in Budget/Tasks. Currency → all financial data. Timezone → all date formatting.

---

### 2. Account Settings
**Purpose:** Authentication and user account management
- Authentication status (signed in/out)
- Email address
- User ID (truncated for security)
- Sign Out button (clears Supabase session, SessionManager, repository caches, AppCoordinator)

**Data Dependencies:** Authentication affects all data access. Logout triggers app-wide state reset.

---

### 3. Budget & Cash Flow Settings
**Purpose:** Budget configuration and financial settings
- **Budget Configuration:**
  - Base budget amount
  - Engagement rings inclusion toggle
  - Engagement ring amount (conditional)
  - Total budget (calculated)
  - Auto-categorize expenses toggle
  - Payment reminders toggle
  - Budget notes (text editor)
- **Tax Rates:**
  - Custom tax rates (name + percentage)
  - Default tax rate selection
  - Add/edit/delete with validation
- **Monthly Cash Flow Defaults:**
  - Partner 1 monthly contribution
  - Partner 2 monthly contribution
  - Interest/returns monthly
  - Gifts/contributions monthly
- **Link to Budget Categories**

**Data Dependencies:** Uses partner names from Global. Uses currency from Global. Tax rates apply to expense calculations. Cash flow defaults pre-fill payment schedules.

---

### 4. Budget Categories Settings
**Purpose:** Manage budget categories and subcategories
- **Category Management:**
  - Parent categories (folders)
  - Subcategories (nested items)
  - Category name, description, color
  - Search and filter
  - Selection mode for batch operations
- **Batch Operations:**
  - Multi-select categories
  - Batch delete with dependency validation
  - Shows counts of selected/deletable/blocked
- **Dependency Tracking:**
  - Expense count per category
  - Budget item count per category
  - Task count per category
  - Vendor count per category
  - Subcategory count
  - Prevents deletion if dependencies exist

**Data Dependencies:** Used by Budget Settings. Referenced by expenses, budget items, tasks, vendors.

---

### 5. Guests Settings
**Purpose:** Guest management preferences and meal options
- **Display Preferences:**
  - Default view (list/table)
  - Show meal preferences toggle
  - RSVP reminders toggle
- **Custom Meal Options:**
  - Add/edit/delete meal selections
  - Auto title-case formatting
  - Duplicate prevention (case-insensitive)
  - Default: Chicken, Beef, Fish, Vegetarian, Vegan

**Data Dependencies:** Meal options available in guest forms. RSVP reminders trigger notifications.

---

### 6. Vendors Settings
**Purpose:** Vendor management preferences
- **Display Preferences:**
  - Default view (grid/list)
  - Show payment status toggle
  - Auto reminders toggle
- **Phone Formatting:**
  - Automatic E.164 formatting (no manual action needed)

**Data Dependencies:** Works with Vendor Categories. Phone formatting applies to guests and vendors.

---

### 7. Vendor Categories Settings
**Purpose:** Standard and custom vendor category management
- **Standard Categories (18 predefined):**
  - Venue, Catering, Photography, Videography, Music & Entertainment
  - Florist, Baker, Attire, Hair & Makeup, Stationery
  - Transportation, Accommodation, Officiant, Rentals
  - Planner/Coordinator, Jewelry, Favors & Gifts, Other Services
  - Hide/show toggles for each
- **Custom Categories:**
  - Add categories not in standard list
  - Name, description, typical budget percentage
  - Edit/delete with vendor usage validation
  - Prevents deletion if vendors assigned

**Data Dependencies:** Used by Vendors. Validates category usage before deletion.

---

### 8. Tasks Settings
**Purpose:** Task management preferences and assignees
- **Display Preferences:**
  - Default view (kanban/list)
  - Show completed tasks toggle
  - Notifications enabled toggle
- **Custom Responsible Parties:**
  - Add/remove assignees (beyond couples)
  - Examples: Wedding Planner, Mom, Best Man
  - Available in task assignment dropdowns

**Data Dependencies:** Responsible parties extend task assignees. Notifications use global notification settings.

---

### 9. Documents Settings
**Purpose:** Document management and vendor behavior
- **Document Management:**
  - Auto-organize toggle
  - Cloud backup toggle
  - Retention period (days)
- **Vendor Behavior:**
  - Enforce consistency toggle
  - Allow inheritance toggle
  - Prefer expense vendor toggle
  - Enable validation logging toggle

**Data Dependencies:** Vendor behavior affects document-vendor relationships. Works with Vendors section.

---

### 10. Theme Settings
**Purpose:** Appearance and color preferences
- **Visual Appearance:**
  - Color scheme (default/blue/purple/pink)
  - Dark mode toggle

**Data Dependencies:** App-wide theme application. No dependencies on other settings.

---

### 11. Notifications Settings
**Purpose:** Notification preferences
- **Notification Channels:**
  - Email notifications toggle
  - Push notifications toggle
- **Digest Frequency:** (daily/weekly/monthly)

**Data Dependencies:** Controls notifications from Budget, Tasks, Guests, Vendors sections.

---

### 12. Collaboration Settings
**Purpose:** Multi-user collaboration features
- **My Collaborations:**
  - View all weddings user is collaborating on
  - Shows pending invitation count badge
  - Opens as sheet for invitation management
- **Team Management:**
  - Manage collaborators for current wedding
  - Opens as sheet for team administration

**Data Dependencies:** Multi-tenant collaboration. Real-time invitation tracking. Works with Account section.

---

### 13. API Keys Settings
**Purpose:** Third-party integration API keys
- **API Keys (stored in macOS Keychain):**
  - Unsplash API (wedding inspiration photos)
  - Pinterest API (board sync)
  - Vendor API (marketplace integration)
  - Resend API (optional custom email domain)
- **Security Features:**
  - Keychain storage (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`)
  - Validation before storage
  - Add/remove with confirmation
  - Masked input (SecureField)

**Data Dependencies:** Enables third-party integrations. Optional Resend key (shared service fallback).

---

### 14. Feature Flags Settings
**Purpose:** Enable/disable features for testing
- **Store Architecture:**
  - Budget Store V2 toggle
  - Guest Store V2 toggle
  - Vendor Store V2 toggle
- **Completed Features (all enabled by default):**
  - Timeline milestones
  - Advanced budget export
  - Visual planning paste
  - Image picker
  - Template application
  - Expense details
  - Budget analytics actions
- **Reset All:** Reset to defaults

**Data Dependencies:** Developer/testing tool. Immediate effect (no restart). Stored in UserDefaults.

---

### 15. Danger Zone Settings
**Purpose:** Irreversible destructive actions
- **Delete Account (Most Destructive):**
  - Requires biometric/password authentication
  - Confirmation text: "DELETE MY ACCOUNT"
  - Deletes: All wedding data, account, credentials, settings, couple profile
  - Signs out user automatically
- **Delete My Data (Less Destructive):**
  - Requires biometric/password authentication
  - Confirmation text: "DELETE MY DATA"
  - Options to preserve:
    - Budget Sandbox data
    - Affordability calculator data
    - Custom categories
  - Keeps account intact

**Data Dependencies:** Affects all data. Irreversible. Authentication required.

---

### 16. Important Links Settings
**Purpose:** Bookmark important wedding-related URLs
- **Link Management:**
  - Title, URL, optional description
  - Add/edit/delete links
  - URL validation (http/https required)
  - Click to open external URLs
- **Examples:** Registry, venue website, Pinterest boards, vendor sites

**Data Dependencies:** None. Standalone utility feature.

---

## Logical Grouping Patterns (Analysis)

### By User Workflow:
1. **Setup & Core Info:** Global, Account
2. **Financial Planning:** Budget & Cash Flow, Budget Categories, Vendors, Vendor Categories
3. **People & Collaboration:** Guests, Tasks, Collaboration
4. **Appearance & Experience:** Theme, Notifications
5. **Data & Organization:** Documents, Important Links
6. **Advanced/Developer:** API Keys, Feature Flags
7. **Danger/Destructive:** Danger Zone

### By Data Dependencies:
1. **Foundation Layer:** Account, Global (affects all others)
2. **Feature Layer:** Budget, Guests, Vendors, Tasks, Documents
3. **Configuration Layer:** Categories, Meal Options, Responsible Parties
4. **Integration Layer:** API Keys, Collaboration
5. **System Layer:** Theme, Notifications, Feature Flags
6. **Utility Layer:** Important Links
7. **Destructive Layer:** Danger Zone

### By Common Configuration Patterns:
- **Display Preferences:** Guests, Vendors, Tasks (all have default view + toggle settings)
- **Category Management:** Budget Categories, Vendor Categories (hierarchical + dependency validation)
- **Reminders/Notifications:** Budget, Guests, Vendors, Tasks (all have reminder toggles)
- **Security/Authentication:** Account, API Keys, Danger Zone (all use authentication)

---

## Proposed Nested Hierarchy

### Option 1: Feature-First Grouping
```
Settings
├── Wedding Setup (Global)
│   ├── Overview (current wedding, partners, date, currency, timezone)
│   └── Wedding Events (ceremony, reception, etc.)
├── Account & Security
│   ├── Profile (authentication, email, user ID)
│   ├── Collaboration (team management, invitations)
│   └── Danger Zone (delete account/data)
├── Financial Planning
│   ├── Budget & Cash Flow (base budget, tax rates, contributions)
│   ├── Budget Categories (parent/child categories, dependencies)
│   ├── Vendors (display, reminders, phone formatting)
│   └── Vendor Categories (standard + custom categories)
├── People & Tasks
│   ├── Guests (display, meal options, RSVP reminders)
│   └── Tasks (display, responsible parties, notifications)
├── Appearance & Notifications
│   ├── Theme (color scheme, dark mode)
│   └── Notifications (email, push, digest frequency)
├── Data Management
│   ├── Documents (auto-organize, vendor behavior, retention)
│   └── Important Links (bookmarks, registry, vendor sites)
└── Advanced
    ├── API Keys (Unsplash, Pinterest, Vendor, Resend)
    └── Feature Flags (V2 stores, feature toggles)
```

### Option 2: Workflow-First Grouping
```
Settings
├── Getting Started (Global)
│   ├── Wedding Overview (current wedding, partners, date)
│   ├── Wedding Events (ceremony, reception)
│   └── Regional Preferences (currency, timezone)
├── My Account
│   ├── Profile & Sign In (authentication, email)
│   ├── Team Collaboration (collaborators, invitations)
│   └── Account Management (delete account/data)
├── Budget & Finances
│   ├── Budget Setup (base budget, rings, tax rates)
│   ├── Cash Flow (partner contributions, defaults)
│   ├── Categories (budget + vendor categories)
│   └── Vendors (display, categories, reminders)
├── Guest Management
│   ├── Display & Preferences (view, RSVP reminders)
│   └── Meal Options (custom meal selections)
├── Task Planning
│   ├── Display & Preferences (view, show completed)
│   └── Team Members (responsible parties)
├── Documents & Links
│   ├── Document Settings (auto-organize, retention)
│   └── Important Links (bookmarks, external sites)
├── Appearance
│   ├── Theme (color scheme, dark mode)
│   └── Notifications (channels, digest frequency)
└── Developer & Advanced
    ├── API Integrations (Unsplash, Pinterest, Vendor, Resend)
    ├── Feature Flags (V2 stores, experimental features)
    └── Danger Zone (delete account/data)
```

### Option 3: Hybrid Grouping (Recommended)
```
Settings
├── Wedding Setup (Global) ✅ Already nested
│   ├── Overview
│   └── Wedding Events
├── Account
│   ├── Profile & Authentication
│   ├── Collaboration & Team
│   └── Data & Privacy (Danger Zone)
├── Budget & Vendors
│   ├── Budget Configuration
│   ├── Budget Categories
│   ├── Vendor Management
│   └── Vendor Categories
├── Guests & Tasks
│   ├── Guest Preferences
│   ├── Task Preferences
│   └── Team Members (combined responsible parties)
├── Appearance & Notifications
│   ├── Theme
│   └── Notifications
├── Data & Content
│   ├── Documents
│   └── Important Links
└── Developer & Advanced
    ├── API Keys
    └── Feature Flags
```

---

## Implementation Instructions

### Step 1: MCP Analysis Using Available Tools

**Use ADR Analysis MCP for architectural decisions:**
```swift
// Query existing architecture patterns
mcp__adr-analysis__analyze_project_ecosystem(
    projectPath: "/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint",
    analysisScope: ["architecture", "settings"],
    recursiveDepth: "comprehensive"
)

// Document restructuring decision
mcp__adr-analysis__suggest_adrs(
    analysisType: "comprehensive",
    projectPath: "/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint"
)
```

**Use Grep MCP for code search:**
```swift
// Find all settings view files
mcp__greb-mcp__code_search(
    query: "SettingsView inheritance patterns",
    keywords: {
        primary_terms: ["settings", "view", "subsection"],
        code_patterns: ["case \\\".*\\\"", "enum SettingsSection"],
        file_patterns: ["*.swift"],
        intent: "Find all settings views and their structure"
    },
    directory: "/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint"
)
```

**Use Supabase MCP for data dependencies:**
```swift
// Check database schema for settings relationships
mcp__supabase__list_tables(schemas: ["public"])

// Analyze settings table structure
mcp__supabase__execute_sql(
    query: "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'user_settings'"
)
```

**Use Basic Memory MCP for knowledge management:**
```swift
// Document current structure
mcp__basic-memory__write_note(
    title: "Settings Structure Analysis - Pre-Restructure",
    content: "[Analysis results]",
    folder: "architecture/settings",
    project: "i-do-blueprint",
    tags: ["settings", "ui", "architecture"]
)

// Document proposed structure
mcp__basic-memory__write_note(
    title: "Settings Restructure - Proposed Hierarchy",
    content: "[Proposed nested structure]",
    folder: "architecture/settings",
    project: "i-do-blueprint",
    tags: ["settings", "ui", "architecture", "proposal"]
)

// Document implementation plan
mcp__basic-memory__write_note(
    title: "Settings Restructure - Implementation Roadmap",
    content: "[Step-by-step implementation guide]",
    folder: "architecture/settings",
    project: "i-do-blueprint",
    tags: ["settings", "ui", "implementation"]
)
```

---

### Step 2: Create Beads Issues for Implementation

**Use beads CLI for work tracking:**

```bash
# Create epic for restructure project
bd create --title="Settings UI Restructure" \
  --type=epic \
  --priority=2 \
  --description="Reorganize settings tabs into logical, nested groups mirroring Global Settings structure"

# Get epic ID (example: beads-001)

# Create sub-tasks
bd create --title="Update SettingsModels.swift with new hierarchy" \
  --type=task \
  --priority=2 \
  --description="Add subsection enums for Account, Budget & Vendors, Guests & Tasks, etc."

bd create --title="Refactor SettingsView.swift sidebar navigation" \
  --type=task \
  --priority=2 \
  --description="Implement DisclosureGroup pattern for all parent sections"

bd create --title="Update individual settings views for new grouping" \
  --type=task \
  --priority=2 \
  --description="Move views to appropriate parent sections, adjust imports"

bd create --title="Test settings navigation and state preservation" \
  --type=task \
  --priority=2 \
  --description="Ensure expanded/collapsed state persists, selection works correctly"

bd create --title="Update documentation and user guide" \
  --type=task \
  --priority=3 \
  --description="Document new settings organization in CLAUDE.md and user docs"

# Add dependencies (tasks depend on epic)
bd dep add beads-002 beads-001  # Models depend on epic
bd dep add beads-003 beads-002  # View depends on models
bd dep add beads-004 beads-003  # Individual views depend on main view
bd dep add beads-005 beads-004  # Testing depends on implementation
bd dep add beads-006 beads-005  # Docs depend on testing

# Check ready tasks
bd ready --priority=2
```

---

### Step 3: Code Implementation Patterns

**File Locations:**
- **Models:** `I Do Blueprint/Views/Settings/Models/SettingsModels.swift`
- **Main View:** `I Do Blueprint/Views/Settings/SettingsView.swift` (legacy) or `SettingsViewV2.swift`
- **Section Views:** `I Do Blueprint/Views/Settings/Sections/*.swift`
- **Components:** `I Do Blueprint/Views/Settings/Components/*.swift`

**Implementation Pattern (Based on Global Settings):**

```swift
// 1. Add subsection enums in SettingsModels.swift
enum AccountSubsection: String, CaseIterable, Identifiable {
    case profile = "Profile & Authentication"
    case collaboration = "Collaboration & Team"
    case dataPrivacy = "Data & Privacy"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .profile: "person.circle"
        case .collaboration: "person.2.badge.gearshape"
        case .dataPrivacy: "shield.fill"
        }
    }
}

// 2. Update SettingsSection enum
extension SettingsSection {
    var hasSubsections: Bool {
        switch self {
        case .global, .account, .budgetVendors, .guestsTasks,
             .appearance, .dataContent, .developer:
            return true
        default:
            return false
        }
    }

    var subsections: [any SettingsSubsection]? {
        switch self {
        case .global: return GlobalSubsection.allCases
        case .account: return AccountSubsection.allCases
        // ... etc
        default: return nil
        }
    }
}

// 3. Update sidebar in SettingsView.swift
List(selection: $selectedSection) {
    ForEach(SettingsSection.allCases) { section in
        if section.hasSubsections {
            DisclosureGroup(
                isExpanded: Binding(
                    get: { expandedSections.contains(section) },
                    set: { isExpanded in
                        if isExpanded {
                            expandedSections.insert(section)
                        } else {
                            expandedSections.remove(section)
                        }
                    }
                )
            ) {
                // Render subsections (use generic subsections array)
                ForEach(section.subsections ?? []) { subsection in
                    Button(action: {
                        selectedSection = section
                        selectedSubsection = subsection
                    }) {
                        Label {
                            Text(subsection.rawValue)
                        } icon: {
                            Image(systemName: subsection.icon)
                                .foregroundColor(.accentColor)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 20)
                    .background(
                        isSelected(section: section, subsection: subsection)
                            ? Color.accentColor.opacity(0.1)
                            : Color.clear
                    )
                    .cornerRadius(6)
                }
            } label: {
                Label {
                    Text(section.rawValue)
                } icon: {
                    Image(systemName: section.icon)
                        .foregroundColor(section.color)
                }
            }
        } else {
            // Flat section (no subsections)
            NavigationLink(value: section) {
                Label {
                    Text(section.rawValue)
                } icon: {
                    Image(systemName: section.icon)
                        .foregroundColor(section.color)
                }
            }
        }
    }
}
```

**State Management Pattern:**

```swift
@State private var selectedSection: SettingsSection = .global
@State private var selectedSubsection: (any SettingsSubsection)? = GlobalSubsection.overview
@State private var expandedSections: Set<SettingsSection> = [.global]

// Store expanded state in UserDefaults for persistence
private func saveExpandedState() {
    let expanded = expandedSections.map { $0.rawValue }
    UserDefaults.standard.set(expanded, forKey: "SettingsExpandedSections")
}

private func restoreExpandedState() {
    if let saved = UserDefaults.standard.array(forKey: "SettingsExpandedSections") as? [String] {
        expandedSections = Set(saved.compactMap { SettingsSection(rawValue: $0) })
    }
}
```

---

### Step 4: Testing & Validation

**Test Cases:**
1. **Navigation:** All sections accessible via sidebar
2. **State Persistence:** Expanded/collapsed state survives app restart
3. **Selection Highlighting:** Active subsection highlighted correctly
4. **Detail View Routing:** Each subsection shows correct detail view
5. **Save Functionality:** Settings save correctly regardless of nesting
6. **Accessibility:** Keyboard navigation works, VoiceOver announces structure
7. **Data Integrity:** No settings lost, all functionality preserved

**Test with xcodebuild:**
```bash
# Run UI tests
xcodebuild test \
  -project "I Do Blueprint.xcodeproj" \
  -scheme "I Do Blueprint" \
  -destination 'platform=macOS' \
  -only-testing:"I Do BlueprintUITests/SettingsNavigationTests"
```

---

### Step 5: Documentation Updates

**Update in Basic Memory:**
```swift
mcp__basic-memory__write_note(
    title: "Settings Restructure - Post-Implementation Summary",
    content: """
    # Settings Restructure Completion

    ## Changes Made:
    - Added 7 parent sections with nested subsections
    - Migrated 16 flat sections into hierarchical groups
    - Preserved all functionality and data

    ## New Structure:
    [Document final hierarchy]

    ## Migration Notes:
    - Old enum values deprecated (backward compatibility for 1 release)
    - UserDefaults keys updated for state persistence
    - All tests passing

    ## Lessons Learned:
    [Document any challenges or insights]
    """,
    folder: "architecture/settings",
    project: "i-do-blueprint",
    tags: ["settings", "ui", "implementation", "completed"]
)
```

**Update CLAUDE.md:**
- Add section documenting new settings hierarchy
- Update "Directory Structure" section
- Add migration guide for future developers

---

## Success Criteria

### Functional Requirements:
- [ ] All 16 settings sections accessible in new hierarchy
- [ ] No settings lost or rendered inaccessible
- [ ] Save functionality works correctly for all nested sections
- [ ] Expanded/collapsed state persists across app restarts
- [ ] Navigation state preserved when switching between sections
- [ ] Keyboard navigation and accessibility working

### User Experience Requirements:
- [ ] New structure is more intuitive than flat structure
- [ ] Logical groupings reduce cognitive load
- [ ] Related settings are co-located
- [ ] Frequently used settings remain easily accessible
- [ ] Mirrors "Global Settings" organizational style

### Technical Requirements:
- [ ] Code follows existing patterns (DisclosureGroup, SettingsRow, etc.)
- [ ] All tests passing (unit + UI tests)
- [ ] No memory leaks or performance regressions
- [ ] Conforms to MVVM architecture
- [ ] Uses AppStores.shared (no new store instances)

### Documentation Requirements:
- [ ] All work tracked as beads issues
- [ ] Basic Memory updated with new structure
- [ ] CLAUDE.md updated with new patterns
- [ ] Migration guide added for future developers
- [ ] ADR created documenting decision rationale

---

## Open Questions & Decisions Needed

### Grouping Strategy:
**Question:** Which grouping option (Feature-First, Workflow-First, or Hybrid) best serves users?

**Recommendation:** Hybrid approach balances user workflows with data dependencies. Test with usability feedback.

### Naming Conventions:
**Question:** Should parent sections use descriptive names ("Budget & Vendors") or functional names ("Financial Planning")?

**Recommendation:** Use descriptive names matching existing conventions. Users understand "Budget & Vendors" better than abstract "Financial Planning".

### Migration Path:
**Question:** Should old flat structure remain available for 1 release (gradual migration) or immediate cutover?

**Recommendation:** Immediate cutover. Settings are internal-only, no external API contract.

### State Persistence:
**Question:** Should expanded/collapsed state persist per-user or use app-wide defaults?

**Recommendation:** Per-user persistence in UserDefaults. Different users have different workflows.

### Danger Zone Placement:
**Question:** Should "Danger Zone" remain top-level or nest under "Account"?

**Recommendation:** Nest under "Account > Data & Privacy" to reduce visibility and prevent accidental access.

---

## References

### File Paths:
- **Settings Models:** `I Do Blueprint/Views/Settings/Models/SettingsModels.swift`
- **Main Settings View:** `I Do Blueprint/Views/Settings/SettingsView.swift`
- **Section Views:** `I Do Blueprint/Views/Settings/Sections/*.swift`
- **Components:** `I Do Blueprint/Views/Settings/Components/*.swift`
- **Store:** `I Do Blueprint/Services/Stores/SettingsStoreV2.swift`
- **Data Model:** `I Do Blueprint/Domain/Models/Settings/SettingsModel.swift`

### Related Documentation:
- **CLAUDE.md:** `/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint/CLAUDE.md`
- **Architecture Docs:** `/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint/docs/`
- **Session Specs:** `/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint/_project_specs/session/`

### MCP Tools Used:
- **ADR Analysis:** Architectural decision tracking
- **Grep MCP:** Code search and pattern analysis
- **Supabase MCP:** Database schema analysis
- **Basic Memory:** Knowledge management and documentation
- **Beads:** Issue tracking and work management

---

## Next Steps

1. **Approval Phase:**
   - Review proposed hierarchy with stakeholders
   - Gather feedback on grouping strategy
   - Finalize naming conventions

2. **Implementation Phase:**
   - Create beads epic and sub-tasks
   - Implement model changes (SettingsModels.swift)
   - Update main view (SettingsView.swift)
   - Refactor individual section views
   - Add state persistence

3. **Testing Phase:**
   - Write UI tests for navigation
   - Test state persistence
   - Validate accessibility
   - Performance testing

4. **Documentation Phase:**
   - Update Basic Memory with new structure
   - Update CLAUDE.md
   - Create migration guide
   - Document ADR

5. **Deployment Phase:**
   - Merge to main branch
   - Monitor for issues
   - Gather user feedback
   - Iterate as needed

---

**Generated:** 2025-12-31
**Author:** Claude Code with I Do Blueprint Architecture Context
**Status:** Ready for Implementation
