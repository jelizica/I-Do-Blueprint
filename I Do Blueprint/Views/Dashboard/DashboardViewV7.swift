//
//  DashboardViewV7.swift
//  I Do Blueprint
//
//  V7 Dashboard with glassmorphism design
//  Features:
//  - Mesh gradient background with animated color blobs
//  - Frosted glass panels with blur effects
//  - Modern Apple design language
//  - Real-time countdown with live seconds
//  - Responsive grid layout
//

import SwiftUI
import Combine
import Sentry

struct DashboardViewV7: View {
    @Environment(\.appStores) private var appStores
    @EnvironmentObject private var settingsStore: SettingsStoreV2
    @EnvironmentObject private var coordinator: AppCoordinator
    
    // Preview control
    private let previewForceLoading: Bool?
    
    // View Model
    @StateObject private var viewModel: DashboardViewModel
    
    // Live countdown timer
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Convenience accessors for stores
    private var budgetStore: BudgetStoreV2 { appStores.budget }
    private var vendorStore: VendorStoreV2 { appStores.vendor }
    private var guestStore: GuestStoreV2 { appStores.guest }
    private var taskStore: TaskStoreV2 { appStores.task }

    // MARK: - Conditional Card Visibility
    
    /// Check if Guest Responses card should be shown
    private var shouldShowGuestResponses: Bool {
        !guestStore.guests.isEmpty
    }
    
    /// Check if Payments Due card should be shown
    private var shouldShowPaymentsDue: Bool {
        !currentMonthPayments.isEmpty
    }
    
    /// Check if Recent Responses card should be shown
    private var shouldShowRecentResponses: Bool {
        hasRecentResponses
    }
    
    /// Check if Vendor List card should be shown
    private var shouldShowVendorList: Bool {
        !vendorStore.vendors.isEmpty
    }
    
    /// Get current month payments
    private var currentMonthPayments: [PaymentSchedule] {
        let now = Date()
        let calendar = Calendar.current
        return budgetStore.payments.paymentSchedules.filter { schedule in
            calendar.isDate(schedule.paymentDate, equalTo: now, toGranularity: .month)
        }
    }
    
    /// Check if there are any guests with RSVP dates
    private var hasRecentResponses: Bool {
        guestStore.guests.contains { $0.rsvpDate != nil }
    }

