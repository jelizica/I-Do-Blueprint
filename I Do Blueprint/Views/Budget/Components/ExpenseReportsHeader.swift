import SwiftUI

/// Header component for Expense Reports with title and action buttons
struct ExpenseReportsHeader: View {
    let onExport: () -> Void
    let onRefresh: () async -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Expense Reports")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Manage and analyze your wedding budget expenses")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: onExport) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                }

                Button(action: {
                    Task {
                        await onRefresh()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                }
            }
        }
    }
}
