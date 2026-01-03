# I Do Blueprint

A comprehensive macOS wedding planning application built with SwiftUI and Supabase.

## Overview

**I Do Blueprint** helps couples plan their perfect wedding with intuitive tools for managing budgets, guests, vendors, tasks, timelines, documents, and visual planning. The app combines a native macOS experience with real-time cloud synchronization, collaborative features, and powerful data management.

## Features

### 💰 Budget Management
- **Smart Budget Tracking**: Track expenses across categories with automatic allocation calculations
- **Development Scenarios**: Create "what-if" scenarios to compare different budget approaches
- **Payment Schedules**: Manage vendor payment timelines with reminders
- **Affordability Analysis**: Understand budget impact and get recommendations
- **Gift Tracking**: Track cash gifts and apply them to expenses

### 👥 Guest Management
- **Comprehensive Guest List**: Track guests, plus-ones, dietary restrictions, and contact info
- **RSVP Tracking**: Monitor responses and meal choices in real-time
- **Group Management**: Organize guests by family, friend groups, or custom categories
- **Seating Planning**: Visual seating chart with drag-and-drop table assignments
- **Import/Export**: Bulk import from CSV/XLSX, export to Google Sheets

### 🏢 Vendor Management
- **Vendor Directory**: Track all vendors with contact info, contracts, and payment status
- **Document Storage**: Attach contracts, invoices, and agreements
- **Payment Tracking**: Link vendors to budget and track payment schedules
- **Communication History**: Log all vendor interactions and decisions

### ✅ Task & Timeline Management
- **Task Organization**: Create, assign, and track wedding planning tasks
- **Timeline View**: Visualize all tasks on an interactive timeline
- **Dependency Tracking**: Set task dependencies and prerequisites
- **Milestone Tracking**: Track major milestones leading up to the wedding

### 📄 Document Management
- **Cloud Storage**: Securely store all wedding documents with Supabase Storage
- **Folder Organization**: Organize documents by category (contracts, inspiration, planning)
- **Quick Access**: Search and filter documents by name, type, or date
- **Version Control**: Track document versions and upload history

### 🎨 Visual Planning
- **Mood Boards**: Create visual inspiration boards with images
- **Color Palette**: Define and save wedding color schemes
- **Seating Charts**: Interactive seating arrangement with table management
- **Image Collections**: Gather inspiration from Unsplash and Pinterest

### 👥 Collaboration
- **Multi-User Support**: Share planning access with your partner
- **Real-time Updates**: See changes instantly across all devices
- **Activity Feed**: Track who changed what and when
- **Permissions**: Control access levels for different collaborators

## Tech Stack

### Platform
- **macOS**: 13.0+ (Ventura and later)
- **Language**: Swift 5.9+ with strict concurrency
- **UI Framework**: SwiftUI with NavigationSplitView

### Backend
- **Supabase**: PostgreSQL database with Row Level Security (RLS)
- **Authentication**: Supabase Auth with email/password and OAuth
- **Storage**: Supabase Storage for document and image uploads
- **Real-time**: Supabase Realtime for collaborative features
- **Edge Functions**: Serverless functions for complex operations

### Architecture
- **Pattern**: MVVM with Repository Pattern
- **State Management**: V2 Stores (`@MainActor ObservableObject`)
- **Data Layer**: Actor-based repositories with caching
- **Domain Services**: Business logic separated into domain services
- **Dependency Injection**: Point-Free Dependencies framework
- **Concurrency**: Full Swift 6 concurrency checking enabled

