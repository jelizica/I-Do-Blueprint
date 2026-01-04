//
//  DashboardViewV4.swift
//  I Do Blueprint
//
//  Modern dashboard with Supabase data integration
//  Displays real-time wedding planning metrics and countdown
//

import SwiftUI
import Sentry

struct DashboardViewV4: View {
    @Environment(\.appStores) private var appStores
    
    // Preview control (optional). When set, overrides loading state for previews.
    private let previewForceLoading: Bool?
    
    // View Model
    @StateObject private var viewModel: DashboardViewModel
    
    // Convenience accessors for stores (still needed for passing to child views)
    private var budgetStore: BudgetStoreV2 { appStores.budget }
    private var vendorStore: VendorStoreV2 { appStores.vendor }
    private var guestStore: GuestStoreV2 { appStores.guest }
    private var taskStore: TaskStoreV2 { appStores.task }

    // Adaptive grid: 320pt minimum card width (for main content)
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 320), spacing: Spacing.lg, alignment: .top)
    ]

    // Metrics row: always 3 columns that flex to available width
    private let metricColumns: [GridItem] = Array(
        repeating: GridItem(.flexible(minimum: 0), spacing: Spacing.lg, alignment: .top),
        count: 3
    )

    init(previewForceLoading: Bool? = nil, appStores: AppStores = .shared) {
        self.previewForceLoading = previewForceLoading
        
        // Initialize view model with stores
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
                // Background gradient (Design System)
                AppGradients.appBackground
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Hero Section - full width above the grid
                        Group {
                            if effectiveHasLoaded {
                                WeddingCountdownCard(
                                    weddingDate: viewModel.weddingDate,
                                    daysUntil: viewModel.daysUntilWedding,
                                    partner1Name: viewModel.partner1DisplayName,
                                    partner2Name: viewModel.partner2DisplayName,
                                    userTimezone: viewModel.userTimezone,
                                    themeSettings: viewModel.themeSettings
                                )
                            } else {
                                DashboardHeroSkeleton()
                            }
                        }
                        .padding(.horizontal, Spacing.xxl)

                        // Fixed 3-across metrics row under the hero
                        LazyVGrid(columns: metricColumns, alignment: .center, spacing: Spacing.lg) {
                            if effectiveHasLoaded {
                                DashboardMetricCard(
                                    icon: "person.2.fill",
                                    iconColor: AppColors.Guest.confirmed,
                                    title: "RSVPs",
                                    value: "\(viewModel.rsvpYesCount)/\(viewModel.totalGuests)",
                                    subtitle: "\(viewModel.rsvpPendingCount) pending"
                                )
                                DashboardMetricCard(
                                    icon: "briefcase.fill",
                                    iconColor: AppColors.Vendor.booked,
                                    title: "Vendors Booked",
                                    value: "\(viewModel.vendorsBookedCount)/\(viewModel.totalVendors)",
                                    subtitle: "\(viewModel.vendorsPendingCount) pending"
                                )
                                DashboardMetricCard(
                                    icon: "dollarsign.circle.fill",
                                    iconColor: viewModel.budgetColor,
                                    title: "Budget Used",
                                    value: "\(Int(viewModel.budgetPercentage))%",
                                    subtitle: "$\(viewModel.formatCurrency(viewModel.budgetRemaining)) left"
                                )
                            } else {
                                MetricCardSkeleton().accessibilityIdentifier("dashboard.skeleton.metric.1")
                                MetricCardSkeleton().accessibilityIdentifier("dashboard.skeleton.metric.2")
                                MetricCardSkeleton().accessibilityIdentifier("dashboard.skeleton.metric.3")
                            }
                        }
                        .padding(.horizontal, Spacing.xxl)

                        // Adaptive grid content (main cards)
                        LazyVGrid(columns: columns, alignment: .center, spacing: Spacing.lg) {
                            if effectiveHasLoaded {
                                // Main cards
                                BudgetOverviewCardV4(store: budgetStore, vendorStore: vendorStore, userTimezone: viewModel.userTimezone)
                                TaskProgressCardV4(store: taskStore, userTimezone: viewModel.userTimezone)
                                GuestResponsesCardV4(store: guestStore)
                                VendorStatusCardV4(store: vendorStore)

                            } else {
                                DashboardBudgetCardSkeleton()
                                DashboardTasksCardSkeleton()
                                DashboardGuestsCardSkeleton()
                                DashboardVendorsCardSkeleton()
                                DashboardQuickActionsSkeleton()
                            }
                        }
                        .padding(.horizontal, Spacing.xxl)
                    }
                    
                    // Full-width Quick Actions row
                    Group {
                        if effectiveHasLoaded {
                            QuickActionsCardV4()
                                .padding(.horizontal, Spacing.xxl)
                        } else {
                            DashboardQuickActionsSkeleton()
                                .padding(.horizontal, Spacing.xxl)
                        }
                    }
                }
                .padding(.top, Spacing.xxl)
                .padding(.bottom, Spacing.xxl)
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    HStack(spacing: Spacing.md) {
                        if effectiveIsLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }

                        Button {
                            Task { await viewModel.loadDashboardData() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(SemanticColors.textPrimary)
                        }
                        .buttonStyle(.plain)
                        .accessibleActionButton(
                            label: "Refresh dashboard",
                            hint: "Reload all dashboard data"
                        )
                    }
                }
            }
        }
        .task {
            if !viewModel.hasLoaded {
                await viewModel.loadDashboardData()
            }
        }
    }
}

// MARK: - Hero Components
// Extracted to: Views/Dashboard/Components/Hero/

// MARK: - Budget Components
// Extracted to: Views/Dashboard/Components/Budget/

// MARK: - Task Components
// Extracted to: Views/Dashboard/Components/Tasks/

// MARK: - Guest Components
// Extracted to: Views/Dashboard/Components/Guests/

// MARK: - Vendor Components
// Extracted to: Views/Dashboard/Components/Vendors/

// MARK: - Quick Actions Components
// Extracted to: Views/Dashboard/Components/QuickActions/

// MARK: - Preview

#Preview("Loaded • 1400 light") {
    DashboardViewV4()
        .environmentObject(AppStores.shared)
        .frame(width: 1400, height: 900)
        .preferredColorScheme(.light)
}

#Preview("Loaded • 900 dark") {
    DashboardViewV4()
        .environmentObject(AppStores.shared)
        .frame(width: 900, height: 900)
        .preferredColorScheme(.dark)
}

#Preview("Loading skeleton • 1400") {
    DashboardViewV4(previewForceLoading: true)
        .environmentObject(AppStores.shared)
        .frame(width: 1400, height: 900)
}

