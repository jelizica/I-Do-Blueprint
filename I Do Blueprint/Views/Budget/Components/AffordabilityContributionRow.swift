import SwiftUI

struct AffordabilityContributionRow: View {
    let contribution: ContributionItem
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "gift.fill")
                        .foregroundStyle(contribution.contributionType == .gift ? AppColors.Budget.allocated : AppColors.Budget.income)
                        .font(.system(size: 12))
                    Text(contribution.contributorName)
                        .font(.system(size: 14, weight: .semibold))

                    Text(contribution.contributionType.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(contribution.contributionType == .gift ? AppColors.Budget.allocated.opacity(0.1) : AppColors.Budget.income.opacity(0.1))
                        .clipShape(Capsule())
                        .foregroundStyle(contribution.contributionType == .gift ? AppColors.Budget.allocated : AppColors.Budget.income)
                }

                Text(contribution.contributionDate, style: .date)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                if let notes = contribution.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text("$\(Int(contribution.amount))")
                .font(.system(size: 16, weight: .bold))

            HStack(spacing: 4) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Edit contribution")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.Budget.overBudget)
                }
                .buttonStyle(.borderless)
                .help("Delete contribution")
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
