//
//  BillCalculatorView.swift
//  I Do Blueprint
//
//  Main Bill Calculator view for per-person cost estimation
//  Supports per-person items, service fees, and flat fees with real-time calculations
//

import SwiftUI

// MARK: - Bill Calculator View

struct BillCalculatorView: View {
    @Environment(\.appStores) private var appStores
    @Environment(\.colorScheme) private var colorScheme

    @State private var calculator: BillCalculator
    @State private var selectedVendorId: Int64?
    @State private var selectedEventId: String?
    @State private var lastSaved: Date = Date()
    @State private var showingDeleteAlert = false
    @State private var calculatorToDelete: BillCalculator?
    @State private var isSaving = false
    @State private var hasUnsavedChanges = false
    @State private var initializationError: String?
    @State private var isLoadingCalculators = true

    // Expense linking state
    @State private var linkedExpenseId: UUID?
    @State private var linkedExpense: Expense?
    @State private var isLoadingLinkedExpense = false
    @State private var isLinkingExpense = false

    // Modal state
    @State private var showingAddPerPersonModal = false
    @State private var showingAddServiceFeeModal = false
    @State private var showingAddFlatFeeModal = false
    @State private var showingAddVariableItemModal = false

    private var vendorStore: VendorStoreV2 { appStores.vendor }
    private var settingsStore: SettingsStoreV2 { appStores.settings }
    private var guestStore: GuestStoreV2 { appStores.guest }
    private var budgetStore: BudgetStoreV2 { appStores.budget }
    private var billCalculatorStore: BillCalculatorStoreV2 { appStores.billCalculator }

    /// Whether to use guest count from database (auto mode)
    private var useGuestCountFromDatabase: Bool {
        calculator.guestCountMode == .auto
    }

    /// Whether to show variable item mode (per-item quantities)
    private var usesVariableItemCount: Bool {
        calculator.guestCountMode == .variable
    }

    /// Initialize with a new empty calculator using the current session's tenant ID
    init() {
        // Get tenant ID from session, fall back to placeholder if not authenticated
        // The placeholder will be replaced in .task when session is available
        let tenantId = SessionManager.shared.getTenantId() ?? UUID()
        _calculator = State(initialValue: BillCalculator(coupleId: tenantId))
    }

    /// Initialize with an existing calculator for editing
    init(calculator: BillCalculator) {
        _calculator = State(initialValue: calculator)
    }

