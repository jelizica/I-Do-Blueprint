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

    // Fixed 3-column grid for metric cards
    private let metricColumns: [GridItem] = Array(
        repeating: GridItem(.flexible(minimum: 0), spacing: Spacing.lg, alignment: .top),
        count: 3
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

                // Use VStack with fixed-height header elements, then GeometryReader ONLY for masonry
                VStack(spacing: Spacing.lg) {
                    // MARK: - Header (fixed height)
                    DashboardHeaderV7()
                        .frame(height: 60)
                        .padding(.horizontal, Spacing.xxl)

                    // MARK: - Hero Banner with Countdown (fixed height)
                    Group {
                        if effectiveHasLoaded {
                            HeroBannerV7(
                                weddingDate: viewModel.weddingDate,
                                partner1Name: viewModel.partner1DisplayName,
                                partner2Name: viewModel.partner2DisplayName,
                                currentTime: currentTime
                            )
                        } else {
                            DashboardHeroSkeleton()
                        }
                    }
                    .frame(height: 100)
                    .padding(.horizontal, Spacing.xxl)

                    // MARK: - Metric Cards Row (fixed height)
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
                        } else {
                            MetricCardSkeleton()
                            MetricCardSkeleton()
                            MetricCardSkeleton()
                        }
                    }
                    .frame(height: 120)
                    .padding(.horizontal, Spacing.xxl)

                    // MARK: - Main Content: Masonry Layout (fills remaining space)
                    // GeometryReader ONLY for the masonry area - this prevents overlap
                    GeometryReader { masonryGeometry in
                        let columnLayout = calculateColumnLayout(
                            availableHeight: masonryGeometry.size.height,
                            availableWidth: masonryGeometry.size.width - (Spacing.xxl * 2)
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
    
    // MARK: - Column-Based Masonry Layout
    
    /// Layout configuration for masonry columns
    struct ColumnLayout {
        let availableHeight: CGFloat
        let availableWidth: CGFloat
        let columnCount: Int
        let columnWidth: CGFloat
        let cardSpacing: CGFloat
        
        /// Calculate height for a card based on its data count
        func cardHeight(forItemCount count: Int, itemHeight: CGFloat, headerHeight: CGFloat = 50, minHeight: CGFloat = 120) -> CGFloat {
            let contentHeight = CGFloat(count) * itemHeight + headerHeight + (Spacing.lg * 2)
            return max(contentHeight, minHeight)
        }
    }
    
    /// Calculate column layout based on available space and data density
    private func calculateColumnLayout(availableHeight: CGFloat, availableWidth: CGFloat) -> ColumnLayout {
        let cardSpacing = Spacing.lg  // Standardized gap between cards
        let columnCount = 3  // 3-column layout
        let totalSpacing = cardSpacing * CGFloat(columnCount - 1)
        let columnWidth = (availableWidth - totalSpacing) / CGFloat(columnCount)
        
        return ColumnLayout(
            availableHeight: availableHeight,
            availableWidth: availableWidth,
            columnCount: columnCount,
            columnWidth: columnWidth,
            cardSpacing: cardSpacing
        )
    }
}

// MARK: - Masonry Columns View

/// True masonry layout where each column is INDEPENDENT
/// Cards stack vertically within their column based on content height
/// Columns don't need to align horizontally - each fills viewport height independently
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
    
    // MARK: - Card Height Calculations
    
    /// Standardized spacing between cards (Spacing.lg = 16pt)
    private var cardSpacing: CGFloat { Spacing.lg }
    
    /// Calculate height for Budget Overview card (fills remaining space in column 1)
    private var budgetCardHeight: CGFloat {
        let availableHeight = columnLayout.availableHeight
        let paymentsHeight = paymentsCardHeight
        
        // Budget takes remaining space after Payments + spacing
        return max(availableHeight - paymentsHeight - cardSpacing, 150)
    }
    
    /// Calculate FIXED height for Payments Due card (shows ALL payments)
    private var paymentsCardHeight: CGFloat {
        let cardHeaderHeight: CGFloat = 50
        let paymentRowHeight: CGFloat = 36
        let cardPadding: CGFloat = Spacing.lg * 2
        let emptyStateHeight: CGFloat = 60
        
        let paymentCount = currentMonthPayments.count
        
        if paymentCount == 0 {
            return cardHeaderHeight + emptyStateHeight + cardPadding
        }
        
        return cardHeaderHeight + (CGFloat(paymentCount) * paymentRowHeight) + cardPadding
    }
    
    /// Calculate height for Task Manager card
    /// Uses minimum height to ensure Tasks card doesn't get too small
    private var tasksCardHeight: CGFloat {
        let availableHeight = columnLayout.availableHeight
        
        // If vendors are shown, split column 2 based on data density
        // But ensure Tasks gets at least 120pt (header + 1-2 items)
        if shouldShowVendorList {
            let taskCount = max(CGFloat(taskStore.tasks.count), 1.0)
            let vendorCount = max(CGFloat(vendorStore.vendors.count), 1.0)
            
            // Calculate proportional heights
            let totalWeight = taskCount + vendorCount
            let taskRatio = taskCount / totalWeight
            
            // Available for both cards minus spacing
            let availableForCards = availableHeight - cardSpacing
            let proportionalHeight = availableForCards * taskRatio
            
            // Ensure minimum height for Tasks (header + 2 items)
            let minTaskHeight: CGFloat = 120
            return max(proportionalHeight, minTaskHeight)
        }
        
        // Tasks take full column height if no vendors
        return availableHeight
    }
    
    /// Calculate height for Vendor List card
    /// Takes remaining space after Tasks card
    private var vendorsCardHeight: CGFloat {
        let availableHeight = columnLayout.availableHeight
        
        // Vendors get remaining space after Tasks + spacing
        let tasksHeight = tasksCardHeight
        return availableHeight - tasksHeight - cardSpacing
    }
    
    /// Calculate height for Guest Responses card
    private var guestsCardHeight: CGFloat {
        let availableHeight = columnLayout.availableHeight
        
        // If recent responses are shown, split column 3
        // Guests get majority of space (they have more data)
        if shouldShowRecentResponses {
            let guestCount = CGFloat(guestStore.guests.count)
            // Guests get proportionally more space based on data count
            // Minimum 70% of available space for guests
            let guestRatio = max(0.7, min(guestCount / (guestCount + 10), 0.85))
            let availableForCards = availableHeight - cardSpacing
            return availableForCards * guestRatio
        }
        
        // Guests take full column height if no recent responses
        return availableHeight
    }
    
    /// Calculate height for Recent Responses card
    private var recentCardHeight: CGFloat {
        let availableHeight = columnLayout.availableHeight
        
        // Recent gets remaining space after Guests + spacing
        let guestsHeight = guestsCardHeight
        return availableHeight - guestsHeight - cardSpacing
    }
    
    /// Calculate max items for a card based on its height
    /// Returns enough items to fill the available space
    private func maxItems(forHeight height: CGFloat, itemHeight: CGFloat) -> Int {
        let headerHeight: CGFloat = 50
        let padding: CGFloat = Spacing.lg * 2
        let available = height - headerHeight - padding
        // Calculate how many items fit, minimum 2
        return max(Int(available / itemHeight), 2)
    }
    
    /// Calculate row spacing for cards that don't have enough items to fill space
    /// This distributes items evenly instead of leaving empty space at bottom
    private func rowSpacing(forHeight height: CGFloat, itemCount: Int, itemHeight: CGFloat) -> CGFloat {
        let headerHeight: CGFloat = 50
        let padding: CGFloat = Spacing.lg * 2
        let availableForItems = height - headerHeight - padding
        
        guard itemCount > 1 else { return Spacing.md }
        
        // Calculate total content height
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
        // Use standardized cardSpacing (Spacing.lg = 16pt) for all gaps
        HStack(alignment: .top, spacing: cardSpacing) {
            // MARK: - Column 1: Budget + Payments
            VStack(alignment: .leading, spacing: cardSpacing) {
                BudgetOverviewCardV7(
                    totalBudget: viewModel.totalBudget,
                    totalSpent: viewModel.totalPaid
                )
                .frame(height: budgetCardHeight)
                
                if shouldShowPaymentsDue {
                    PaymentsDueCardV7(maxItems: 999)  // Show ALL payments
                        .frame(height: paymentsCardHeight)
                }
            }
            .frame(width: columnLayout.columnWidth, alignment: .top)
            
            // MARK: - Column 2: Tasks + Vendors
            VStack(alignment: .leading, spacing: cardSpacing) {
                TaskManagerCardV7(
                    store: taskStore,
                    maxItems: maxItems(forHeight: tasksCardHeight, itemHeight: 44),
                    cardHeight: tasksCardHeight
                )
                .frame(height: tasksCardHeight)
                
                if shouldShowVendorList {
                    VendorListCardV7(
                        store: vendorStore,
                        maxItems: maxItems(forHeight: vendorsCardHeight, itemHeight: 48),
                        cardHeight: vendorsCardHeight
                    )
                    .frame(height: vendorsCardHeight)
                }
            }
            .frame(width: columnLayout.columnWidth, alignment: .top)
            
            // MARK: - Column 3: Guests + Recent
            VStack(alignment: .leading, spacing: cardSpacing) {
                if shouldShowGuestResponses {
                    GuestResponsesCardV7(
                        store: guestStore,
                        maxItems: maxItems(forHeight: guestsCardHeight, itemHeight: 52),
                        cardHeight: guestsCardHeight
                    )
                    .environmentObject(settingsStore)
                    .environmentObject(budgetStore)
                    .environmentObject(coordinator)
                    .frame(height: guestsCardHeight)
                }
                
                if shouldShowRecentResponses {
                    RecentResponsesCardV7(
                        store: guestStore,
                        maxItems: maxItems(forHeight: recentCardHeight, itemHeight: 44),
                        cardHeight: recentCardHeight
                    )
                    .frame(height: recentCardHeight)
                }
            }
            .frame(width: columnLayout.columnWidth, alignment: .top)
        }
        .frame(height: columnLayout.availableHeight)
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
            
            // Spacer to fill available vertical space
            Spacer(minLength: 0)
            
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
        .frame(maxHeight: .infinity, alignment: .top)
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
            
            // Spacer to fill available vertical space
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
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
    let maxItems: Int
    let cardHeight: CGFloat
    @EnvironmentObject private var settingsStore: SettingsStoreV2
    
    /// Item height for guest rows (avatar + 2 lines)
    private let itemHeight: CGFloat = 52
    
    private var recentGuests: [Guest] {
        // Get dynamically calculated number of guests sorted by RSVP date or creation date
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
            .prefix(maxItems)
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
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Spacing.lg)
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
            
            // Spacer to fill available vertical space
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .glassPanel()
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
            
            // Spacer to fill available vertical space
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
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
    let maxItems: Int
    let cardHeight: CGFloat
    
    /// Item height for vendor rows (icon + 2 lines)
    private let itemHeight: CGFloat = 48
    
    private var recentVendors: [Vendor] {
        // Get dynamically calculated number of vendors, prioritizing booked vendors
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
            .prefix(maxItems)
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
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Spacing.lg)
            } else {
                VStack(spacing: dynamicRowSpacing) {
                    ForEach(recentVendors) { vendor in
                        vendorRow(for: vendor)
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
