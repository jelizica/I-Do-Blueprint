# I Do Blueprint - Project Overview

## Vision
A comprehensive macOS wedding planning application that helps couples manage every aspect of their wedding with professional-grade tools while maintaining privacy and control of their data.

## Goals
- ✅ Multi-tenant wedding planning platform with Row Level Security
- ✅ Budget management with payment schedules and expense tracking
- ✅ Guest management with RSVP tracking
- ✅ Vendor management with contract tracking
- ✅ Task and timeline management
- ✅ Document management
- ✅ Visual planning (mood boards, seating charts)
- ✅ Real-time collaboration
- ✅ Export to various formats (Google Sheets, PDF, CSV)
- [ ] Mobile companion app (future)
- [ ] Public wedding website generation (future)

## Non-Goals
- Not a booking platform (we don't facilitate vendor transactions)
- Not a social network (focused on private planning)
- Not a mobile-first app (macOS desktop is primary platform)

## Tech Stack
- **Language**: Swift 5.9+ with strict concurrency
- **Platform**: macOS 13.0+
- **Framework**: SwiftUI with MVVM + Repository Pattern
- **Backend**: Supabase (PostgreSQL with Row Level Security)
- **Testing**: XCTest with dependency injection
- **CI/CD**: GitHub Actions
- **Error Tracking**: Sentry
- **Analytics**: Custom analytics via ErrorTracker

## Architecture Principles
1. **Feature-based organization** - Code grouped by feature domain
2. **Separation of concerns** - Clear boundaries between UI, State, Business Logic, Data Access
3. **Repository pattern** - All data access through repository protocols
4. **Domain Services layer** - Complex business logic separated from repositories
5. **Strategy-based cache invalidation** - Per-domain cache strategies
6. **Dependency injection** - Using `@Dependency` macro for loose coupling
7. **V2 naming convention** - New architecture stores use `V2` suffix
8. **Actor-based caching** - Thread-safe `RepositoryCache` actor
9. **Multi-tenant security** - All data scoped by `couple_id` with RLS
10. **Strict concurrency** - Full Swift 6 concurrency checking enabled

## Success Metrics
- **Performance**: < 500ms for all data operations (cached)
- **Reliability**: > 99.9% uptime for Supabase backend
- **Security**: Zero data leaks across tenants (enforced by RLS)
- **Test Coverage**: > 80% for business logic
- **Code Quality**: Zero force unwraps in production code
- **User Experience**: < 1s app launch time

## Current Status
- **Phase**: Active development
- **Version**: Internal beta
- **User Base**: Development testing only
- **Deployment**: Local development + Supabase cloud backend