    var body: some View {
        ZStack {
            // Mesh gradient background from design system
            MeshGradientBackground()

            VStack(spacing: 0) {
                headerView
                contentView
                footerView
            }
        }
        .task {
            isLoadingCalculators = true

            // Load calculators and tax info in parallel (tax info needed for dropdown)
            async let calculatorsLoad: () = billCalculatorStore.loadCalculators()
            async let taxInfoLoad: () = billCalculatorStore.loadTaxInfoOptions()
            await calculatorsLoad
            await taxInfoLoad

            // If there are existing calculators, load the most recent one
            if let mostRecent = billCalculatorStore.calculators.first {
                calculator = mostRecent
                hasUnsavedChanges = false
                if let savedAt = mostRecent.updatedAt ?? mostRecent.createdAt {
                    lastSaved = savedAt
                }
            } else {
                // No existing calculators - ensure we have the correct tenant ID for new one
                if let tenantId = SessionManager.shared.getTenantId() {
                    // Update calculator with correct tenant ID if it was initialized with placeholder
                    if calculator.coupleId != tenantId {
                        calculator = BillCalculator(
                            id: calculator.id,
                            coupleId: tenantId,
                            name: calculator.name,
                            vendorId: calculator.vendorId,
                            eventId: calculator.eventId,
                            taxInfoId: calculator.taxInfoId,
                            guestCount: calculator.guestCount,
                            guestCountMode: calculator.guestCountMode,
                            notes: calculator.notes,
                            createdAt: calculator.createdAt,
                            updatedAt: calculator.updatedAt,
                            vendorName: calculator.vendorName,
                            eventName: calculator.eventName,
                            taxRate: calculator.taxRate,
                            taxRegion: calculator.taxRegion,
                            items: calculator.items
                        )
                    }
                } else {
                    initializationError = "Not authenticated. Please sign in to create a bill calculator."
                }
            }

            isLoadingCalculators = false

            await vendorStore.loadVendors()
            await settingsStore.loadSettings()
            await guestStore.loadGuestData()
            await budgetStore.loadBudgetData()

            // Load linked expense for current calculator
            await loadLinkedExpense()

            // Note: Tax info already loaded above in parallel with calculators
            // Set initial guest count from database if auto mode
            if useGuestCountFromDatabase && calculator.createdAt == nil {
                calculator.guestCount = guestStore.attendingCount
            }
        }
        .onChange(of: calculator.guestCountMode) { _, newMode in
            // When switching to auto mode, sync guest count from database
            if newMode == .auto {
                calculator.guestCount = guestStore.attendingCount
            }
            // Mode conversion is handled by BillCalculator.convertToMode() if needed
        }
        .onChange(of: guestStore.attendingCount) { _, newCount in
            if useGuestCountFromDatabase {
                calculator.guestCount = newCount
            }
        }
        .sheet(isPresented: $showingAddPerPersonModal) {
            AddPerPersonItemModal(
                guestCount: calculator.guestCount,
                onAdd: { item in
                    let calcItem = item.toBillCalculatorItem(
                        calculatorId: calculator.id,
                        coupleId: calculator.coupleId,
                        type: .perPerson
                    )
                    calculator.addItem(calcItem)
                    lastSaved = Date()
                    hasUnsavedChanges = true
                },
                onAddAnother: { item in
                    let calcItem = item.toBillCalculatorItem(
                        calculatorId: calculator.id,
                        coupleId: calculator.coupleId,
                        type: .perPerson
                    )
                    calculator.addItem(calcItem)
                    lastSaved = Date()
                    hasUnsavedChanges = true
                }
            )
        }
        .sheet(isPresented: $showingAddServiceFeeModal) {
            AddServiceFeeModal(
                subtotal: calculator.serviceFeeSubtotal,
                onAdd: { item in
                    let calcItem = item.toBillCalculatorItem(
                        calculatorId: calculator.id,
                        coupleId: calculator.coupleId,
                        type: .serviceFee
                    )
                    calculator.addItem(calcItem)
                    lastSaved = Date()
                    hasUnsavedChanges = true
                },
                onAddAnother: { item in
                    let calcItem = item.toBillCalculatorItem(
                        calculatorId: calculator.id,
                        coupleId: calculator.coupleId,
                        type: .serviceFee
                    )
                    calculator.addItem(calcItem)
                    lastSaved = Date()
                    hasUnsavedChanges = true
                }
            )
        }
        .sheet(isPresented: $showingAddFlatFeeModal) {
            AddFlatFeeItemModal(
                onAdd: { item in
                    let calcItem = item.toBillCalculatorItem(
                        calculatorId: calculator.id,
                        coupleId: calculator.coupleId,
                        type: .flatFee
                    )
                    calculator.addItem(calcItem)
                    lastSaved = Date()
                    hasUnsavedChanges = true
                },
                onAddAnother: { item in
                    let calcItem = item.toBillCalculatorItem(
                        calculatorId: calculator.id,
                        coupleId: calculator.coupleId,
                        type: .flatFee
                    )
                    calculator.addItem(calcItem)
                    lastSaved = Date()
                    hasUnsavedChanges = true
                }
            )
        }
        .sheet(isPresented: $showingAddVariableItemModal) {
            AddVariableItemModal(
                guestCount: guestStore.attendingCount,
                onAdd: { item in
                    let calcItem = item.toBillCalculatorItem(
                        calculatorId: calculator.id,
                        coupleId: calculator.coupleId,
                        type: .perPerson
                    )
                    calculator.addItem(calcItem)
                    lastSaved = Date()
                    hasUnsavedChanges = true
                },
                onAddAnother: { item in
                    let calcItem = item.toBillCalculatorItem(
                        calculatorId: calculator.id,
                        coupleId: calculator.coupleId,
                        type: .perPerson
                    )
                    calculator.addItem(calcItem)
                    lastSaved = Date()
                    hasUnsavedChanges = true
                }
            )
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: Spacing.md) {
                    calculatorIcon
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Budget Calculator")
                            .font(Typography.title2)
                            .foregroundColor(SemanticColors.textPrimary)
                        Text("Per-Person Cost Estimator")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                }

                Spacer()

                calculatorSelector

                Spacer()

                HStack(spacing: Spacing.md) {
                    lastSavedIndicator
                    shareButton
                    saveToBudgetButton
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.lg)

            Divider()

            headerInputsRow
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.lg)
        }
        .glassPanel(cornerRadius: CornerRadius.lg, padding: 0)
        .padding(.horizontal, Spacing.xxl)
        .padding(.top, Spacing.xxl)
    }

    private var calculatorSelector: some View {
        HStack(spacing: Spacing.md) {
            if isLoadingCalculators {
                ProgressView()
                    .controlSize(.small)
                Text("Loading calculators...")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)
            } else {
                Menu {
                    // Existing calculators with submenus for actions
                    if !billCalculatorStore.calculators.isEmpty {
                        ForEach(billCalculatorStore.calculators) { calc in
                            Menu {
                                Button {
                                    selectCalculator(calc)
                                } label: {
                                    Label("Select", systemImage: "checkmark.circle")
                                }

                                Divider()

                                Button(role: .destructive) {
                                    calculatorToDelete = calc
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            } label: {
                                HStack {
                                    Text(calculatorDisplayName(calc))
                                    if calc.id == calculator.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }

                        Divider()
                    }

                    // New bill option
                    Button {
                        createNewCalculator()
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("New Bill")
                        }
                    }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "doc.text")
                            .foregroundColor(SemanticColors.primaryAction)

                        Text(calculatorDisplayName(calculator))
                            .font(Typography.bodyRegular.weight(.medium))
                            .foregroundColor(SemanticColors.textPrimary)
                            .lineLimit(1)

                        if calculator.createdAt == nil {
                            Text("(New)")
                                .font(Typography.caption)
                                .foregroundColor(SemanticColors.textTertiary)
                        }

                        Image(systemName: "chevron.down")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(SemanticColors.controlBackground)
                    .cornerRadius(CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                    )
                }
                .menuStyle(.borderlessButton)
            }
        }
    }

    private func calculatorDisplayName(_ calc: BillCalculator) -> String {
        if !calc.name.isEmpty {
            return calc.name
        } else if let eventName = calc.eventName {
            return eventName
        } else if let vendorName = calc.vendorName {
            return vendorName
        } else {
            return "Untitled Bill"
        }
    }

    private func selectCalculator(_ calc: BillCalculator) {
        // Check for unsaved changes before switching
        if hasUnsavedChanges {
            // For now, just switch - in the future could show confirmation dialog
            // TODO: Add confirmation dialog for unsaved changes
        }
        calculator = calc
        hasUnsavedChanges = false
        if let savedAt = calc.updatedAt ?? calc.createdAt {
            lastSaved = savedAt
        }

        // Load linked expense for the selected calculator
        Task {
            await loadLinkedExpense()
        }
    }

    private func createNewCalculator() {
        // Check for unsaved changes before creating new
        if hasUnsavedChanges {
            // For now, just create new - in the future could show confirmation dialog
            // TODO: Add confirmation dialog for unsaved changes
        }

        let tenantId = SessionManager.shared.getTenantId() ?? UUID()
        calculator = BillCalculator(
            coupleId: tenantId,
            guestCount: guestStore.attendingCount
        )

        // Clear linked expense state for new calculator
        linkedExpenseId = nil
        linkedExpense = nil
        hasUnsavedChanges = false
        lastSaved = Date()
    }

    private func deleteCalculator(_ calcToDelete: BillCalculator) async {
        // Only delete if the calculator has been saved to the database
        guard calcToDelete.createdAt != nil else {
            // Not saved yet, just create a new empty calculator if deleting current
            if calcToDelete.id == calculator.id {
                createNewCalculator()
            }
            return
        }

        let calculatorId = calcToDelete.id
        let isDeletingCurrent = calcToDelete.id == calculator.id

        // Delete from database
        await billCalculatorStore.deleteCalculator(id: calculatorId)

        // Refresh calculators list
        await billCalculatorStore.loadCalculators()

        // If we deleted the current calculator, switch to another or create new
        if isDeletingCurrent {
            if let nextCalculator = billCalculatorStore.calculators.first {
                calculator = nextCalculator
                hasUnsavedChanges = false
                if let savedAt = nextCalculator.updatedAt ?? nextCalculator.createdAt {
                    lastSaved = savedAt
                }
            } else {
                // No more calculators, create a new empty one
                createNewCalculator()
            }
        }
    }

    private var calculatorIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(SemanticColors.primaryAction.opacity(0.15))
                .frame(width: Spacing.huge - Spacing.sm, height: Spacing.huge - Spacing.sm)

            Image(systemName: "function")
                .font(Typography.subheading)
                .foregroundColor(SemanticColors.primaryAction)
        }
    }

    private var lastSavedIndicator: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "clock")
                .foregroundColor(SemanticColors.primaryAction)
            Text("Last saved: \(lastSavedText)")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
        }
    }

    private var lastSavedText: String {
        let interval = Date().timeIntervalSince(lastSaved)
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        }
    }

    private var shareButton: some View {
        Button(action: {}) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "square.and.arrow.up")
                Text("Share")
            }
            .font(Typography.bodySmall.weight(.medium))
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(SemanticColors.controlBackground)
            .foregroundColor(SemanticColors.textPrimary)
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(.plain)
    }

    private var saveToBudgetButton: some View {
        Button(action: {
            Task {
                await saveCalculator()
            }
        }) {
            HStack(spacing: Spacing.xs) {
                if isSaving {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "square.and.arrow.down")
                }
                Text(isSaving ? "Saving..." : "Save to Budget")
            }
            .font(Typography.bodySmall.weight(.medium))
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(SemanticColors.primaryAction)
            .foregroundColor(.white)
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(.plain)
        .macOSShadow(.subtle)
        .disabled(isSaving || !hasUnsavedChanges)
    }

    private var headerInputsRow: some View {
        HStack(spacing: Spacing.lg) {
            vendorPicker
            billNameField
            eventPicker
            expensePicker
            Spacer()
            guestCountStepper
        }
    }

    private var vendorPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("VENDOR")
                .font(Typography.caption.weight(.semibold))
                .foregroundColor(SemanticColors.textSecondary)
                .tracking(0.5)

            Menu {
                ForEach(vendorStore.vendors, id: \.id) { vendor in
                    Button(vendor.vendorName) {
                        calculator.vendorId = vendor.id
                        calculator.vendorName = vendor.vendorName
                        hasUnsavedChanges = true
                    }
                }
                Divider()
                Button("+ Add New Vendor") {}
            } label: {
                HStack {
                    Text(calculator.vendorName ?? "Select Vendor")
                        .font(Typography.bodyRegular.weight(.medium))
                        .foregroundColor(calculator.vendorName == nil ? SemanticColors.textTertiary : SemanticColors.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(SemanticColors.controlBackground)
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                )
            }
            .menuStyle(.borderlessButton)
        }
        .frame(width: 160)
    }

    private var billNameField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("BILL NAME")
                .font(Typography.caption.weight(.semibold))
                .foregroundColor(SemanticColors.textSecondary)
                .tracking(0.5)

            TextField("Enter bill name", text: $calculator.name)
                .textFieldStyle(.plain)
                .font(Typography.bodyRegular.weight(.medium))
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(SemanticColors.controlBackground)
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                )
                .frame(minWidth: 150, maxWidth: 250)
        }
    }

    private var eventPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("EVENT")
                .font(Typography.caption.weight(.semibold))
                .foregroundColor(SemanticColors.textSecondary)
                .tracking(0.5)

            Menu {
                ForEach(budgetStore.weddingEvents.sorted(by: { ($0.eventOrder ?? 0) < ($1.eventOrder ?? 0) }), id: \.id) { event in
                    Button(event.eventName) {
                        // Convert String ID to UUID if valid
                        calculator.eventId = UUID(uuidString: event.id)
                        calculator.eventName = event.eventName
                        hasUnsavedChanges = true
                    }
                }
            } label: {
                HStack {
                    Text(calculator.eventName ?? "Select Event")
                        .font(Typography.bodyRegular.weight(.medium))
                        .foregroundColor(calculator.eventName == nil ? SemanticColors.textTertiary : SemanticColors.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(SemanticColors.controlBackground)
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                )
            }
            .menuStyle(.borderlessButton)
        }
        .frame(width: 180)
    }

    private var expensePicker: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Text("LINK TO EXPENSE")
                    .font(Typography.caption.weight(.semibold))
                    .foregroundColor(SemanticColors.textSecondary)
                    .tracking(0.5)

                if isLinkingExpense {
                    ProgressView()
                        .controlSize(.mini)
                }
            }

            Menu {
                // Option to clear/unlink
                if linkedExpenseId != nil {
                    Button {
                        Task {
                            await unlinkExpense()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Remove Link")
                        }
                    }

                    Divider()
                }

                // Available expenses
                ForEach(budgetStore.expenseStore.expenses, id: \.id) { expense in
                    Button {
                        Task {
                            await linkToExpense(expense)
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(expense.expenseName)
                                if let vendorName = expense.vendorName {
                                    Text(vendorName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Text(formatCurrency(expense.amount))
                                .foregroundColor(.secondary)
                            if linkedExpenseId == expense.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                if budgetStore.expenseStore.expenses.isEmpty {
                    Text("No expenses available")
                        .foregroundColor(.secondary)
                }
            } label: {
                HStack {
                    if isLoadingLinkedExpense {
                        ProgressView()
                            .controlSize(.small)
                    } else if let expense = linkedExpense {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "link")
                                .foregroundColor(SemanticColors.statusSuccess)
                            Text(expense.expenseName)
                                .font(Typography.bodyRegular.weight(.medium))
                                .foregroundColor(SemanticColors.textPrimary)
                                .lineLimit(1)
                        }
                    } else {
                        Text("Link to Expense")
                            .font(Typography.bodyRegular.weight(.medium))
                            .foregroundColor(SemanticColors.textTertiary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(linkedExpense != nil ? SemanticColors.statusSuccess.opacity(Opacity.verySubtle) : SemanticColors.controlBackground)
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(linkedExpense != nil ? SemanticColors.statusSuccess : SemanticColors.borderPrimary, lineWidth: 1)
                )
            }
            .menuStyle(.borderlessButton)
        }
        .frame(width: 200)
    }

    private var guestCountStepper: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                Text("GUEST COUNT")
                    .font(Typography.caption.weight(.semibold))
                    .foregroundColor(SemanticColors.textSecondary)
                    .tracking(0.5)

                guestCountSourceToggle
            }

            HStack(spacing: Spacing.xs) {
                Button(action: {
                    if !useGuestCountFromDatabase && calculator.guestCount > 0 {
                        calculator.guestCount -= 1
                        hasUnsavedChanges = true
                    }
                }) {
                    Image(systemName: "minus")
                        .font(Typography.caption.weight(.bold))
                        .frame(width: Spacing.xxxl, height: Spacing.xxxl)
                        .background(SemanticColors.controlBackground)
                        .foregroundColor(useGuestCountFromDatabase ? SemanticColors.textTertiary : SemanticColors.textPrimary)
                        .cornerRadius(CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(useGuestCountFromDatabase)

                TextField("", value: $calculator.guestCount, format: .number)
                    .textFieldStyle(.plain)
                    .font(Typography.numberMedium)
                    .multilineTextAlignment(.center)
                    .frame(width: 70)
                    .padding(.vertical, Spacing.xs)
                    .background(SemanticColors.controlBackground)
                    .cornerRadius(CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                    )
                    .disabled(useGuestCountFromDatabase)
                    .onChange(of: calculator.guestCount) { _, _ in
                        if !useGuestCountFromDatabase {
                            hasUnsavedChanges = true
                        }
                    }

                Button(action: {
                    if !useGuestCountFromDatabase {
                        calculator.guestCount += 1
                        hasUnsavedChanges = true
                    }
                }) {
                    Image(systemName: "plus")
                        .font(Typography.caption.weight(.bold))
                        .frame(width: Spacing.xxxl, height: Spacing.xxxl)
                        .background(SemanticColors.controlBackground)
                        .foregroundColor(useGuestCountFromDatabase ? SemanticColors.textTertiary : SemanticColors.textPrimary)
                        .cornerRadius(CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(useGuestCountFromDatabase)
            }
        }
    }

    private var guestCountSourceToggle: some View {
        Menu {
            // Auto mode - uses guest list count
            Button {
                calculator.convertToMode(.auto)
                calculator.guestCount = guestStore.attendingCount
                hasUnsavedChanges = true
            } label: {
                HStack {
                    Image(systemName: "person.3.fill")
                    Text("Auto (\(guestStore.attendingCount) attending)")
                    Spacer()
                    if calculator.guestCountMode == .auto {
                        Image(systemName: "checkmark")
                    }
                }
            }

            // Manual mode - user enters count
            Button {
                calculator.convertToMode(.manual)
                hasUnsavedChanges = true
            } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text("Manual Entry")
                    Spacer()
                    if calculator.guestCountMode == .manual {
                        Image(systemName: "checkmark")
                    }
                }
            }

            Divider()

            // Variable mode - each item has its own quantity
            Button {
                calculator.convertToMode(.variable)
                hasUnsavedChanges = true
            } label: {
                HStack {
                    Image(systemName: "number.square")
                    Text("Variable (Per-Item)")
                    Spacer()
                    if calculator.guestCountMode == .variable {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: calculator.guestCountMode.icon)
                    .font(Typography.caption2)
                Text(calculator.guestCountMode.displayName)
                    .font(Typography.caption)
            }
            .foregroundColor(SemanticColors.primaryAction)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(SemanticColors.primaryAction.opacity(0.1))
            .cornerRadius(CornerRadius.sm)
        }
        .menuStyle(.borderlessButton)
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            HStack(alignment: .top, spacing: Spacing.xxl) {
                VStack(spacing: Spacing.lg) {
                    perPersonSection
                    serviceFeeSection
                    flatFeeSection
                    notesSection
                }
                .frame(maxWidth: .infinity)

                costSummarySidebar
                    .frame(width: 340)
            }
            .padding(Spacing.xxl)
        }
    }

    // MARK: - Per-Person Section

    private var perPersonSection: some View {
        BillCalculatorSectionView(
            title: usesVariableItemCount ? "Per-Item Expenses" : "Per-Person Items",
            subtitle: usesVariableItemCount ? "Each item has its own quantity" : "Costs multiplied by guest count",
            icon: usesVariableItemCount ? "number.square" : "person.fill",
            sectionTotal: calculator.perPersonTotal,
            accentColor: SoftLavender.shade500
        ) {
            VStack(spacing: Spacing.md) {
                ForEach(Array(calculator.perPersonItems.enumerated()), id: \.element.id) { index, _ in
                    if usesVariableItemCount {
                        // Variable mode: show VariableItemRow with editable quantity
                        VariableItemRow(
                            item: bindingForPerPersonItem(at: index),
                            onDelete: {
                                calculator.removePerPersonItem(at: index)
                                hasUnsavedChanges = true
                            }
                        )
                    } else {
                        // Auto/Manual mode: show standard PerPersonItemRow
                        PerPersonItemRow(
                            item: bindingForPerPersonItem(at: index),
                            guestCount: calculator.guestCount,
                            onDelete: {
                                calculator.removePerPersonItem(at: index)
                                hasUnsavedChanges = true
                            }
                        )
                    }
                }

                if usesVariableItemCount {
                    addItemButton(type: .perPerson, accentColor: SoftLavender.shade500) {
                        showingAddVariableItemModal = true
                    }
                } else {
                    addItemButton(type: .perPerson, accentColor: SoftLavender.shade500) {
                        showingAddPerPersonModal = true
                    }
                }
            }
        }
    }

    // MARK: - Service Fee Section

    private var serviceFeeSection: some View {
        BillCalculatorSectionView(
            title: "Service Fee Items",
            subtitle: "Percentage-based fees on subtotal",
            icon: "percent",
            sectionTotal: calculator.serviceFeeTotal,
            accentColor: AppColors.info
        ) {
            VStack(spacing: Spacing.md) {
                serviceFeeInfoBox

                ForEach(Array(calculator.serviceFeeItems.enumerated()), id: \.element.id) { index, item in
                    ServiceFeeItemRow(
                        item: bindingForServiceFeeItem(at: index),
                        subtotal: calculator.serviceFeeSubtotal,
                        onDelete: {
                            calculator.removeServiceFeeItem(at: index)
                            hasUnsavedChanges = true
                        }
                    )
                }

                addItemButton(type: .serviceFee, accentColor: AppColors.info) {
                    showingAddServiceFeeModal = true
                }
            }
        }
    }

    private var serviceFeeInfoBox: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(AppColors.info)
                .font(Typography.numberSmall)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Service fees are calculated on subtotal")
                    .font(Typography.bodySmall.weight(.semibold))
                    .foregroundColor(SemanticColors.textPrimary)
                Text("Service fees exclude other service fees from the calculation base. Current subtotal: \(formatCurrency(calculator.serviceFeeSubtotal))")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.infoLight)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(AppColors.info.opacity(Opacity.semiLight), lineWidth: 1)
        )
    }

    // MARK: - Flat Fee Section

    private var flatFeeSection: some View {
        BillCalculatorSectionView(
            title: "Flat Fee Items",
            subtitle: "One-time fixed costs",
            icon: "tag.fill",
            sectionTotal: calculator.flatFeeTotal,
            accentColor: SageGreen.shade500
        ) {
            VStack(spacing: Spacing.md) {
                ForEach(Array(calculator.flatFeeItems.enumerated()), id: \.element.id) { index, item in
                    FlatFeeItemRow(
                        item: bindingForFlatFeeItem(at: index),
                        onDelete: {
                            calculator.removeFlatFeeItem(at: index)
                            hasUnsavedChanges = true
                        }
                    )
                }

                addItemButton(type: .flatFee, accentColor: SageGreen.shade500) {
                    showingAddFlatFeeModal = true
                }
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "note.text")
                    .foregroundColor(SemanticColors.primaryAction)
                Text("Notes & Details")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            TextEditor(text: Binding(
                get: { calculator.notes ?? "" },
                set: { calculator.notes = $0.isEmpty ? nil : $0 }
            ))
            .font(Typography.bodyRegular)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 100)
            .padding(Spacing.md)
        }
        .glassPanel(cornerRadius: CornerRadius.lg, padding: 0)
    }

    // MARK: - Cost Summary Sidebar

    private var costSummarySidebar: some View {
        VStack(spacing: Spacing.lg) {
            costSummaryCard
            quickStatsCard
            calculatorActionsCard
        }
    }

    private var costSummaryCard: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Cost Summary")
                    .font(Typography.title3)
                    .foregroundColor(SemanticColors.textPrimary)
                Text(calculator.summaryDescription)
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)

            VStack(spacing: Spacing.lg) {
                VStack(spacing: Spacing.md) {
                    summaryRow(label: "Per-Person Items", amount: calculator.perPersonTotal, dotColor: SoftLavender.shade500)
                    summaryRow(label: "Service Fees", amount: calculator.serviceFeeTotal, dotColor: AppColors.info)
                    summaryRow(label: "Flat Fees", amount: calculator.flatFeeTotal, dotColor: SageGreen.shade500)

                    HStack {
                        Text("Subtotal")
                            .font(Typography.bodyRegular.weight(.semibold))
                            .foregroundColor(SemanticColors.textSecondary)
                        Spacer()
                        Text(formatCurrency(calculator.subtotal))
                            .font(Typography.numberMedium)
                            .foregroundColor(SemanticColors.textPrimary)
                    }
                    .padding(.top, Spacing.sm)
                }

                perGuestCostBox

                taxRateSelector

                VStack(spacing: Spacing.sm) {
                    HStack {
                        Text("Tax Amount (\(String(format: "%.1f", calculator.effectiveTaxRate))%)")
                            .font(Typography.bodySmall)
                            .foregroundColor(SemanticColors.textSecondary)
                        Spacer()
                        Text(formatCurrency(calculator.taxAmount))
                            .font(Typography.bodyRegular.weight(.semibold))
                            .foregroundColor(SemanticColors.textPrimary)
                    }
                }

                Divider()

                estimatedTotalBox

                VStack(spacing: Spacing.sm) {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save to Budget")
                        }
                        .font(Typography.bodyRegular.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(SemanticColors.primaryAction)
                        .foregroundColor(.white)
                        .cornerRadius(CornerRadius.lg)
                    }
                    .buttonStyle(.plain)

                    Button(action: {}) {
                        HStack {
                            Image(systemName: "doc.richtext")
                            Text("Export as PDF")
                        }
                        .font(Typography.bodyRegular.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(SemanticColors.controlBackground)
                        .foregroundColor(SemanticColors.textPrimary)
                        .cornerRadius(CornerRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.lg)
                                .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Spacing.lg)
        }
        .glassPanel(cornerRadius: CornerRadius.lg, padding: 0)
    }

    private func summaryRow(label: String, amount: Double, dotColor: Color) -> some View {
        HStack {
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(dotColor)
                    .frame(width: Spacing.sm, height: Spacing.sm)
                Text(label)
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)
            }
            Spacer()
            Text(formatCurrency(amount))
                .font(Typography.bodyRegular.weight(.bold))
                .foregroundColor(SemanticColors.textPrimary)
        }
        .padding(.bottom, Spacing.sm)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var perGuestCostBox: some View {
        VStack(spacing: Spacing.xs) {
            HStack {
                Text("Per Guest Cost")
                    .font(Typography.bodySmall.weight(.semibold))
                    .foregroundColor(SemanticColors.textSecondary)
                Spacer()
                Text(formatCurrency(calculator.perGuestCost))
                    .font(Typography.numberLarge)
                    .foregroundColor(SemanticColors.primaryAction)
            }
            Text("Based on \(calculator.guestCount) guests")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.md)
        .background(SemanticColors.primaryAction.opacity(0.08))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(SemanticColors.primaryAction.opacity(0.2), lineWidth: 1)
        )
    }

    private var taxRateSelector: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Tax Rate")
                .font(Typography.bodySmall.weight(.semibold))
                .foregroundColor(SemanticColors.textSecondary)

            Menu {
                // Tax info options from database
                ForEach(billCalculatorStore.taxInfoOptions) { taxInfo in
                    Button(taxInfo.displayName) {
                        calculator.taxInfoId = taxInfo.id
                        // Update the joined tax rate field for display purposes
                        // Use taxRateAsPercentage since BillCalculator expects percentage format
                        calculator = BillCalculator(
                            id: calculator.id,
                            coupleId: calculator.coupleId,
                            name: calculator.name,
                            vendorId: calculator.vendorId,
                            eventId: calculator.eventId,
                            taxInfoId: taxInfo.id,
                            guestCount: calculator.guestCount,
                            guestCountMode: calculator.guestCountMode,
                            notes: calculator.notes,
                            createdAt: calculator.createdAt,
                            updatedAt: calculator.updatedAt,
                            vendorName: calculator.vendorName,
                            eventName: calculator.eventName,
                            taxRate: taxInfo.taxRateAsPercentage,
                            taxRegion: taxInfo.region,
                            items: calculator.items
                        )
                        hasUnsavedChanges = true
                    }
                }

                if !billCalculatorStore.taxInfoOptions.isEmpty {
                    Divider()
                }

                Button("No Tax (0%)") {
                    calculator.taxInfoId = nil
                    calculator = BillCalculator(
                        id: calculator.id,
                        coupleId: calculator.coupleId,
                        name: calculator.name,
                        vendorId: calculator.vendorId,
                        eventId: calculator.eventId,
                        taxInfoId: nil,
                        guestCount: calculator.guestCount,
                        guestCountMode: calculator.guestCountMode,
                        notes: calculator.notes,
                        createdAt: calculator.createdAt,
                        updatedAt: calculator.updatedAt,
                        vendorName: calculator.vendorName,
                        eventName: calculator.eventName,
                        taxRate: 0,
                        taxRegion: nil,
                        items: calculator.items
                    )
                    hasUnsavedChanges = true
                }
            } label: {
                HStack {
                    Text(taxRateDisplayName)
                        .font(Typography.bodyRegular.weight(.medium))
                        .foregroundColor(SemanticColors.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(SemanticColors.controlBackground)
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                )
            }
            .menuStyle(.borderlessButton)
        }
    }

    private var taxRateDisplayName: String {
        let effectiveRate = calculator.taxRate ?? 0
        if effectiveRate == 0 {
            return "No Tax (0%)"
        }
        if let region = calculator.taxRegion {
            return "\(String(format: "%.2f", effectiveRate))% - \(region)"
        }
        return "\(String(format: "%.2f", effectiveRate))%"
    }

    private var estimatedTotalBox: some View {
        VStack(spacing: Spacing.xs) {
            HStack {
                Text("Estimated Total")
                    .font(Typography.bodyRegular.weight(.semibold))
                    .foregroundColor(SemanticColors.textPrimary)
                Spacer()
                Text(formatCurrency(calculator.grandTotal))
                    .font(Typography.displaySmall)
                    .foregroundColor(SemanticColors.primaryAction)
            }
            Text("Including all fees and taxes")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.lg)
        .background(SemanticColors.primaryAction.opacity(0.12))
        .cornerRadius(CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(SemanticColors.primaryAction.opacity(0.3), lineWidth: 1)
        )
    }

    private var quickStatsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("QUICK STATS")
                .font(Typography.caption.weight(.bold))
                .foregroundColor(SemanticColors.textSecondary)
                .tracking(0.5)

            VStack(spacing: Spacing.md) {
                statRow(icon: "person.2.fill", label: "Total Guests", value: "\(calculator.guestCount)")
                statRow(icon: "calendar", label: "Events", value: calculator.eventName != nil ? "1" : "0")
                statRow(icon: "list.bullet", label: "Total Items", value: "\(calculator.totalItemCount)")

                Divider()

                statRow(icon: "banknote", label: "Grand Total", value: formatCurrency(calculator.grandTotal), isHighlighted: true)
            }
        }
        .glassPanel(cornerRadius: CornerRadius.lg, padding: Spacing.lg)
    }

    private func statRow(icon: String, label: String, value: String, isHighlighted: Bool = false) -> some View {
        HStack {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(isHighlighted ? SemanticColors.primaryAction : SemanticColors.primaryAction)
                    .font(Typography.bodySmall)
                Text(label)
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)
            }
            Spacer()
            Text(value)
                .font(Typography.bodyRegular.weight(.bold))
                .foregroundColor(isHighlighted ? SemanticColors.primaryAction : SemanticColors.textPrimary)
        }
    }

    private var calculatorActionsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("CALCULATOR ACTIONS")
                .font(Typography.caption.weight(.bold))
                .foregroundColor(SemanticColors.textSecondary)
                .tracking(0.5)

            VStack(spacing: Spacing.sm) {
                actionButton(icon: "doc.on.doc", label: "Duplicate Calculator") {}
                actionButton(icon: "tablecells", label: "Export to Excel") {}
                actionButton(icon: "printer", label: "Print Summary") {}
                actionButton(icon: "trash", label: "Delete Bill", isDestructive: true) {
                    showingDeleteAlert = true
                }
            }
        }
        .glassPanel(cornerRadius: CornerRadius.lg, padding: Spacing.lg)
        .alert("Delete Bill", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                calculatorToDelete = nil
            }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteCalculator(calculatorToDelete ?? calculator)
                    calculatorToDelete = nil
                }
            }
        } message: {
            let name = calculatorDisplayName(calculatorToDelete ?? calculator)
            Text("Are you sure you want to delete \"\(name)\"? This action cannot be undone.")
        }
    }

    private func actionButton(icon: String, label: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(label)
            }
            .font(Typography.bodySmall.weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(SemanticColors.backgroundPrimary)
            .foregroundColor(isDestructive ? SemanticColors.error : SemanticColors.textPrimary)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(SemanticColors.borderPrimary, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footer View

    private var footerView: some View {
        HStack {
            HStack(spacing: Spacing.xl) {
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(SemanticColors.statusSuccess)
                        .frame(width: Spacing.sm, height: Spacing.sm)
                    Text("Auto-saved \(lastSavedText)")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }

                HStack(spacing: Spacing.lg) {
                    footerStat(icon: "list.bullet", value: "\(calculator.totalItemCount) Items")
                    footerStat(icon: "person.2.fill", value: "\(calculator.guestCount) Total Guests")
                    footerStat(icon: "function", value: formatCurrency(calculator.grandTotal) + " Grand Total", isHighlighted: true)
                }
            }

            Spacer()

            HStack(spacing: Spacing.sm) {
                Button(action: {}) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Undo")
                    }
                    .font(Typography.bodySmall.weight(.medium))
                    .foregroundColor(SemanticColors.textSecondary)
                }
                .buttonStyle(.plain)

                Button(action: {}) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "arrow.uturn.forward")
                        Text("Redo")
                    }
                    .font(Typography.bodySmall.weight(.medium))
                    .foregroundColor(SemanticColors.textSecondary)
                }
                .buttonStyle(.plain)

                Divider()
                    .frame(height: Spacing.xl)

                Button(action: {}) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "doc.richtext")
                        Text("Export PDF")
                    }
                    .font(Typography.bodySmall.weight(.medium))
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(SemanticColors.controlBackground)
                    .foregroundColor(SemanticColors.textPrimary)
                    .cornerRadius(CornerRadius.md)
                }
                .buttonStyle(.plain)

                Button(action: {}) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "doc.on.doc")
                        Text("Duplicate")
                    }
                    .font(Typography.bodySmall.weight(.medium))
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(SemanticColors.controlBackground)
                    .foregroundColor(SemanticColors.textPrimary)
                    .cornerRadius(CornerRadius.md)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.xxl)
        .padding(.vertical, Spacing.md)
        .glassPanel(cornerRadius: 0, padding: 0)
    }

    private func footerStat(icon: String, value: String, isHighlighted: Bool = false) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .foregroundColor(SemanticColors.primaryAction)
                .font(Typography.caption)
            Text(value)
                .font(Typography.bodySmall.weight(.semibold))
                .foregroundColor(isHighlighted ? SemanticColors.primaryAction : SemanticColors.textPrimary)
        }
    }

    // MARK: - Helper Methods

    private func addItemButton(type: BillItemType, accentColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus")
                Text("Add \(type.displayName) Item")
            }
            .font(Typography.bodySmall.weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .foregroundColor(SemanticColors.textSecondary)
            .contentShape(Rectangle()) // Hit area for the entire button
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .foregroundColor(SemanticColors.borderPrimary)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = settingsStore.settings.global.currency
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    /// Creates a binding for a per-person item that adapts BillCalculatorItem to BillLineItem
    private func bindingForPerPersonItem(at index: Int) -> Binding<BillLineItem> {
        Binding(
            get: {
                let item = calculator.perPersonItems[index]
                return BillLineItem(id: item.id, name: item.name, amount: item.amount, quantity: item.quantity, sortOrder: item.sortOrder)
            },
            set: { newValue in
                // Find and update the item in the items array
                if let itemIndex = calculator.items.firstIndex(where: { $0.id == newValue.id }) {
                    calculator.items[itemIndex].name = newValue.name
                    calculator.items[itemIndex].amount = newValue.amount
                    calculator.items[itemIndex].quantity = newValue.quantity
                    calculator.items[itemIndex].sortOrder = newValue.sortOrder
                    hasUnsavedChanges = true
                }
            }
        )
    }

    /// Creates a binding for a service fee item that adapts BillCalculatorItem to BillLineItem
    private func bindingForServiceFeeItem(at index: Int) -> Binding<BillLineItem> {
        Binding(
            get: {
                let item = calculator.serviceFeeItems[index]
                return BillLineItem(id: item.id, name: item.name, amount: item.amount, quantity: item.quantity, sortOrder: item.sortOrder)
            },
            set: { newValue in
                // Find and update the item in the items array
                if let itemIndex = calculator.items.firstIndex(where: { $0.id == newValue.id }) {
                    calculator.items[itemIndex].name = newValue.name
                    calculator.items[itemIndex].amount = newValue.amount
                    calculator.items[itemIndex].quantity = newValue.quantity
                    calculator.items[itemIndex].sortOrder = newValue.sortOrder
                    hasUnsavedChanges = true
                }
            }
        )
    }

    /// Creates a binding for a flat fee item that adapts BillCalculatorItem to BillLineItem
    private func bindingForFlatFeeItem(at index: Int) -> Binding<BillLineItem> {
        Binding(
            get: {
                let item = calculator.flatFeeItems[index]
                return BillLineItem(id: item.id, name: item.name, amount: item.amount, quantity: item.quantity, sortOrder: item.sortOrder)
            },
            set: { newValue in
                // Find and update the item in the items array
                if let itemIndex = calculator.items.firstIndex(where: { $0.id == newValue.id }) {
                    calculator.items[itemIndex].name = newValue.name
                    calculator.items[itemIndex].amount = newValue.amount
                    calculator.items[itemIndex].quantity = newValue.quantity
                    calculator.items[itemIndex].sortOrder = newValue.sortOrder
                    hasUnsavedChanges = true
                }
            }
        )
    }

    // MARK: - Expense Linking

    /// Loads the linked expense for the current calculator
    private func loadLinkedExpense() async {
        guard calculator.createdAt != nil else {
            // Calculator hasn't been saved yet, no links possible
            linkedExpenseId = nil
            linkedExpense = nil
            return
        }

        isLoadingLinkedExpense = true
        defer { isLoadingLinkedExpense = false }

        do {
            let links = try await budgetStore.repository.fetchExpenseLinksForBillCalculator(
                billCalculatorId: calculator.id
            )

            if let firstLink = links.first {
                linkedExpenseId = firstLink.expenseId
                // Find the expense in our loaded expenses
                linkedExpense = budgetStore.expenseStore.expenses.first { $0.id == firstLink.expenseId }
            } else {
                linkedExpenseId = nil
                linkedExpense = nil
            }
        } catch {
            AppLogger.ui.error("Failed to load linked expense for calculator \(calculator.id)", error: error)
            linkedExpenseId = nil
            linkedExpense = nil
        }
    }

    /// Links this bill calculator to an expense
    private func linkToExpense(_ expense: Expense) async {
        // If already linked to this expense, do nothing
        guard linkedExpenseId != expense.id else { return }

        // First, ensure the calculator is saved
        if calculator.createdAt == nil {
            await saveCalculator()
            // If save failed (calculator still not saved), abort
            guard calculator.createdAt != nil else { return }
        }

        isLinkingExpense = true
        defer { isLinkingExpense = false }

        do {
            // If there's an existing link, remove only this bill calculator's link (not all links to that expense)
            if let oldExpenseId = linkedExpenseId {
                let existingLinks = try await budgetStore.repository.fetchBillCalculatorLinksForExpense(expenseId: oldExpenseId)
                if let linkToRemove = existingLinks.first(where: { $0.billCalculatorId == calculator.id }) {
                    try await budgetStore.repository.unlinkBillCalculatorFromExpense(linkId: linkToRemove.id)
                }
            }

            // Create the new link
            _ = try await budgetStore.repository.linkBillCalculatorsToExpense(
                expenseId: expense.id,
                billCalculatorIds: [calculator.id],
                linkType: .full,
                notes: nil
            )

            linkedExpenseId = expense.id
            linkedExpense = expense

            AppLogger.ui.info("Linked bill calculator \(calculator.id) to expense \(expense.id)")
        } catch {
            AppLogger.ui.error("Failed to link bill calculator to expense", error: error)
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(operation: "linkBillToExpense", feature: "billCalculator")
            )
        }
    }

    /// Unlinks this bill calculator from its current expense
    private func unlinkExpense() async {
        guard let expenseId = linkedExpenseId else { return }

        isLinkingExpense = true
        defer { isLinkingExpense = false }

        do {
            // Get the specific link to remove
            let links = try await budgetStore.repository.fetchBillCalculatorLinksForExpense(expenseId: expenseId)
            if let linkToRemove = links.first(where: { $0.billCalculatorId == calculator.id }) {
                try await budgetStore.repository.unlinkBillCalculatorFromExpense(linkId: linkToRemove.id)
            }

            linkedExpenseId = nil
            linkedExpense = nil

            AppLogger.ui.info("Unlinked bill calculator \(calculator.id) from expense \(expenseId)")
        } catch {
            AppLogger.ui.error("Failed to unlink bill calculator from expense", error: error)
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(operation: "unlinkBillFromExpense", feature: "billCalculator")
            )
        }
    }

    // MARK: - Store Operations

    /// Saves the calculator to the database
    private func saveCalculator() async {
        guard hasUnsavedChanges else { return }

        isSaving = true
        defer { isSaving = false }

        // Check if this is a new calculator or an update
        if calculator.createdAt == nil {
            // Create new
            if let created = await billCalculatorStore.createCalculator(calculator) {
                calculator = created
                hasUnsavedChanges = false
                lastSaved = Date()
            }
        } else {
            // Update existing
            if let updated = await billCalculatorStore.updateCalculator(calculator) {
                calculator = updated
                hasUnsavedChanges = false
                lastSaved = Date()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BillCalculatorView()
}
