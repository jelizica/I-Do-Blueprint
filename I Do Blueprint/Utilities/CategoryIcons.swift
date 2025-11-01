import SwiftUI

/// Centralized category icon and color mapping for budget items
struct CategoryIcons {

    // MARK: - Icon Mapping

    /// Returns the SF Symbol icon name for a given category
    static func icon(for category: String) -> String {
        switch category.lowercased() {
        // Venue & Location
        case "venue", "venues":
            return "building.2.fill"
        case "accommodation", "hotel":
            return "bed.double.fill"

        // Food & Beverage
        case "catering", "food", "food & beverage":
            return "fork.knife"  // System SF Symbol
        case "cake", "dessert":
            return "birthday.cake.fill"
        case "bar", "beverage":
            return "wineglass.fill"

        // Photography & Videography
        case "photography", "photographer":
            return "camera.fill"
        case "videography", "video":
            return "video.fill"

        // Entertainment
        case "music", "entertainment", "dj":
            return "music.note"
        case "band", "live music":
            return "music.mic"

        // Flowers & Decorations
        case "flowers", "floral":
            return "leaf.fill"
        case "decorations", "decor":
            return "sparkles"

        // Attire & Beauty
        case "attire", "clothing":
            return "tshirt.fill"
        case "dress", "gown":
            return "figure.dress.line.vertical.figure"
        case "suit", "tuxedo":
            return "person.fill"
        case "hair", "makeup", "beauty":
            return "comb.fill"
        case "jewelry", "accessories":
            return "crown.fill"

        // Transportation
        case "transportation", "transport":
            return "car.fill"
        case "limo", "limousine":
            return "car.side.fill"

        // Stationery & Paper
        case "invitations", "stationery":
            return "envelope.fill"
        case "favors", "gifts":
            return "gift.fill"

        // Planning & Services
        case "planner", "coordinator":
            return "calendar.badge.checkmark"
        case "officiant":
            return "person.2.fill"

        // Miscellaneous
        case "miscellaneous", "other":
            return "star.fill"
        case "rentals", "rental":
            return "house.fill"
        case "insurance":
            return "shield.fill"

        default:
            return "dollarsign.circle.fill"
        }
    }

    // MARK: - Color Mapping

    /// Returns the color for a given category
    static func color(for category: String) -> Color {
        switch category.lowercased() {
        // Venue & Location
        case "venue", "venues":
            return .purple
        case "accommodation", "hotel":
            return .teal

        // Food & Beverage
        case "catering", "food", "food & beverage":
            return .orange
        case "cake", "dessert":
            return .pink
        case "bar", "beverage":
            return .red

        // Photography & Videography
        case "photography", "photographer":
            return .pink
        case "videography", "video":
            return .indigo

        // Entertainment
        case "music", "entertainment", "dj":
            return .blue
        case "band", "live music":
            return .cyan

        // Flowers & Decorations
        case "flowers", "floral":
            return .green
        case "decorations", "decor":
            return .mint

        // Attire & Beauty
        case "attire", "clothing":
            return .indigo
        case "dress", "gown":
            return .purple
        case "suit", "tuxedo":
            return .brown
        case "hair", "makeup", "beauty":
            return .pink
        case "jewelry", "accessories":
            return .yellow

        // Transportation
        case "transportation", "transport":
            return .cyan
        case "limo", "limousine":
            return .blue

        // Stationery & Paper
        case "invitations", "stationery":
            return .purple
        case "favors", "gifts":
            return .green

        // Planning & Services
        case "planner", "coordinator":
            return .orange
        case "officiant":
            return .blue

        // Miscellaneous
        case "miscellaneous", "other":
            return .gray
        case "rentals", "rental":
            return .brown
        case "insurance":
            return .blue

        default:
            return .gray
        }
    }

    // MARK: - Badge Component

    /// A reusable category badge view
    struct Badge: View {
        let category: String
        var showIcon: Bool = true
        var showLabel: Bool = true

        var body: some View {
            HStack(spacing: 6) {
                if showIcon {
                    Image(systemName: CategoryIcons.icon(for: category))
                        .font(.caption)
                        .foregroundColor(CategoryIcons.color(for: category))
                }

                if showLabel {
                    Text(category)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, showLabel ? 8 : 6)
            .padding(.vertical, Spacing.xs)
            .background(CategoryIcons.color(for: category).opacity(0.1))
            .cornerRadius(8)
        }
    }

    // MARK: - Category Dot

    /// A simple colored dot for category indication
    struct Dot: View {
        let category: String
        var size: CGFloat = 6

        var body: some View {
            Circle()
                .fill(CategoryIcons.color(for: category))
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Convenience Extensions

extension String {
    /// Returns the SF Symbol icon name for this category string
    var categoryIcon: String {
        CategoryIcons.icon(for: self)
    }

    /// Returns the color for this category string
    var categoryColor: Color {
        CategoryIcons.color(for: self)
    }
}
