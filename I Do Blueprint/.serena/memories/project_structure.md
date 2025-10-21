# I Do Blueprint - Project Structure

## Directory Organization

```
I Do Blueprint/
├── App/                          # Application entry point
│   ├── My_Wedding_Planning_AppApp.swift  # App entry with auth/tenant flow
│   ├── RootFlowView.swift        # Root navigation based on auth state
│   └── ContentView.swift         # Legacy content view
│
├── Core/                         # Core infrastructure
│   ├── Common/
│   │   ├── Analytics/            # Analytics services
│   │   ├── Auth/                 # Authentication context
│   │   ├── Common/               # Dependency injection, app stores
│   │   ├── Errors/               # Error types
│   │   ├── Storage/              # Supabase client
│   │   └── Utilities/            # Core utilities
│   ├── Extensions/               # Swift extensions
│   └── Utilities/                # Shared utilities
│
├── Design/                       # Design system
│   ├── DesignSystem.swift        # Complete design system (colors, typography, spacing)
│   ├── AccessibilityAudit.swift  # WCAG compliance tools
│   └── ACCESSIBILITY_*.md        # Accessibility documentation
│
├── Domain/                       # Business logic layer
│   ├── Models/                   # Domain models by feature
│   │   ├── Budget/               # Budget, expenses, categories
│   │   ├── Guest/                # Guest, RSVP, groups
│   │   ├── Vendor/               # Vendor, contracts
│   │   ├── Task/                 # Tasks, deadlines
│   │   ├── Timeline/             # Events, milestones
│   │   ├── Document/             # Documents, storage
│   │   ├── VisualPlanning/       # Seating charts, mood boards
│   │   ├── Settings/             # User settings, preferences
│   │   └── Shared/               # Shared models (LoadingState, etc.)
│   │
│   └── Repositories/             # Data access layer
│       ├── Protocols/            # Repository interfaces
│       ├── Live/                 # Production Supabase implementations
│       └── Mock/                 # Test implementations
│
├── Services/                     # Application services
│   ├── Stores/                   # State management (V2 stores)
│   │   ├── BudgetStoreV2.swift
│   │   ├── GuestStoreV2.swift
│   │   ├── VendorStoreV2.swift
│   │   └── ...
│   ├── API/                      # API clients
│   ├── Auth/                     # GoogleAuthManager, OAuth
│   ├── Storage/                  # SupabaseManager
│   ├── Analytics/                # Performance monitoring
│   ├── Navigation/               # AppCoordinator
│   ├── UI/                       # AlertPresenter, toast notifications
│   ├── Export/                   # PDF/Google Sheets export
│   ├── Integration/              # Google Drive, Sheets
│   └── VisualPlanning/           # Visual planning services
│
├── Utilities/                    # Shared utilities
│   ├── Logging/                  # AppLogger with categories
│   ├── Validation/               # Input validation
│   ├── NetworkRetry.swift        # Retry logic
│   └── PaymentScheduleCalculator.swift
│
├── Views/                        # UI layer by feature
│   ├── Auth/                     # Login, tenant selection
│   ├── Dashboard/                # Main dashboard
│   ├── Budget/                   # Budget management views
│   ├── Guests/                   # Guest list, RSVP
│   ├── Vendors/                  # Vendor management
│   ├── Tasks/                    # Task tracking
│   ├── Timeline/                 # Timeline/milestones
│   ├── Documents/                # Document management
│   ├── Notes/                    # Notes feature
│   ├── VisualPlanning/           # Seating charts, mood boards
│   ├── Settings/                 # User settings
│   └── Shared/                   # Reusable components
│       ├── Components/           # UI component library
│       └── Loading/              # Loading states
│
├── Resources/                    # Assets
├── I Do BlueprintTests/          # Unit/integration tests
├── I Do BlueprintUITests/        # UI tests
├── Scripts/                      # Build/audit scripts
└── Packages/                     # Local Swift packages
```

## Key Patterns

### Feature Organization
Each feature follows this structure:
- **Models**: `Domain/Models/{Feature}/`
- **Repository**: `Domain/Repositories/Protocols/` + `Live/` + `Mock/`
- **Store**: `Services/Stores/{Feature}StoreV2.swift`
- **Views**: `Views/{Feature}/`
- **Tests**: `I Do BlueprintTests/Services/Stores/{Feature}StoreV2Tests.swift`

### Naming Conventions
- **Views**: `{Feature}{Purpose}View.swift` (e.g., `BudgetDashboardView.swift`)
- **Stores**: `{Feature}StoreV2.swift` (V2 suffix mandatory)
- **Models**: `{EntityName}.swift` (e.g., `Guest.swift`)
- **Protocols**: `{Purpose}Protocol.swift` (e.g., `GuestRepositoryProtocol.swift`)
- **Extensions**: `{Type}+{Purpose}.swift` (e.g., `Color+Hex.swift`)
