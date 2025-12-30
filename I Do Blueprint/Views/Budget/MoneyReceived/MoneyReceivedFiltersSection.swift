//
//  MoneyReceivedFiltersSection.swift
//  I Do Blueprint
//
//  Filters and sorting controls for money received view
//

import SwiftUI

struct MoneyReceivedFiltersSection: View {
    @Binding var selectedGiftType: GiftType?
    @Binding var sortOrder: MoneyReceivedSortOrder
    
    var body: some View {
        VStack(spacing: 12) {
            // Gift type filter
            giftTypeFilterRow
            
            // Sort order
            sortOrderRow
        }
    }
    
    // MARK: - Subviews
    
    private var giftTypeFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All Types",
                    isSelected: selectedGiftType == nil,
                    action: { selectedGiftType = nil }
                )
                
                ForEach(GiftType.allCases, id: \.self) { type in
                    FilterChip(
                        title: type.rawValue,
                        isSelected: selectedGiftType == type,
                        action: { selectedGiftType = type }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var sortOrderRow: some View {
        HStack {
            Text("Sort by:")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Menu {
                ForEach(MoneyReceivedSortOrder.allCases, id: \.self) { order in
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

// MARK: - Supporting Types

enum MoneyReceivedSortOrder: String, CaseIterable {
    case dateDescending = "Date (Latest)"
    case dateAscending = "Date (Oldest)"
    case amountDescending = "Amount (High to Low)"
    case amountAscending = "Amount (Low to High)"
    case personAscending = "Person (A-Z)"
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

// MARK: - Preview

#Preview {
    MoneyReceivedFiltersSection(
        selectedGiftType: .constant(nil),
        sortOrder: .constant(.dateDescending)
    )
    .frame(width: 600)
}
