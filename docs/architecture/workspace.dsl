workspace "I Do Blueprint" {
    model {
        user = person "Wedding Planning Couple" {
            description "Couple planning their wedding using I Do Blueprint"
        }

        idoBlueprint = softwareSystem "I Do Blueprint" {
            description "Comprehensive macOS wedding planning application with multi-tenant architecture"

            swiftUIApp = container "macOS Application" {
                description "Native Swift 5.9+ macOS app with SwiftUI, strict concurrency, and five-layer architecture"
                technology "Swift, SwiftUI, Combine, Swift Concurrency"

                viewLayer = component "View Layer" {
                    description "SwiftUI views and UI components with @Environment injection"
                    technology "SwiftUI, @Environment, @StateObject"
                    tags "Presentation"
                }

                storeLayer = component "Store Layer" {
                    description "Feature stores (BudgetStoreV2, GuestStoreV2, etc.) with @MainActor isolation"
                    technology "@MainActor, ObservableObject, @Published, Combine"
                    tags "StateManagement"
                }

                repositoryLayer = component "Repository Layer" {
                    description "Protocol-based data access with caching, retry logic, and error tracking"
                    technology "async/await, Protocols, NetworkRetry, Sentry"
                    tags "DataAccess"
                }

                cacheLayer = component "RepositoryCache Actor" {
                    description "Thread-safe in-memory cache with TTL expiration (60s default)"
                    technology "Swift Actor, Dictionary<String, CacheEntry>"
                    tags "Cache"
                }

                domainServices = component "Domain Services Layer" {
                    description "Actor-based business logic and data aggregation services"
                    technology "Actor isolation, parallel async/await"
                    tags "BusinessLogic"
                }

                dependencyInjection = component "Dependency Injection" {
                    description "Point-Free Dependencies framework for loose coupling"
                    technology "@Dependency macro, DependencyValues"
                    tags "Infrastructure"
                }

                cacheStrategies = component "Cache Invalidation Strategies" {
                    description "Per-domain cache invalidation (GuestCacheStrategy, BudgetCacheStrategy, etc.)"
                    technology "Actor, CacheOperation enum, strategy pattern"
                    tags "Infrastructure"
                }
            }

            supabase = container "Supabase Backend" {
                description "PostgreSQL database with Row Level Security, Realtime, and Auth"
                technology "PostgreSQL 15, PostgREST, Realtime, GoTrue Auth"
                tags "Database"
            }
        }

        # External integrations
        googleSheets = softwareSystem "Google Sheets" {
            description "Export budget data to spreadsheets via Google Sheets API"
            tags "External"
        }

        sentry = softwareSystem "Sentry" {
            description "Error tracking, crash reporting, and performance monitoring"
            tags "External"
        }

        keychain = softwareSystem "macOS Keychain" {
            description "Secure storage for auth tokens and API keys"
            tags "External"
        }

        # User interactions
        user -> viewLayer "Interacts with macOS app"

        # Layer-to-layer relationships
        viewLayer -> storeLayer "Accesses via @Environment injection"
        storeLayer -> repositoryLayer "Calls via @Dependency macro"
        repositoryLayer -> cacheLayer "Checks cache before network"
        repositoryLayer -> domainServices "Delegates complex business logic"
        repositoryLayer -> supabase "Queries with NetworkRetry and RLS filters"
        domainServices -> supabase "Parallel data fetching with async let"

        # Infrastructure relationships
        dependencyInjection -> repositoryLayer "Injects repository implementations"
        dependencyInjection -> storeLayer "Provides dependencies to stores"
        cacheStrategies -> cacheLayer "Invalidates cache on mutations"
        repositoryLayer -> cacheStrategies "Triggers invalidation after writes"

        # External integrations
        swiftUIApp -> googleSheets "Exports budget data via Google API Client"
        swiftUIApp -> sentry "Reports errors and crashes with context"
        swiftUIApp -> keychain "Stores/retrieves auth tokens securely"

        # Cache flow
        cacheLayer -> repositoryLayer "Returns cached data (cache hit)"
        supabase -> repositoryLayer "Returns fresh data (cache miss)"
        repositoryLayer -> cacheLayer "Caches result with 60s TTL"
    }

    views {
        systemContext idoBlueprint "SystemContext" {
            include *
            autolayout lr
            description "System context showing I Do Blueprint, users, and external integrations"
        }

        container idoBlueprint "Containers" {
            include *
            autolayout tb
            description "Container view showing macOS app and Supabase backend separation"
        }

        component swiftUIApp "Components" {
            include *
            autolayout tb
            description "Five-layer architecture with dependency injection and caching"
        }

        dynamic swiftUIApp "DataFlowRead" "Data flow: User reads data from database" {
            viewLayer -> storeLayer "1. User action triggers load"
            storeLayer -> repositoryLayer "2. Call repository.fetch()"
            repositoryLayer -> cacheLayer "3. Check cache first"
            cacheLayer -> repositoryLayer "4. Cache miss (nil)"
            repositoryLayer -> supabase "5. Query with NetworkRetry + RLS filter"
            supabase -> repositoryLayer "6. Return data"
            repositoryLayer -> cacheLayer "7. Cache result (60s TTL)"
            repositoryLayer -> storeLayer "8. Return to store"
            storeLayer -> viewLayer "9. Update @Published property → Combine updates UI"
            autolayout lr
        }

        dynamic swiftUIApp "DataFlowWrite" "Data flow: User creates/updates data with cache invalidation" {
            viewLayer -> storeLayer "1. User creates budget category"
            storeLayer -> repositoryLayer "2. Call repository.create(category)"
            repositoryLayer -> supabase "3. INSERT with couple_id (RLS enforced)"
            supabase -> repositoryLayer "4. Return created entity"
            repositoryLayer -> cacheStrategies "5. Trigger invalidation (.categoryCreated)"
            cacheStrategies -> cacheLayer "6. Remove categories_*, budget_summary_*"
            repositoryLayer -> storeLayer "7. Return created entity"
            storeLayer -> viewLayer "8. Update @Published array → UI re-renders"
            autolayout lr
        }

        dynamic swiftUIApp "CacheMiss" "Subsequent read after cache invalidation" {
            viewLayer -> storeLayer "1. Reload categories"
            storeLayer -> repositoryLayer "2. Call repository.fetchCategories()"
            repositoryLayer -> cacheLayer "3. Check cache"
            cacheLayer -> repositoryLayer "4. Cache miss (invalidated)"
            repositoryLayer -> supabase "5. Fetch fresh data"
            supabase -> repositoryLayer "6. Return categories"
            repositoryLayer -> cacheLayer "7. Re-cache (60s TTL)"
            repositoryLayer -> storeLayer "8. Return to store"
            storeLayer -> viewLayer "9. Update UI with fresh data"
            autolayout lr
        }

        dynamic swiftUIApp "DomainServiceDelegation" "Repository delegates complex logic to domain service" {
            storeLayer -> repositoryLayer "1. fetchBudgetOverview(scenarioId)"
            repositoryLayer -> domainServices "2. Delegate to BudgetAggregationService"
            domainServices -> supabase "3. Parallel fetch: async let items, expenses, gifts"
            supabase -> domainServices "4. Return all data"
            domainServices -> repositoryLayer "5. Return aggregated overview items"
            repositoryLayer -> cacheLayer "6. Cache aggregated result"
            repositoryLayer -> storeLayer "7. Return to store"
            storeLayer -> viewLayer "8. Display budget overview"
            autolayout lr
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Presentation" {
                background #90EE90
                color #000000
            }
            element "StateManagement" {
                background #87CEEB
                color #000000
            }
            element "DataAccess" {
                background #FFB6C1
                color #000000
            }
            element "Cache" {
                background #DDA0DD
                color #000000
            }
            element "BusinessLogic" {
                background #F0E68C
                color #000000
            }
            element "Infrastructure" {
                background #D3D3D3
                color #000000
            }
            element "Database" {
                background #FF6B6B
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