    // Adaptive grid for main content cards
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 300), spacing: Spacing.lg, alignment: .top)
    ]

    // Fixed 4-column grid for metric cards (includes countdown)
    private let metricColumns: [GridItem] = Array(
        repeating: GridItem(.flexible(minimum: 0), spacing: Spacing.lg, alignment: .top),
        count: 4
    )

    init(previewForceLoading: Bool? = nil, appStores: AppStores = .shared) {
        self.previewForceLoading = previewForceLoading
        _viewModel = StateObject(wrappedValue: DashboardViewModel(
            budgetStore: appStores.budget,
            vendorStore: appStores.vendor,
            guestStore: appStores.guest,
            taskStore: appStores.task,
            settingsStore: appStores.settings
        ))
    }

    var body: some View {
        let effectiveIsLoading = previewForceLoading ?? viewModel.isLoading
        let effectiveHasLoaded = (previewForceLoading == nil) ? viewModel.hasLoaded : !(previewForceLoading!)

        return NavigationStack {
            ZStack {
                // MARK: - Mesh Gradient Background
                MeshGradientBackgroundV7()
                    .ignoresSafeArea()

                // Use VStack with fixed-height header elements, then masonry layout
                VStack(spacing: Spacing.lg) {
                    // MARK: - Header (compressed from 60pt to 50pt)
                    DashboardHeaderV7()
                        .frame(height: 50)
                        .padding(.horizontal, Spacing.xxl)

                    // MARK: - Metric Cards Row (4 columns, compressed to 70pt)
                    LazyVGrid(columns: metricColumns, alignment: .center, spacing: Spacing.lg) {
                        if effectiveHasLoaded {
                            RSVPMetricCardV7(
                                confirmed: viewModel.rsvpYesCount,
                                pending: viewModel.rsvpPendingCount,
                                total: viewModel.totalGuests
                            )
                            VendorMetricCardV7(
                                booked: viewModel.vendorsBookedCount,
                                total: viewModel.totalVendors
                            )
                            BudgetMetricCardV7(
                                spent: viewModel.totalPaid,
                                total: viewModel.totalBudget,
                                percentage: viewModel.budgetPercentage
                            )
                            CountdownMetricCardV7(
                                weddingDate: viewModel.weddingDate,
                                partner1Name: viewModel.partner1DisplayName,
                                partner2Name: viewModel.partner2DisplayName,
                                currentTime: currentTime
                            )
                        } else {
                            MetricCardSkeleton()
                            MetricCardSkeleton()
                            MetricCardSkeleton()
                            MetricCardSkeleton()
                        }
                    }
                    .frame(height: 70)
                    .padding(.horizontal, Spacing.xxl)

                    // MARK: - Main Content: Masonry Layout (fills remaining space)
                    // GeometryReader provides both width AND height for proper card sizing
                    GeometryReader { masonryGeometry in
                        let columnLayout = calculateColumnLayout(
                            availableHeight: masonryGeometry.size.height,  // Use actual available height
                            availableWidth: masonryGeometry.size.width - (Spacing.xxl * 2)
                        )
                        
                        // DEBUG: Log layout dimensions for troubleshooting
                        let _ = logLayoutDimensions(
                            totalHeight: masonryGeometry.size.height,
                            totalWidth: masonryGeometry.size.width,
                            headerHeight: 50,
                            metricCardsHeight: 70,
                            topPadding: Spacing.lg,
                            bottomPadding: Spacing.lg,
                            horizontalPadding: Spacing.xxl
                        )

                        if effectiveHasLoaded {
                            MasonryColumnsView(
                                columnLayout: columnLayout,
                                budgetStore: budgetStore,
                                taskStore: taskStore,
                                guestStore: guestStore,
                                vendorStore: vendorStore,
                                settingsStore: settingsStore,
                                coordinator: coordinator,
                                viewModel: viewModel,
                                shouldShowGuestResponses: shouldShowGuestResponses,
                                shouldShowPaymentsDue: shouldShowPaymentsDue,
                                shouldShowVendorList: shouldShowVendorList,
                                shouldShowRecentResponses: shouldShowRecentResponses,
                                currentMonthPayments: currentMonthPayments
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .padding(.horizontal, Spacing.xxl)
                        } else {
                            // Loading skeletons
                            HStack(alignment: .top, spacing: Spacing.lg) {
                                VStack(spacing: Spacing.lg) {
                                    DashboardBudgetCardSkeleton()
                                    DashboardVendorsCardSkeleton()
                                }
                                VStack(spacing: Spacing.lg) {
                                    DashboardTasksCardSkeleton()
                                }
                                VStack(spacing: Spacing.lg) {
                                    DashboardGuestsCardSkeleton()
                                }
                            }
                            .padding(.horizontal, Spacing.xxl)
                        }
                    }
                }
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
            .navigationTitle("")
        }
        .task {
            if !viewModel.hasLoaded {
                await viewModel.loadDashboardData()
            }
        }
        .onReceive(timer) { time in
            currentTime = time
        }
    }
    
    // MARK: - Dynamic Layout Helpers
    
    /// Data density for each card type (higher = more data to show)
    private struct CardDataDensity {
        let guestCount: Int
        let vendorCount: Int
        let taskCount: Int
        
        /// Weight for guest responses card (scales with data)
        var guestWeight: CGFloat {
            min(CGFloat(guestCount) / 20.0, 3.0) // Cap at 3x weight
        }
        
        /// Weight for vendor list card (scales with data)
        var vendorWeight: CGFloat {
            min(CGFloat(vendorCount) / 10.0, 2.0) // Cap at 2x weight
        }
        
        /// Weight for task manager card (scales with data)
        var taskWeight: CGFloat {
            min(CGFloat(taskCount) / 10.0, 2.0) // Cap at 2x weight
        }
    }
    
    /// Get current data density
    private var dataDensity: CardDataDensity {
        CardDataDensity(
            guestCount: guestStore.guests.count,
            vendorCount: vendorStore.vendors.count,
            taskCount: taskStore.tasks.count
        )
    }
    
    /// Calculate number of visible cards in Row 1
    private var row1CardCount: Int {
        var count = 2  // Always show: Budget Overview + Task Manager
        if shouldShowGuestResponses { count += 1 }
        return count
    }
    
    /// Calculate number of visible cards in Row 2 (excluding Payments Due which is fixed)
    private var row2FlexibleCardCount: Int {
        var count = 0
        if shouldShowVendorList { count += 1 }
        if shouldShowRecentResponses { count += 1 }
        return count
    }
    
    /// Calculate number of visible cards in Row 2 (including Payments Due)
    private var row2CardCount: Int {
        var count = 0
        if shouldShowPaymentsDue { count += 1 }
        if shouldShowVendorList { count += 1 }
        if shouldShowRecentResponses { count += 1 }
        return count
    }
    
    /// Calculate available height for cards after fixed elements
    private func calculateAvailableHeight(geometry: GeometryProxy) -> CGFloat {
        // Fixed elements
        let headerHeight: CGFloat = 60
        let heroBannerHeight: CGFloat = 150
        let metricCardsHeight: CGFloat = 120
        let spacing: CGFloat = Spacing.xl * 4  // Between sections
        let padding: CGFloat = Spacing.lg + Spacing.xxl  // Top + bottom
        
        let fixedHeight = headerHeight + heroBannerHeight + metricCardsHeight + spacing + padding
        return max(geometry.size.height - fixedHeight, 300) // Minimum 300pt for cards
    }
    
    /// Calculate FIXED height for Payments Due card based on actual payment count
    /// This card shows ALL payments - no truncation
    private func calculatePaymentsCardHeight() -> CGFloat {
        let cardHeaderHeight: CGFloat = 50  // Title + Add button
        let paymentRowHeight: CGFloat = 36  // Per payment row (compact)
        let cardPadding: CGFloat = Spacing.lg * 2  // Internal padding
        let emptyStateHeight: CGFloat = 60  // "No payments this month" message
        
        let paymentCount = currentMonthPayments.count
        
        if paymentCount == 0 {
            return cardHeaderHeight + emptyStateHeight + cardPadding
        }
        
        // Calculate exact height needed for all payments
        let contentHeight = CGFloat(paymentCount) * paymentRowHeight
        return cardHeaderHeight + contentHeight + cardPadding
    }
    
    /// Calculate row heights based on data density
    /// IMPORTANT: Payments Due card has FIXED height - everything else is flexible
    private func calculateRowHeights(availableHeight: CGFloat) -> (row1: CGFloat, row2: CGFloat) {
        let rowSpacing: CGFloat = Spacing.lg
        let totalAvailable = availableHeight - rowSpacing
        
        // If only row 1 has cards, give it all the space
        guard row2CardCount > 0 else {
            return (totalAvailable, 0)
        }
        
        // Calculate weights for each row based on data density
        // Row 1: Budget (1.0) + Tasks (variable) + Guests (high density)
        let row1Weight: CGFloat = 1.0 + dataDensity.taskWeight + (shouldShowGuestResponses ? dataDensity.guestWeight : 0)
        
        // Row 2: Vendors (medium) + Recent (low) - Payments is FIXED, not weighted
        var row2Weight: CGFloat = 0
        if shouldShowVendorList { row2Weight += dataDensity.vendorWeight }
        if shouldShowRecentResponses { row2Weight += 1.0 }
        // Payments Due is NOT included in weight calculation - it's fixed
        
        // If row 2 only has Payments Due (no flexible cards), use minimum height
        if row2FlexibleCardCount == 0 && shouldShowPaymentsDue {
            let paymentsHeight = calculatePaymentsCardHeight()
            return (totalAvailable - paymentsHeight, paymentsHeight)
        }
        
        // Normalize weights and distribute height
        let totalWeight = row1Weight + row2Weight
        let row1Ratio = row1Weight / totalWeight
        let row2Ratio = row2Weight / totalWeight
        
        // Apply minimum heights (at least 150pt per row)
        let minRowHeight: CGFloat = 150
        var row1Height = totalAvailable * row1Ratio
        var row2Height = totalAvailable * row2Ratio
        
        // Ensure row 2 is at least as tall as the Payments Due card needs
        if shouldShowPaymentsDue {
            let paymentsMinHeight = calculatePaymentsCardHeight()
            if row2Height < paymentsMinHeight {
                row2Height = paymentsMinHeight
                row1Height = totalAvailable - row2Height
            }
        }
        
        // Ensure minimums
        if row1Height < minRowHeight {
            row1Height = minRowHeight
            row2Height = totalAvailable - row1Height
        } else if row2Height < minRowHeight {
            row2Height = minRowHeight
            row1Height = totalAvailable - row2Height
        }
        
        return (row1Height, row2Height)
    }
    
    /// Calculate maximum items for a card based on its allocated height
    private func calculateMaxItems(cardHeight: CGFloat) -> Int {
        let cardHeaderHeight: CGFloat = 50  // Title + button
        let itemHeight: CGFloat = 44  // Per item row (slightly larger for touch targets)
        let cardPadding: CGFloat = Spacing.lg * 2  // Internal padding
        
        let availableForItems = cardHeight - cardHeaderHeight - cardPadding
        let maxItems = Int(availableForItems / itemHeight)
        
        return max(maxItems, 2)  // At least 2 items
    }
    
    /// Calculate items for guest responses card (can show more due to data density)
    private func calculateGuestMaxItems(cardHeight: CGFloat) -> Int {
        let cardHeaderHeight: CGFloat = 50
        let itemHeight: CGFloat = 52  // Guest rows are slightly taller (avatar + 2 lines)
        let cardPadding: CGFloat = Spacing.lg * 2
        
        let availableForItems = cardHeight - cardHeaderHeight - cardPadding
        let maxItems = Int(availableForItems / itemHeight)
        
        return max(maxItems, 3)
    }
    
    /// Calculate items for vendor list card
    private func calculateVendorMaxItems(cardHeight: CGFloat) -> Int {
        let cardHeaderHeight: CGFloat = 50
        let itemHeight: CGFloat = 48  // Vendor rows with icon
        let cardPadding: CGFloat = Spacing.lg * 2
        
        let availableForItems = cardHeight - cardHeaderHeight - cardPadding
        let maxItems = Int(availableForItems / itemHeight)
        
        return max(maxItems, 3)
    }
    
    // MARK: - Row-Based Horizontal Alignment Layout

    /// Card type for dynamic content-driven masonry layout
    enum CardType: Hashable {
        case budget           // Budget Overview
        case payments         // Payments Due
        case tasks            // Task Manager
        case vendors          // Vendor List
        case guests           // Guest Responses
        case recentResponses  // Recent Responses

        /// Row assignment - which row does this card belong to?
        var row: Int {
            switch self {
            case .budget, .tasks, .guests: return 1  // Row 1: Budget, Tasks, Guests (tops align)
            case .payments, .vendors, .recentResponses: return 2  // Row 2: Payments, Vendors, Recent (bottoms align)
            }
        }
    }

    /// Alignment offsets for bottom-aligned Row 2 cards
    struct AlignmentOffsets {
        let paymentsOffset: CGFloat
        let vendorsOffset: CGFloat
        let recentOffset: CGFloat

        static let zero = AlignmentOffsets(paymentsOffset: 0, vendorsOffset: 0, recentOffset: 0)

        /// Calculate offsets to align Row 2 card bottoms
        /// Tallest card has offset 0, shorter cards get pushed down
        static func calculate(
            paymentsHeight: CGFloat,
            vendorsHeight: CGFloat,
            recentHeight: CGFloat
        ) -> AlignmentOffsets {
            let maxHeight = max(paymentsHeight, vendorsHeight, recentHeight)

            return AlignmentOffsets(
                paymentsOffset: maxHeight - paymentsHeight,
                vendorsOffset: maxHeight - vendorsHeight,
                recentOffset: maxHeight - recentHeight
            )
        }
    }

    /// Column assignment for intelligent card distribution
    struct ColumnAssignment {
        let column1: [CardType]
        let column2: [CardType]
        let column3: [CardType]

        /// Dynamic cards that expand to fill available space
        /// Guest Responses (.guests) and Vendor List (.vendors) are the primary dynamic cards
        /// Recent Responses (.recentResponses) is also dynamic if shown
        private static let dynamicCardTypes: Set<CardType> = [.vendors, .guests, .recentResponses]

        /// Minimum height needed for a dynamic card to display at least 2 items
        /// Header (~60pt) + 2 rows (~88pt) + padding (~32pt) = ~180pt minimum
        private static let minimumDynamicCardHeight: CGFloat = 180

        /// Bottom buffer for clean visual endpoint across all columns
        private static let bottomBuffer: CGFloat = 24

        /// Calculate optimal column distribution with conditional overflow
        ///
        /// LAYOUT ALGORITHM:
        /// 1. Measure available height for masonry grid
        /// 2. Calculate static card heights: Budget (~260), Payments (~268), Tasks (~136)
        /// 3. Check if all static cards fit in Column 1:
        ///    - If YES: Budget + Payments + Tasks all in Column 1
        ///    - If NO: Budget + Payments in Column 1, Tasks overflows to Column 2
        /// 4. Column 2: Guest Responses fills remaining space (minus Tasks if overflowed)
        /// 5. Column 3: Vendor List fills full column height (with bottom buffer)
        /// 6. Apply bottom buffer (~24pt) to all columns for clean endpoint
        static func distribute(
            cards: [CardType],
            heights: [CardType: CGFloat],
            rowSpacing: CGFloat,
            availableHeight: CGFloat = 800
        ) -> ColumnAssignment {
            // Separate static and dynamic cards
            let staticCards = cards.filter { !dynamicCardTypes.contains($0) }
            let dynamicCards = cards.filter { dynamicCardTypes.contains($0) }

            var columnCards: [Int: [CardType]] = [0: [], 1: [], 2: []]

            // Static card heights (from heights dict or defaults)
            let budgetHeight = heights[.budget] ?? 260
            let paymentsHeight = heights[.payments] ?? 268
            let tasksHeight = heights[.tasks] ?? 136

            // Calculate total height if ALL static cards were in Column 1
            // Budget + Payments + Tasks + spacing between them
            let staticCardCount = [CardType.budget, .payments, .tasks].filter { staticCards.contains($0) }.count
            let spacingNeeded = CGFloat(max(staticCardCount - 1, 0)) * rowSpacing
            let allStaticInColumn1 = budgetHeight + paymentsHeight + tasksHeight + spacingNeeded + bottomBuffer

            // Find specific cards
            let hasBudget = staticCards.contains(.budget)
            let hasPayments = staticCards.contains(.payments)
            let hasTasks = staticCards.contains(.tasks)
            let hasGuestResponses = dynamicCards.contains(.guests)
            let hasVendorList = dynamicCards.contains(.vendors)
            let hasRecentResponses = dynamicCards.contains(.recentResponses)

            // CONDITIONAL FIT CHECK: Do all static cards fit in Column 1?
            let allStaticFit = allStaticInColumn1 <= availableHeight

            print("📊 LAYOUT CHECK: availableHeight=\(availableHeight), allStaticInColumn1=\(allStaticInColumn1), fit=\(allStaticFit)")

            if allStaticFit {
                // ALL static cards fit in Column 1
                // Column 1: Budget + Payments + Tasks
                if hasBudget { columnCards[0]?.append(.budget) }
                if hasPayments { columnCards[0]?.append(.payments) }
                if hasTasks { columnCards[0]?.append(.tasks) }

                // Column 2: Guest Responses (full height)
                if hasGuestResponses {
                    columnCards[1]?.append(.guests)
                } else if hasRecentResponses {
                    columnCards[1]?.append(.recentResponses)
                }

                // Column 3: Vendor List (full height)
                if hasVendorList {
                    columnCards[2]?.append(.vendors)
                }

                print("📊 LAYOUT: ALL static fit → Budget+Payments+Tasks in col 1")
            } else {
                // Tasks overflows to Column 2 (Budget + Payments stay in Column 1)
                // Column 1: Budget + Payments only
                if hasBudget { columnCards[0]?.append(.budget) }
                if hasPayments { columnCards[0]?.append(.payments) }

                // Column 2: Tasks (overflowed) + Guest Responses (fills remaining)
                if hasTasks { columnCards[1]?.append(.tasks) }
                if hasGuestResponses {
                    columnCards[1]?.append(.guests)
                } else if hasRecentResponses {
                    columnCards[1]?.append(.recentResponses)
                }

                // Column 3: Vendor List (full height)
                if hasVendorList {
                    columnCards[2]?.append(.vendors)
                }

                print("📊 LAYOUT: OVERFLOW → Tasks to col 2, Guests fills remaining")
            }

            // Handle edge case: Recent Responses as additional card
            if hasRecentResponses && hasGuestResponses {
                // If we have both, Recent Responses goes below Guests
                columnCards[1]?.append(.recentResponses)
            }

            print("📊 Column 0: \(columnCards[0] ?? [])")
            print("📊 Column 1: \(columnCards[1] ?? [])")
            print("📊 Column 2: \(columnCards[2] ?? [])")

            return ColumnAssignment(
                column1: columnCards[0] ?? [],
                column2: columnCards[1] ?? [],
                column3: columnCards[2] ?? []
            )
        }
    }

    /// Layout configuration for dynamic masonry with intelligent card distribution
    struct ColumnLayout {
        let availableHeight: CGFloat
        let availableWidth: CGFloat
        let columnCount: Int
        let columnWidth: CGFloat
        let cardSpacing: CGFloat
        let rowSpacing: CGFloat  // Spacing between rows

        // Visible cards (determined by user settings)
        let visibleCards: [CardType]
    }

    /// Log layout dimensions for debugging alignment issues
    /// Called from GeometryReader to output total page height, fixed components, and dynamic grid
    private func logLayoutDimensions(
        totalHeight: CGFloat,
        totalWidth: CGFloat,
        headerHeight: CGFloat,
        metricCardsHeight: CGFloat,
        topPadding: CGFloat,
        bottomPadding: CGFloat,
        horizontalPadding: CGFloat
    ) {
        let fixedComponentsHeight = headerHeight + metricCardsHeight + topPadding + bottomPadding + Spacing.lg * 2  // VStack spacing
        let dynamicGridHeight = totalHeight  // This is the GeometryReader's available height
        
        // Calculate column widths
        let cardSpacing = Spacing.sm  // 8pt between columns
        let columnCount: CGFloat = 3
        let totalSpacing = cardSpacing * (columnCount - 1)  // 16pt total
        let contentWidth = totalWidth - horizontalPadding * 2  // Width available for columns
        let columnWidth = (contentWidth - totalSpacing) / columnCount
        
        print("📐 DASHBOARD LAYOUT DIMENSIONS:")
        print("   📏 Total page height (GeometryReader): \(totalHeight)pt")
        print("   📏 Total page width: \(totalWidth)pt")
        print("   📦 Fixed components:")
        print("      - Header: \(headerHeight)pt")
        print("      - Metric cards: \(metricCardsHeight)pt")
        print("      - Top padding: \(topPadding)pt")
        print("      - Bottom padding: \(bottomPadding)pt")
        print("      - VStack spacing (2x): \(Spacing.lg * 2)pt")
        print("      - Total fixed: \(fixedComponentsHeight)pt")
        print("   📊 Dynamic grid height: \(dynamicGridHeight)pt")
        print("   📐 Horizontal layout:")
        print("      - Window width: \(totalWidth)pt")
        print("      - Horizontal padding: \(horizontalPadding)pt (each side, total: \(horizontalPadding * 2)pt)")
        print("      - Content width (for columns): \(contentWidth)pt")
        print("      - Column spacing: \(cardSpacing)pt (total: \(totalSpacing)pt)")
        print("      - Column width: \(columnWidth)pt (x3 = \(columnWidth * 3)pt)")
        print("      - Verification: columns + spacing = \(columnWidth * 3 + totalSpacing)pt (should equal \(contentWidth)pt)")
        print("   📐 Edge distances:")
        print("      - Left edge to first card: \(horizontalPadding)pt")
        print("      - Last card to right edge: \(horizontalPadding)pt")
    }
    
    /// Calculate column layout based on available space and visible cards
    private func calculateColumnLayout(availableHeight: CGFloat, availableWidth: CGFloat) -> ColumnLayout {
        let cardSpacing = Spacing.sm  // Horizontal spacing between columns (8pt)
        let rowSpacing = Spacing.lg   // Vertical spacing between rows
        let columnCount = 3  // 3-column layout
        let totalSpacing = cardSpacing * CGFloat(columnCount - 1)
        let columnWidth = (availableWidth - totalSpacing) / CGFloat(columnCount)

        // Determine which cards are visible based on user settings
        var visibleCards: [CardType] = [.budget, .tasks]  // Budget and Tasks always visible

        // DEBUG: Log card visibility conditions
        print("🔍 Dashboard Card Visibility:")
        print("  - Guests count: \(guestStore.guests.count), shouldShow: \(shouldShowGuestResponses)")
        print("  - Vendors count: \(vendorStore.vendors.count), shouldShow: \(shouldShowVendorList)")
        print("  - Payments count: \(currentMonthPayments.count), shouldShow: \(shouldShowPaymentsDue)")
        print("  - Recent responses: \(shouldShowRecentResponses)")

        if shouldShowPaymentsDue {
            visibleCards.append(.payments)
        }
        if shouldShowVendorList {
            visibleCards.append(.vendors)
        }
        if shouldShowGuestResponses {
            visibleCards.append(.guests)
        }
        if shouldShowRecentResponses {
            visibleCards.append(.recentResponses)
        }

        print("  - Visible cards: \(visibleCards)")
        print("  - Available height: \(availableHeight), width: \(availableWidth)")

        return ColumnLayout(
            availableHeight: availableHeight,
            availableWidth: availableWidth,
            columnCount: columnCount,
            columnWidth: columnWidth,
            cardSpacing: cardSpacing,
            rowSpacing: rowSpacing,
            visibleCards: visibleCards
        )
    }
}

// MARK: - Custom Column Top Alignment

/// Custom vertical alignment that ensures all columns start at exactly the same Y position
/// This fixes the issue where HStack's default .top alignment computes differently for VStacks with different content
private extension VerticalAlignment {
    struct ColumnTopAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            // Return the top edge of the view's bounds
            context[.top]
        }
    }

    static let columnTop = VerticalAlignment(ColumnTopAlignment.self)
}

