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
    @State private var useGuestCountFromDatabase = false

    private var vendorStore: VendorStoreV2 { appStores.vendor }
    private var settingsStore: SettingsStoreV2 { appStores.settings }
    private var guestStore: GuestStoreV2 { appStores.guest }

    init(coupleId: UUID = UUID()) {
        _calculator = State(initialValue: BillCalculator(coupleId: coupleId))
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            contentView
            footerView
        }
        .background(SemanticColors.backgroundSecondary)
        .task {
            await vendorStore.loadVendors()
            await settingsStore.loadSettings()
            await guestStore.loadGuestData()
        }
        .onChange(of: useGuestCountFromDatabase) { _, useDatabase in
            if useDatabase {
                calculator.guestCount = guestStore.attendingCount
            }
        }
        .onChange(of: guestStore.attendingCount) { _, newCount in
            if useGuestCountFromDatabase {
                calculator.guestCount = newCount
            }
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

                HStack(spacing: Spacing.md) {
                    lastSavedIndicator
                    shareButton
                    saveToBudgetButton
                }
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.vertical, Spacing.lg)

            Divider()

            headerInputsRow
                .padding(.horizontal, Spacing.xxl)
                .padding(.vertical, Spacing.lg)
        }
        .background(SemanticColors.backgroundPrimary)
        .macOSShadow(.subtle)
    }

    private var calculatorIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(
                    LinearGradient(
                        colors: [SoftLavender.shade500, BlushPink.shade500],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)

            Image(systemName: "function")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
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
        Button(action: {}) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "square.and.arrow.down")
                Text("Save to Budget")
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
    }

    private var headerInputsRow: some View {
        HStack(spacing: Spacing.xl) {
            vendorPicker
            billNameField
            eventPicker
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
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(SemanticColors.textTertiary)
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
            .frame(width: 200)
        }
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
        }
    }

    private var eventPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("EVENT")
                .font(Typography.caption.weight(.semibold))
                .foregroundColor(SemanticColors.textSecondary)
                .tracking(0.5)

            Menu {
                ForEach(settingsStore.settings.global.weddingEvents.sorted(by: { $0.eventOrder < $1.eventOrder }), id: \.id) { event in
                    Button(event.eventName) {
                        calculator.eventId = event.id
                        calculator.eventName = event.eventName
                    }
                }
            } label: {
                HStack {
                    Text(calculator.eventName ?? "Select Event")
                        .font(Typography.bodyRegular.weight(.medium))
                        .foregroundColor(calculator.eventName == nil ? SemanticColors.textTertiary : SemanticColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(SemanticColors.textTertiary)
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
            .frame(width: 180)
        }
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
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 32, height: 32)
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

                Button(action: {
                    if !useGuestCountFromDatabase {
                        calculator.guestCount += 1
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 32, height: 32)
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
            Button {
                useGuestCountFromDatabase = false
            } label: {
                HStack {
                    Text("Manual Entry")
                    if !useGuestCountFromDatabase {
                        Image(systemName: "checkmark")
                    }
                }
            }

            Button {
                useGuestCountFromDatabase = true
                calculator.guestCount = guestStore.attendingCount
            } label: {
                HStack {
                    Text("From Guest List (\(guestStore.attendingCount) attending)")
                    if useGuestCountFromDatabase {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: useGuestCountFromDatabase ? "person.3.fill" : "pencil")
                    .font(.system(size: 10))
                Text(useGuestCountFromDatabase ? "Auto" : "Manual")
                    .font(Typography.caption)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8))
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
            title: "Per-Person Items",
            subtitle: "Costs multiplied by guest count",
            icon: "person.fill",
            sectionTotal: calculator.perPersonTotal,
            gradientColors: [SoftLavender.shade500, BlushPink.shade500],
            accentColor: SoftLavender.shade500
        ) {
            VStack(spacing: Spacing.md) {
                ForEach(Array(calculator.perPersonItems.enumerated()), id: \.element.id) { index, item in
                    PerPersonItemRow(
                        item: bindingForPerPersonItem(at: index),
                        guestCount: calculator.guestCount,
                        onDelete: { calculator.removePerPersonItem(at: index) }
                    )
                }

                addItemButton(type: .perPerson, accentColor: SoftLavender.shade500) {
                    calculator.addPerPersonItem()
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
            gradientColors: [Color.fromHex("3B82F6"), Color.fromHex("2563EB")],
            accentColor: Color.fromHex("3B82F6")
        ) {
            VStack(spacing: Spacing.md) {
                serviceFeeInfoBox

                ForEach(Array(calculator.serviceFeeItems.enumerated()), id: \.element.id) { index, item in
                    ServiceFeeItemRow(
                        item: bindingForServiceFeeItem(at: index),
                        subtotal: calculator.serviceFeeSubtotal,
                        onDelete: { calculator.removeServiceFeeItem(at: index) }
                    )
                }

                addItemButton(type: .serviceFee, accentColor: Color.fromHex("3B82F6")) {
                    calculator.addServiceFeeItem()
                }
            }
        }
    }

    private var serviceFeeInfoBox: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(Color.fromHex("3B82F6"))
                .font(.system(size: 16))

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Service fees are calculated on subtotal")
                    .font(Typography.bodySmall.weight(.semibold))
                    .foregroundColor(SemanticColors.textPrimary)
                Text("Service fees exclude other service fees from the calculation base. Current subtotal: \(formatCurrency(calculator.serviceFeeSubtotal))")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
        }
        .padding(Spacing.md)
        .background(Color.fromHex("3B82F6").opacity(0.1))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.fromHex("3B82F6").opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Flat Fee Section

    private var flatFeeSection: some View {
        BillCalculatorSectionView(
            title: "Flat Fee Items",
            subtitle: "One-time fixed costs",
            icon: "tag.fill",
            sectionTotal: calculator.flatFeeTotal,
            gradientColors: [Color.fromHex("10B981"), Color.fromHex("059669")],
            accentColor: Color.fromHex("10B981")
        ) {
            VStack(spacing: Spacing.md) {
                ForEach(Array(calculator.flatFeeItems.enumerated()), id: \.element.id) { index, item in
                    FlatFeeItemRow(
                        item: bindingForFlatFeeItem(at: index),
                        onDelete: { calculator.removeFlatFeeItem(at: index) }
                    )
                }

                addItemButton(type: .flatFee, accentColor: Color.fromHex("10B981")) {
                    calculator.addFlatFeeItem()
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
            .background(SemanticColors.backgroundPrimary)

            Divider()

            TextEditor(text: Binding(
                get: { calculator.notes ?? "" },
                set: { calculator.notes = $0.isEmpty ? nil : $0 }
            ))
            .font(Typography.bodyRegular)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 100)
            .padding(Spacing.md)
            .background(SemanticColors.contentBackground)
        }
        .background(SemanticColors.backgroundPrimary)
        .cornerRadius(CornerRadius.lg)
        .macOSShadow(.subtle)
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
                    .foregroundColor(.white)
                Text(calculator.summaryDescription)
                    .font(Typography.caption)
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .background(
                LinearGradient(
                    colors: [SoftLavender.shade500, BlushPink.shade500],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            VStack(spacing: Spacing.lg) {
                VStack(spacing: Spacing.md) {
                    summaryRow(label: "Per-Person Items", amount: calculator.perPersonTotal, dotColor: SoftLavender.shade500)
                    summaryRow(label: "Service Fees", amount: calculator.serviceFeeTotal, dotColor: Color.fromHex("3B82F6"))
                    summaryRow(label: "Flat Fees", amount: calculator.flatFeeTotal, dotColor: Color.fromHex("10B981"))

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
                        Text("Tax Amount (\(String(format: "%.1f", calculator.taxRate))%)")
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
        .background(SemanticColors.backgroundPrimary)
        .cornerRadius(CornerRadius.lg)
        .macOSShadow(.elevated)
    }

    private func summaryRow(label: String, amount: Double, dotColor: Color) -> some View {
        HStack {
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 8, height: 8)
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
        .background(
            LinearGradient(
                colors: [SoftLavender.shade50, BlushPink.shade50],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(SoftLavender.shade200, lineWidth: 1)
        )
    }

    private var taxRateSelector: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Tax Rate")
                .font(Typography.bodySmall.weight(.semibold))
                .foregroundColor(SemanticColors.textSecondary)

            Menu {
                ForEach(settingsStore.settings.budget.taxRates, id: \.id) { taxRate in
                    Button("\(taxRate.name) (\(String(format: "%.2f", taxRate.rate))%)") {
                        calculator.taxRate = taxRate.rate
                    }
                }

                if !settingsStore.settings.budget.taxRates.isEmpty {
                    Divider()
                }

                Button("No Tax (0%)") {
                    calculator.taxRate = 0
                }
            } label: {
                HStack {
                    Text(taxRateDisplayName)
                        .font(Typography.bodyRegular.weight(.medium))
                        .foregroundColor(SemanticColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(SemanticColors.textTertiary)
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
        if calculator.taxRate == 0 {
            return "No Tax (0%)"
        }
        if let matchingRate = settingsStore.settings.budget.taxRates.first(where: { $0.rate == calculator.taxRate }) {
            return "\(matchingRate.name) (\(String(format: "%.2f", matchingRate.rate))%)"
        }
        return "\(String(format: "%.2f", calculator.taxRate))% - Custom Rate"
    }

    private var estimatedTotalBox: some View {
        VStack(spacing: Spacing.xs) {
            HStack {
                Text("Estimated Total")
                    .font(Typography.bodyRegular.weight(.semibold))
                    .foregroundColor(.white)
                Spacer()
                Text(formatCurrency(calculator.grandTotal))
                    .font(Typography.displaySmall)
                    .foregroundColor(.white)
            }
            Text("Including all fees and taxes")
                .font(Typography.caption)
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.lg)
        .background(
            LinearGradient(
                colors: [SoftLavender.shade500, BlushPink.shade500],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(CornerRadius.lg)
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
        .padding(Spacing.lg)
        .background(SemanticColors.backgroundPrimary)
        .cornerRadius(CornerRadius.lg)
        .macOSShadow(.subtle)
    }

    private func statRow(icon: String, label: String, value: String, isHighlighted: Bool = false) -> some View {
        HStack {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(isHighlighted ? SemanticColors.primaryAction : SemanticColors.primaryAction)
                    .font(.system(size: 14))
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
                actionButton(icon: "trash", label: "Delete Calculator", isDestructive: true) {
                    showingDeleteAlert = true
                }
            }
        }
        .padding(Spacing.lg)
        .background(
            LinearGradient(
                colors: [SemanticColors.backgroundSecondary, SemanticColors.backgroundTertiary],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(CornerRadius.lg)
        .macOSShadow(.subtle)
        .alert("Delete Calculator", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {}
        } message: {
            Text("Are you sure you want to delete this calculator? This action cannot be undone.")
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
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
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
                    .frame(height: 20)

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
        .background(SemanticColors.backgroundPrimary)
        .macOSShadow(.subtle)
    }

    private func footerStat(icon: String, value: String, isHighlighted: Bool = false) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .foregroundColor(SemanticColors.primaryAction)
                .font(.system(size: 12))
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
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .foregroundColor(SemanticColors.borderPrimary)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
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

    private func bindingForPerPersonItem(at index: Int) -> Binding<BillLineItem> {
        Binding(
            get: { calculator.perPersonItems[index] },
            set: { calculator.perPersonItems[index] = $0 }
        )
    }

    private func bindingForServiceFeeItem(at index: Int) -> Binding<BillLineItem> {
        Binding(
            get: { calculator.serviceFeeItems[index] },
            set: { calculator.serviceFeeItems[index] = $0 }
        )
    }

    private func bindingForFlatFeeItem(at index: Int) -> Binding<BillLineItem> {
        Binding(
            get: { calculator.flatFeeItems[index] },
            set: { calculator.flatFeeItems[index] = $0 }
        )
    }
}

// MARK: - Preview

#Preview {
    BillCalculatorView(coupleId: UUID())
}
