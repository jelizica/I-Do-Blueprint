import SwiftUI

struct AffordabilityGiftImportRow: View {
    let gift: GiftOrOwed
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AppColors.Budget.allocated : .secondary)
                    .font(.system(size: 20))

                VStack(alignment: .leading, spacing: 4) {
                    Text(gift.fromPerson ?? gift.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        Text(gift.type.displayName)
                            .font(.system(size: 11))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppColors.Budget.allocated.opacity(0.1))
                            .foregroundStyle(AppColors.Budget.allocated)
                            .clipShape(Capsule())

                        if let date = gift.receivedDate ?? gift.expectedDate {
                            Text(date, style: .date)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                Text("$\(Int(gift.amount))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)
            }
            .padding(12)
            .background(isSelected ? AppColors.Budget.allocated.opacity(0.05) : Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? AppColors.Budget.allocated : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