// MARK: - Masonry Columns View

/// Dynamic masonry layout with content-driven heights and horizontal alignment
/// Row 1 cards (Budget, Tasks, Guests) align their tops
/// Row 2 cards (Payments, Vendors, Recent) align their bottoms via calculated offsets
struct MasonryColumnsView: View {
    let columnLayout: DashboardViewV7.ColumnLayout
    let budgetStore: BudgetStoreV2
    let taskStore: TaskStoreV2
    let guestStore: GuestStoreV2
    let vendorStore: VendorStoreV2
    let settingsStore: SettingsStoreV2
    let coordinator: AppCoordinator
    let viewModel: DashboardViewModel
    let shouldShowGuestResponses: Bool
    let shouldShowPaymentsDue: Bool
    let shouldShowVendorList: Bool
    let shouldShowRecentResponses: Bool
    let currentMonthPayments: [PaymentSchedule]

    // MARK: - Intelligent Distribution

    /// Column assignments calculated with estimated heights
    /// This prevents the need for hidden rendering - we use estimated heights based on content
    @State private var columnAssignment: DashboardViewV7.ColumnAssignment = DashboardViewV7.ColumnAssignment(
        column1: [],
        column2: [],
        column3: []
    )

    // MARK: - Static vs Dynamic Card Classification

