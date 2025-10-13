import SwiftUI

/// Skeleton loading placeholder for task cards
struct TaskCardSkeleton: View {
    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Checkbox skeleton
            RoundedRectangle(cornerRadius: 6)
                .fill(AppColors.borderLight)
                .frame(width: 24, height: 24)
                .shimmer()

            // Content skeleton
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Task title
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.borderLight)
                    .frame(width: 180, height: 16)
                    .shimmer()

                // Due date and priority
                HStack(spacing: Spacing.sm) {
                    Capsule()
                        .fill(AppColors.borderLight)
                        .frame(width: 80, height: 14)
                        .shimmer()

                    Capsule()
                        .fill(AppColors.borderLight)
                        .frame(width: 60, height: 14)
                        .shimmer()
                }
            }

            Spacer()

            // Category badge skeleton
            Capsule()
                .fill(AppColors.borderLight)
                .frame(width: 70, height: 20)
                .shimmer()
        }
        .padding(Spacing.md)
        .card()
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        TaskCardSkeleton()
        TaskCardSkeleton()
        TaskCardSkeleton()
    }
    .padding()
    .background(AppColors.background)
}
