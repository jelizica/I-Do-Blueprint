import SwiftUI

struct BudgetMainView: View {
    @EnvironmentObject private var budgetStore: BudgetStoreV2
    @State private var selectedItem: BudgetNavigationItem = .budgetDashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar with all navigation items (all 12 views accessible)
            BudgetSidebarView(selection: $selectedItem)
                .frame(width: 240)

            Divider()

            // Content area - all 12 views preserved
            Group {
                switch selectedItem {
                // Overview group (5 views)
                case .budgetDashboard:
                    BudgetOverviewDashboardViewV2()
                case .analyticsHub:
                    BudgetAnalyticsView()
                case .accountCashFlow:
                    BudgetCashFlowView()
                case .budgetDevelopment:
                    BudgetDevelopmentView()
                case .calculator:
                    BudgetCalculatorView()

                // Expenses group (3 views)
                case .expenseTracker:
                    ExpenseTrackerView()
                case .expenseReports:
                    ExpenseReportsView()
                case .expenseCategories:
                    ExpenseCategoriesView()

                // Payments group (1 view)
                case .paymentSchedule:
                    PaymentScheduleView()

                // Gifts & Owed group (3 views)
                case .moneyTracker:
                    GiftsAndOwedView()
                case .moneyReceived:
                    MoneyReceivedViewV2()
                case .moneyOwed:
                    MoneyOwedView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(selectedItem.title)
        }
        .environmentObject(budgetStore)
        .onAppear {
            Task {
                await budgetStore.loadBudgetData(force: true)
            }
        }
    }
}

// MARK: - Placeholder Views for Missing Components

struct BudgetFiltersView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2

    var body: some View {
        VStack {
            Text("Budget Filters")
                .font(.title2)
                .fontWeight(.bold)
                .padding()

            Text("Filter budget items by category, person responsible, amount range, and more.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 16) {
                // Placeholder filter components
                FilterGroupView(title: "Categories") {
                    Text("• Venue & Catering")
                    Text("• Photography")
                    Text("• Flowers & Decorations")
                    Text("• Attire & Beauty")
                }

                FilterGroupView(title: "Person Responsible") {
                    Text("• Jess")
                    Text("• Liz")
                    Text("• Both")
                }

                FilterGroupView(title: "Amount Range") {
                    Text("• Under $500")
                    Text("• $500 - $2,000")
                    Text("• $2,000 - $5,000")
                    Text("• Over $5,000")
                }

                FilterGroupView(title: "Status") {
                    Text("• Planned")
                    Text("• Paid")
                    Text("• Pending")
                    Text("• Overdue")
                }
            }
            .padding()

            Spacer()

            Text(
                "Note: This is a placeholder view. Full filtering functionality will be implemented based on the Next.js BudgetFiltersDemo component.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding()
        }
    }
}

struct FilterGroupView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 4) {
                content
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct BudgetSettingsView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @State private var showingTaxRateSettings = false
    @State private var showingEventSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Budget Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)

                VStack(spacing: 16) {
                    // Tax Rates Settings
                    SettingsGroupView(title: "Tax Rates", icon: "percent") {
                        Text("Manage tax rates used in budget calculations")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button("Configure Tax Rates") {
                            showingTaxRateSettings = true
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    // Wedding Events Settings
                    SettingsGroupView(title: "Wedding Events", icon: "calendar") {
                        Text("Configure wedding events for budget allocation")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button("Configure Events") {
                            showingEventSettings = true
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    // Budget Categories Settings
                    SettingsGroupView(title: "Budget Categories", icon: "folder") {
                        Text("Manage budget categories and subcategories")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button("Manage Categories") {
                            // Navigate to category management
                        }
                        .buttonStyle(.bordered)
                    }

                    // Export/Import Settings
                    SettingsGroupView(title: "Data Management", icon: "square.and.arrow.up") {
                        Text("Export and import budget data")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack {
                            Button("Export All Data") {
                                // Export functionality
                            }
                            .buttonStyle(.bordered)

                            Button("Import Data") {
                                // Import functionality
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding(.horizontal)

                Text(
                    """
                    Note: These settings integrate with the main Settings page referenced in the Next.js components. \
                    Full functionality includes Global Settings and Budget Settings tabs.
                    """
                )
                .font(.caption)
                .foregroundStyle(.tertiary)
                    .padding()
            }
        }
        .sheet(isPresented: $showingTaxRateSettings) {
            TaxRateSettingsView()
        }
        .sheet(isPresented: $showingEventSettings) {
            EventSettingsView()
        }
    }
}

struct SettingsGroupView<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct TaxRateSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var budgetStore: BudgetStoreV2

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Configure Tax Rates")
                    .font(.headline)

                List {
                    ForEach(budgetStore.taxRates, id: \.id) { taxRate in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(taxRate.region)
                                    .fontWeight(.medium)
                                Text("\(String(format: "%.2f", taxRate.taxRate))%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            // TaxInfo doesn't have isDefault property
                            /* if taxRate.isDefault {
                                 Text("Default")
                                     .font(.caption)
                                     .padding(.horizontal, Spacing.sm)
                                     .padding(.vertical, Spacing.xxs)
                                     .background(Color.accentColor)
                                     .foregroundColor(AppColors.textPrimary)
                                     .cornerRadius(4)
                             } */
                        }
                    }
                }

                Text("Tax rates are used for budget calculations in the Development sandbox.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            }
            .navigationTitle("Tax Rates")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Rate") {
                        // Add new tax rate
                    }
                }
            }
        }
    }
}

struct EventSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var budgetStore: BudgetStoreV2

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Configure Wedding Events")
                    .font(.headline)

                List {
                    ForEach(budgetStore.weddingEvents, id: \.id) { event in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(event.eventName)
                                    .fontWeight(.medium)
                                Text(event.eventDate, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }

                Text("Wedding events are used for budget allocation across multiple events.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            }
            .navigationTitle("Wedding Events")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Event") {
                        // Add new wedding event
                    }
                }
            }
        }
    }
}

#Preview {
    BudgetMainView()
}