    /// Cards are classified as:
    /// - STATIC: Budget (fixed size), Payments (based on payment count), Tasks (based on task count, max 3)
    /// - DYNAMIC: Guest Responses and Vendors (fill remaining space in their dedicated columns)
    private var staticCards: [DashboardViewV7.CardType] {
        [.budget, .payments, .tasks]  // Static cards go in column 1
    }

    private var dynamicCards: [DashboardViewV7.CardType] {
        [.guests, .vendors, .recentResponses]  // Dynamic cards expand to fill column space
    }

    /// Check if a card is dynamic (fills remaining space)
    private func isDynamicCard(_ cardType: DashboardViewV7.CardType) -> Bool {
        cardType == .guests || cardType == .vendors || cardType == .recentResponses
    }

    /// Calculate static card height (content-based, exact sizing)
    private func staticCardHeight(for cardType: DashboardViewV7.CardType) -> CGFloat {
        let cardHeaderHeight: CGFloat = 60  // Title + spacing
        let cardPadding: CGFloat = 32  // Vertical padding inside card
        let rowHeight: CGFloat = 44  // Height per item row

        switch cardType {
        case .budget:
            // Budget Overview: Completely static (fixed content)
            return 260

        case .payments:
            // Payments Due: Exact size for actual payment count
            let paymentCount = currentMonthPayments.count
            let contentHeight = CGFloat(max(paymentCount, 1)) * rowHeight
            return cardHeaderHeight + contentHeight + cardPadding

        case .tasks:
            // Task Manager: Based on task count (max 3)
            let taskCount = min(taskStore.tasks.filter { $0.status != .completed }.count, 3)
            let contentHeight = CGFloat(max(taskCount, 1)) * rowHeight
            return cardHeaderHeight + contentHeight + cardPadding

        default:
            // Dynamic cards (guests, vendors) don't use this function
            return 200  // Fallback (shouldn't reach here for static cards)
        }
    }

    /// Estimate card heights based on their type and content
    /// Static cards get exact content-based heights
    /// Dynamic cards fill remaining space after static cards are placed
    private func estimateCardHeight(for cardType: DashboardViewV7.CardType) -> CGFloat {
        let cardHeaderHeight: CGFloat = 60  // Title + spacing
        let cardPadding: CGFloat = 32  // Vertical padding inside card
        let rowHeight: CGFloat = 44  // Height per item row

        switch cardType {
        case .budget:
            // Budget Overview: Completely static card (no variable content)
            return 260

        case .tasks:
            // Task Manager: Content-based (max 3 tasks)
            let taskCount = min(taskStore.tasks.filter { $0.status != .completed }.count, 3)
            let contentHeight = CGFloat(max(taskCount, 1)) * rowHeight
            return cardHeaderHeight + contentHeight + cardPadding

        case .payments:
            // Payment Due: Exact size for actual payment count (no extra space)
            // Use actual count, minimum 1 row for empty state
            let paymentCount = currentMonthPayments.count
            let contentHeight = CGFloat(max(paymentCount, 1)) * rowHeight
            return cardHeaderHeight + contentHeight + cardPadding

        case .guests, .vendors, .recentResponses:
            // Dynamic cards - height calculated after distribution (placeholder for bin-packing)
            // Actual height is set in calculateDynamicCardHeights() after column assignment
            return 200  // Initial estimate for bin-packing (will be replaced)
        }
    }

    /// Calculate estimated heights for all visible cards (initial pass for bin-packing)
    private var estimatedCardHeights: [DashboardViewV7.CardType: CGFloat] {
        var heights: [DashboardViewV7.CardType: CGFloat] = [:]
        for card in columnLayout.visibleCards {
            heights[card] = estimateCardHeight(for: card)
        }
        return heights
    }

    /// Calculate dynamic card heights AFTER column assignment is known
    /// Dynamic cards fill remaining space in their column; 50/50 split if both share a column
    private func calculateDynamicCardHeights(for column: [DashboardViewV7.CardType]) -> [DashboardViewV7.CardType: CGFloat] {
        var heights: [DashboardViewV7.CardType: CGFloat] = [:]
        let availableHeight = columnLayout.availableHeight

        // Calculate total height used by static cards in this column
        var staticHeight: CGFloat = 0
        var dynamicCardsInColumn: [DashboardViewV7.CardType] = []

        for card in column {
            if isDynamicCard(card) {
                dynamicCardsInColumn.append(card)
            } else {
                // Static card - use exact content-based height
                let cardHeight = staticCardHeight(for: card)
                heights[card] = cardHeight
                staticHeight += cardHeight
            }
        }

        // Add spacing between cards (N-1 gaps for N cards)
        if column.count > 1 {
            staticHeight += CGFloat(column.count - 1) * columnLayout.rowSpacing
        }

        // Bottom buffer for clean visual endpoint
        let bottomBuffer: CGFloat = 24

        // Calculate remaining space for dynamic cards (with bottom buffer)
        let remainingHeight = max(availableHeight - staticHeight - bottomBuffer, 0)

        // Distribute remaining space to dynamic cards
        // Both Guest Responses and Vendor List fill available space (with bottom buffer)
        // Note: Tasks is STATIC (already counted in staticHeight), so dynamicCardsInColumn
        // will only contain truly dynamic cards like .guests, .vendors, .recentResponses
        if dynamicCardsInColumn.count == 1 {
            let dynamicCard = dynamicCardsInColumn[0]
            // Dynamic card fills remaining space (shows as many items as fit)
            let dynamicHeight = max(remainingHeight, 150)
            heights[dynamicCard] = dynamicHeight
            print("📊 \(dynamicCard) fills column: \(dynamicHeight)pt (with \(bottomBuffer)pt buffer)")
        } else if dynamicCardsInColumn.count >= 2 {
            // Multiple dynamic cards split space evenly
            let gaps = CGFloat(dynamicCardsInColumn.count - 1) * columnLayout.rowSpacing
            let heightPerCard = max((remainingHeight - gaps) / CGFloat(dynamicCardsInColumn.count), 120)
            for card in dynamicCardsInColumn {
                heights[card] = heightPerCard
            }
            print("📊 Multiple dynamic cards: \(heightPerCard)pt each")
        }
        // If no dynamic cards, heights dict only has static cards (already set)

        return heights
    }

    /// Final calculated heights per column (after layout is known)
    @State private var finalCardHeights: [DashboardViewV7.CardType: CGFloat] = [:]