### Key Dependencies
- [Supabase Swift](https://github.com/supabase/supabase-swift) - Backend client
- [Dependencies](https://github.com/pointfreeco/swift-dependencies) - Dependency injection
- [Sentry Cocoa](https://github.com/getsentry/sentry-cocoa) - Error tracking (optional)
- [SwiftLint](https://github.com/realm/SwiftLint) - Code linting

## Getting Started

### Prerequisites
- **Xcode 15.0+** with Swift 5.9+
- **macOS 13.0+** (Ventura or later)
- **Active internet connection** for Supabase backend

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd "I Do Blueprint"
   ```

2. **Open in Xcode:**
   ```bash
   open "I Do Blueprint.xcodeproj"
   ```

3. **Build and run:**
   - Select the "I Do Blueprint" scheme
   - Choose your Mac as the destination
   - Press `Cmd+R` to build and run

The app includes hardcoded Supabase configuration in [`I Do Blueprint/Core/Configuration/AppConfig.swift`](I Do Blueprint/Core/Configuration/AppConfig.swift), so it works out-of-the-box without additional setup.

### Optional: Custom Configuration

To use your own Supabase instance (for development or testing), create `I Do Blueprint/Config.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SUPABASE_URL</key>
    <string>https://your-project.supabase.co</string>
    <key>SUPABASE_ANON_KEY</key>
    <string>your-anon-key</string>
    <key>SENTRY_DSN</key>
    <string>https://your-sentry-dsn@sentry.io/project</string>
</dict>
</plist>
```

**Configuration Priority:**
1. `Config.plist` (if present) - highest priority
2. `AppConfig.swift` (hardcoded) - fallback

## Project Structure

```
I Do Blueprint/
├── App/                    # App entry point and root navigation
├── Core/                   # Common utilities and infrastructure
│   ├── Common/             # DI, error handling, analytics
│   ├── Configuration/      # App configuration
│   ├── Extensions/         # Swift type extensions
│   └── Security/           # Security infrastructure
├── Design/                 # Design system (colors, typography, spacing)
├── Domain/                 # Business logic and data models
│   ├── Models/             # Feature-organized domain models
│   ├── Repositories/       # Data access layer
│   │   ├── Protocols/      # Repository interfaces
│   │   ├── Live/           # Supabase implementations (actors)
│   │   ├── Mock/           # Test implementations
│   │   └── Caching/        # Cache strategies and infrastructure
│   └── Services/           # Domain services (complex business logic)
├── Services/               # Application services
│   ├── Stores/             # State management (V2 pattern)
│   ├── API/                # API clients
│   ├── Auth/               # SessionManager
│   ├── Export/             # Google Sheets export
│   ├── Import/             # CSV/XLSX import
│   └── Realtime/           # Real-time collaboration
├── Utilities/              # Helper functions and utilities
├── Views/                  # SwiftUI views (feature-organized)
└── Resources/              # Assets, Lottie animations, sample data

I Do BlueprintTests/        # Unit tests
I Do BlueprintUITests/      # UI tests

supabase/
├── functions/              # Supabase Edge Functions
└── migrations/             # Database migrations (51 migrations)
```

## Database Setup

The app uses Supabase PostgreSQL with 51 migrations that create:
- Multi-tenant tables with Row Level Security (RLS)
- Budget tracking (categories, items, expenses, scenarios)
- Guest management (guest list, RSVPs, dietary restrictions)
- Vendor management (contacts, contracts, payments)
- Task and timeline management
- Document storage metadata
- Visual planning (mood boards, seating charts)
- User settings and preferences

### Running Migrations Locally

If you're setting up your own Supabase instance:

```bash
# Install Supabase CLI
brew install supabase/tap/supabase

# Link to your project
supabase link --project-ref your-project-ref

# Run migrations
supabase db push
```

## Architecture Overview

### Data Flow

```
View (SwiftUI)
    ↓
Store (@MainActor ObservableObject)
    ↓
Repository (actor with caching)
    ↓ (complex logic delegated to →) Domain Service (actor)
    ↓
Supabase Backend (PostgreSQL + RLS)
```

### Key Patterns

**1. V2 Store Pattern**
- `@MainActor` observable objects with `@Published` state
- Inject repositories via `@Dependency`
- Use `LoadingState<T>` enum for async operations
- Handle errors with `handleError` extension

**2. Repository Pattern**
- Protocol-based interfaces for testability
- Actor-based Live implementations for thread safety
- In-memory caching with `RepositoryCache`
- Domain-specific cache invalidation strategies
- Network retry logic with `RepositoryNetwork.withRetry`

**3. Domain Services**
- Complex business logic separated from repositories
- Actor-based for thread-safe operations
- Examples: `BudgetAggregationService`, `BudgetAllocationService`

**4. Multi-Tenancy**
- All data scoped by `couple_id` (tenant ID)
- Row Level Security (RLS) enforces tenant isolation
- Automatic tenant filtering in all queries

**5. Dependency Injection**
- Point-Free Dependencies framework
- Live, test, and preview implementations
- Centralized in `DependencyValues.swift`

## Security

### Authentication & Authorization
- Supabase Auth with email/password and OAuth providers
- Session management with macOS Keychain storage
- Row Level Security (RLS) on all multi-tenant tables
- Tenant isolation enforced at database level

### Data Protection
- **Supabase anon key**: Safe for client-side use (protected by RLS)
- **User secrets**: Stored securely in macOS Keychain
- **Session data**: Uses `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- **API keys**: Never hardcoded in source (use Config.plist)

### Security Best Practices
- SwiftLint rules enforce secure coding patterns
- No force unwrapping without justification
- Sensitive data excluded from logs and error messages
- Input validation on all user data
- HTTPS-only communication with backend

## Testing

### Running Tests

```bash
# All tests
xcodebuild test -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS'

# Specific test class
xcodebuild test -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS' -only-testing:"I Do BlueprintTests/BudgetStoreV2Tests"

# Specific test method
xcodebuild test -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS' -only-testing:"I Do BlueprintTests/BudgetStoreV2Tests/test_loadBudgetData_success"
```

### Test Structure
- **Unit Tests**: Repository and store tests with mocks
- **Integration Tests**: End-to-end feature tests
- **UI Tests**: SwiftUI view interaction tests
- **Accessibility Tests**: WCAG compliance tests

### Test Philosophy
- Mock repositories for isolated unit tests
- `@MainActor` for store tests
- `.makeTest()` factory methods for test data
- Dependency injection via `withDependencies`

## Building & Distribution

### Development Build

```bash
xcodebuild build -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS'
```

### Clean Build

```bash
xcodebuild clean -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint"
```

### Resolve Package Dependencies

```bash
xcodebuild -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS' -resolvePackageDependencies
```

## CI/CD

The project includes GitHub Actions for continuous integration:

- **Automated Tests**: Runs on every push and pull request
- **Build Validation**: Ensures project builds successfully
- **SwiftLint**: Enforces code style and best practices
- **No Secrets Required**: Uses hardcoded `AppConfig.swift` in CI

See [`.github/workflows/tests.yml`](.github/workflows/tests.yml) for configuration.

## Utilities & Scripts

The [`Scripts/`](Scripts/) directory contains production utilities:

- **`audit_logging.sh`**: Security audit script
- **`convert_csv_to_xlsx.py`**: Convert CSV files to Excel format
- **`migrate-appcolors-to-semantic.py`**: Migrate color tokens
- **`migrate-colors.sh`**: Color migration helper
- **`migrate_print_to_logger.py`**: Migrate print statements to AppLogger

## Code Style

The project follows strict Swift coding standards enforced by SwiftLint:

- **Design Tokens**: Use constants from `Design/DesignSystem.swift` (AppColors, Typography, Spacing)
- **Concurrency**: Full Swift 6 concurrency checking enabled
- **Naming**: Descriptive names following Swift API Design Guidelines
- **Comments**: MARK comments for organization, documentation for complex logic
- **Extensions**: Group related functionality with extensions

See [`.swiftlint.yml`](.swiftlint.yml) for complete linting rules.

## Contributing

### Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes following the code style guidelines
4. Write tests for new functionality
5. Run SwiftLint: `swiftlint`
6. Run tests: `xcodebuild test ...`
7. Commit changes: `git commit -m "feat: add your feature"`
8. Push to your fork: `git push origin feature/your-feature-name`
9. Open a pull request

### Commit Message Format

Follow conventional commits:
- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code refactoring
- `docs:` - Documentation changes
- `test:` - Test changes
- `chore:` - Build/tooling changes

### Code Review Guidelines

- All changes require passing tests
- SwiftLint must pass with no errors
- Follow existing architectural patterns
- Update tests for modified functionality
- Document complex logic and architectural decisions

## Support & Issues

- **Bug Reports**: Open an issue with reproduction steps
- **Feature Requests**: Describe the use case and proposed solution
- **Questions**: Check existing issues first, then open a discussion

## License

[Your License Here - e.g., MIT, Apache 2.0, or Proprietary]

## Acknowledgments

- Built with [Supabase](https://supabase.com) - Open source Firebase alternative
- UI inspiration from modern macOS design patterns
- Community feedback and contributions

---

**Built with ❤️ for couples planning their special day**
