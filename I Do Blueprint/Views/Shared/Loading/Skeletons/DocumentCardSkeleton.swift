import SwiftUI

/// Skeleton loading placeholder for document cards
struct DocumentCardSkeleton: View {
    var body: some View {
        HStack(spacing: Spacing.lg) {
            // File icon skeleton
            RoundedRectangle(cornerRadius: 8)
                .fill(SemanticColors.borderPrimaryLight)
                .frame(width: 48, height: 48)
                .shimmer()

            // Content skeleton
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Document name
                RoundedRectangle(cornerRadius: 4)
                    .fill(SemanticColors.borderPrimaryLight)
                    .frame(width: 160, height: 16)
                    .shimmer()

                // File type and size
                HStack(spacing: Spacing.sm) {
                    Capsule()
                        .fill(SemanticColors.borderPrimaryLight)
                        .frame(width: 40, height: 14)
                        .shimmer()

                    RoundedRectangle(cornerRadius: 4)
                        .fill(SemanticColors.borderPrimaryLight)
                        .frame(width: 60, height: 12)
                        .shimmer()
                }
            }

            Spacer()

            // Upload date skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(SemanticColors.borderPrimaryLight)
                .frame(width: 70, height: 12)
                .shimmer()
        }
        .padding(Spacing.md)
        .card()
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        DocumentCardSkeleton()
        DocumentCardSkeleton()
        DocumentCardSkeleton()
    }
    .padding()
    .background(SemanticColors.backgroundPrimary)
}