    var body: some View {
        // Use custom columnTop alignment to ensure all columns start at exactly the same Y position
        // This fixes the issue where standard .top alignment computes differently for VStacks with varying content
        HStack(alignment: .columnTop, spacing: columnLayout.cardSpacing) {
            // Column 1
            columnView(for: columnAssignment.column1, columnIndex: 0)

            // Column 2
            columnView(for: columnAssignment.column2, columnIndex: 1)

            // Column 3
            columnView(for: columnAssignment.column3, columnIndex: 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            // Step 1: Distribute cards using static heights for bin-packing
            // Dynamic cards (Vendors, Guest Responses) are separated into different columns when possible
            if columnAssignment.column1.isEmpty {
                columnAssignment = DashboardViewV7.ColumnAssignment.distribute(
                    cards: columnLayout.visibleCards,
                    heights: estimatedCardHeights,
                    rowSpacing: columnLayout.rowSpacing,
                    availableHeight: columnLayout.availableHeight
                )

                // Step 2: Calculate final heights with dynamic cards filling remaining space
                var allHeights: [DashboardViewV7.CardType: CGFloat] = [:]
                for heights in [
                    calculateDynamicCardHeights(for: columnAssignment.column1),
                    calculateDynamicCardHeights(for: columnAssignment.column2),
                    calculateDynamicCardHeights(for: columnAssignment.column3)
                ] {
                    allHeights.merge(heights) { _, new in new }
                }
                finalCardHeights = allHeights

                print("✅ Dashboard layout: static-first, dynamic fills remaining space")
                print("   Final heights: \(finalCardHeights)")
            }
        }
    }

    /// Get the final calculated height for a card (uses finalCardHeights after layout)
    private func finalHeight(for cardType: DashboardViewV7.CardType) -> CGFloat {
        if let height = finalCardHeights[cardType] {
            return height
        }
        // Fallback to estimate if not yet calculated
        return estimateCardHeight(for: cardType)
    }
    // MARK: - Helper Views

    /// Build a column with dynamically assigned cards
    /// Cards fill available height with no bottom space (dynamic cards expand to fill)
    /// Uses custom columnTop alignment guide to ensure all columns start at the same Y position
    /// All columns are constrained to the same height (columnLayout.availableHeight) for visual consistency
    @ViewBuilder
    private func columnView(for cards: [DashboardViewV7.CardType], columnIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: columnLayout.rowSpacing) {
            ForEach(cards, id: \.self) { cardType in
                cardView(for: cardType)
                    .frame(width: columnLayout.columnWidth)
            }
            // Add spacer to push content to top when column has less content
            Spacer(minLength: 0)
        }
        // Constrain all columns to the same width AND height for visual consistency
        // This ensures all columns start and end at the same Y positions
        .frame(width: columnLayout.columnWidth, height: columnLayout.availableHeight, alignment: .top)
        // Use custom columnTop alignment to force all columns to start at the same Y position
        // Return 0 to ensure all columns align at the top of the HStack
        .alignmentGuide(.columnTop) { dimension in
            let topValue = dimension[.top]
            print("📐 Column \(columnIndex) alignment: top=\(topValue), height=\(dimension.height), width=\(dimension.width)")
            return topValue
        }
    }

    /// Build individual card view based on type
    /// Uses finalHeight for accurate sizing (static cards = content-based, dynamic cards = fill remaining)
    @ViewBuilder
    private func cardView(for cardType: DashboardViewV7.CardType) -> some View {
        let height = finalHeight(for: cardType)

        switch cardType {
        case .budget:
            BudgetOverviewCardV7(
                totalBudget: viewModel.totalBudget,
                totalSpent: viewModel.totalPaid
            )
            .frame(height: height)  // Static height (260pt)

        case .payments:
            PaymentsDueCardV7(maxItems: 5)
            .frame(height: height)  // Content-based height

        case .tasks:
            TaskManagerCardV7(
                store: taskStore,
                maxItems: 3,  // Max 3 tasks
                cardHeight: height
            )
            .frame(height: height)  // Content-based height

        case .vendors:
            VendorListCardV7(
                store: vendorStore,
                maxItems: 10,  // Dynamic - card calculates based on available height
                cardHeight: height
            )
            .frame(height: height)  // Dynamic - fills remaining space

        case .guests:
            GuestResponsesCardV7(
                store: guestStore,
                maxItems: 99,  // Dynamic - card calculates based on available height
                cardHeight: height
            )
            .frame(height: height)  // Dynamic - fills available space with more guests
            .environmentObject(settingsStore)
            .environmentObject(budgetStore)
            .environmentObject(coordinator)

        case .recentResponses:
            RecentResponsesCardV7(
                store: guestStore,
                maxItems: 10,  // Dynamic - card calculates based on available height
                cardHeight: height
            )
            .frame(height: height)  // Dynamic - fills remaining space
        }
    }
}

// MARK: - Mesh Gradient Background

/// Enhanced mesh gradient background with vibrant, saturated colors
/// Inspired by guest_management.png glassmorphism design
/// Features larger blobs, higher saturation, and stronger blur for depth
struct MeshGradientBackgroundV7: View {
    @EnvironmentObject private var settingsStore: SettingsStoreV2
    
    var body: some View {
        let colors = AppGradients.meshGradientColors(for: settingsStore.settings.theme)
        
        return ZStack {
            // Base color with subtle warmth
            colors.base
            
            // Vibrant color blobs - larger and more saturated for glassmorphism effect
            GeometryReader { geometry in
                ZStack {
                    // Blob 1 - Large pink/primary blob top-left area
                    Circle()
                        .fill(colors.blob1)
                        .frame(width: 500, height: 500)
                        .blur(radius: 120)
                        .position(x: geometry.size.width * 0.15, y: geometry.size.height * 0.15)
                    
                    // Blob 2 - Large green/secondary blob bottom-right
                    Circle()
                        .fill(colors.blob2)
                        .frame(width: 600, height: 600)
                        .blur(radius: 130)
                        .position(x: geometry.size.width * 0.85, y: geometry.size.height * 0.75)
                    
                    // Blob 3 - Purple/accent blob center-right
                    Circle()
                        .fill(colors.blob3)
                        .frame(width: 450, height: 450)
                        .blur(radius: 110)
                        .position(x: geometry.size.width * 0.7, y: geometry.size.height * 0.35)
                    
                    // Blob 4 - Secondary pink blob bottom-left for balance
                    Circle()
                        .fill(colors.blob1.opacity(0.6))
                        .frame(width: 400, height: 400)
                        .blur(radius: 100)
                        .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.85)
                    
                    // Blob 5 - Small accent blob top-right
                    Circle()
                        .fill(colors.blob3.opacity(0.5))
                        .frame(width: 300, height: 300)
                        .blur(radius: 90)
                        .position(x: geometry.size.width * 0.9, y: geometry.size.height * 0.1)
                    
                    // Blob 6 - Center green accent for depth
                    Circle()
                        .fill(colors.blob2.opacity(0.4))
                        .frame(width: 350, height: 350)
                        .blur(radius: 100)
                        .position(x: geometry.size.width * 0.4, y: geometry.size.height * 0.55)
                }
            }
        }
    }
}

// MARK: - Dashboard Header

struct DashboardHeaderV7: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Wedding Planning")
                    .font(Typography.title2)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Text("Wedding Planner - Dec 11, 2026")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
            
            Spacer()
            
            HStack(spacing: Spacing.md) {
                // Import Button
                Button {
                    // Import action
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import")
                    }
                    .font(Typography.bodySmall.weight(.semibold))
                    .foregroundColor(SemanticColors.textPrimary)
                }
                .buttonStyle(.plain)
                .glassPanel(cornerRadius: CornerRadius.lg, padding: Spacing.sm)
                
                // Export Button
                Button {
                    // Export action
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export")
                    }
                    .font(Typography.bodySmall.weight(.semibold))
                    .foregroundColor(SemanticColors.textPrimary)
                }
                .buttonStyle(.plain)
                .glassPanel(cornerRadius: CornerRadius.lg, padding: Spacing.sm)
                
                // Add Guest Button
                Button {
                    // Add guest action
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "plus")
                        Text("Add Guest")
                    }
                    .font(Typography.bodySmall.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .fill(AppGradients.weddingPink)
                    )
                    .shadow(color: AppGradients.weddingPink.opacity(0.5), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Hero Banner with Live Countdown

struct HeroBannerV7: View {
    let weddingDate: Date?
    let partner1Name: String
    let partner2Name: String
    let currentTime: Date
    
    private var weddingTitle: String {
        if !partner1Name.isEmpty && !partner2Name.isEmpty {
            return "\(partner1Name) & \(partner2Name)'s Wedding"
        } else if !partner1Name.isEmpty {
            return "\(partner1Name)'s Wedding"
        } else if !partner2Name.isEmpty {
            return "\(partner2Name)'s Wedding"
        } else {
            return "Our Wedding"
        }
    }
    
    private var countdown: (days: Int, hours: Int, minutes: Int, seconds: Int) {
        guard let weddingDate = weddingDate else {
            return (0, 0, 0, 0)
        }
        let interval = weddingDate.timeIntervalSince(currentTime)
        guard interval > 0 else { return (0, 0, 0, 0) }
        
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        
        return (days, hours, minutes, seconds)
    }
    
    private var formattedDate: String {
        guard let date = weddingDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack {
            // Left side - Wedding info
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(weddingTitle)
                    .font(Typography.title2)
                    .foregroundColor(SemanticColors.textPrimary)
                
                if weddingDate != nil {
                    Text(formattedDate)
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }
            
            Spacer()
            
            // Right side - Countdown
            HStack(spacing: Spacing.xl) {
                // Days
                VStack(spacing: Spacing.xxs) {
                    Text("\(countdown.days)")
                        .font(Typography.displayMedium)
                        .foregroundColor(SemanticColors.textPrimary)
                    Text("DAYS")
                        .font(Typography.caption2)
                        .foregroundColor(SemanticColors.textSecondary)
                        .tracking(1.2)
                }
                
                // Divider
                Rectangle()
                    .fill(SemanticColors.borderLight)
                    .frame(width: 1, height: 40)
                
                // Time components
                HStack(spacing: Spacing.lg) {
                    CountdownUnitV7(value: countdown.hours, label: "Hours")
                    Text(":")
                        .font(Typography.title3)
                        .foregroundColor(SemanticColors.textSecondary)
                    CountdownUnitV7(value: countdown.minutes, label: "Minutes")
                    Text(":")
                        .font(Typography.title3)
                        .foregroundColor(SemanticColors.textSecondary)
                    CountdownUnitV7(value: countdown.seconds, label: "Seconds")
                }
            }
        }
        .padding(Spacing.xxl)
        .glassPanel(cornerRadius: CornerRadius.xxl, padding: 0)
        .overlay(
            // Decorative pink circle
            Circle()
                .fill(BlushPink.shade100.opacity(0.5))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: 100, y: -50),
            alignment: .topTrailing
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xxl))
    }
}

