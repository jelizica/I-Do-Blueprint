import SwiftUI

// MARK: - Navigation Enums

enum BudgetSection: String, CaseIterable {
    case overview = "Overview"
    case expenses = "Expenses"
    case payments = "Payments"
    case giftsOwed = "Gifts & Owed"

    var icon: String {
        switch self {
        case .overview: "chart.bar.fill"
        case .expenses: "receipt.fill"
        case .payments: "calendar.badge.clock"
        case .giftsOwed: "dollarsign.circle.fill"
        }
    }
}

enum OverviewSubsection: String, CaseIterable {
    case analyticsHub = "Analytics Hub"
    case accountCashFlow = "Account Cash Flow"
    case budgetDashboard = "Budget Dashboard"
    case budgetDevelopment = "Budget Development"
    case calculator = "Calculator"

    var icon: String {
        switch self {
        case .analyticsHub: "chart.xyaxis.line"
        case .accountCashFlow: "chart.line.uptrend.xyaxis"
        case .budgetDashboard: "chart.bar.fill"
        case .budgetDevelopment: "hammer.fill"
        case .calculator: "function"
        }
    }
}

enum ExpenseSubsection: String, CaseIterable {
    case expenseTracker = "Expense Tracker"
    case expenseReports = "Expense Reports"
    case expenseCategories = "Expense Categories"

    var icon: String {
        switch self {
        case .expenseTracker: "receipt.fill"
        case .expenseReports: "chart.bar.doc.horizontal.fill"
        case .expenseCategories: "folder.fill"
        }
    }
}

enum PaymentSubsection: String, CaseIterable {
    case paymentsSchedule = "Payments Schedule"

    var icon: String {
        switch self {
        case .paymentsSchedule: "calendar.badge.clock"
        }
    }
}

enum GiftsOwedSubsection: String, CaseIterable {
    case moneyTracker = "Money Tracker"
    case moneyReceived = "Money Received"
    case moneyOwed = "Money Owed"

    var icon: String {
        switch self {
        case .moneyTracker: "dollarsign.circle.fill"
        case .moneyReceived: "arrow.down.circle.fill"
        case .moneyOwed: "arrow.up.circle.fill"
        }
    }
}

struct BudgetMainView: View {
    @StateObject private var budgetStore = BudgetStoreV2()
    @State private var selectedSection: BudgetSection = .overview
    @State private var selectedOverviewTab: OverviewSubsection = .budgetDashboard
    @State private var selectedExpenseTab: ExpenseSubsection = .expenseTracker
    @State private var selectedPaymentTab: PaymentSubsection = .paymentsSchedule
    @State private var selectedGiftsOwedTab: GiftsOwedSubsection = .moneyTracker

    var body: some View {
        VStack(spacing: 0) {
            // Main section navigation (4 sections)
            VStack(spacing: 0) {
                HStack(spacing: 4) {
                    ForEach(BudgetSection.allCases, id: \.self) { section in
                        Button(action: {
                            selectedSection = section
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: section.icon)
                                    .font(.system(size: 16, weight: selectedSection == section ? .semibold : .medium))
                                Text(section.rawValue)
                                    .font(.system(size: 11, weight: selectedSection == section ? .semibold : .medium))
                            }
                            .foregroundColor(selectedSection == section ? .accentColor : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                selectedSection == section ?
                                    Color.accentColor.opacity(0.1) :
                                    Color.clear)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                // Dynamic sub-navigation based on selected section
                Group {
                    if selectedSection == .overview {
                        SubNavigationView(
                            items: OverviewSubsection.allCases,
                            selection: $selectedOverviewTab)
                    } else if selectedSection == .expenses {
                        SubNavigationView(
                            items: ExpenseSubsection.allCases,
                            selection: $selectedExpenseTab)
                    } else if selectedSection == .payments {
                        SubNavigationView(
                            items: PaymentSubsection.allCases,
                            selection: $selectedPaymentTab)
                    } else if selectedSection == .giftsOwed {
                        SubNavigationView(
                            items: GiftsOwedSubsection.allCases,
                            selection: $selectedGiftsOwedTab)
                    }
                }
            }
            .background(
                Color(.windowBackgroundColor)
                    .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1))

            // Content area
            Group {
                switch selectedSection {
                case .overview:
                    switch selectedOverviewTab {
                    case .analyticsHub:
                        BudgetAnalyticsView()
                    case .accountCashFlow:
                        BudgetCashFlowView()
                    case .budgetDashboard:
                        BudgetOverviewDashboardViewV2()
                    case .budgetDevelopment:
                        BudgetDevelopmentView()
                    case .calculator:
                        BudgetCalculatorView()
                    }
                case .expenses:
                    switch selectedExpenseTab {
                    case .expenseTracker:
                        ExpenseTrackerView()
                    case .expenseReports:
                        ExpenseReportsView()
                    case .expenseCategories:
                        ExpenseCategoriesView()
                    }
                case .payments:
                    switch selectedPaymentTab {
                    case .paymentsSchedule:
                        PaymentScheduleView()
                    }
                case .giftsOwed:
                    switch selectedGiftsOwedTab {
                    case .moneyTracker:
                        GiftsAndOwedView()
                    case .moneyReceived:
                        MoneyReceivedView()
                    case .moneyOwed:
                        MoneyOwedView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .environmentObject(budgetStore)
        .onAppear {
            // Trigger initial data load that both views can access
            Task {
                await budgetStore.loadBudgetData()
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
                    "Note: These settings integrate with the main Settings page referenced in the Next.js components. Full functionality includes Global Settings and Budget Settings tabs.")
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
                                     .padding(.horizontal, 8)
                                     .padding(.vertical, 2)
                                     .background(Color.accentColor)
                                     .foregroundColor(.white)
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

// MARK: - Sub Navigation Component

struct SubNavigationView<T: RawRepresentable & CaseIterable & Hashable>: View where T.RawValue == String,
    T: SubNavigationItem {
    let items: [T]
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 2) {
            ForEach(items, id: \.self) { item in
                Button(action: {
                    selection = item
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: item.icon)
                            .font(.system(size: 12, weight: .medium))
                        Text(item.rawValue)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(selection == item ? .white : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        selection == item ?
                            Color.accentColor :
                            Color.clear)
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background(
            LinearGradient(
                colors: [Color.accentColor.opacity(0.05), Color.clear],
                startPoint: .top,
                endPoint: .bottom))
    }
}

// MARK: - Protocol for Sub Navigation Items

protocol SubNavigationItem {
    var icon: String { get }
}

extension OverviewSubsection: SubNavigationItem {}
extension ExpenseSubsection: SubNavigationItem {}
extension PaymentSubsection: SubNavigationItem {}
extension GiftsOwedSubsection: SubNavigationItem {}

#Preview {
    BudgetMainView()
}
