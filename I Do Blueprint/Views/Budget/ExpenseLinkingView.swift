import SwiftUI
import Dependencies

struct ExpenseLinkingView: View {
    @Binding var isPresented: Bool
    let budgetItem: BudgetOverviewItem
    let activeScenario: SavedScenario?
    let onSuccess: () -> Void

    @EnvironmentObject var budgetStore: BudgetStoreV2
    @Dependency(\.budgetRepository) var budgetRepository
    @Dependency(\.vendorRepository) var vendorRepository
    @Dependency(\.budgetAllocationService) var allocationService

    // State for expenses
    @State var expenses: [Expense] = []
    @State var filteredExpenses: [Expense] = []
    @State var selectedExpenses: Set<UUID> = []
    @State var linkedExpenseIds: Set<UUID> = []

    // Search and filter state
    @State var searchText = ""
    @State var hideLinkedExpenses = false

    // Loading and error state
    @State var isLoading = true
    @State var isSubmitting = false
    @State var errorMessage: String?
    @State var linkingProgress: (current: Int, total: Int)?

    // Vendor information cache
    @State var vendorCache: [Int64: Vendor] = [:]
    @State var categoryCache: [UUID: BudgetCategory] = [:]

    let logger = AppLogger.ui

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection

                if let error = errorMessage {
                    errorView(error)
                }

                if isLoading {
                    ProgressView("Loading expenses...")
                        .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            searchSection
                            filterSection

                            if !selectedExpenses.isEmpty {
                                selectionSummary
                            }

                            expensesList

                            if !selectedExpenses.isEmpty {
                                allocationPreview
                            }
                        }
                        .padding()
                    }
                }

                Divider()

                footerSection
            }
            .frame(width: 700, height: 600)
            .navigationTitle("Link Expenses to \(budgetItem.itemName)")
        }
        .onAppear {
            Task {
                await loadExpenses()
            }
        }
    }
}