struct CountdownUnitV7: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Text(String(format: "%02d", value))
                .font(Typography.numberMedium)
                .foregroundColor(SemanticColors.textPrimary)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(SemanticColors.textSecondary)
                .textCase(.uppercase)
        }
    }
}

// MARK: - Metric Cards

struct RSVPMetricCardV7: View {
    let confirmed: Int
    let pending: Int
    let total: Int
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(confirmed) / Double(total)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Total Responses")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                    Text("\(confirmed + pending) RSVP")
                        .font(Typography.title3)
                        .foregroundColor(SemanticColors.textPrimary)
                }
                
                Spacer()
                
                NativeIconBadge(
                    systemName: "person.2.fill",
                    color: AppGradients.weddingPink,
                    size: 40
                )
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppGradients.weddingPink)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(AppGradients.weddingPink)
                        .frame(width: 6, height: 6)
                    Text("Confirmed: \(confirmed)")
                        .font(Typography.caption2)
                        .foregroundColor(SemanticColors.textSecondary)
                }
                
                Spacer()
                
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                    Text("Pending: \(pending)")
                        .font(Typography.caption2)
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }
        }
        .glassPanel()
    }
}

struct VendorMetricCardV7: View {
    let booked: Int
    let total: Int
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(booked) / Double(total)
    }
    
    private var percentage: Int {
        guard total > 0 else { return 0 }
        return Int((Double(booked) / Double(total)) * 100)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Vendors Booked")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                        Text("\(booked)")
                            .font(Typography.title3)
                            .foregroundColor(SemanticColors.textPrimary)
                        Text("/ \(total)")
                            .font(Typography.bodyRegular)
                            .foregroundColor(SemanticColors.textTertiary)
                    }
                }
                
                Spacer()
                
                NativeIconBadge(
                    systemName: "wrench.and.screwdriver.fill",
                    color: AppGradients.sageDark,
                    size: 40
                )
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppGradients.sageDark)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
            
            Text("\(percentage)% Completed")
                .font(Typography.caption2)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .glassPanel()
    }
}

struct BudgetMetricCardV7: View {
    let spent: Double
    let total: Double
    let percentage: Double
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(spent / total, 1.0)
    }
    
    private var formattedSpent: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: spent)) ?? "$0"
    }
    
    private var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: total)) ?? "$0"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Budget Used")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                    Text(formattedSpent)
                        .font(Typography.title3)
                        .foregroundColor(SemanticColors.textPrimary)
                }
                
                Spacer()
                
                NativeIconBadge(
                    systemName: "dollarsign.circle.fill",
                    color: AppGradients.sageDark,
                    size: 40
                )
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppGradients.sageDark)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
            
            Text("Total Budget: \(formattedTotal)")
                .font(Typography.caption2)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .glassPanel()
    }
}

// MARK: - Countdown Metric Card

struct CountdownMetricCardV7: View {
    let weddingDate: Date?
    let partner1Name: String
    let partner2Name: String
    let currentTime: Date

    private var daysUntil: Int {
        guard let weddingDate = weddingDate else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: currentTime), to: calendar.startOfDay(for: weddingDate))
        return max(components.day ?? 0, 0)
    }

    private var formattedDate: String {
        guard let weddingDate = weddingDate else { return "Date TBD" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: weddingDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Days Until Wedding")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                    Text("\(daysUntil) DAYS")
                        .font(Typography.title3)
                        .foregroundColor(SemanticColors.textPrimary)
                }

                Spacer()

                NativeIconBadge(
                    systemName: "heart.fill",
                    color: AppGradients.weddingPink,
                    size: 40
                )
            }

            // Wedding date subtitle
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("\(partner1Name) & \(partner2Name)")
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textSecondary)
                    .lineLimit(1)

                Text(formattedDate)
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textSecondary)
            }
        }
        .glassPanel()
    }
}

// MARK: - Budget Overview Card

struct BudgetOverviewCardV7: View {
    let totalBudget: Double
    let totalSpent: Double
    
    private var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: totalBudget)) ?? "$0"
    }
    
    private var formattedSpent: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: totalSpent)) ?? "$0"
    }
    
    private var spentProgress: Double {
        guard totalBudget > 0 else { return 0 }
        return min(totalSpent / totalBudget, 1.0)
    }
    
    private var remainingProgress: Double {
        guard totalBudget > 0 else { return 0 }
        let remaining = max(totalBudget - totalSpent, 0)
        return min(remaining / totalBudget, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text("Budget Overview")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Spacer()
                
                Text(formattedTotal)
                    .font(Typography.title3)
                    .foregroundColor(SemanticColors.textPrimary)
            }
            
            VStack(spacing: Spacing.lg) {
                // Progress bar 1 - Spent
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppGradients.sageDark)
                            .frame(width: geometry.size.width * spentProgress, height: 8)
                    }
                }
                .frame(height: 8)
                
                // Progress bar 2 - Remaining
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: geometry.size.width * remainingProgress, height: 8)
                    }
                }
                .frame(height: 8)
            }
            
            HStack {
                Text(formattedSpent)
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textSecondary)

                Spacer()

                Text(formattedTotal)
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textSecondary)
            }
        }
        // Static size - no expansion (budget card has fixed content)
        .glassPanel()
    }
}

// MARK: - Task Manager Card

struct TaskManagerCardV7: View {
    @ObservedObject var store: TaskStoreV2
    let maxItems: Int
    let cardHeight: CGFloat
    
    /// Item height for task rows
    private let itemHeight: CGFloat = 44
    
    private var recentTasks: [WeddingTask] {
        // Get dynamically calculated number of tasks, prioritizing incomplete tasks
        store.tasks
            .sorted { (t1, t2) in
                // Incomplete tasks first
                if t1.status != .completed && t2.status == .completed {
                    return true
                } else if t1.status == .completed && t2.status != .completed {
                    return false
                }
                // Then by due date (soonest first)
                if let date1 = t1.dueDate, let date2 = t2.dueDate {
                    return date1 < date2
                }
                // Tasks with due dates come before those without
                if t1.dueDate != nil {
                    return true
                } else if t2.dueDate != nil {
                    return false
                }
                // Finally by creation date (newest first)
                return t1.createdAt > t2.createdAt
            }
            .prefix(maxItems)
            .map { $0 }
    }
    
    /// Calculate dynamic row spacing to distribute items evenly
    private var dynamicRowSpacing: CGFloat {
        let headerHeight: CGFloat = 50
        let padding: CGFloat = Spacing.lg * 2
        let availableForItems = cardHeight - headerHeight - padding
        
        let itemCount = recentTasks.count
        guard itemCount > 1 else { return Spacing.sm }
        
        let totalItemHeight = CGFloat(itemCount) * itemHeight
        
        // If items don't fill space, distribute extra space as row spacing
        if totalItemHeight < availableForItems {
            let extraSpace = availableForItems - totalItemHeight
            let gaps = CGFloat(itemCount - 1)
            let extraPerGap = extraSpace / gaps
            return Spacing.sm + extraPerGap
        }
        
        return Spacing.sm
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Task Manager")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Spacer()
                
                Button("View All") {
                    // View all action
                }
                .font(Typography.caption)
                .foregroundColor(AppGradients.weddingPink)
            }
            
            if recentTasks.isEmpty {
                Text("No tasks yet")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Spacing.lg)
            } else {
                VStack(alignment: .leading, spacing: dynamicRowSpacing) {
                    ForEach(recentTasks) { task in
                        TaskRowV7(
                            title: task.taskName,
                            isCompleted: task.status == .completed
                        )
                        .frame(height: itemHeight)
                    }
                }
            }
        }
        // Content-sized - no expansion (task card sizes to actual task count)
        .glassPanel()
    }
}

struct TaskRowV7: View {
    let title: String
    let isCompleted: Bool
    @State private var checked: Bool
    
    init(title: String, isCompleted: Bool) {
        self.title = title
        self.isCompleted = isCompleted
        self._checked = State(initialValue: isCompleted)
    }
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Button {
                checked.toggle()
            } label: {
                Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(checked ? AppGradients.weddingPink : SemanticColors.textTertiary)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
            
            Text(title)
                .font(Typography.bodySmall)
                .foregroundColor(checked ? AppGradients.weddingPink : SemanticColors.textPrimary)
                .strikethrough(checked, color: AppGradients.weddingPink)
        }
    }
}

// MARK: - Guest Responses Card

