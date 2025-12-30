//
//  BudgetItemsTableHeader.swift
//  I Do Blueprint
//
//  Sticky header with title and column headers for budget items table
//

import SwiftUI

struct BudgetItemsTableHeader: View {
    var body: some View {
        VStack(spacing: 0) {
            // Budget Items title
            HStack {
                Text("Budget Items")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.sm)

            // Column headers
            HStack(spacing: 12) {
                Text("Event")
                    .frame(width: 120, alignment: .leading)
                Text("Item")
                    .frame(width: 180, alignment: .leading)
                Text("Category")
                    .frame(width: 120, alignment: .leading)
                Text("Subcategory")
                    .frame(width: 120, alignment: .leading)
                Text("Est. (No Tax)")
                    .frame(width: 100, alignment: .leading)
                Text("Tax Rate")
                    .frame(width: 80, alignment: .leading)
                Text("Est. (With Tax)")
                    .frame(width: 110, alignment: .leading)
                Text("Person")
                    .frame(width: 80, alignment: .leading)
                Text("Notes")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Actions")
                    .frame(width: 60, alignment: .leading)
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .padding(.vertical, Spacing.sm)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

#Preview {
    BudgetItemsTableHeader()
}
