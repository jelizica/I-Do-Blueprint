import SwiftUI

struct BudgetCategoryDetailView: View {
    let category: BudgetCategory
    let expenses: [Expense]
    let onUpdateCategory: (BudgetCategory) -> Void
    let onAddExpense: (Expense) -> Void
    let onUpdateExpense: (Expense) -> Void

    @State private var isEditing = false
    @State private var editedCategory: BudgetCategory
    @State private var showingAddExpense = false
    @State private var selectedExpense: Expense?
    @State private var showingExpenseDetail = false
    @State private var showingEditExpense = false
    @State private var expenseFilterOption: ExpenseFilterOption = .all
    @State private var searchText = ""

    init(
        category: BudgetCategory,
        expenses: [Expense],
        onUpdateCategory: @escaping (BudgetCategory) -> Void,
        onAddExpense: @escaping (Expense) -> Void,
        onUpdateExpense: @escaping (Expense) -> Void) {
        self.category = category
        self.expenses = expenses
        self.onUpdateCategory = onUpdateCategory
        self.onAddExpense = onAddExpense
        self.onUpdateExpense = onUpdateExpense
        _editedCategory = State(initialValue: category)
    }

    var filteredExpenses: [Expense] {
        let filtered = expenses.filter { expense in
            let matchesSearch = searchText.isEmpty || expense.expenseName.localizedCaseInsensitiveContains(searchText)
            let matchesFilter: Bool = switch expenseFilterOption {
            case .all:
                true
            case .pending:
                expense.paymentStatus == .pending
            case .partial:
                expense.paymentStatus == .partial
            case .paid:
                expense.paymentStatus == .paid
            case .overdue:
                expense.isOverdue
            case .dueToday:
                expense.isDueToday
            case .dueSoon:
                expense.isDueSoon
            }

            return matchesSearch && matchesFilter
        }
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Category header
                CategoryHeaderView(category: category)

                // Category stats and progress
                CategoryStatsView(category: category, expenses: expenses)

                // Expense management section
                VStack(spacing: 16) {
                    // Section header with controls
                    HStack {
                        Text("Expenses")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Spacer()

                        Button(action: {
                            showingAddExpense = true
                        }) {
                            Label("Add Expense", systemImage: "plus.circle.fill")
                                .font(.subheadline)
                        }
                    }

                    // Search and filter controls
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search expenses...", text: $searchText)
                                .textFieldStyle(.roundedBorder)
                        }

                        HStack {
                            Picker("Filter", selection: $expenseFilterOption) {
                                ForEach(ExpenseFilterOption.allCases, id: \.self) { option in
                                    Text(option.displayName).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)

                            Spacer()
                        }
                    }

                    // Expenses list
                    if filteredExpenses.isEmpty {
                        ContentUnavailableView(
                            "No Expenses Found",
                            systemImage: "doc.text",
                            description: Text(searchText
                                .isEmpty ? "Add your first expense to this category" :
                                "Try adjusting your search or filters"))
                            .frame(minHeight: 200)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredExpenses, id: \.id) { expense in
                                ExpenseRowView(
                                    expense: expense,
                                    onUpdate: onUpdateExpense,
                                    onViewDetails: { expense in
                                        selectedExpense = expense
                                        showingExpenseDetail = true
                                    },
                                    onEdit: { expense in
                                        selectedExpense = expense
                                        showingEditExpense = true
                                    })
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .id(expense.id)
                            }
                        }
                    }
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle(category.categoryName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if isEditing {
                    HStack {
                        Button("Cancel") {
                            editedCategory = category
                            isEditing = false
                        }
                        Button("Save") {
                            onUpdateCategory(editedCategory)
                            isEditing = false
                        }
                        .fontWeight(.semibold)
                    }
                } else {
                    Button("Edit") {
                        isEditing = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(
                categories: [category],
                preselectedCategory: category) { newExpense in
                onAddExpense(newExpense)
            }
            #if os(macOS)
            .frame(minWidth: 700, idealWidth: 750, maxWidth: 800, minHeight: 650, idealHeight: 750, maxHeight: 850)
            #endif
        }
        .sheet(isPresented: $showingExpenseDetail) {
            if let expense = selectedExpense {
                ExpenseDetailView(expense: expense)
            }
        }
        .sheet(isPresented: $showingEditExpense) {
            if let expense = selectedExpense {
                ExpenseTrackerEditView(expense: expense)
                    .environmentObject(BudgetStoreV2())
            }
        }
    }
}

#Preview {
    BudgetCategoryDetailView(
        category: BudgetCategory(
            id: UUID(),
            coupleId: UUID(),
            categoryName: "Venue",
            parentCategoryId: nil,
            allocatedAmount: 15000,
            spentAmount: 12000,
            typicalPercentage: 35.0,
            priorityLevel: 1,
            isEssential: true,
            notes: nil,
            forecastedAmount: 15000,
            confidenceLevel: 0.9,
            lockedAllocation: false,
            description: "Wedding venue and related costs",
            createdAt: Date(),
            updatedAt: Date()),
        expenses: [],
        onUpdateCategory: { _ in },
        onAddExpense: { _ in },
        onUpdateExpense: { _ in })
}