struct GuestResponsesCardV7: View {
    @ObservedObject var store: GuestStoreV2
    let maxItems: Int  // Ignored - calculated dynamically from cardHeight
    let cardHeight: CGFloat
    @EnvironmentObject private var settingsStore: SettingsStoreV2

    /// Item height for guest rows (avatar + 2 lines)
    private let itemHeight: CGFloat = 52

    /// Calculate how many guests fit within the card height
    private var calculatedMaxItems: Int {
        let headerHeight: CGFloat = 50  // Title + menu
        let cardPadding: CGFloat = Spacing.lg * 2  // Internal padding
        let availableForItems = cardHeight - headerHeight - cardPadding
        let maxItems = Int(availableForItems / itemHeight)
        return max(maxItems, 2)  // At least 2 items
    }

    private var recentGuests: [Guest] {
        // Get dynamically calculated number of guests based on available height
        store.guests
            .sorted { (g1, g2) in
                if let date1 = g1.rsvpDate, let date2 = g2.rsvpDate {
                    return date1 > date2
                } else if g1.rsvpDate != nil {
                    return true
                } else if g2.rsvpDate != nil {
                    return false
                } else {
                    return g1.createdAt > g2.createdAt
                }
            }
            .prefix(calculatedMaxItems)  // Use calculated max based on height
            .map { $0 }
    }
    
    /// Calculate dynamic row spacing to distribute items evenly
    private var dynamicRowSpacing: CGFloat {
        let headerHeight: CGFloat = 50
        let padding: CGFloat = Spacing.lg * 2
        let availableForItems = cardHeight - headerHeight - padding
        
        let itemCount = recentGuests.count
        guard itemCount > 1 else { return Spacing.md }
        
        let totalItemHeight = CGFloat(itemCount) * itemHeight
        
        // If items don't fill space, distribute extra space as row spacing
        if totalItemHeight < availableForItems {
            let extraSpace = availableForItems - totalItemHeight
            let gaps = CGFloat(itemCount - 1)
            let extraPerGap = extraSpace / gaps
            return Spacing.md + extraPerGap
        }
        
        return Spacing.md
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Guest Responses")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                Spacer()

                Image(systemName: "ellipsis")
                    .foregroundColor(SemanticColors.textTertiary)
            }

            if recentGuests.isEmpty {
                Text("No guest responses yet")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                VStack(spacing: dynamicRowSpacing) {
                    ForEach(recentGuests) { guest in
                        GuestRowV7(
                            guest: guest,
                            invitedBy: guest.invitedBy?.displayName(with: settingsStore.settings) ?? "Unknown",
                            status: mapRSVPStatus(guest.rsvpStatus)
                        )
                        .frame(height: itemHeight)
                    }
                }
            }

            // Fill remaining vertical space (dynamic card behavior)
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        // Dynamic - fills available height with as many guests as fit
        .glassPanel()
        .onAppear {
            print("📊 GuestResponsesCardV7: cardHeight=\(cardHeight), calculatedMaxItems=\(calculatedMaxItems), guestCount=\(store.guests.count), showing=\(recentGuests.count)")
        }
    }

    private func mapRSVPStatus(_ status: RSVPStatus) -> GuestStatusV7 {
        switch status {
        case .attending, .confirmed:
            return .confirmed
        case .declined, .noResponse:
            return .declined
        default:
            return .pending
        }
    }
}

enum GuestStatusV7 {
    case confirmed, pending, declined
    
    var color: Color {
        switch self {
        case .confirmed: return AppGradients.sageDark
        case .pending: return SoftLavender.shade500
        case .declined: return Terracotta.shade500
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .confirmed: return AppGradients.sageGreen.opacity(0.5)
        case .pending: return SoftLavender.shade100
        case .declined: return Terracotta.shade100
        }
    }
    
    var text: String {
        switch self {
        case .confirmed: return "Confirmed"
        case .pending: return "Pending"
        case .declined: return "Declined"
        }
    }
}

struct GuestRowV7: View {
    let guest: Guest
    let invitedBy: String
    let status: GuestStatusV7
    
    @State private var avatarImage: NSImage?
    
    private var initials: String {
        "\(guest.firstName.prefix(1))\(guest.lastName.prefix(1))".uppercased()
    }
    
    var body: some View {
        HStack {
            // Avatar with MultiAvatarJSService
            avatarView
                .task {
                    await loadAvatar()
                }
                .accessibilityLabel("Avatar for \(guest.fullName)")
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(guest.fullName)
                    .font(Typography.bodySmall)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Text(invitedBy)
                    .font(.system(size: 10))
                    .foregroundColor(SemanticColors.textSecondary)
            }
            
            Spacer()
            
            // Status badge
            Text(status.text.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(status.color)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(
                    Capsule()
                        .fill(status.backgroundColor)
                )
        }
    }
    
    // MARK: - Avatar View
    
    @ViewBuilder
    private var avatarView: some View {
        if let image = avatarImage {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        } else {
            // Fallback to initials with status color
            Circle()
                .fill(status.color.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(initials)
                        .font(Typography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(status.color)
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
        }
    }
    
    // MARK: - Avatar Loading
    
    private func loadAvatar() async {
        do {
            let image = try await guest.fetchAvatar(
                size: CGSize(width: 80, height: 80) // 2x for retina
            )
            await MainActor.run {
                avatarImage = image
            }
        } catch {
            // Silently fail, keep showing initials
            // Error already logged by MultiAvatarJSService
        }
    }
}

// MARK: - Payments Due Card

/// Payments Due card shows ALL payments for the current month
/// This card has FIXED height based on payment count - no truncation
struct PaymentsDueCardV7: View {
    // Note: maxItems is ignored - this card shows ALL payments
    let maxItems: Int
    @Environment(\.appStores) private var appStores
    
    private var budgetStore: BudgetStoreV2 { appStores.budget }
    
    /// Get ALL payment schedules for current month - NO LIMIT
    private var currentMonthPayments: [(schedule: PaymentSchedule, isPaid: Bool)] {
        let now = Date()
        let calendar = Calendar.current
        
        // Get ALL payment schedules for current month (both paid and unpaid)
        // NO .prefix() - show every payment
        return budgetStore.payments.paymentSchedules
            .filter { schedule in
                calendar.isDate(schedule.paymentDate, equalTo: now, toGranularity: .month)
            }
            .sorted { $0.paymentDate < $1.paymentDate }
            .map { (schedule: $0, isPaid: $0.paid) }
    }
    
    private var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: Date())
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
    
    private func isOverdue(_ date: Date, isPaid: Bool) -> Bool {
        return !isPaid && date < Date()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Payments Due (\(currentMonthName))")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Spacer()
                
                Button {
                    // Add payment
                } label: {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "plus")
                            .font(.system(size: 10))
                        Text("Add")
                            .font(Typography.caption2)
                    }
                    .foregroundColor(SemanticColors.textPrimary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(Color.white.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.sm)
                                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            
            if currentMonthPayments.isEmpty {
                Text("No payments this month")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Spacing.lg)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(currentMonthPayments.enumerated()), id: \.offset) { index, payment in
                        PaymentRowV7(
                            title: payment.schedule.vendor,
                            amount: formatAmount(payment.schedule.paymentAmount),
                            isPaid: payment.isPaid,
                            isOverdue: isOverdue(payment.schedule.paymentDate, isPaid: payment.isPaid)
                        )
                        if index < currentMonthPayments.count - 1 {
                            Divider().opacity(0.5)
                        }
                    }
                }
            }
        }
        // Content-sized - no expansion (payment card sizes to actual payment count)
        .glassPanel()
    }
}

struct PaymentRowV7: View {
    let title: String
    let amount: String
    let isPaid: Bool
    let isOverdue: Bool
    
    var body: some View {
        HStack {
            // Paid/Unpaid indicator
            Image(systemName: isPaid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isPaid ? AppGradients.sageDark : SemanticColors.textTertiary)
                .font(.system(size: 16))
            
            Text(title)
                .font(Typography.bodySmall)
                .foregroundColor(SemanticColors.textPrimary)
                .strikethrough(isPaid, color: SemanticColors.textTertiary)
            
            Spacer()
            
            Text(amount)
                .font(Typography.bodySmall)
                .fontWeight(.bold)
                .foregroundColor(isOverdue ? AppGradients.weddingPink : SemanticColors.textPrimary)
        }
        .padding(.vertical, Spacing.sm)
        .opacity(isPaid ? 0.6 : 1.0)  // Dim paid items
    }
}

// MARK: - Recent Responses Card

struct RecentResponsesCardV7: View {
    @ObservedObject var store: GuestStoreV2
    let maxItems: Int
    let cardHeight: CGFloat
    
    /// Item height for activity rows
    private let itemHeight: CGFloat = 44
    
