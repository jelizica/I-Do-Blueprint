import SwiftUI

/// Skeleton loading placeholder for a small metric card (icon + title + value)
struct MetricCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Circle()
                    .fill(AppColors.borderLight)
                    .frame(width: 48, height: 48)
                    .shimmer()
                Spacer()
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.borderLight)
                    .frame(width: 80, height: 12)
                    .shimmer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.borderLight)
                    .frame(width: 60, height: 18)
                    .shimmer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.borderLight)
                    .frame(width: 100, height: 12)
                    .shimmer()
            }
        }
        .padding(Spacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppColors.shadowLight, radius: 2, x: 0, y: 1)
        .frame(minHeight: 120)
        .accessibilityHidden(true)
    }
}

#Preview {
    MetricCardSkeleton()
        .padding()
        .background(AppColors.background)
}
