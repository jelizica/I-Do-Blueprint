import SwiftUI

/// Skeleton loading placeholder for timeline items
struct TimelineItemSkeleton: View {
    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Date indicator skeleton
            VStack(spacing: Spacing.xs) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.borderLight)
                    .frame(width: 40, height: 14)
                    .shimmer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.borderLight)
                    .frame(width: 30, height: 20)
                    .shimmer()
            }
            .frame(width: 60)

            // Timeline dot
            Circle()
                .fill(AppColors.borderLight)
                .frame(width: 12, height: 12)
                .shimmer()

            // Content skeleton
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Event title
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.borderLight)
                    .frame(width: 200, height: 16)
                    .shimmer()

                // Event details
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.borderLight)
                    .frame(width: 140, height: 12)
                    .shimmer()
            }

            Spacer()
        }
        .padding(Spacing.md)
        .card()
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        TimelineItemSkeleton()
        TimelineItemSkeleton()
        TimelineItemSkeleton()
    }
    .padding()
    .background(AppColors.background)
}
