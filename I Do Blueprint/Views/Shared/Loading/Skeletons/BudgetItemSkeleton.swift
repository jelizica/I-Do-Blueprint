import SwiftUI

/// Skeleton loading placeholder for budget items
struct BudgetItemSkeleton: View {
    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Icon skeleton
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.borderLight)
                .frame(width: 40, height: 40)
                .shimmer()

            // Content skeleton
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Category name
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.borderLight)
                    .frame(width: 120, height: 16)
                    .shimmer()

                // Budget vs actual
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.borderLight)
                    .frame(width: 160, height: 12)
                    .shimmer()
            }

            Spacer()

            // Amount skeleton
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.borderLight)
                    .frame(width: 80, height: 18)
                    .shimmer()

                Capsule()
                    .fill(AppColors.borderLight)
                    .frame(width: 60, height: 16)
                    .shimmer()
            }
        }
        .padding(Spacing.md)
        .card()
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        BudgetItemSkeleton()
        BudgetItemSkeleton()
        BudgetItemSkeleton()
    }
    .padding()
    .background(AppColors.background)
}