    private var recentActivity: [(guest: Guest, action: String, color: Color)] {
        // Get guests with RSVP dates, sorted by most recent
        let guestsWithRSVP = store.guests
            .filter { $0.rsvpDate != nil }
            .sorted { ($0.rsvpDate ?? Date.distantPast) > ($1.rsvpDate ?? Date.distantPast) }
            .prefix(maxItems)
        
        return guestsWithRSVP.map { guest in
            let action: String
            let color: Color
            
            switch guest.rsvpStatus {
            case .attending, .confirmed:
                action = "\(guest.fullName) confirmed attendance."
                color = AppGradients.sageDark
            case .declined, .noResponse:
                action = "\(guest.fullName) declined."
                color = Terracotta.shade400
            case .maybe:
                action = "\(guest.fullName) responded maybe."
                color = SoftLavender.shade400
            default:
                action = "\(guest.fullName) viewed the invitation."
                color = SoftLavender.shade400
            }
            
            return (guest, action, color)
        }
    }
    
    /// Calculate dynamic row spacing to distribute items evenly
    private var dynamicRowSpacing: CGFloat {
        let headerHeight: CGFloat = 50
        let padding: CGFloat = Spacing.lg * 2
        let availableForItems = cardHeight - headerHeight - padding
        
        let itemCount = recentActivity.count
        guard itemCount > 1 else { return Spacing.md }
        
        let totalItemHeight = CGFloat(itemCount) * itemHeight
        
        // If items don't fill space, distribute extra space as row spacing
        if totalItemHeight < availableForItems {
            let extraSpace = availableForItems - totalItemHeight
            let gaps = CGFloat(itemCount - 1)
            let extraPerGap = extraSpace / gaps
            return Spacing.md + extraPerGap
        }
        
        return Spacing.md
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Recent Responses")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Spacer()
                
                Image(systemName: "clock")
                    .foregroundColor(SemanticColors.textTertiary)
            }
            
            if recentActivity.isEmpty {
                Text("No recent responses")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Spacing.lg)
            } else {
                VStack(alignment: .leading, spacing: dynamicRowSpacing) {
                    ForEach(recentActivity, id: \.guest.id) { item in
                        ActivityRowV7(
                            color: item.color,
                            text: item.action,
                            time: timeAgo(from: item.guest.rsvpDate ?? item.guest.createdAt)
                        )
                        .frame(height: itemHeight)
                    }
                }
            }
            
            // Spacer to fill available vertical space
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .glassPanel()
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
}

struct ActivityRowV7: View {
    let color: Color
    let text: String
    let time: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(text)
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Text(time)
                    .font(.system(size: 10))
                    .foregroundColor(SemanticColors.textTertiary)
            }
        }
    }
}

// MARK: - Vendor List Card

struct VendorListCardV7: View {
    @ObservedObject var store: VendorStoreV2
    let maxItems: Int  // Ignored - calculated dynamically from cardHeight
    let cardHeight: CGFloat

    /// Item height for vendor rows (icon + 2 lines)
    private let itemHeight: CGFloat = 48

    /// Calculate how many vendors fit within the card height
    private var calculatedMaxItems: Int {
        let headerHeight: CGFloat = 50  // Title + button
        let cardPadding: CGFloat = Spacing.lg * 2  // Internal padding
        let availableForItems = cardHeight - headerHeight - cardPadding
        let maxItems = Int(availableForItems / itemHeight)
        return max(maxItems, 2)  // At least 2 items
    }

    private var recentVendors: [Vendor] {
        // Get dynamically calculated number of vendors based on available height
        store.vendors
            .sorted { (v1, v2) in
                // Booked vendors first
                let booked1 = v1.isBooked ?? false
                let booked2 = v2.isBooked ?? false
                if booked1 && !booked2 {
                    return true
                } else if !booked1 && booked2 {
                    return false
                }
                // Then by creation date (newest first)
                return v1.createdAt > v2.createdAt
            }
            .prefix(calculatedMaxItems)  // Use calculated max based on height
            .map { $0 }
    }
    
    /// Calculate dynamic row spacing to distribute items evenly
    private var dynamicRowSpacing: CGFloat {
        let headerHeight: CGFloat = 50
        let padding: CGFloat = Spacing.lg * 2
        let availableForItems = cardHeight - headerHeight - padding
        
        let itemCount = recentVendors.count
        guard itemCount > 1 else { return Spacing.md }
        
        let totalItemHeight = CGFloat(itemCount) * itemHeight
        
        // If items don't fill space, distribute extra space as row spacing
        if totalItemHeight < availableForItems {
            let extraSpace = availableForItems - totalItemHeight
            let gaps = CGFloat(itemCount - 1)
            let extraPerGap = extraSpace / gaps
            return Spacing.md + extraPerGap
        }
        
        return Spacing.md
    }
    
    private func vendorIcon(for category: String) -> String {
        let lowercased = category.lowercased()
        if lowercased.contains("photo") {
            return "camera.fill"
        } else if lowercased.contains("music") || lowercased.contains("dj") || lowercased.contains("band") {
            return "music.note"
        } else if lowercased.contains("cater") || lowercased.contains("food") {
            return "fork.knife"
        } else if lowercased.contains("flor") {
            return "leaf.fill"
        } else if lowercased.contains("venue") {
            return "building.2.fill"
        } else if lowercased.contains("decor") {
            return "sparkles"
        } else {
            return "briefcase.fill"
        }
    }
    
    private func vendorIconColor(for category: String) -> Color {
        let lowercased = category.lowercased()
        if lowercased.contains("photo") {
            return Color.blue
        } else if lowercased.contains("music") || lowercased.contains("dj") || lowercased.contains("band") {
            return AppGradients.weddingPink
        } else if lowercased.contains("cater") || lowercased.contains("food") {
            return Terracotta.shade500
        } else if lowercased.contains("flor") {
            return AppGradients.sageDark
        } else {
            return SoftLavender.shade500
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Vendor List")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                Spacer()

                Button("Manage") {
                    // Manage action
                }
                .font(Typography.caption)
                .foregroundColor(AppGradients.weddingPink)
            }

            if recentVendors.isEmpty {
                Text("No vendors yet")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                VStack(spacing: dynamicRowSpacing) {
                    ForEach(recentVendors) { vendor in
                        vendorRow(for: vendor)
                            .frame(height: itemHeight)
                    }
                }
            }

            // Fill remaining vertical space (constrained by parent)
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        // Constrained to available height - shows fewer vendors if space is limited
        .glassPanel()
        .onAppear {
            print("📊 VendorListCardV7: cardHeight=\(cardHeight), calculatedMaxItems=\(calculatedMaxItems), vendorCount=\(store.vendors.count), showing=\(recentVendors.count)")
        }
    }

    // MARK: - Helper Methods

    @ViewBuilder
    private func vendorRow(for vendor: Vendor) -> some View {
        let category = vendor.vendorType ?? "Other"
        let icon = vendorIcon(for: category)
        let iconColor = vendorIconColor(for: category)
        let status: VendorStatusV7 = (vendor.isBooked ?? false) ? .booked : .pending

        VendorRowV7(
            icon: icon,
            iconColor: iconColor,
            iconBackground: iconColor.opacity(0.1),
            name: vendor.vendorName,
            category: category,
            status: status
        )
    }
}

enum VendorStatusV7 {
    case booked, pending, declined
    
    var icon: String {
        switch self {
        case .booked: return "checkmark"
        case .pending: return "hourglass"
        case .declined: return "xmark"
        }
    }
    
    var color: Color {
        switch self {
        case .booked: return AppGradients.sageDark
        case .pending: return SoftLavender.shade600
        case .declined: return Terracotta.shade600
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .booked: return AppGradients.sageGreen.opacity(0.5)
        case .pending: return SoftLavender.shade100
        case .declined: return Terracotta.shade100
        }
    }
}

struct VendorRowV7: View {
    let icon: String
    let iconColor: Color
    let iconBackground: Color
    let name: String
    let category: String
    let status: VendorStatusV7
    
    var body: some View {
        HStack {
            // Icon
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(iconBackground)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(iconColor)
                )
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(name)
                    .font(Typography.bodySmall)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Text(category)
                    .font(.system(size: 10))
                    .foregroundColor(SemanticColors.textSecondary)
            }
            
            Spacer()
            
            // Status button
            Button {
                // Status action
            } label: {
                Circle()
                    .fill(status.backgroundColor)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: status.icon)
                            .font(.system(size: 12))
                            .foregroundColor(status.color)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview

#Preview("Dashboard V7 - Light") {
    DashboardViewV7()
        .environmentObject(AppStores.shared)
        .environmentObject(AppStores.shared.settings)
        .frame(width: 1400, height: 900)
        .preferredColorScheme(.light)
}

#Preview("Dashboard V7 - Dark") {
    DashboardViewV7()
        .environmentObject(AppStores.shared)
        .environmentObject(AppStores.shared.settings)
        .frame(width: 1400, height: 900)
        .preferredColorScheme(.dark)
}

#Preview("Dashboard V7 - Loading") {
    DashboardViewV7(previewForceLoading: true)
        .environmentObject(AppStores.shared)
        .environmentObject(AppStores.shared.settings)
        .frame(width: 1400, height: 900)
}
