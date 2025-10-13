import Charts
import SwiftUI

struct MoneyReceivedView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @State private var searchText = ""
    @State private var selectedGiftType: GiftType?
    @State private var sortOrder: SortOrder = .dateDescending
    @State private var showingNewGiftForm = false
    @State private var selectedGift: GiftReceived?

    private enum SortOrder: String, CaseIterable {
        case dateDescending = "Date (Latest)"
        case dateAscending = "Date (Oldest)"
        case amountDescending = "Amount (High to Low)"
        case amountAscending = "Amount (Low to High)"
        case personAscending = "Person (A-Z)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Summary section
            summarySection

            // Filters and sorting
            filtersSection

            // Gift type breakdown chart
            chartSection

            // Gifts list
            giftsListSection
        }
        .searchable(text: $searchText, prompt: "Search gifts...")
        .sheet(isPresented: $showingNewGiftForm) {
            AddGiftOrOwedModal { newGift in
                Task {
                    await budgetStore.addGiftOrOwed(newGift)
                }
            }
        }
        .sheet(item: $selectedGift) { gift in
            GiftDetailView(gift: gift)
                .environmentObject(budgetStore)
        }
    }

    private var summarySection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Received")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(totalReceived, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("Gift Count")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(filteredGifts.count)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Avg Gift")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(averageGiftAmount, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }

            // Thank you status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Thank You Sent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(thankYouSentCount)")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Pending")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(thankYouPendingCount)")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .padding()
    }

    private var filtersSection: some View {
        VStack(spacing: 12) {
            // Gift type filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All Types",
                        isSelected: selectedGiftType == nil,
                        action: { selectedGiftType = nil })

                    ForEach(GiftType.allCases, id: \.self) { type in
                        FilterChip(
                            title: type.rawValue,
                            isSelected: selectedGiftType == type,
                            action: { selectedGiftType = type })
                    }
                }
                .padding(.horizontal)
            }

            // Sort order
            HStack {
                Text("Sort by:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Menu {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button(order.rawValue) {
                            sortOrder = order
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(sortOrder.rawValue)
                            .font(.caption)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gifts by Type")
                .font(.headline)
                .padding(.horizontal)

            Chart {
                ForEach(giftTypeData, id: \.type) { data in
                    SectorMark(
                        angle: .value("Amount", data.amount),
                        innerRadius: .ratio(0.6),
                        angularInset: 2)
                        .foregroundStyle(data.color)
                        .cornerRadius(4)
                }
            }
            .frame(height: 200)
            .chartOverlay { _ in
                GeometryReader { geometry in
                    VStack {
                        Text("$\(totalReceived, specifier: "%.0f")")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Total")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .position(
                        x: geometry.frame(in: .local).midX,
                        y: geometry.frame(in: .local).midY)
                }
            }
            .padding(.horizontal)

            // Legend
            HStack {
                ForEach(giftTypeData, id: \.type) { data in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(data.color)
                            .frame(width: 8, height: 8)
                        Text(data.type.rawValue)
                            .font(.caption2)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var giftsListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Gifts Received")
                    .font(.headline)
                Spacer()
                Button("Add Gift") {
                    showingNewGiftForm = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding()

            if filteredGifts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "gift")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)

                    Text("No gifts received yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("Add your first gift to start tracking")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Button("Add Gift") {
                        showingNewGiftForm = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(filteredGifts, id: \.id) { gift in
                        GiftRowView(gift: gift) {
                            selectedGift = gift
                        }
                        .environmentObject(budgetStore)

                        if gift.id != filteredGifts.last?.id {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var totalReceived: Double {
        filteredGifts.reduce(0) { $0 + $1.amount }
    }

    private var averageGiftAmount: Double {
        guard !filteredGifts.isEmpty else { return 0 }
        return totalReceived / Double(filteredGifts.count)
    }

    private var thankYouSentCount: Int {
        filteredGifts.filter(\.isThankYouSent).count
    }

    private var thankYouPendingCount: Int {
        filteredGifts.filter { !$0.isThankYouSent }.count
    }

    private var filteredGifts: [GiftReceived] {
        var gifts = budgetStore.giftsReceived

        // Apply search filter
        if !searchText.isEmpty {
            gifts = gifts.filter { gift in
                gift.fromPerson.localizedCaseInsensitiveContains(searchText) ||
                    gift.giftType.rawValue.localizedCaseInsensitiveContains(searchText) ||
                    (gift.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Apply gift type filter
        if let selectedType = selectedGiftType {
            gifts = gifts.filter { $0.giftType == selectedType }
        }

        // Apply sorting
        switch sortOrder {
        case .dateDescending:
            gifts.sort { $0.dateReceived > $1.dateReceived }
        case .dateAscending:
            gifts.sort { $0.dateReceived < $1.dateReceived }
        case .amountDescending:
            gifts.sort { $0.amount > $1.amount }
        case .amountAscending:
            gifts.sort { $0.amount < $1.amount }
        case .personAscending:
            gifts.sort { $0.fromPerson < $1.fromPerson }
        }

        return gifts
    }

    private var giftTypeData: [GiftTypeData] {
        let grouped = Dictionary(grouping: filteredGifts) { $0.giftType }
        let colors: [Color] = [.blue, .green, .orange, .purple, .red, .pink]

        return GiftType.allCases.enumerated().compactMap { index, type in
            let gifts = grouped[type] ?? []
            let amount = gifts.reduce(0) { $0 + $1.amount }
            guard amount > 0 else { return nil }

            return GiftTypeData(
                type: type,
                amount: amount,
                count: gifts.count,
                color: colors[index % colors.count])
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct GiftRowView: View {
    let gift: GiftReceived
    let onTap: () -> Void
    @EnvironmentObject var budgetStore: BudgetStoreV2

    var body: some View {
        HStack(spacing: 12) {
            // Gift type icon
            ZStack {
                Circle()
                    .fill(giftTypeColor)
                    .frame(width: 40, height: 40)

                Image(systemName: giftTypeIcon)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(gift.fromPerson)
                        .font(.system(size: 14, weight: .medium))

                    if !gift.isThankYouSent {
                        Text("THANK YOU")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }

                Text(gift.giftType.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(gift.dateReceived, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(gift.amount, specifier: "%.0f")")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)

                Button(action: {
                    toggleThankYouStatus()
                }) {
                    Image(systemName: gift.isThankYouSent ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(gift.isThankYouSent ? .green : .gray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }

    private var giftTypeColor: Color {
        switch gift.giftType {
        case .cash: .green
        case .check: .blue
        case .gift: .purple
        case .giftCard: .orange
        case .other: .gray
        }
    }

    private var giftTypeIcon: String {
        switch gift.giftType {
        case .cash: "dollarsign"
        case .check: "doc.text"
        case .gift: "gift"
        case .giftCard: "creditcard"
        case .other: "ellipsis"
        }
    }

    private func toggleThankYouStatus() {
        var updatedGift = gift
        updatedGift.isThankYouSent.toggle()
        Task {
            await budgetStore.updateGiftReceived(updatedGift)
        }
    }
}

struct GiftDetailView: View {
    let gift: GiftReceived
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @State private var showingEditForm = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Gift amount
                HStack {
                    Text("$\(gift.amount, specifier: "%.2f")")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.green)

                    Spacer()

                    Button(action: {
                        var updatedGift = gift
                        updatedGift.isThankYouSent.toggle()
                        Task {
                            await budgetStore.updateGiftReceived(updatedGift)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: gift.isThankYouSent ? "checkmark.circle.fill" : "circle")
                            Text(gift.isThankYouSent ? "Thank You Sent" : "Send Thank You")
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(gift.isThankYouSent ? Color.green : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }

                // Gift details
                VStack(alignment: .leading, spacing: 12) {
                    MoneyReceivedDetailRow(label: "From", value: gift.fromPerson)
                    MoneyReceivedDetailRow(label: "Type", value: gift.giftType.rawValue)
                    MoneyReceivedDetailRow(
                        label: "Date Received",
                        value: gift.dateReceived.formatted(date: .abbreviated, time: .omitted))

                    if let notes = gift.notes, !notes.isEmpty {
                        MoneyReceivedDetailRow(label: "Notes", value: notes)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Gift Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        showingEditForm = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditForm) {
            // Convert GiftReceived to GiftOrOwed for editing
            if let giftOrOwed = convertToGiftOrOwed(gift: gift) {
                EditGiftOrOwedModal(
                    giftOrOwed: giftOrOwed,
                    onSave: { updatedGift in
                        Task {
                            await budgetStore.updateGiftOrOwed(updatedGift)
                        }
                    },
                    onDelete: { giftToDelete in
                        Task {
                            await budgetStore.deleteGiftOrOwed(id: giftToDelete.id)
                        }
                    })
            }
        }
    }

    private func convertToGiftOrOwed(gift: GiftReceived) -> GiftOrOwed? {
        guard let coupleId = SessionManager.shared.getTenantId() else {
            return nil
        }
        return GiftOrOwed(
            id: UUID(), // Will be handled by database
            coupleId: coupleId,
            title: "Gift from \(gift.fromPerson)",
            amount: gift.amount,
            type: .giftReceived,
            description: gift.notes,
            fromPerson: gift.fromPerson,
            expectedDate: nil,
            receivedDate: gift.dateReceived,
            status: .received,
            createdAt: Date(),
            updatedAt: nil)
    }
}

struct MoneyReceivedDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 14))
        }
    }
}

// MARK: - Data Models

struct GiftTypeData {
    let type: GiftType
    let amount: Double
    let count: Int
    let color: Color
}

#Preview {
    MoneyReceivedView()
        .environmentObject(BudgetStoreV2())
}
