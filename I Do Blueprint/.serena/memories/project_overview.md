# I Do Blueprint - Project Overview

## Purpose
**I Do Blueprint** is a comprehensive macOS wedding planning application built with SwiftUI. It helps couples manage all aspects of their wedding including:
- Budget tracking with affordability calculator
- Guest management with RSVP tracking
- Vendor coordination and contract management
- Task planning with deadline tracking
- Timeline management with milestones
- Document storage (Supabase + Google Drive integration)
- Visual planning (mood boards, seating charts, color palettes)

**Domain**: Wedding planning and event management
**Platform**: macOS 13.0+ (SwiftUI)
**Architecture**: MVVM with Repository Pattern, Dependency Injection
**Backend**: Supabase (multi-tenant architecture)

## Tech Stack

### Core Frameworks
- **SwiftUI** - UI framework
- **Combine** - Reactive programming (@Published properties)
- **Swift Concurrency** - async/await, MainActor
- **OSLog** - Structured logging with AppLogger

### Major Dependencies
- **Supabase** (2.33.2) - Backend as a service (database, auth, storage)
- **swift-dependencies** (1.10.0) - Dependency injection framework
- **SwiftUICharts** (2.10.4) - Data visualization
- **Lottie** (4.5.2) - Animations
- **TPPDF** (2.6.1) - PDF generation
- **Kingfisher** (8.5.0) - Image loading/caching
- **swift-markdown-ui** (2.4.1) - Markdown rendering

### Google Integration
- **GTMAppAuth** (5.0.0) - Google OAuth
- **AppAuth** (2.0.0) - OAuth 2.0/OpenID Connect
- **GTMSessionFetcher** (3.5.0) - HTTP session management

## Architecture Version
**V2 Pattern** (Repository-based architecture)
- All stores use V2 suffix (e.g., `BudgetStoreV2`)
- Repository pattern for all data access
- Dependency injection for testability
- Strict separation of concerns (Views → Stores → Repositories → Supabase)
